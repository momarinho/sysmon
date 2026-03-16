import 'package:sysmon/src/collectors/metrics_snapshot.dart';
import 'package:test/test.dart';

void main() {
  group('CpuMetrics', () {
    test('toJson serializes expected keys', () {
      const metrics = CpuMetrics(
        usagePercent: 37.5,
        cores: 4,
        perCore: [20.0, 40.0, 60.0, 30.0],
      );

      expect(metrics.toJson(), {
        'usage_percent': 37.5,
        'cores': 4,
        'per_core': [20.0, 40.0, 60.0, 30.0],
      });
    });
  });

  group('MemMetrics', () {
    test('usedPercent calculates from total and available memory', () {
      const metrics = MemMetrics(
        totalKb: 1000,
        freeKb: 100,
        availableKb: 250,
        cachedKb: 200,
        swapTotalKb: 500,
        swapFreeKb: 300,
        buffersKb: 50,
      );

      expect(metrics.usedPercent, closeTo(75.0, 0.0001));
    });

    test('toJson includes rounded used_percent', () {
      const metrics = MemMetrics(
        totalKb: 3000,
        freeKb: 200,
        availableKb: 1000,
        cachedKb: 500,
        swapTotalKb: 1000,
        swapFreeKb: 800,
        buffersKb: 100,
      );

      expect(metrics.toJson(), {
        'total_kb': 3000,
        'free_kb': 200,
        'available_kb': 1000,
        'cached_kb': 500,
        'swap_total_kb': 1000,
        'swap_free_kb': 800,
        'buffers_kb': 100,
        'used_percent': 66.7,
      });
    });
  });

  group('MetricsSnapshot', () {
    test('toJson nests cpu and memory metrics and uses UTC timestamp', () {
      final timestamp = DateTime.parse('2026-03-16T12:34:56-03:00');
      const cpu =
          CpuMetrics(usagePercent: 12.3, cores: 2, perCore: [10.0, 14.6]);
      const memory = MemMetrics(
        totalKb: 1024,
        freeKb: 128,
        availableKb: 256,
        cachedKb: 64,
        swapTotalKb: 512,
        swapFreeKb: 256,
        buffersKb: 32,
      );

      final snapshot = MetricsSnapshot(
        timestamp: timestamp,
        cpu: cpu,
        memory: memory,
      );

      expect(snapshot.toJson(), {
        'timestamp': '2026-03-16T15:34:56.000Z',
        'cpu': cpu.toJson(),
        'memory': memory.toJson(),
      });
    });
  });
}
