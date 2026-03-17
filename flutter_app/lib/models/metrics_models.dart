
import 'package:flutter/foundation.dart';

class CpuMetrics {
  final double usagePercent;
  final int cores;
  final List<double> perCore;

  const CpuMetrics({
    required this.usagePercent,
    required this.cores,
    required this.perCore,
  });

  factory CpuMetrics.fromJson(Map<String, dynamic> json) {
    return CpuMetrics(
      usagePercent: (json['usage_percent'] as num).toDouble(),
      cores: json['cores'] as int,
      perCore: List<double>.from(
        (json['per_core'] as List).map((e) => (e as num).toDouble()),
      ),
    );
  }
}

class MemMetrics {
  final int totalKb;
  final int freeKb;
  final int availableKb;
  final int cachedKb;
  final int swapTotalKb;
  final int swapFreeKb;
  final int buffersKb;

  const MemMetrics({
    required this.totalKb,
    required this.freeKb,
    required this.availableKb,
    required this.cachedKb,
    required this.swapTotalKb,
    required this.swapFreeKb,
    required this.buffersKb,
  });

  double get usedPercent {
    if (totalKb == 0) return 0;
    return ((totalKb - availableKb) / totalKb * 100);
  }

  factory MemMetrics.fromJson(Map<String, dynamic> json) {
    return MemMetrics(
      totalKb: json['total_kb'] as int,
      freeKb: json['free_kb'] as int,
      availableKb: json['available_kb'] as int,
      cachedKb: json['cached_kb'] as int,
      swapTotalKb: json['swap_total_kb'] as int,
      swapFreeKb: json['swap_free_kb'] as int,
      buffersKb: json['buffers_kb'] as int,
    );
  }
}

class MetricsSnapshot {
  final DateTime timestamp;
  final CpuMetrics cpu;
  final MemMetrics memory;

  const MetricsSnapshot({
    required this.timestamp,
    required this.cpu,
    required this.memory,
  });

  factory MetricsSnapshot.fromJson(Map<String, dynamic> json) {
    return MetricsSnapshot(
      timestamp: DateTime.parse(json['timestamp'] as String),
      cpu: CpuMetrics.fromJson(json['cpu'] as Map<String, dynamic>),
      memory: MemMetrics.fromJson(json['memory'] as Map<String, dynamic>),
    );
  }
}