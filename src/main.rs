mod collectors;
mod config;
mod logging;
mod models;
mod server;
mod prometheus;

use std::sync::Arc;

use axum::serve;
use config::Config;
use logging::{LogLevel, Logger};
use server::{AppState, run_collector_loop, router};
use tokio::net::TcpListener;
use tokio::sync::{RwLock, broadcast};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::from_env()?;
    Logger::configure(config.log_level);

    let latest = Arc::new(RwLock::new(None));
    let (tx, _) = broadcast::channel(64);

    let state = AppState::new(config.clone(), Arc::clone(&latest), tx.clone());

    let collector_handle = tokio::spawn(run_collector_loop(
        config.clone(),
        Arc::clone(&latest),
        tx,
    ));

    let listener = TcpListener::bind(("127.0.0.1", config.port)).await?;

    Logger::new("Main").info(
        "Server started",
        serde_json::json!({
            "port": config.port,
            "interval_ms": config.interval_ms,
            "services": config.services,
            "log_level": match config.log_level {
                LogLevel::Debug => "debug",
                LogLevel::Info => "info",
                LogLevel::Warn => "warn",
                LogLevel::Error => "error",
            },
            "endpoints": ["/health", "/metrics", "/metrics/prometheus", "/ws"],
        }),
    );

    let app = router(state);
    let server = serve(listener, app).with_graceful_shutdown(async {
        let _ = tokio::signal::ctrl_c().await;
    });

    if let Err(error) = server.await {
        Logger::new("Main").error(
            "Server terminated with error",
            serde_json::json!({ "error": error.to_string() }),
        );
    }

    collector_handle.abort();
    let _ = collector_handle.await;

    Ok(())
}

