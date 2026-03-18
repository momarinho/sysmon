import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';
import 'package:sysmon_dashboard/widgets/status_indicator.dart';

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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 23,
                ),
          ),
          const SizedBox(height: 10),
          if (indicator != null)
            Row(
              children: [
                Icon(
                  indicator!.icon,
                  size: 14,
                  color: indicator!.color,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    indicator!.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: indicator!.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
