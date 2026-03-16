import '../collectors/metrics_snapshot.dart';

class PrometheusFormatter {
  static String format(MetricsSnapshot s) {
    final buf = StringBuffer();

    _write(
      buf,
      name: 'sysmon_cpu_usage_percent',
      help: 'CPU usage percentage (0-100)',
      type: 'gauge',
      value: s.cpu.usagePercent,
    );

    _write(
      buf,
      name: 'sysmon_cpu_cores_total',
      help: 'Number of CPU cores',
      type: 'gauge',
      value: s.cpu.cores.toDouble(),
    );

    _write(
      buf,
      name: 'sysmon_memory_total_bytes',
      help: 'Total physical memory in bytes',
      type: 'gauge',
      value: (s.memory.totalKb * 1024).toDouble(),
    );

    _write(
      buf,
      name: 'sysmon_memory_available_bytes',
      help: 'Available memory in bytes',
      type: 'gauge',
      value: (s.memory.availableKb * 1024).toDouble(),
    );

    _write(
      buf,
      name: 'sysmon_memory_used_percent',
      help: 'Memory used percentage (0-100)',
      type: 'gauge',
      value: s.memory.usedPercent,
    );

    _write(
      buf,
      name: 'sysmon_memory_swap_total_bytes',
      help: 'Total swap in bytes',
      type: 'gauge',
      value: (s.memory.swapTotalKb * 1024).toDouble(),
    );

    return buf.toString();
  }

  static void _write(
    StringBuffer buf, {
    required String name,
    required String help,
    required String type,
    required double value,
    Map<String, String>? labels,
  }) {
    buf.writeln('# HELP $name $help');
    buf.writeln('# TYPE $name $type');

    if (labels != null && labels.isNotEmpty) {
      final lblStr =
          labels.entries.map((e) => '${e.key}="${e.value}"').join(',');
      buf.writeln('$name{$lblStr} $value');
    } else {
      buf.writeln('$name $value');
    }
  }
}
