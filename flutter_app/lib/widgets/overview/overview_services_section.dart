import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/models/metrics_models.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';

class OverviewServicesSection extends StatelessWidget {
  final ServiceMetrics services;

  const OverviewServicesSection({
    super.key,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    final visibleServices = services.services.take(4).toList();
    final runningCount = services.services
        .where((service) => service.status == 'running')
        .length;

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
          Row(
            children: [
              Text(
                'SERVICES',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
              ),
              const Spacer(),
              Text(
                '$runningCount/${services.services.length} running',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (visibleServices.isEmpty)
            Text(
              'No services configured.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            )
          else
            ...visibleServices.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ServiceRow(service: service),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final ServiceInfo service;

  const _ServiceRow({required this.service});

  @override
  Widget build(BuildContext context) {
    final isRunning = service.status == 'running';
    final statusColor = isRunning ? AppColors.statusGreen : AppColors.statusRed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.status} · PID ${service.pid}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${service.memoryKb} KB',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
