import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';
import 'package:sysmon_dashboard/widgets/kpi_card.dart';
import 'package:sysmon_dashboard/widgets/status_indicator.dart';

class OverviewKpiSection extends StatelessWidget {
  final String uptime;
  final String serverHealth;
  final String healthLabel;
  final String networkIo;
  final int activeProcesses;
  final String lastUpdatedLabel;

  const OverviewKpiSection({
    super.key,
    required this.uptime,
    required this.serverHealth,
    required this.healthLabel,
    required this.networkIo,
    required this.activeProcesses,
    required this.lastUpdatedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.38,
      children: [
        const KPICard(
          title: 'Uptime',
          value: '',
          icon: Icons.timer_outlined,
        ).copyWithValue(
            uptime,
            const StatusIndicator(
              label: 'Mock metric for layout',
              icon: Icons.construction,
              color: AppColors.statusGreen,
            )),
        KPICard(
          title: 'Server Health',
          value: serverHealth,
          icon: Icons.health_and_safety_outlined,
          indicator: StatusIndicator(
            label: healthLabel,
            icon: Icons.check_circle_outline,
            color: AppColors.statusGreen,
          ),
        ),
        const KPICard(
          title: 'Network I/O',
          value: '',
          icon: Icons.swap_horiz,
        ).copyWithValue(
            networkIo,
            const StatusIndicator(
              label: 'Mock traffic baseline',
              icon: Icons.analytics_outlined,
              color: AppColors.statusOrange,
            )),
        KPICard(
          title: 'Active Processes',
          value: '$activeProcesses',
          icon: Icons.developer_board_outlined,
          indicator: StatusIndicator(
            label: lastUpdatedLabel,
            icon: Icons.update,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

extension on KPICard {
  KPICard copyWithValue(String value, StatusIndicator indicator) {
    return KPICard(
      title: title,
      value: value,
      icon: icon,
      indicator: indicator,
    );
  }
}
