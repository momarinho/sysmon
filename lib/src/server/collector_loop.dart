import 'dart:async';
import '../collectors/cpu_collector.dart';
import '../collectors/mem_collector.dart';
import '../collectors/metrics_snapshot.dart';
import '../config/config.dart';
import '../logging/logger.dart';

class CollectorLoop {
  static final _log = Logger('CollectorLoop');

  final _controller = StreamController<MetricsSnapshot>.broadcast();
  final _cpu = CpuCollector();
  final _mem = MemCollector();

  Timer? _timer;
  MetricsSnapshot? _latest;

  Stream<MetricsSnapshot> get stream => _controller.stream;
  MetricsSnapshot? get latest => _latest;

  void start() {
    _log.info('Iniciando coleta', {
      'interval_ms': Config.intervalMs,
    });

    _collect();

    _timer = Timer.periodic(
      Duration(milliseconds: Config.intervalMs),
      (_) => _collect(),
    );
  }

  void stop() {
    _timer?.cancel();
    _controller.close();
    _log.info('Coleta encerrada');
  }

  Future<void> _collect() async {
    try {
      final cpu = await _cpu.collect();
      final mem = await _mem.collect();

      final snapshot = MetricsSnapshot(
        timestamp: DateTime.now().toUtc(),
        cpu: cpu,
        memory: mem,
      );

      _latest = snapshot;
      _controller.add(snapshot);

      _log.debug('Snapshot coletado', {
        'cpu_pct': cpu.usagePercent,
        'mem_pct': mem.usedPercent,
      });
    } catch (e) {
      _log.error('Falha no ciclo de coleta', {'error': e.toString()});
    }
  }
}
