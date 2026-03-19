import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/widgets/memory_card.dart';

class OverviewMemorySection extends StatelessWidget {
  final int totalKb;
  final int usedKb;
  final int cachedKb;
  final int swapUsedKb;
  final int swapTotalKb;
  final int availableKb;

  const OverviewMemorySection({
    super.key,
    required this.totalKb,
    required this.usedKb,
    required this.cachedKb,
    required this.swapUsedKb,
    required this.swapTotalKb,
    required this.availableKb,
  });

  @override
  Widget build(BuildContext context) {
    return MemoryCard(
      totalKb: totalKb,
      usedKb: usedKb,
      cachedKb: cachedKb,
      swapUsedKb: swapUsedKb,
      swapTotalKb: swapTotalKb,
      availableKb: availableKb,
    );
  }
}
