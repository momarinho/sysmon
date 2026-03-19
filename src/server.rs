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

use crate::collectors::{CpuCollector, MemCollector};
use crate::models::{MetricsSnapshot, DiskMetrics, NetMetrics, ServiceMetrics};
use crate::config::Config;
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

    log.info(
        "Starting collection",
        json!({ "interval_ms": config.interval_ms }),
    );

    loop {
        let snapshot = MetricsSnapshot {
            timestamp: Utc::now(),
            cpu: cpu.collect(),
            memory: mem.collect(),
            disk: DiskMetrics::new(0, 0),
            network: NetMetrics::new(),
            services: ServiceMetrics::new(),
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
