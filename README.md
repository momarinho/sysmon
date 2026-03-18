![Rust](https://img.shields.io/badge/Rust-000000?style=flat&logo=rust&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)

# Sysmon

Sysmon is a Linux system monitor with a Rust backend and a Flutter Desktop frontend.

## Goal

The backend collects system metrics from Linux sources such as `/proc` and exposes them over HTTP and WebSocket so the Flutter dashboard can consume them in real time.

## Status

Current backend scope:

- CPU and memory collectors
- Periodic collection loop
- `GET /health` liveness endpoint
- `GET /metrics` JSON snapshot endpoint
- `GET /metrics/prometheus` Prometheus exposition endpoint
- `GET /ws` WebSocket stream for realtime snapshots
- Structured JSON logging to stdout
- Environment-based validated configuration
- Request logs with `request_id`

Current frontend scope:

- Linux Flutter desktop app in `flutter_app`
- Realtime dashboard connected to `ws://localhost:8080/ws`
- CPU and memory visualization

## Configuration

Configuration comes from environment variables and is validated at startup. Example:

```env
SYSMON_PORT=8080
SYSMON_INTERVAL_MS=2000
SYSMON_SERVICES=postgresql,redis,elasticsearch
SYSMON_LOG_LEVEL=info
```

Rules:

- `SYSMON_PORT`: integer between `1` and `65535`
- `SYSMON_INTERVAL_MS`: integer greater than `0`
- `SYSMON_SERVICES`: comma-separated list of service names
- `SYSMON_LOG_LEVEL`: `debug`, `info`, `warn`, or `error`

## Running

```bash
cargo run
```

The active backend entrypoint is [src/main.rs](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/src/main.rs).

To run the Flutter desktop app:

```bash
cd flutter_app
flutter run -d linux
```

## Pending Work

- Add disk, network, and service collectors
- Expand production and packaging setup
- Keep backend and frontend CI green

## CI

GitHub Actions covers the required roadmap checks:

- backend: `cargo test` and `cargo build --release`
- frontend: `flutter analyze`, `flutter test`, and `flutter build linux --release`

## Phase 2 checks

```bash
# Liveness
curl -s http://localhost:8080/health | jq .

# JSON snapshot
curl -s http://localhost:8080/metrics | jq .

# Prometheus exposition
curl -i http://localhost:8080/metrics/prometheus

# Backend validation
cargo test
```

## Logging

Logs are emitted as JSON to stdout with stable fields:

- `timestamp`
- `level`
- `component`
- `message`

Request-specific logs and responses also include `request_id`.

## Planned Structure

```text
┌─────────────────────────────────────────────┐
│         Flutter Desktop (Frontend)          │
│  Dashboard with fl_chart + riverpod         │
└───────────────┬─────────────────────────────┘
                │ WebSocket (JSON stream)
                │ ws://localhost:8080/ws
┌───────────────▼─────────────────────────────┐
│         Rust Backend (Server)               │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │  Collector Loop (every 2s)           │   │
│  │  cpu · mem · disk · net · services   │   │
│  └──────────────┬───────────────────────┘   │
│                 │ Stream<MetricsSnapshot>   │
│  ┌──────────────▼───────────────────────┐   │
│  │  WebSocket Handler                   │   │
│  │  Broadcast to all clients            │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                │ reads
┌───────────────▼─────────────────────────────┐
│  Linux Kernel                               │
│  /proc/stat · /proc/meminfo · /proc/net/dev │
│  /proc/diskstats · systemctl                │
└─────────────────────────────────────────────┘
```

## Rust Backend Files

- [Cargo.toml](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/Cargo.toml)
- [src/main.rs](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/src/main.rs)
- [src/config.rs](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/src/config.rs)
- [src/logging.rs](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/src/logging.rs)
- [src/models.rs](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/src/models.rs)
- [src/collectors.rs](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/src/collectors.rs)
- [src/server.rs](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/src/server.rs)

## Frontend Files

- [flutter_app/pubspec.yaml](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/flutter_app/pubspec.yaml)
- [flutter_app/lib/main.dart](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/flutter_app/lib/main.dart)
- [flutter_app/lib/screens/dashboard_screen.dart](/run/media/mateus/f8271cf2-fe57-43a3-a203-4b4c407bd599/sysmon/flutter_app/lib/screens/dashboard_screen.dart)
