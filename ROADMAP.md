# SysMon Roadmap

Roadmap revisado com foco em entregas executaveis, observabilidade e baixo retrabalho.

Convencoes deste documento:

- Obrigatorio: item necessario para considerar a fase concluida
- Recomendado: item que deve ser validado cedo, mas nao bloqueia toda a fase
- Adiavel: item util, mas pode esperar a fase seguinte sem comprometer a base

## Fase 1 - Core e Fundacao

Objetivo: criar uma base solida que nao precise ser reescrita quando o servidor e o frontend crescerem.

### Estrutura

- Obrigatorio: `dart create --template=package sysmon`
- Obrigatorio: estrutura minima `bin`, `lib/src/{collectors,config,logging}`, `test`, `deploy`
- Obrigatorio: `.gitignore`
- Obrigatorio: `.env.example` documentando variaveis
- Obrigatorio: `README.md` com arquitetura, execucao local e endpoints planejados

### Config

- Obrigatorio: `Config.fromEnvironment()` carrega todas as env vars de uma vez
- Obrigatorio: validacao tipada com limites para inteiros e enum para `LogLevel`
- Obrigatorio: `ConfigException` agrega todos os erros encontrados de configuracao
- Obrigatorio: `Config` passada por injecao de dependencia, sem leitura espalhada de env

### Logging

- Obrigatorio: schema fixo e congelado com `timestamp`, `level`, `message`, `component`, `request_id` opcional
- Obrigatorio: `Logger(component)` com `debug`, `info`, `warn`, `error`
- Obrigatorio: saida JSON em `stdout`
- Recomendado: `Logger.withRequestId(id)` ou mecanismo equivalente para rastreabilidade

### Coletores

- Obrigatorio: `MetricsSnapshot` como modelo central com `CpuMetrics` e `MemMetrics`
- Obrigatorio: `CpuCollector` lendo `/proc/stat` com calculo diferencial entre leituras
- Obrigatorio: `MemCollector` lendo `/proc/meminfo` por parsing de campos nomeados
- Recomendado: `CpuCollector({String? source})` para aceitar fixture em testes
- Recomendado: `MemCollector({String? source})` para aceitar fixture em testes

### Testes

- Obrigatorio: testes unitarios de `Config`
- Obrigatorio: testes unitarios de `Logger`
- Obrigatorio: testes unitarios dos coletores
- Recomendado: `test/fixtures/proc_stat.txt`
- Recomendado: `test/fixtures/proc_meminfo.txt`

### Commits sugeridos

- `chore: project structure, gitignore and env example`
- `docs: README with architecture and execution guide`
- `feat(config): typed config with env validation`
- `feat(logging): structured JSON logger with fixed schema`
- `feat(collectors): metrics snapshot and Linux collectors`
- `test: unit tests and fixtures for core components`

### Checklist de saida

- Obrigatorio: `dart analyze` sem issues
- Obrigatorio: `dart test` verde
- Obrigatorio: configuracao invalida imprime erro claro e encerra com falha
- Obrigatorio: logger produz JSON compativel com o schema definido

## Fase 2 - Servidor, Observabilidade e Validacao de Runtime

Objetivo: entregar um servidor funcional, observavel e validado em runtime real antes de iniciar o frontend.

### Servidor

- Obrigatorio: `CollectorLoop` com `StreamController<MetricsSnapshot>.broadcast()`
- Obrigatorio: `Timer.periodic` usando `Config.intervalMs`
- Obrigatorio: primeira coleta imediata no `start()`
- Obrigatorio: cache do ultimo snapshot em memoria para uso por REST
- Obrigatorio: `WebSocketHandler` com broadcast para varios clientes
- Obrigatorio: remocao automatica de clientes mortos
- Obrigatorio: `HttpHandler` com rotas `GET /health`, `GET /metrics`, `GET /metrics/prometheus` e `GET /ws`
- Obrigatorio: `request_id` por request
- Obrigatorio: correlacao de logs por request, via `withRequestId` ou equivalente

### Observabilidade

- Obrigatorio: `PrometheusFormatter` com `# HELP` e `# TYPE`
- Obrigatorio: exportar no minimo:
  - `sysmon_cpu_usage_percent`
  - `sysmon_cpu_cores_total`
  - `sysmon_memory_total_bytes`
  - `sysmon_memory_available_bytes`
  - `sysmon_memory_used_percent`
  - `sysmon_memory_swap_total_bytes`
- Obrigatorio: logging por request com `method`, `path`, `status` e `latency_ms`
- Recomendado: incluir `remote_addr` quando disponivel

### Validacao de runtime

- Obrigatorio: `dart compile exe bin/server.dart -o build/sysmon-agent`
- Obrigatorio: validar o binario compilado com `./build/sysmon-agent`
- Obrigatorio: smoke test com `curl /health`
- Obrigatorio: smoke test com `curl /metrics`
- Obrigatorio: smoke test com `curl /metrics/prometheus`
- Recomendado: validar WebSocket com `websocat ws://localhost:8080/ws`
- Recomendado: validar pico de CPU com `stress-ng --cpu 2 --timeout 10s`

### Operacao no host

- Recomendado: adicionar `deploy/sysmon.service`
- Recomendado: `Restart=on-failure` com `RestartSec=5s`
- Recomendado: declarar env vars no `[Service]` ou `EnvironmentFile`
- Recomendado: `StandardOutput=journal`
- Recomendado: hardening com `NoNewPrivileges=true` e protecoes de filesystem compativeis com leitura de `/proc`

Nota: `systemd` faz parte da preparacao operacional, mas nao deve bloquear a conclusao do backend. A fase 2 pode ser considerada concluida sem instalacao em host, desde que o servidor e o binario compilado estejam corretos.

### Commits sugeridos

- `feat(server): collector loop with broadcast stream`
- `feat(server): websocket multi-client broadcast`
- `feat(server): HTTP handler with request correlation`
- `feat(observability): Prometheus exporter and request logging`
- `build: validate compiled backend binary`
- `deploy: add systemd service template`

### Checklist de saida

- Obrigatorio: `curl /health` retorna `uptime_seconds` crescente
- Obrigatorio: `curl /metrics` retorna snapshot atualizado
- Obrigatorio: `curl /metrics/prometheus` retorna texto valido
- Obrigatorio: binario compilado funciona como `dart run`
- Obrigatorio: `dart analyze` e `dart test` verdes
- Recomendado: `websocat` recebe JSON a cada aproximadamente 2s
- Recomendado: `cpu_pct` sobe durante `stress-ng`
- Recomendado: `systemctl status sysmon` mostra `active (running)`
- Recomendado: `journalctl -u sysmon` mostra JSON estruturado

## Fase 3 - Frontend e CI Completo

Objetivo: entregar dashboard Flutter Desktop e pipeline de CI cobrindo backend e frontend.

### Design System

- Obrigatorio: paleta de cores centralizada
  - Primaria: `#0d59f2` (azul)
  - Background dark: `#101622`
  - Background light: `#f5f6f8`
  - Status verde: `#10b981`, laranja: `#f59e0b`, vermelho: `#ef4444`
- Obrigatorio: componentes visuais padronizados
  - KPI cards com titulo, valor, icone e indicador
  - Grafico de serie temporal com area preenchida
  - Cards de metricas com barras de progresso
  - Status indicators com dots e cores
  - Sidebar com navegacao e perfil do usuario
- Obrigatorio: icones Material Symbols Outlined
- Obrigatorio: tema dark mode com transicoes suaves
- Recomendado: `lib/theme/app_theme.dart` centralizando cores, tipografia e estilos
- Recomendado: documentacao visual ou guia de componentes

### Mock/Prototipo como Entregavel

- Obrigatorio: HTML mockup aprovado como referencia visual antes de implementacao
- Obrigatorio: checkpoint de alinhamento com design antes de iniciar codigo Flutter
- Recomendado: comparacao visual entre mockup e implementacao Flutter final

### Flutter Desktop setup

- Obrigatorio: `flutter create --platforms=linux flutter_app`
- Obrigatorio: habilitar Linux desktop no ambiente
- Obrigatorio: dependencias no `pubspec.yaml`:
  - `riverpod` e `flutter_riverpod` para state management
  - `fl_chart` para graficos de series temporais
  - `material_design_icons` para iconografia
  - `intl` para formatacao de numeros e datas
  - `web_socket_channel` para conexao WebSocket
- Recomendado: versoes fixadas em `pubspec.lock` para reproducibilidade

### Providers e dados

- Obrigatorio: `websocketProvider` conectando em `ws://localhost:8080/ws`
- Obrigatorio: `metricsStreamProvider` convertendo o stream do WebSocket
- Obrigatorio: `cpuHistoryProvider` com janela de historico
- Adiavel: `alertsProvider` enquanto alertas nao existirem no backend

### Layout

- Obrigatorio: tela principal com visao geral funcional
- Obrigatorio: KPI cards para metricas que ja existem no backend
- Obrigatorio: grafico de CPU em tempo real
- Obrigatorio: card de memoria com dados reais
- Adiavel: esconder ou marcar explicitamente como indisponiveis os widgets dependentes da Fase 4

### Tema

- Obrigatorio: identidade visual consistente
- Recomendado: paleta definida em constantes ou tema central

### CI - GitHub Actions

- Obrigatorio: job `backend`
  - `dart analyze --fatal-infos`
  - `dart test --reporter=expanded`
  - `dart compile exe`
- Obrigatorio: job `frontend`
  - depende de `backend`
  - `flutter analyze`
  - `flutter test`
  - `flutter build linux --release`

### Commits sugeridos

- `chore(flutter): create linux desktop app`
- `feat(flutter): base theme and layout`
- `feat(flutter): websocket and state providers`
- `feat(flutter): KPI cards and realtime CPU chart`
- `feat(flutter): memory card with backend data`
- `ci: backend and frontend pipeline`

### Checklist de saida

- Obrigatorio: `flutter build linux --release` sem erros
- Obrigatorio: app conecta no WebSocket do backend
- Obrigatorio: KPI cards atualizam a cada aproximadamente 2s
- Obrigatorio: grafico de CPU atualiza em tempo real
- Obrigatorio: card de memoria mostra dados corretos
- Obrigatorio: GitHub Actions verde para backend e frontend
- Obrigatorio: validacao visual
  - [ ] Cores seguem paleta definida (azul primaria, backgrounds dark/light)
  - [ ] Dark mode funciona e tem transicoes suaves
  - [ ] Icones Material Symbols aparecem corretamente
  - [ ] Layout match mockup HTML (sidebar + main area)
  - [ ] Tipografia consistente entre componentes
  - [ ] Cards de status mostram indicadores de saude
- Recomendado: comparacao lado-a-lado do mockup HTML com app Flutter
- Recomendado: validacao em resolucoes diferentes (1920x1080, 2560x1440, 1600x900)

## Fase 4 - Producao e Empacotamento Final

Objetivo: completar os coletores restantes, alertas, instalacao e operacao final.

### Coletores restantes

- Obrigatorio: `DiskCollector` via `/proc/diskstats` com calculo diferencial
- Obrigatorio: `NetCollector` via `/proc/net/dev` com calculo diferencial
- Obrigatorio: `ServiceCollector` via `systemctl`

### Modelo

- Obrigatorio: expandir `MetricsSnapshot` com `DiskMetrics`, `NetMetrics` e `List<ServiceStatus>`
- Obrigatorio: atualizar JSON e Prometheus para refletir novas metricas

### Alerts

- Obrigatorio: thresholds via env, como `SYSMON_ALERT_CPU` e `SYSMON_ALERT_MEM`
- Obrigatorio: janela temporal para evitar alertas instantaneos ruidosos
- Obrigatorio: modelo de alerta com inicio e resolucao

### Flutter

- Obrigatorio: `NetworkTrafficCard`
- Obrigatorio: `DiskSpeedCard`
- Obrigatorio: `ServiceStatusCard`
- Obrigatorio: tela de alertas com badge

### Empacotamento

- Obrigatorio: `Makefile` ou `justfile` para `build`, `install` e `uninstall`
- Recomendado: `logrotate` para execucao fora de `systemd`
- Obrigatorio: `INSTALL.md` com instalacao do zero

### Commits sugeridos

- `feat(collectors): disk and network collectors`
- `feat(collectors): service collector via systemctl`
- `feat(alerts): threshold-based alerts engine`
- `feat(flutter): network, disk and service widgets`
- `feat(flutter): alerts screen and badge`
- `build: install and packaging scripts`
- `docs: installation and operations guide`

### Checklist de saida

- Obrigatorio: `/metrics` inclui `disk`, `net` e `services`
- Obrigatorio: exporter Prometheus inclui novas metricas
- Obrigatorio: `AlertsEngine` dispara sob carga sustentada
- Obrigatorio: badge de alertas aparece no Flutter
- Obrigatorio: `make build` ou equivalente produz backend e app Linux
- Obrigatorio: `INSTALL.md` descreve instalacao sem ambiguidade
- Recomendado: `make install` funciona em maquina limpa
- Recomendado: servico fica ativo apos instalacao
