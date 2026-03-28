import 'package:flutter/material.dart';
import 'services/metrics_service.dart';
import 'widgets/cpu_chart.dart';
import 'widgets/metric_card.dart';

void main() => runApp(const MonitorApp());

class MonitorApp extends StatelessWidget {
  const MonitorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'System Monitor',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4DB6AC),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F0E8),
      cardTheme: CardThemeData(
        color: const Color(0xFFFAF7F0),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    home: const DashboardScreen(),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = MetricsService();
  Metrics? _last;

  @override
  void initState() {
    super.initState();
    _service.stream.listen((m) {
      if (mounted) setState(() => _last = m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _last;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  const Text(
                    "System Monitor",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C4A1E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CpuRamChart(),
                  if (m != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      "Uptime: ${m.uptime}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (m.temp.isNotEmpty)
                      Text(
                        "${m.temp['label']}: ${(m.temp['current'] as num).toStringAsFixed(1)}°C",
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 20),
            if (m != null)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    MetricCard(
                      label: "RAM",
                      percent: m.ram,
                      subtitle: "${m.ramUsed} / ${m.ramTotal} GB",
                      color: const Color(0xFFB5A642),
                    ),
                    const SizedBox(height: 12),
                    MetricCard(
                      label: "Disk",
                      percent: m.disk,
                      subtitle: "${m.diskUsed} / ${m.diskTotal} GB",
                    ),
                    const SizedBox(height: 12),
                    MetricCard(
                      label: "CPU",
                      percent: m.cpu,
                      subtitle: "percent usage",
                      color: const Color(0xFF8B7355),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
