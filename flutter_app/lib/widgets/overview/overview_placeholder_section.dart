import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';

class OverviewPlaceholderSection extends StatelessWidget {
  final String title;
  final String description;

  const OverviewPlaceholderSection({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Coming soon',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.statusOrange,
                ),
          ),
        ],
      ),
    );
  }
}
