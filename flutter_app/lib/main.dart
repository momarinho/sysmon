import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/widgets/kpi_card.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: KPICard(
        title: 'CPU Usage',
        value: '45%',
        icon: Icons.memory,
        indicator: StatusIndicator(
          label: 'Normal',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
      ),
    );
  }
}
