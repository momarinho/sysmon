import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/widgets/cpu_chart.dart';

class OverviewCpuSection extends StatelessWidget {
  final List<double> data;
  final double currentValue;
  final String modelName;
  final int cores;

  const OverviewCpuSection({
    super.key,
    required this.data,
    required this.currentValue,
    required this.modelName,
    required this.cores,
  });

  @override
  Widget build(BuildContext context) {
    return CPUChart(
      data: data,
      currentValue: currentValue,
      modelName: modelName,
      cores: cores,
    );
  }
}
