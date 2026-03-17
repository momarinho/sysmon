import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/widgets/memory_card.dart';

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
        home: MemoryCard(
          totalKb: 16 * 1024 * 1024,
          // 16 GB
          usedKb: 8 * 1024 * 1024,
          // 8 GB
          cachedKb: 2 * 1024 * 1024,
          // 2 GB
          swapUsedKb: 1 * 1024 * 1024,
          // 1 GB
          swapTotalKb: 2 * 1024 * 1024, // 2 GB
        ));
  }
}
