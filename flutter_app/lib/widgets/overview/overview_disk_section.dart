import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';

class OverviewDiskSection extends StatelessWidget {
  final String speedLabel;
  final String deviceLabel;

  const OverviewDiskSection({
    super.key,
    required this.speedLabel,
    required this.deviceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISK WRITE SPEED',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            speedLabel,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.storage_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                deviceLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
