# SysMon Roadmap

Roadmap atualizado para a arquitetura atual do projeto:

- backend em Rust
- frontend desktop em Flutter
- foco em observabilidade, baixo retrabalho e entregas incrementais

Convencoes deste documento:

- Obrigatorio: item necessario para considerar a fase concluida
- Recomendado: item importante para reduzir risco ou retrabalho
- Adiavel: item util, mas que pode esperar

## Estado Atual

Ja concluido:

- backend Rust com config tipada
- logging JSON estruturado
- coletores de CPU e memoria
- loop de coleta periodica
- `GET /health`
- `GET /metrics`
- `GET /ws`
- frontend Flutter desktop consumindo o stream

Pendente imediato:

- `GET /metrics/prometheus`
- alinhamento final da documentacao
- pipeline de CI para backend Rust e frontend Flutter

## Fase 1 - Backend Rust Core

Objetivo: manter uma base pequena, correta e facil de expandir sem reescrever o servidor.

### Estrutura

- Obrigatorio: `Cargo.toml` no root do projeto
- Obrigatorio: backend em `src/`
- Obrigatorio: frontend preservado em `flutter_app/`
- Obrigatorio: `.env.example` documentando variaveis aceitas
- Obrigatorio: `README.md` com arquitetura, execucao local e endpoints

### Config

- Obrigatorio: carregar env vars uma vez no startup
- Obrigatorio: validar `SYSMON_PORT`, `SYSMON_INTERVAL_MS`, `SYSMON_SERVICES` e `SYSMON_LOG_LEVEL`
- Obrigatorio: falhar com erro claro em configuracao invalida
- Recomendado: manter o parser desacoplado para testes unitarios

### Logging

- Obrigatorio: schema fixo com `timestamp`, `level`, `message`, `component`
- Obrigatorio: `request_id` em respostas HTTP e logs de request
- Obrigatorio: saida JSON em `stdout`

### Coletores

- Obrigatorio: `MetricsSnapshot` como modelo central
- Obrigatorio: `CpuCollector` lendo `/proc/stat`
- Obrigatorio: `MemCollector` lendo `/proc/meminfo`
- Recomendado: parsing testavel com entradas artificiais

### Testes

- Obrigatorio: testes unitarios de config
- Obrigatorio: testes unitarios dos coletores
- Recomendado: testes unitarios do formatter Prometheus quando ele existir

### Checklist de saida

- Obrigatorio: `cargo test` verde
- Obrigatorio: `cargo run` sobe o servidor localmente
- Obrigatorio: `curl /health` responde `200`
- Obrigatorio: `curl /metrics` responde snapshot valido

## Fase 2 - Observabilidade e Paridade de Endpoints

Objetivo: fechar a paridade minima do backend e estabilizar o contrato consumido pelo frontend.

### Servidor

- Obrigatorio: manter `GET /health`, `GET /metrics`, `GET /metrics/prometheus` e `GET /ws`
- Obrigatorio: cache do ultimo snapshot em memoria
- Obrigatorio: broadcast WebSocket para varios clientes
- Obrigatorio: remocao automatica de clientes desconectados

### Prometheus

- Obrigatorio: implementar formatter Rust com `# HELP` e `# TYPE`
- Obrigatorio: exportar no minimo:
  - `sysmon_cpu_usage_percent`
  - `sysmon_cpu_cores_total`
  - `sysmon_memory_total_bytes`
  - `sysmon_memory_available_bytes`
  - `sysmon_memory_used_percent`
  - `sysmon_memory_swap_total_bytes`
- Obrigatorio: responder `text/plain; version=0.0.4; charset=utf-8`

### Logs de request

- Obrigatorio: logar `method`, `path`, `status` e `latency_ms`
- Recomendado: incluir `remote_addr` quando houver

### Validacao de runtime

- Obrigatorio: `cargo build --release`
- Obrigatorio: validar o binario `target/release/sysmon-rs`
- Obrigatorio: smoke test com `curl /health`
- Obrigatorio: smoke test com `curl /metrics`
- Obrigatorio: smoke test com `curl /metrics/prometheus`
- Recomendado: validar WebSocket com `websocat ws://localhost:8080/ws`

### Checklist de saida

- Obrigatorio: `/metrics/prometheus` retorna texto valido
- Obrigatorio: binario release funciona como o binario de debug
- Obrigatorio: frontend Flutter continua funcionando sem ajuste de contrato

## Fase 3 - Frontend e CI

Objetivo: consolidar o dashboard e automatizar validacao do projeto inteiro.

### Frontend Flutter

- Obrigatorio: app Linux desktop funcional
- Obrigatorio: conexao com `ws://localhost:8080/ws`
- Obrigatorio: KPI cards para metricas reais
- Obrigatorio: grafico de CPU em tempo real
- Obrigatorio: card de memoria com dados reais

### Design System

- Obrigatorio: identidade visual consistente
- Obrigatorio: componentes visuais padronizados
- Recomendado: tema centralizado em `flutter_app/lib/theme/`

### CI - GitHub Actions

- Obrigatorio: job `backend`
  - `cargo test`
  - `cargo build --release`
- Obrigatorio: job `frontend`
  - `flutter analyze`
  - `flutter test`
  - `flutter build linux --release`

### Checklist de saida

- Obrigatorio: app Flutter conecta no backend Rust
- Obrigatorio: GitHub Actions verde para backend e frontend
- Recomendado: validacao em mais de uma resolucao

## Fase 3.5 - CLI (Interface de Linha de Comando)

Objetivo: fornecer ferramenta de linha de comando para gerenciar e consultar o daemon do backend.

### Comandos Basicos

- Obrigatorio: `sysmon status` - verifica se o servidor esta rodando
- Obrigatorio: `sysmon show-config` - exibe configuracao atual
- Obrigatorio: `sysmon metrics` - fetch em `/metrics` e formata saida
- Obrigatorio: `sysmon health` - verifica `/health` endpoint

### Implementacao

- Obrigatorio: usar `clap` para parsing de argumentos
- Obrigatorio: testes unitarios para parsers e chamadas HTTP
- Recomendado: output formatado (JSON ou tabular)
- Recomendado: codigo desacoplado da logica do servidor

### Checklist de saida

- Obrigatorio: `cargo test` com testes de CLI verde
- Obrigatorio: cada comando respondendo sem erro
- Obrigatorio: tratamento de erro quando servidor nao esta disponivel
- Recomendado: help message completo em `sysmon --help`

## Fase 4 - Expansao de Metricas

Objetivo: completar os coletores planejados e ampliar o modelo de snapshot sem quebrar o frontend atual.

### Coletores restantes

- Obrigatorio: `DiskCollector` via `/proc/diskstats`
- Obrigatorio: `NetCollector` via `/proc/net/dev`
- Obrigatorio: `ServiceCollector` via `systemctl`

### Modelo

- Obrigatorio: expandir `MetricsSnapshot` com disco, rede e servicos
- Obrigatorio: refletir as novas metricas em JSON, WebSocket e Prometheus
- Recomendado: versionar mudancas de contrato se o frontend precisar de transicao

### Frontend

- Obrigatorio: widgets para disco, rede e status de servicos
- Adiavel: tela de alertas enquanto o backend ainda nao emitir alertas

### Checklist de saida

- Obrigatorio: `/metrics` inclui `disk`, `net` e `services`
- Obrigatorio: exporter Prometheus inclui novas metricas
- Obrigatorio: frontend mostra as novas secoes sem regressao nas metricas atuais

## Fase 5 - Operacao e Empacotamento

Objetivo: preparar o projeto para execucao continua fora do ambiente de desenvolvimento.

### Operacao

- Obrigatorio: unit file `systemd` para o backend
- Obrigatorio: restart policy e configuracao por env
- Recomendado: hardening minimo do servico
- Recomendado: instrucoes de observacao com `journalctl`

### Empacotamento

- Obrigatorio: fluxo de build reproduzivel para backend e frontend
- Obrigatorio: `INSTALL.md` ou secao equivalente no `README`
- Recomendado: `Makefile` ou `justfile` para tarefas comuns

### Checklist de saida

- Obrigatorio: instalacao documentada sem ambiguidade
- Obrigatorio: binario backend e app Flutter gerados em release
- Recomendado: processo de instalacao validado em maquina limpa