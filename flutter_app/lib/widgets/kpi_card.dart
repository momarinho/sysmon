import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';

class StatusIndicator {
  final String label;
  final IconData icon;
  final Color color;

  StatusIndicator({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final StatusIndicator? indicator;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                ),
          ),
          const SizedBox(height: 8),

          // Indicator
          if (indicator != null)
            Row(
              children: [
                Icon(
                  indicator!.icon,
                  size: 14,
                  color: indicator!.color,
                ),
                const SizedBox(width: 4),
                Text(
                  indicator!.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: indicator!.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
