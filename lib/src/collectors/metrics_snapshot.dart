class CpuMetrics {
  final double usagePercent; // 0.0 a 100.0
  final int cores;
  final List<double> perCore; // uso por core

  const CpuMetrics({
    required this.usagePercent,
    required this.cores,
    required this.perCore,
  });

  Map<String, dynamic> toJson() => {
        'usage_percent': usagePercent,
        'cores': cores,
        'per_core': perCore,
      };
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
    if (totalKb == 0) {
      return 0;
    }

    return ((totalKb - availableKb) / totalKb * 100);
  }

  Map<String, dynamic> toJson() => {
        'total_kb': totalKb,
        'free_kb': freeKb,
        'available_kb': availableKb,
        'cached_kb': cachedKb,
        'swap_total_kb': swapTotalKb,
        'swap_free_kb': swapFreeKb,
        'buffers_kb': buffersKb,
        'used_percent': double.parse(usedPercent.toStringAsFixed(1)),
      };
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

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'cpu': cpu.toJson(),
        'memory': memory.toJson(),
      };
}
