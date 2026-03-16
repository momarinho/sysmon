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
  Future<void>? _inFlightCollect;
  bool _started = false;
  bool _stopped = false;

  Stream<MetricsSnapshot> get stream => _controller.stream;
  MetricsSnapshot? get latest => _latest;

  void start() {
    if (_started) {
      _log.warn('Collection already started');
      return;
    }

    _started = true;
    _stopped = false;
    _log.info('Starting collection', {
      'interval_ms': Config.intervalMs,
    });

    _triggerCollect();

    _timer = Timer.periodic(
      Duration(milliseconds: Config.intervalMs),
      (_) => _triggerCollect(),
    );
  }

  Future<void> stop() async {
    if (_stopped) {
      return;
    }

    _stopped = true;
    _timer?.cancel();
    await _inFlightCollect;
    await _controller.close();
    _log.info('Collection stopped');
  }

  void _triggerCollect() {
    if (_stopped || _inFlightCollect != null) {
      return;
    }

    final future = _collect();
    _inFlightCollect = future;
    future.whenComplete(() {
      if (identical(_inFlightCollect, future)) {
        _inFlightCollect = null;
      }
    });
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
      if (!_stopped && !_controller.isClosed) {
        _controller.add(snapshot);
      }

      _log.debug('Snapshot collected', {
        'cpu_pct': cpu.usagePercent,
        'mem_pct': mem.usedPercent,
      });
    } catch (e) {
      _log.error('Collection cycle failed', {'error': e.toString()});
    }
  }
}
