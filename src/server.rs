use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{Duration, Instant};

use axum::extract::State;
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::http::{HeaderMap, StatusCode, header};
use axum::response::{IntoResponse, Response};
use axum::routing::get;
use axum::{Json, Router};
use chrono::Utc;
use serde_json::{Value, json};
use tokio::sync::{RwLock, broadcast};

use crate::collectors::{
    CpuCollector, DiskCollector, MemCollector, NetCollector, ServiceCollector
};
use crate::config::Config;
use crate::models::MetricsSnapshot;
use crate::logging::{Logger, empty};
use crate::prometheus::PrometheusFormatter;

static REQUEST_SEQUENCE: AtomicU64 = AtomicU64::new(0);

#[derive(Clone)]
pub struct AppState {
    latest: Arc<RwLock<Option<MetricsSnapshot>>>,
    tx: broadcast::Sender<MetricsSnapshot>,
    start: Instant,
}

impl AppState {
    pub fn new(
        _config: Config,
        latest: Arc<RwLock<Option<MetricsSnapshot>>>,
        tx: broadcast::Sender<MetricsSnapshot>,
    ) -> Self {
        Self {
            latest,
            tx,
            start: Instant::now(),
        }
    }
}

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health))
        .route("/metrics", get(metrics))
        .route("/metrics/prometheus", get(prometheus_metrics))
        .route("/ws", get(ws_upgrade))
        .with_state(state)
}

pub async fn run_collector_loop(
    config: Config,
    latest: Arc<RwLock<Option<MetricsSnapshot>>>,
    tx: broadcast::Sender<MetricsSnapshot>,
) {
    let log = Logger::new("CollectorLoop");
    let mut cpu = CpuCollector::new();
    let mem = MemCollector::new();
    let mut disk = DiskCollector::new();
    let mut network = NetCollector::new();
    let services = ServiceCollector::new(config.services.clone());

    log.info(
        "Starting collection",
        json!({ "interval_ms": config.interval_ms }),
    );

    loop {
        let snapshot = MetricsSnapshot {
            timestamp: Utc::now(),
            cpu: cpu.collect(),
            memory: mem.collect(),
            disk: disk.collect(),
            network: network.collect(),
            services: services.collect(),
        };

        {
            let mut guard = latest.write().await;
            *guard = Some(snapshot.clone());
        }

        let _ = tx.send(snapshot.clone());
        log.debug(
            "Snapshot collected",
            json!({
                "cpu_pct": snapshot.cpu.usage_percent,
                "mem_pct": snapshot.memory.used_percent,
                "disk_read_bps": snapshot.disk.bytes_read_per_sec,
                "disk_write_bps": snapshot.disk.bytes_written_per_sec,
                "net_recv_bps": snapshot.network.bytes_recv,
                "net_sent_bps": snapshot.network.bytes_sent,
                "services_count": snapshot.services.services.len(),
            }),
        );

        tokio::time::sleep(Duration::from_millis(config.interval_ms)).await;
    }
}

async fn health(State(state): State<AppState>) -> Response {
    let started = Instant::now();
    let request_id = next_request_id();
    let body = json!({
        "status": "ok",
        "request_id": request_id,
        "uptime_seconds": state.start.elapsed().as_secs(),
        "version": "0.2.0",
    });
    json_response(
        StatusCode::OK,
        &request_id,
        body,
        Some("/health"),
        "GET",
        started,
        None,
    )
}

async fn metrics(State(state): State<AppState>) -> Response {
    let started = Instant::now();
    let request_id = next_request_id();
    let snapshot = state.latest.read().await.clone();

    match snapshot {
        Some(snapshot) => json_response(
            StatusCode::OK,
            &request_id,
            serde_json::to_value(snapshot).unwrap_or_else(|_| json!({})),
            Some("/metrics"),
            "GET",
            started,
            None,
        ),
        None => json_response(
            StatusCode::SERVICE_UNAVAILABLE,
            &request_id,
            json!({
                "error": "collecting, try again",
                "request_id": request_id,
            }),
            Some("/metrics"),
            "GET",
            started,
            None,
        ),
    }
}

async fn prometheus_metrics(State(state): State<AppState>) -> Response {
    let started = Instant::now();
    let request_id = next_request_id();
    let snapshot = state.latest.read().await.clone();

    match snapshot {
        Some(snapshot) => text_response(
            StatusCode::OK,
            &request_id,
            PrometheusFormatter::format(&snapshot),
            Some("/metrics/prometheus"),
            "GET",
            started,
            None,
        ),
        None => json_response(
            StatusCode::SERVICE_UNAVAILABLE,
            &request_id,
            json!({
                "error": "collecting, try again",
                "request_id": request_id,
            }),
            Some("/metrics/prometheus"),
            "GET",
            started,
            None,
        ),
    }
}

async fn ws_upgrade(ws: WebSocketUpgrade, State(state): State<AppState>) -> impl IntoResponse {
    let request_id = next_request_id();
    Logger::new("HttpHandler").debug(
        "Request",
        json!({
            "request_id": request_id,
            "method": "GET",
            "path": "/ws",
        }),
    );

    ws.on_upgrade(move |socket| handle_socket(socket, state))
}

async fn handle_socket(mut socket: WebSocket, state: AppState) {
    let log = Logger::new("WebSocketHandler");
    let mut rx = state.tx.subscribe();

    if let Some(snapshot) = state.latest.read().await.clone() {
        let _ = socket
            .send(Message::Text(
                serde_json::to_string(&snapshot)
                    .unwrap_or_else(|_| "{}".into())
                    .into(),
            ))
            .await;
    }

    log.info("Client connected", empty());

    loop {
        match rx.recv().await {
            Ok(snapshot) => {
                if socket
                    .send(Message::Text(
                        serde_json::to_string(&snapshot)
                            .unwrap_or_else(|_| "{}".into())
                            .into(),
                    ))
                    .await
                    .is_err()
                {
                    break;
                }
            }
            Err(broadcast::error::RecvError::Lagged(_)) => continue,
            Err(_) => break,
        }
    }

    log.info("Client disconnected", empty());
}

fn next_request_id() -> String {
    format!(
        "req-{}",
        REQUEST_SEQUENCE.fetch_add(1, Ordering::Relaxed) + 1
    )
}

fn json_response(
    status: StatusCode,
    request_id: &str,
    body: Value,
    path: Option<&str>,
    method: &str,
    started: Instant,
    remote_addr: Option<&str>,
) -> Response {
    let mut headers = HeaderMap::new();
    headers.insert("access-control-allow-origin", "*".parse().unwrap());
    headers.insert("x-request-id", request_id.parse().unwrap());

    Logger::new("HttpHandler").info(
        "Request handled",
        json!({
            "request_id": request_id,
            "method": method,
            "path": path.unwrap_or(""),
            "status": status.as_u16(),
            "latency_ms": started.elapsed().as_millis(),
            "remote_addr": remote_addr,
        }),
    );

    (status, headers, Json(body)).into_response()
}

fn text_response(
    status: StatusCode,
    request_id: &str,
    body: String,
    path: Option<&str>,
    method: &str,
    started: Instant,
    remote_addr: Option<&str>,
) -> Response {
    let mut headers = HeaderMap::new();
    headers.insert("access-control-allow-origin", "*".parse().unwrap());
    headers.insert("x-request-id", request_id.parse().unwrap());
    headers.insert(
        header::CONTENT_TYPE,
        "text/plain; version=0.0.4; charset=utf-8".parse().unwrap(),
    );

    Logger::new("HttpHandler").info(
        "Request handled",
        json!({
            "request_id": request_id,
            "method": method,
            "path": path.unwrap_or(""),
            "status": status.as_u16(),
            "latency_ms": started.elapsed().as_millis(),
            "remote_addr": remote_addr,
        }),
    );

    (status, headers, body).into_response()
}

#[cfg(test)]
mod tests {
    use chrono::Utc;
    use serde_json::json;

    use super::*;
    use crate::models::{
        CpuMetrics, DiskMetrics, FilesystemInfo, InterfaceInfo, MemMetrics, NetMetrics,
        ServiceInfo, ServiceMetrics,
    };

    fn sample_snapshot() -> MetricsSnapshot {
        let mut disk = DiskMetrics::new(1_000, 400);
        disk.add_filesystem(FilesystemInfo {
            mount_point: "/".into(),
            device: "/dev/sda1".into(),
            total_bytes: 1_000,
            used_bytes: 400,
            used_percent: 40.0,
        });
        disk.bytes_read_per_sec = 12.5;
        disk.bytes_written_per_sec = 8.5;

        let mut network = NetMetrics::new();
        network.bytes_recv = 1_024;
        network.bytes_sent = 2_048;
        network.packets_recv = 10;
        network.packets_sent = 20;
        network.errors_in = 1;
        network.errors_out = 2;
        network.dropped_in = 3;
        network.dropped_out = 4;
        network.add_interface(InterfaceInfo {
            name: "eth0".into(),
            bytes_recv: 1_024,
            bytes_sent: 2_048,
            status: "up".into(),
        });

        let mut services = ServiceMetrics::new();
        services.add_service(ServiceInfo {
            name: "postgresql".into(),
            status: "running".into(),
            memory_kb: 8_192,
            cpu_percent: 1.5,
            pid: 1234,
        });

        MetricsSnapshot {
            timestamp: Utc::now(),
            cpu: CpuMetrics {
                model_name: "Test CPU".into(),
                usage_percent: 42.0,
                cores: 8,
                per_core: vec![42.0; 8],
            },
            memory: MemMetrics::new(1_000, 200, 600, 100, 300, 200, 50),
            disk,
            network,
            services,
        }
    }

    #[test]
    fn metrics_json_contract_includes_disk_network_and_services() {
        let payload = serde_json::to_value(sample_snapshot()).unwrap();

        assert_eq!(payload["disk"]["bytes_read_per_sec"], json!(12.5));
        assert_eq!(payload["network"]["bytes_recv"], json!(1_024));
        assert_eq!(payload["services"]["services"][0]["name"], json!("postgresql"));
        assert!(payload.get("net").is_none());
    }

    #[test]
    fn websocket_payload_matches_json_contract() {
        let snapshot = sample_snapshot();
        let json_payload = serde_json::to_value(&snapshot).unwrap();
        let ws_payload: serde_json::Value = serde_json::from_str(
            &serde_json::to_string(&snapshot).unwrap(),
        )
        .unwrap();

        assert_eq!(ws_payload, json_payload);
    }
}
