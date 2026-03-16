import 'package:sysmon/src/collectors/metrics_snapshot.dart';
import 'package:sysmon/src/server/prometheus_formatter.dart';
import 'package:test/test.dart';

void main() {
  group('PrometheusFormatter', () {
    test('format outputs Prometheus gauge metrics', () {
      final snapshot = MetricsSnapshot(
        timestamp: DateTime.parse('2026-03-16T15:00:00Z'),
        cpu: const CpuMetrics(
          usagePercent: 12.4,
          cores: 8,
          perCore: [10, 11, 12, 13, 14, 15, 16, 17],
        ),
        memory: const MemMetrics(
          totalKb: 1024,
          freeKb: 128,
          availableKb: 256,
          cachedKb: 64,
          swapTotalKb: 512,
          swapFreeKb: 256,
          buffersKb: 32,
        ),
      );

      final output = PrometheusFormatter.format(snapshot);

      expect(output, contains('# HELP sysmon_cpu_usage_percent'));
      expect(output, contains('# TYPE sysmon_cpu_usage_percent gauge'));
      expect(output, contains('sysmon_cpu_usage_percent 12.4'));
      expect(output, contains('sysmon_cpu_cores_total 8.0'));
      expect(output, contains('sysmon_memory_total_bytes 1048576.0'));
      expect(output, contains('sysmon_memory_available_bytes 262144.0'));
    });
  });
}