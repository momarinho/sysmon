![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)

# Sysmon

Monitor de sistema em Dart com backend para coleta de metricas no Linux e um frontend Flutter Desktop planejado para visualizacao em tempo real.

## Objetivo

O projeto foi pensado para expor snapshots de uso de CPU, memoria, disco, rede e status de servicos via WebSocket, permitindo que um dashboard Flutter consuma os dados em tempo real.

## Status

O repositorio esta na fase inicial e, neste momento, a base em Dart esta sendo estruturada primeiro.
O frontend Flutter Desktop faz parte da arquitetura planejada e sera adicionado depois no mesmo ecossistema.

## Configuracao

As configuracoes devem vir de variaveis de ambiente. Exemplo:

```env
SYSMON_PORT=8080
SYSMON_INTERVAL_MS=2000
SYSMON_SERVICES=postgresql,redis,elasticsearch
SYSMON_LOG_LEVEL=info
```

## Estrutura Planejada

```text
┌─────────────────────────────────────────────┐
│         Flutter Desktop (Frontend)          │
│  Dashboard com fl_chart + riverpod          │
└───────────────┬─────────────────────────────┘
                │ WebSocket (JSON stream)
                │ ws://localhost:8080/ws
┌───────────────▼─────────────────────────────┐
│         Dart Backend (Servidor)             │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │  Collector Loop (a cada 2s)          │   │
│  │  cpu · mem · disk · net · services   │   │
│  └──────────────┬───────────────────────┘   │
│                 │ Stream<MetricsSnapshot>   │
│  ┌──────────────▼───────────────────────┐   │
│  │  WebSocket Handler                   │   │
│  │  Broadcast para todos os clientes    │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                │ le
┌───────────────▼─────────────────────────────┐
│  Linux Kernel                               │
│  /proc/stat · /proc/meminfo · /proc/net/dev │
│  /proc/diskstats · systemctl                │
└─────────────────────────────────────────────┘
```

## Roadmap Inicial

- Estruturar o backend em Dart para leitura das fontes do Linux.
- Gerar `MetricsSnapshot` em intervalo configuravel.
- Expor stream via WebSocket para multiplos clientes.
- Adicionar frontend Flutter Desktop para dashboard em tempo real.
