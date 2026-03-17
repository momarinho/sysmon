![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)

# Sysmon

A Dart-based system monitor with a phase-2 backend that collects Linux metrics and exposes them over HTTP, Prometheus, and WebSocket for a future Flutter Desktop frontend.

## Goal

The project is designed to expose snapshots of CPU, memory, disk, network, and service status over WebSocket so a Flutter dashboard can consume the data in real time.

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
dart run bin/server.dart
```

## Phase 2 checks

```bash
# Liveness
curl -s http://localhost:8080/health | jq .

# JSON snapshot
curl -s http://localhost:8080/metrics | jq .

# Prometheus exposition
curl -s http://localhost:8080/metrics/prometheus

# Backend validation
dart analyze
dart test
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
│         Dart Backend (Server)               │
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

## Initial Roadmap

- Structure the Dart backend to read Linux data sources.
- Generate `MetricsSnapshot` on a configurable interval.
- Expose the stream over WebSocket for multiple clients.
- Add a Flutter Desktop frontend for a real-time dashboard.
