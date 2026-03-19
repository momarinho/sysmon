import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/models/metrics_models.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';

class OverviewNetworkSection extends StatelessWidget {
  final NetworkMetrics network;

  const OverviewNetworkSection({
    super.key,
    required this.network,
  });

  @override
  Widget build(BuildContext context) {
    final primaryInterface =
        network.interfaces.isNotEmpty ? network.interfaces.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NETWORK',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NetworkStatTile(
                  label: 'Inbound',
                  value: _formatBytesPerSecond(network.bytesRecv),
                  icon: Icons.south_west_rounded,
                  color: AppColors.statusGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _NetworkStatTile(
                  label: 'Outbound',
                  value: _formatBytesPerSecond(network.bytesSent),
                  icon: Icons.north_east_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (primaryInterface != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    primaryInterface.status == 'up'
                        ? Icons.wifi_tethering_rounded
                        : Icons.portable_wifi_off_rounded,
                    size: 18,
                    color: primaryInterface.status == 'up'
                        ? AppColors.statusGreen
                        : AppColors.statusOrange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${primaryInterface.name} · ${primaryInterface.status}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Text(
                    '${network.interfaces.length} iface',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NetworkStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _NetworkStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatBytesPerSecond(num bytesPerSecond) {
  final value = bytesPerSecond.toDouble();
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  var unitIndex = 0;
  var scaled = value;

  while (scaled >= 1024 && unitIndex < units.length - 1) {
    scaled /= 1024;
    unitIndex++;
  }

  final fractionDigits = scaled >= 100 ? 0 : 1;
  return '${scaled.toStringAsFixed(fractionDigits)} ${units[unitIndex]}';
}
