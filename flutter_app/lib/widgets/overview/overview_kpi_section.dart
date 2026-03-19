import 'package:flutter/material.dart';
import 'package:sysmon_dashboard/widgets/kpi_card.dart';
import 'package:sysmon_dashboard/widgets/status_indicator.dart';

class OverviewKpiSection extends StatelessWidget {
  final String uptime;
  final String serverHealth;
  final StatusIndicator healthIndicator;
  final String networkIo;
  final StatusIndicator networkIndicator;
  final String activeProcesses;
  final StatusIndicator uptimeIndicator;
  final StatusIndicator activeProcessesIndicator;

  const OverviewKpiSection({
    super.key,
    required this.uptime,
    required this.serverHealth,
    required this.healthIndicator,
    required this.networkIo,
    required this.networkIndicator,
    required this.activeProcesses,
    required this.uptimeIndicator,
    required this.activeProcessesIndicator,
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
        ).copyWithValue(uptime, uptimeIndicator),
        KPICard(
          title: 'Server Health',
          value: serverHealth,
          icon: Icons.health_and_safety_outlined,
          indicator: healthIndicator,
        ),
        const KPICard(
          title: 'Network I/O',
          value: '',
          icon: Icons.swap_horiz,
        ).copyWithValue(networkIo, networkIndicator),
        KPICard(
          title: 'Active Processes',
          value: activeProcesses,
          icon: Icons.developer_board_outlined,
          indicator: activeProcessesIndicator,
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
