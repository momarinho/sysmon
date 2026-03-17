import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:sysmon_dashboard/models/metrics_models.dart';

import 'metrics_provider.dart';

class MetricsHistory {
  final List<MetricsSnapshot> snapshots;
  final int maxSize;

  MetricsHistory({required this.snapshots, required this.maxSize});

  MetricsHistory addSnapshot(MetricsSnapshot snapshot) {
    final newList = [...snapshots, snapshot];
    if (newList.length > maxSize) {
      newList.removeAt(0);
    }
    return MetricsHistory(snapshots: newList, maxSize: maxSize);
  }

  List<double> get cpuHistory =>
      snapshots.map((s) => s.cpu.usagePercent).toList();

  List<double> get memoryHistory =>
      snapshots.map((s) => s.memory.usedPercent).toList();
}

final cpuHistoryProvider =
    StateNotifierProvider<CpuHistoryNotifier, MetricsHistory>((ref) {
  return CpuHistoryNotifier(ref, maxSize: 60);
});

class CpuHistoryNotifier extends StateNotifier<MetricsHistory> {
  final Ref ref;
  final int maxSize;

  CpuHistoryNotifier(this.ref, {required this.maxSize})
      : super(MetricsHistory(snapshots: [], maxSize: maxSize)) {
    _init();
  }

  void _init() {
    ref.listen(metricsStreamProvider, (previous, next) {
      next.whenData((snapshot) {
        state = state.addSnapshot(snapshot);
      });
    });
  }
}
