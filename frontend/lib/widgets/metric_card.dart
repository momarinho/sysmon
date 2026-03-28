import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final double percent;
  final String subtitle;
  final Color color;

  const MetricCard({
    super.key,
    required this.label,
    required this.percent,
    required this.subtitle,
    this.color = const Color(0xFF4DB6AC),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black..withValues(alpha:0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  sections: [
                    PieChartSectionData(value: percent,       color: color,                   radius: 10, showTitle: false),
                    PieChartSectionData(value: 100 - percent, color: color..withValues(alpha:0.15), radius: 10, showTitle: false),
                  ],
                )),
                Text("${percent.toInt()}%",
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label,    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5C4A1E))),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}