import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_selector.dart';
import '../services/metrics_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _service = MetricsService();
  Metrics? _currentMetrics;

  @override
  void initState() {
    super.initState();
    // Connect to WebSocket to get real-time metrics
    _service.stream.listen((m) {
      if (mounted) {
        setState(() => _currentMetrics = m);
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate authentication delay
    await Future.delayed(const Duration(seconds: 1));

    // For demo purposes, accept any password
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/loading');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time = DateFormat('HH:mm').format(now);
    final date = DateFormat('EEEE, d MMMM yyyy').format(now).toUpperCase();

    // Use real metrics if available, otherwise show placeholder
    final metrics = _currentMetrics;
    final cpuPercent = (metrics?.cpu ?? 0).toDouble();
    final tempValue = metrics!.temp.isNotEmpty
        ? (metrics!.temp['current'] as num).toStringAsFixed(0)
        : '0';
    final tempColor = _getTempColor(metrics);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main Container with Grid Layout
                Container(
                  height: 700,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E2DA),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black..withValues(alpha:0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top Bar
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SYSTEM_OS_V1',
                              style: TextStyle(
                                color: Color(0xFF56612F),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF56612F),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFBBCDA3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF546341),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Grid Content - Using actual grid layout
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Row(
                            children: [
                              // Left Column (3/12)
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Weather Widget
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6F3EB),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Clear',
                                                style: TextStyle(
                                                  color: const Color(0xFF56612F),
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Humidity: 70%',
                                                style: TextStyle(
                                                  color: const Color(0xFF3D4B2B),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Icon(
                                            Icons.light_mode,
                                            color: const Color(0xFF56612F),
                                            size: 36,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // System Info Widget - Now with REAL data
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF6F3EB),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.terminal,
                                                  color: const Color(0xFF56612F),
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'SYSTEM_INFO',
                                                  style: TextStyle(
                                                    color: const Color(0xFF56612F),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'OS: CachyOS',
                                              style: TextStyle(
                                                color: const Color(0xFF3D4B2B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'WM: Hyprland',
                                              style: TextStyle(
                                                color: const Color(0xFF3D4B2B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'USER: ADMIN_NODE_01',
                                              style: TextStyle(
                                                color: const Color(0xFF3D4B2B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'UPTIME: ${metrics?.uptime ?? '4h 12m'}',
                                              style: TextStyle(
                                                color: const Color(0xFF3D4B2B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 20),

                              // Center Column (6/12)
                              Expanded(
                                flex: 6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Profile Picture
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E2DA),
                                        borderRadius: BorderRadius.circular(60),
                                        border: Border.all(
                                          color: const Color(0xFFE5E2DA),
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black..withValues(alpha:0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(56),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              'https://lh3.googleusercontent.com/aida-public/AB6AXuC5O5PSc31ZiRn8pDrhJwu2GEM2MDpGjw8Klcjdihq7mIxAdbttGMguGdpal9CiSmVKRPdMXMScIm4A_T8fnGvD6J1iI0OPEEqPlJTpC50Og3Nk6_ounJCsHCD3mJ-U27jWgQvam-pea2hy8lVXYDOVF8n1Yexy6tGBsIphv9GA9DKH3ScRynbLHrCmP0WrCDZQ6cATQW4V_kPPOkB_9dc6oAlwZIBDRjTZAAirfTo5Yr__qPXxrlIFFrFbx720UrsP9XfwIOh_TA',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: const Color(0xFF56612F),
                                                );
                                              },
                                            ),
                                            // Status indicator
                                            if (metrics != null)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF00D4AA),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              )
                                            else
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF546341),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),

                                    // Clock
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color: const Color(0xFF56612F),
                                        fontSize: 72,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      date,
                                      style: TextStyle(
                                        color: const Color(0xFF56612F)..withValues(alpha:0.6),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 40),

                                    // Password Input
                                    Container(
                                      width: 320,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: const TextStyle(
                                            color: Color(0xFF56612F),
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: const Color(0xFFE5E2DA),
                                            hintText: 'Enter credentials...',
                                            hintStyle: TextStyle(
                                              color: const Color(0xFF77786B),
                                              fontSize: 14,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF56612F),
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: const BorderSide(color: Colors.red),
                                            ),
                                            focusedErrorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: const BorderSide(color: Colors.red),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.lock,
                                              color: const Color(0xFF56612F)..withValues(alpha:0.6),
                                              size: 24,
                                            ),
                                            suffixIcon: Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF56612F),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  setState(() => _obscurePassword = !_obscurePassword);
                                                },
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              vertical: 20,
                                              horizontal: 56,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Please enter your credentials';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Login Button
                                    SizedBox(
                                      width: 320,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF56612F),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                          disabledBackgroundColor: Colors.white24,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.arrow_forward,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'LOGIN',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 20),

                              // Right Column (3/12)
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    // Performance Gauges Grid - Now with REAL data
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF6F3EB),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Performance',
                                                  style: TextStyle(
                                                    color: const Color(0xFF56612F),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.dashboard,
                                                  color: const Color(0xFF56612F),
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            // Gauges Grid
                                            GridView.count(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              children: [
                                                _GaugeCard(
                                                  icon: Icons.memory,
                                                  label: 'CPU',
                                                  value: '${cpuPercent.toInt()}%',
                                                  color: const Color(0xFF56612F),
                                                  bgColor: const Color(0xFFF6F3EB),
                                                  displayValue: cpuPercent,
                                                ),
                                                _GaugeCard(
                                                  icon: Icons.thermostat,
                                                  label: 'TEMP',
                                                  value: '$tempValue°C',
                                                  color: tempColor,
                                                  bgColor: const Color(0xFFF6F3EB),
                                                  displayValue: metrics!.temp.isNotEmpty
                                                      ? (metrics!.temp['current'] as num).toDouble()
                                                      : 0.0,
                                                ),
                                                _GaugeCard(
                                                  icon: Icons.sd_card,
                                                  label: 'RAM',
                                                  value: '${(metrics?.ram ?? 0).toInt()}%',
                                                  color: const Color(0xFF56612F),
                                                  bgColor: const Color(0xFFF6F3EB),
                                                  displayValue: (metrics?.ram ?? 0).toDouble(),
                                                ),
                                                _GaugeCard(
                                                  icon: Icons.storage,
                                                  label: 'DISK',
                                                  value: '${(metrics?.disk ?? 0).toInt()}%',
                                                  color: const Color(0xFF56612F),
                                                  bgColor: const Color(0xFFF6F3EB),
                                                  displayValue: (metrics?.disk ?? 0).toDouble(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Theme Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Theme: ',
                      style: TextStyle(
                        color: Color(0xFFE5E2DA),
                        fontSize: 14,
                      ),
                    ),
                    ThemeSelector(themeNotifier: Provider.of<AppThemeNotifier>(context, listen: false)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTempColor(Metrics? metrics) {
    if (metrics == null || metrics!.temp.isEmpty) return const Color(0xFF56612F);
    final temp = (metrics!.temp['current'] as num);
    if (temp < 50) return const Color(0xFF56612F);
    if (temp < 70) return const Color(0xFF8F4A00);
    return const Color(0xFFEF4444);
  }
}

class _GaugeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final double displayValue;

  const _GaugeCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: displayValue,
                  strokeWidth: 4,
                  backgroundColor: bgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF3D4B2B),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
