import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysmon_dashboard/models/metrics_models.dart';
import 'package:sysmon_dashboard/providers/history_provider.dart';
import 'package:sysmon_dashboard/providers/metrics_provider.dart';
import 'package:sysmon_dashboard/providers/websocket_provider.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';
import 'package:sysmon_dashboard/widgets/cpu_chart.dart';
import 'package:sysmon_dashboard/widgets/kpi_card.dart';
import 'package:sysmon_dashboard/widgets/memory_card.dart';
import 'package:sysmon_dashboard/widgets/sidebar.dart';
import 'package:sysmon_dashboard/widgets/status_indicator.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(metricsStreamProvider);
    final history = ref.watch(cpuHistoryProvider);
    final wsAsync = ref.watch(webSocketProvider);
    final isLive = wsAsync.hasValue;
    final showSearch = MediaQuery.sizeOf(context).width > 1100;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            items: [
              SidebarItem(
                icon: Icons.dashboard,
                label: 'Overview',
                isSelected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              SidebarItem(
                icon: Icons.description,
                label: 'Detailed Logs',
                isSelected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              SidebarItem(
                icon: Icons.notifications,
                label: 'Alerts',
                isSelected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              SidebarItem(
                icon: Icons.settings,
                label: 'Settings',
                isSelected: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
            onLogout: () {},
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          'System Monitoring',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 1,
                          height: 24,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isLive
                                    ? AppColors.statusGreen
                                    : AppColors.statusOrange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isLive ? 'SYSTEM LIVE' : 'OFFLINE MODE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isLive
                                    ? AppColors.statusGreen
                                    : AppColors.statusOrange,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (showSearch) ...[
                          SizedBox(
                            width: 300,
                            height: 40,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search processes...',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            ref.read(webSocketProvider.notifier).reconnect();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: metricsAsync.when(
                      data: (snapshot) => _buildDashboard(snapshot, history),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (error, st) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.statusRed,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Connection Error',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(MetricsSnapshot snapshot, MetricsHistory history) {
    final swapUsedKb = snapshot.memory.swapTotalKb - snapshot.memory.swapFreeKb;
    final lastUpdated = DateTime.now().difference(snapshot.timestamp);
    final lastUpdatedLabel = lastUpdated.inSeconds <= 1
        ? 'Updated just now'
        : 'Updated ${lastUpdated.inSeconds}s ago';
    final mockOverview = _buildMockOverview(snapshot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.38,
          children: [
            KPICard(
              title: 'Uptime',
              value: mockOverview.uptime,
              icon: Icons.timer_outlined,
              indicator: const StatusIndicator(
                label: 'Mock metric for layout',
                icon: Icons.construction,
                color: AppColors.statusGreen,
              ),
            ),
            KPICard(
              title: 'Server Health',
              value: mockOverview.serverHealth,
              icon: Icons.health_and_safety_outlined,
              indicator: StatusIndicator(
                label: mockOverview.healthLabel,
                icon: Icons.check_circle_outline,
                color: AppColors.statusGreen,
              ),
            ),
            KPICard(
              title: 'Network I/O',
              value: mockOverview.networkIo,
              icon: Icons.swap_horiz,
              indicator: const StatusIndicator(
                label: 'Mock traffic baseline',
                icon: Icons.analytics_outlined,
                color: AppColors.statusOrange,
              ),
            ),
            KPICard(
              title: 'Active Processes',
              value: '${mockOverview.activeProcesses}',
              icon: Icons.developer_board_outlined,
              indicator: StatusIndicator(
                label: lastUpdatedLabel,
                icon: Icons.update,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: CPUChart(
                data: history.cpuHistory,
                currentValue: snapshot.cpu.usagePercent,
                modelName: snapshot.cpu.modelName,
                cores: snapshot.cpu.cores,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                children: [
                  MemoryCard(
                    totalKb: snapshot.memory.totalKb,
                    usedKb:
                        snapshot.memory.totalKb - snapshot.memory.availableKb,
                    cachedKb: snapshot.memory.cachedKb,
                    swapUsedKb: swapUsedKb,
                    swapTotalKb: snapshot.memory.swapTotalKb,
                    availableKb: snapshot.memory.availableKb,
                  ),
                  const SizedBox(height: 18),
                  _DiskSpeedCard(
                    speedLabel: mockOverview.diskWriteSpeed,
                    deviceLabel: 'NVMe RAID 0 Array',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  _MockOverview _buildMockOverview(MetricsSnapshot snapshot) {
    final seconds = snapshot.timestamp.millisecondsSinceEpoch ~/ 1000;
    final uptimeHours = 240 + (seconds % 96);
    final uptimeDays = uptimeHours ~/ 24;
    final remainingHours = uptimeHours % 24;
    final remainingMinutes = (seconds ~/ 60) % 60;
    final serverHealth = (99.4 -
            (snapshot.memory.usedPercent / 1000) +
            (snapshot.cpu.cores / 100))
        .clamp(96.0, 99.9);
    final networkGbps = ((snapshot.cpu.usagePercent * 0.018) +
            (snapshot.memory.usedPercent * 0.01))
        .clamp(0.4, 9.5);
    final activeProcesses = 120 + (snapshot.cpu.cores * 8) + (seconds % 18);
    final diskWriteSpeed = ((usedMemoryKbFrom(snapshot) / 1024 / 1024) * 0.012 +
            snapshot.cpu.usagePercent * 2.6)
        .clamp(80.0, 980.0);

    return _MockOverview(
      uptime:
          '${uptimeDays}d ${remainingHours.toString().padLeft(2, '0')}h ${remainingMinutes.toString().padLeft(2, '0')}m',
      serverHealth: '${serverHealth.toStringAsFixed(1)}%',
      healthLabel:
          serverHealth >= 98.0 ? 'Optimal performance' : 'Stable state',
      networkIo: networkGbps >= 1
          ? '${networkGbps.toStringAsFixed(1)} Gb/s'
          : '${(networkGbps * 1000).toStringAsFixed(0)} Mb/s',
      activeProcesses: activeProcesses,
      diskWriteSpeed: '${diskWriteSpeed.toStringAsFixed(0)} MB/s',
    );
  }

  int usedMemoryKbFrom(MetricsSnapshot snapshot) {
    return snapshot.memory.totalKb - snapshot.memory.availableKb;
  }
}

class _MockOverview {
  final String uptime;
  final String serverHealth;
  final String healthLabel;
  final String networkIo;
  final int activeProcesses;
  final String diskWriteSpeed;

  const _MockOverview({
    required this.uptime,
    required this.serverHealth,
    required this.healthLabel,
    required this.networkIo,
    required this.activeProcesses,
    required this.diskWriteSpeed,
  });
}

class _DiskSpeedCard extends StatelessWidget {
  final String speedLabel;
  final String deviceLabel;

  const _DiskSpeedCard({
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
