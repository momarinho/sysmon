import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/metrics_service.dart';

class CpuRamChart extends StatefulWidget {
  const CpuRamChart({super.key});
  @override State<CpuRamChart> createState() => _CpuRamChartState();
}

class _CpuRamChartState extends State<CpuRamChart> {
  final _service = MetricsService();
  final List<FlSpot> _cpuPoints = [];
  final List<FlSpot> _ramPoints = [];
  double _tick = 0;

  static const _maxPoints = 60;
  static const _teal   = Color(0xFF00D4AA);
  static const _blue  = Color(0xFF3B82F6);
  static const _bg     = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _service.stream.listen((m) {
      if (!mounted) return;
      setState(() {
        _tick++;
        _cpuPoints.add(FlSpot(_tick, m.cpu));
        _ramPoints.add(FlSpot(_tick, m.ram));
        if (_cpuPoints.length > _maxPoints) {
          _cpuPoints.removeAt(0);
          _ramPoints.removeAt(0);
        }
      });
    });
  }

  LineChartBarData _bar(List<FlSpot> pts, Color c) => LineChartBarData(
    spots: pts,
    color: c,
    isCurved: true,
    barWidth: 2,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: true, color: c..withValues(alpha:0.15)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey..withValues(alpha:0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legend(_teal, "CPU"),
              const SizedBox(width: 20),
              _legend(_blue, "RAM"),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _cpuPoints.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                  ),
                )
              : LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey..withValues(alpha:0.1),
                        strokeWidth: 1,
                      ),
                      drawVerticalLine: false,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, _) => Text(
                            "${v.toInt()}%",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                          interval: 20,
                        ),
                      ),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      _bar(_cpuPoints, _teal),
                      _bar(_ramPoints, _blue),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(children: [
    Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white..withValues(alpha:0.3)),
      ),
    ),
    const SizedBox(width: 8),
    Text(
      label,
      style: TextStyle(
        fontSize: 14,
        color: Colors.white54,
        fontWeight: FontWeight.w500,
      ),
    ),
  ]);

  @override
  void dispose() { _service.dispose(); super.dispose(); }
}