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
  static const _teal   = Color(0xFF4DB6AC);
  static const _amber  = Color(0xFFB5A642);
  static const _bg     = Color(0xFFFAF7F0);

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
    belowBarData: BarAreaData(show: true, color: c.withOpacity(0.15)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _legend(_teal,  "CPU"),
            const SizedBox(width: 16),
            _legend(_amber, "RAM"),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: _cpuPoints.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : LineChart(LineChartData(
                  minY: 0, maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.brown.withOpacity(0.1), strokeWidth: 1,
                    ),
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, reservedSize: 32,
                        getTitlesWidget: (v, _) => Text("${v.toInt()}%",
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        interval: 25,
                      ),
                    ),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [_bar(_cpuPoints, _teal), _bar(_ramPoints, _amber)],
                )),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF5C4A1E))),
  ]);

  @override
  void dispose() { _service.dispose(); super.dispose(); }
}