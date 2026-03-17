import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysmon_dashboard/screens/dashboard_screen.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sysmon Dashboard',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
