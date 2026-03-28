import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/loading_screen.dart';
import 'services/metrics_service.dart';
import 'widgets/cpu_chart.dart';
import 'widgets/theme_selector.dart';

void main() => runApp(const MonitorApp());

class MonitorApp extends StatelessWidget {
  const MonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppThemeNotifier(),
      child: Consumer<AppThemeNotifier>(
        builder: (context, themeNotifier, child) {
          // Load theme on startup
          WidgetsBinding.instance.addPostFrameCallback((_) {
            themeNotifier.loadTheme();
          });

          return MaterialApp(
            title: 'System Monitor',
            debugShowCheckedModeBanner: false,
            theme: themeNotifier.themeData,
            initialRoute: '/',
            routes: {
              '/': (context) => const LoginScreen(),
              '/loading': (context) => const LoadingScreen(),
              '/dashboard': (context) => const DashboardScreen(),
            },
          );
        },
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = MetricsService();
  Metrics? _last;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  void _initializeConnection() async {
    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 1));

    // Try to connect and get first metrics
    _service.stream.listen((m) {
      if (mounted) {
        setState(() {
          _last = m;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
              ),
              SizedBox(height: 20),
              Text(
                'Connecting to monitor...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final m = _last;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Consumer<AppThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return IconButton(
                icon: const Icon(Icons.logout, color: Colors.white54),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context, '/',
                    (route) => false,
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
          Consumer<AppThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return ThemeSelector(themeNotifier: themeNotifier);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "System Monitor",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Live",
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF00D4AA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Real-time system metrics",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _last = null);
                    await Future.delayed(const Duration(seconds: 1));
                    _initializeConnection();
                  },
                  color: const Color(0xFF00D4AA),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              const CpuRamChart(),
                              const SizedBox(height: 20),
                              if (m != null) ...[
                                _infoCard("Uptime", m.uptime, const Color(0xFF00D4AA)),
                                const SizedBox(height: 12),
                                if (m.temp.isNotEmpty)
                                  _infoCard(
                                    "Temperature",
                                    "${(m.temp['current'] as num).toStringAsFixed(1)}°C",
                                    const Color(0xFFEF4444),
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
                                _metricCard(
                                  "CPU",
                                  m.cpu,
                                  "Usage",
                                  const Color(0xFF00D4AA),
                                ),
                                const SizedBox(height: 16),
                                _metricCard(
                                  "RAM",
                                  m.ram,
                                  "${m.ramUsed.toStringAsFixed(1)} / ${m.ramTotal.toStringAsFixed(1)} GB",
                                  const Color(0xFF3B82F6),
                                ),
                                const SizedBox(height: 16),
                                _metricCard(
                                  "Disk",
                                  m.disk,
                                  "${m.diskUsed.toStringAsFixed(1)} / ${m.diskTotal.toStringAsFixed(1)} GB",
                                  const Color(0xFF8B5CF6),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<AppThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return FloatingActionButton(
            onPressed: () async {
              await themeNotifier.toggleTheme();
              await themeNotifier.saveTheme();
            },
            backgroundColor: const Color(0xFF00D4AA),
            foregroundColor: Colors.black,
            mini: true,
            child: Icon(
              themeNotifier.isSystemTheme
                  ? themeNotifier.currentTheme == AppTheme.dark
                      ? Icons.light_mode
                      : Icons.dark_mode
                  : themeNotifier.currentTheme == AppTheme.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Widget _infoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              title == "Uptime" ? Icons.timer : Icons.thermostat,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, double percent, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${percent.toInt()}%",
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                "${percent.toInt()}%",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
