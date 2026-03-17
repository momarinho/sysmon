import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysmon_dashboard/models/metrics_models.dart';

import 'websocket_provider.dart';

final metricsStreamProvider = StreamProvider<MetricsSnapshot>((ref) {
  final wsAsync = ref.watch(webSocketProvider);

  return wsAsync.when(
    data: (ws) => _liveOrFallbackStream(ws),
    loading: _mockMetricsStream,
    error: (_, __) => _mockMetricsStream(),
  );
});

final latestMetricsProvider = Provider<AsyncValue<MetricsSnapshot>>((ref) {
  return ref.watch(metricsStreamProvider);
});

Stream<MetricsSnapshot> _liveOrFallbackStream(WebSocketService ws) async* {
  try {
    await for (final event in ws.stream) {
      try {
        final payload = jsonDecode(event as String) as Map<String, dynamic>;
        yield MetricsSnapshot.fromJson(payload);
      } catch (_) {
        // Ignore malformed payloads and keep listening for next frame.
      }
    }
  } catch (_) {
    yield* _mockMetricsStream();
  }
}

Stream<MetricsSnapshot> _mockMetricsStream() {
  return Stream<MetricsSnapshot>.periodic(
    const Duration(seconds: 2),
    (_) => _buildMockSnapshot(),
  );
}

MetricsSnapshot _buildMockSnapshot() {
  final now = DateTime.now();
  final phase = now.millisecondsSinceEpoch / 1000.0;
  final cpu = 45 + 25 * math.sin(phase / 4);

  const totalKb = 32 * 1024 * 1024; // 32 GB
  final usedRatio = 0.55 + 0.08 * math.sin(phase / 10);
  final usedKb = (totalKb * usedRatio).round();
  final availableKb = totalKb - usedKb;

  return MetricsSnapshot(
    timestamp: now,
    cpu: CpuMetrics(
      usagePercent: cpu.clamp(0, 100).toDouble(),
      cores: 6,
      perCore: List<double>.generate(
        6,
        (index) => (cpu + 8 * math.sin((phase + index) / 3))
            .clamp(0, 100)
            .toDouble(),
      ),
    ),
    memory: MemMetrics(
      totalKb: totalKb,
      freeKb: availableKb ~/ 2,
      availableKb: availableKb,
      cachedKb: totalKb ~/ 8,
      swapTotalKb: 2 * 1024 * 1024,
      swapFreeKb: 1400 * 1024,
      buffersKb: 120 * 1024,
    ),
  );
}

