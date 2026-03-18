use std::error::Error;

use clap::{Args, Parser, Subcommand};
use reqwest::StatusCode;
use serde_json::Value;
use sysmon_rs::Config;

#[derive(Debug, Parser)]
#[command(name = "sysmon")]
#[command(about = "CLI para consultar o backend Sysmon")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    Status(ServerArgs),
    ShowConfig,
    Metrics(ServerArgs),
    Health(ServerArgs),
}

#[derive(Debug, Clone, Args)]
struct ServerArgs {
    #[arg(long, default_value = "http://127.0.0.1:8080")]
    server: String,
}

#[tokio::main]
async fn main() {
    let cli = Cli::parse();

    let result = match cli.command {
        Command::Status(args) => check_status(&args.server).await,
        Command::ShowConfig => show_config(),
        Command::Metrics(args) => fetch_metrics(&args.server).await,
        Command::Health(args) => check_health(&args.server).await,
    };

    if let Err(error) = result {
        eprintln!("error: {error}");
        std::process::exit(1);
    }
}

async fn check_status(server: &str) -> Result<(), Box<dyn Error>> {
    let response = reqwest::Client::new()
        .get(endpoint(server, "/health"))
        .send()
        .await?;

    if response.status().is_success() {
        println!("server online ({})", response.status());
        return Ok(());
    }

    Err(format!("health check failed with status {}", response.status()).into())
}

async fn check_health(server: &str) -> Result<(), Box<dyn Error>> {
    let response = reqwest::Client::new()
        .get(endpoint(server, "/health"))
        .send()
        .await?;
    let status = response.status();
    let body = response.text().await?;

    println!("status: {status}");
    println!("{body}");

    if status == StatusCode::OK {
        Ok(())
    } else {
        Err(format!("health endpoint returned {}", status).into())
    }
}

async fn fetch_metrics(server: &str) -> Result<(), Box<dyn Error>> {
    let response = reqwest::Client::new()
        .get(endpoint(server, "/metrics"))
        .send()
        .await?;
    let status = response.status();
    let body = response.text().await?;

    if !status.is_success() {
        return Err(format!("metrics endpoint returned {}", status).into());
    }

    if let Ok(json) = serde_json::from_str::<Value>(&body) {
        println!("{}", serde_json::to_string_pretty(&json)?);
    } else {
        println!("{body}");
    }

    Ok(())
}

fn show_config() -> Result<(), Box<dyn Error>> {
    let config = Config::from_env()?;

    println!("port: {}", config.port);
    println!("interval_ms: {}", config.interval_ms);
    println!("services: {}", config.services.join(","));
    println!("log_level: {}", config.log_level);

    Ok(())
}

fn endpoint(server: &str, path: &str) -> String {
    format!("{}{}", server.trim_end_matches('/'), path)
}

#[cfg(test)]
mod tests {
    use clap::Parser;

    use super::{Cli, Command, endpoint};

    #[test]
    fn parses_metrics_command_with_custom_server() {
        let cli = Cli::try_parse_from(["sysmon", "metrics", "--server", "http://localhost:9090"])
            .expect("cli should parse");

        match cli.command {
            Command::Metrics(args) => assert_eq!(args.server, "http://localhost:9090"),
            _ => panic!("expected metrics command"),
        }
    }

    #[test]
    fn joins_server_and_path_without_duplicate_slash() {
        assert_eq!(
            endpoint("http://localhost:8080/", "/health"),
            "http://localhost:8080/health"
        );
    }
}
