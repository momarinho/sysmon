import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';

class MemoryCard extends StatelessWidget {
  final int totalKb;
  final int usedKb;
  final int cachedKb;
  final int swapUsedKb;
  final int swapTotalKb;
  final int availableKb;

  const MemoryCard({
    super.key,
    required this.totalKb,
    required this.usedKb,
    required this.cachedKb,
    required this.swapUsedKb,
    required this.swapTotalKb,
    required this.availableKb,
  });

  String _formatBytes(int kb) {
    final bytes = kb * 1024;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  double get usedPercent {
    if (totalKb == 0) return 0;
    return (usedKb / totalKb * 100);
  }

  double get freePercent {
    if (totalKb == 0) return 0;
    return (availableKb / totalKb * 100);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Memory Allocation',
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune,
                  color: isDark ? AppColors.textMutedLight : AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Memory Free
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Memory Free',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _formatBytes(availableKb),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: freePercent / 100,
                  minHeight: 8,
                  backgroundColor:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.statusGreen),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatBytes(availableKb)} available',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Memory Used
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Memory Used',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _formatBytes(usedKb),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: usedPercent / 100,
                  minHeight: 8,
                  backgroundColor:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total capacity: ${_formatBytes(totalKb)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
          const SizedBox(height: 16),

          // Footer Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                label: 'Cached',
                value: _formatBytes(cachedKb),
              ),
              _StatItem(
                label: 'Swap',
                value: _formatBytes(swapUsedKb),
                color: AppColors.statusOrange,
              ),
              _StatItem(
                label: 'Swap Total',
                value: _formatBytes(swapTotalKb),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
