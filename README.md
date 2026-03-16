![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)

# Sysmon

A Dart-based system monitor with a backend for collecting Linux metrics and a planned Flutter Desktop frontend for real-time visualization.

## Goal

The project is designed to expose snapshots of CPU, memory, disk, network, and service status over WebSocket so a Flutter dashboard can consume the data in real time.

## Status

The repository is in its initial phase, and the Dart backend foundation is being built first.
The Flutter Desktop frontend is part of the planned architecture and will be added later in the same ecosystem.

## Configuration

Configuration should come from environment variables. Example:

```env
SYSMON_PORT=8080
SYSMON_INTERVAL_MS=2000
SYSMON_SERVICES=postgresql,redis,elasticsearch
SYSMON_LOG_LEVEL=info
```

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
