import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';

class OverviewDiskSection extends StatelessWidget {
  final String writeSpeedLabel;
  final String readSpeedLabel;
  final String deviceLabel;
  final String usageLabel;

  const OverviewDiskSection({
    super.key,
    required this.writeSpeedLabel,
    required this.readSpeedLabel,
    required this.deviceLabel,
    required this.usageLabel,
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
            writeSpeedLabel,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DiskStatChip(
                icon: Icons.download_rounded,
                label: 'Read',
                value: readSpeedLabel,
              ),
              _DiskStatChip(
                icon: Icons.pie_chart_outline_rounded,
                label: 'Usage',
                value: usageLabel,
              ),
            ],
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

class _DiskStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DiskStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
