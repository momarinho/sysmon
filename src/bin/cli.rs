use clap::Parser;

#[derive(Parser)]
#[command(name = "sysmon")]
#[command(about = "CLI para gerenciar sysmon")]
struct Args {
    #[command(subcommand)]
    command: Command,
}

#[derive(Parser)]
enum Command {
    Status {
        #[arg(long, default_value = "http://localhost:8080")]
        server: String,
    },
    ShowConfig {
        #[arg(long, default_value = "http://localhost:8080")]
        server: String,
    },
    Metrics {
        #[arg(long, default_value = "http://localhost:8080")]
        server: String,
    },
    Health {
        #[arg(long, default_value = "http://localhost:8080")]
        server: String,
    },
}

#[tokio::main]
async fn main() {
    let args = Args::parse();
    
    let result = match args.command {
        Command::Status { server } => check_status(&server).await,
        Command::ShowConfig { server } => show_config(&server).await,
        Command::Metrics { server } => fetch_metrics(&server).await,
        Command::Health { server } => check_health(&server).await,
    };
    
    if let Err(e) = result {
        eprintln!("Erro: {}", e);
        std::process::exit(1);
    }
}

async fn check_status(server: &str) -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();
    match client.get(&format!("{}/health", server)).send().await {
        Ok(res) => {
            println!("✓ Servidor rodando ({} {})", res.status().as_u16(), res.status().canonical_reason().unwrap_or("OK"));
            Ok(())
        }
        Err(_) => {
            println!("✗ Servidor offline");
            Err("Servidor não respondeu".into())
        }
    }
}

async fn check_health(server: &str) -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();
    let res = client.get(&format!("{}/health", server)).send().await?;
    println!("Status: {}", res.status());
    Ok(())
}

async fn fetch_metrics(server: &str) -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();
    let res = client.get(&format!("{}/metrics", server)).send().await?;
    let body = res.text().await?;
    println!("{}", body);
    Ok(())
}

async fn show_config(server: &str) -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();
    let res = client.get(&format!("{}/health", server)).send().await?;
    println!("Servidor: {}", server);
    println!("Status: {}", res.status());
    Ok(())
}
