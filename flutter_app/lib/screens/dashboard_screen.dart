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
            onLogout: () {
              print('Logout');
            },
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 64,
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
                    padding: const EdgeInsets.symmetric(horizontal: 32),
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
                              isLive ? 'System Live' : 'Offline Mode',
                              style: TextStyle(
                                fontSize: 12,
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
                      data: (snapshot) => _buildDashboard(
                        context,
                        snapshot,
                        history,
                      ),
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (error, st) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
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

  Widget _buildDashboard(
    BuildContext context,
    MetricsSnapshot snapshot,
    MetricsHistory history,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Row
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: [
            KPICard(
              title: 'Uptime',
              value: '14d 06h 22m',
              icon: Icons.timer,
              indicator: StatusIndicator(
                label: '99.9% availability',
                icon: Icons.trending_up,
                color: AppColors.statusGreen,
              ),
            ),
            KPICard(
              title: 'Server Health',
              value: '98.2%',
              icon: Icons.health_and_safety,
              indicator: StatusIndicator(
                label: 'Optimal performance',
                icon: Icons.check_circle,
                color: AppColors.statusGreen,
              ),
            ),
            KPICard(
              title: 'Network I/O',
              value: '2.4 Gb/s',
              icon: Icons.swap_calls,
              indicator: StatusIndicator(
                label: 'High traffic detected',
                icon: Icons.warning,
                color: AppColors.statusOrange,
              ),
            ),
            KPICard(
              title: 'Active Processes',
              value: '142',
              icon: Icons.view_list,
              indicator: StatusIndicator(
                label: 'Last updated 2s ago',
                icon: Icons.update,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Charts Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CPU Chart
            Expanded(
              flex: 2,
              child: CPUChart(
                data: history.cpuHistory,
                currentValue: snapshot.cpu.usagePercent,
              ),
            ),
            const SizedBox(width: 24),

            // Memory Card
            Expanded(
              child: MemoryCard(
                totalKb: snapshot.memory.totalKb,
                usedKb: snapshot.memory.totalKb - snapshot.memory.availableKb,
                cachedKb: snapshot.memory.cachedKb,
                swapUsedKb:
                    snapshot.memory.swapTotalKb - snapshot.memory.swapFreeKb,
                swapTotalKb: snapshot.memory.swapTotalKb,
                availableKb: snapshot.memory.availableKb,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
