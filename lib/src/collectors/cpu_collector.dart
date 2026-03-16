import 'dart:io';
import '../logging/logger.dart';
import 'metrics_snapshot.dart';

class CpuCollector {
  static final _log = Logger('CpuCollector');

  // Previous state used for differential CPU usage calculation.
  List<int>? _prevTotal;
  List<int>? _prevIdle;

  Future<CpuMetrics> collect() async {
    try {
      final lines = await File('/proc/stat').readAsLines();

      // First line = totals, following lines = cpu0, cpu1...
      final cpuLines = lines.where((l) => l.startsWith('cpu')).toList();

      final totals = <int>[];
      final idles = <int>[];

      for (final line in cpuLines) {
        final parts = line.split(RegExp(r'\s+')).skip(1).toList();
        final values = parts.map((v) => int.tryParse(v) ?? 0).toList();

        // /proc/stat: user nice system idle iowait irq softirq steal
        final total = values.reduce((a, b) => a + b);
        final idle = values[3] + (values.length > 4 ? values[4] : 0);

        totals.add(total);
        idles.add(idle);
      }

      double overallUsage = 0.0;
      final perCore = <double>[];

      if (_prevTotal != null && _prevIdle != null) {
        for (int i = 0; i < totals.length; i++) {
          final deltaTotal = totals[i] - _prevTotal![i];
          final deltaIdle = idles[i] - _prevIdle![i];

          final usage =
              deltaTotal > 0 ? (1.0 - deltaIdle / deltaTotal) * 100.0 : 0.0;

          if (i == 0) {
            overallUsage = usage;
          } else {
            perCore.add(double.parse(usage.toStringAsFixed(1)));
          }
        }
      }

      _prevTotal = totals;
      _prevIdle = idles;

      return CpuMetrics(
        usagePercent: double.parse(overallUsage.toStringAsFixed(1)),
        cores: perCore.length,
        perCore: perCore,
      );
    } catch (e) {
      _log.error('Failed to collect CPU metrics', {'error': e.toString()});
      return CpuMetrics(usagePercent: 0, cores: 0, perCore: []);
    }
  }
}
