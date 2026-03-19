import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysmon_dashboard/models/metrics_models.dart';
import 'package:sysmon_dashboard/models/overview_layout.dart';
import 'package:sysmon_dashboard/providers/history_provider.dart';
import 'package:sysmon_dashboard/providers/metrics_provider.dart';
import 'package:sysmon_dashboard/providers/overview_layout_provider.dart';
import 'package:sysmon_dashboard/providers/websocket_provider.dart';
import 'package:sysmon_dashboard/theme/app_colors.dart';
import 'package:sysmon_dashboard/widgets/overview/overview_cpu_section.dart';
import 'package:sysmon_dashboard/widgets/overview/overview_customize_sheet.dart';
import 'package:sysmon_dashboard/widgets/overview/overview_disk_section.dart';
import 'package:sysmon_dashboard/widgets/overview/overview_kpi_section.dart';
import 'package:sysmon_dashboard/widgets/overview/overview_memory_section.dart';
import 'package:sysmon_dashboard/widgets/overview/overview_placeholder_section.dart';
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
    final showSearch = MediaQuery.sizeOf(context).width > 1100;

    return Scaffold(
      body: Row(
        children: [
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
          Expanded(
            child: Column(
              children: [
                _DashboardHeader(
                  isLive: isLive,
                  showSearch: showSearch,
                  onReconnect: () {
                    ref.read(webSocketProvider.notifier).reconnect();
                  },
                  onCustomize: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const OverviewCustomizeSheet(),
                    );
                  },
                ),
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
    final layout = ref.watch(overviewLayoutProvider);
    final mockOverview = _buildMockOverview(snapshot);
    final topBlocks = visibleBlocksForZone(layout, OverviewZone.top);
    final mainBlocks = visibleBlocksForZone(layout, OverviewZone.main);
    final sideBlocks = visibleBlocksForZone(layout, OverviewZone.side);
    final bottomBlocks = visibleBlocksForZone(layout, OverviewZone.bottom);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topBlocks.isNotEmpty) ...[
          ..._buildZoneBlocks(
            topBlocks,
            snapshot,
            history,
            mockOverview,
          ),
          const SizedBox(height: 22),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: _buildZoneBlocks(
                  mainBlocks,
                  snapshot,
                  history,
                  mockOverview,
                ),
              ),
            ),
            if (sideBlocks.isNotEmpty) ...[
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: _withSpacing(
                    _buildZoneBlocks(
                      sideBlocks,
                      snapshot,
                      history,
                      mockOverview,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (bottomBlocks.isNotEmpty) ...[
          const SizedBox(height: 22),
          ..._withSpacing(
            _buildZoneBlocks(
              bottomBlocks,
              snapshot,
              history,
              mockOverview,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildZoneBlocks(
    List<OverviewBlockConfig> blocks,
    MetricsSnapshot snapshot,
    MetricsHistory history,
    _MockOverview mockOverview,
  ) {
    return blocks.map((block) {
      switch (block.id) {
        case OverviewBlockId.kpis:
          return OverviewKpiSection(
            uptime: mockOverview.uptime,
            serverHealth: mockOverview.serverHealth,
            healthLabel: mockOverview.healthLabel,
            networkIo: mockOverview.networkIo,
            activeProcesses: mockOverview.activeProcesses,
            lastUpdatedLabel: mockOverview.lastUpdatedLabel,
          );
        case OverviewBlockId.cpu:
          return OverviewCpuSection(
            data: history.cpuHistory,
            currentValue: snapshot.cpu.usagePercent,
            modelName: snapshot.cpu.modelName,
            cores: snapshot.cpu.cores,
          );
        case OverviewBlockId.memory:
          return OverviewMemorySection(
            totalKb: snapshot.memory.totalKb,
            usedKb: snapshot.memory.totalKb - snapshot.memory.availableKb,
            cachedKb: snapshot.memory.cachedKb,
            swapUsedKb:
                snapshot.memory.swapTotalKb - snapshot.memory.swapFreeKb,
            swapTotalKb: snapshot.memory.swapTotalKb,
            availableKb: snapshot.memory.availableKb,
          );
        case OverviewBlockId.disk:
          return OverviewDiskSection(
            speedLabel: mockOverview.diskWriteSpeed,
            deviceLabel: 'NVMe RAID 0 Array',
          );
        case OverviewBlockId.network:
          return const OverviewPlaceholderSection(
            title: 'Network',
            description:
                'Network metrics block reserved for phase 5 integration.',
          );
        case OverviewBlockId.services:
          return const OverviewPlaceholderSection(
            title: 'Services',
            description:
                'Service status block reserved for phase 5 integration.',
          );
      }
    }).toList();
  }

  List<Widget> _withSpacing(List<Widget> children) {
    if (children.isEmpty) {
      return const [];
    }

    final result = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        result.add(const SizedBox(height: 18));
      }
      result.add(children[index]);
    }
    return result;
  }

  _MockOverview _buildMockOverview(MetricsSnapshot snapshot) {
    final seconds = snapshot.timestamp.millisecondsSinceEpoch ~/ 1000;
    final lastUpdated = DateTime.now().difference(snapshot.timestamp);
    final lastUpdatedLabel = lastUpdated.inSeconds <= 1
        ? 'Updated just now'
        : 'Updated ${lastUpdated.inSeconds}s ago';
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
      lastUpdatedLabel: lastUpdatedLabel,
    );
  }

  int usedMemoryKbFrom(MetricsSnapshot snapshot) {
    return snapshot.memory.totalKb - snapshot.memory.availableKb;
  }
}

class _DashboardHeader extends StatelessWidget {
  final bool isLive;
  final bool showSearch;
  final VoidCallback onReconnect;
  final VoidCallback onCustomize;

  const _DashboardHeader({
    required this.isLive,
    required this.showSearch,
    required this.onReconnect,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                    color:
                        isLive ? AppColors.statusGreen : AppColors.statusOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isLive ? 'SYSTEM LIVE' : 'OFFLINE MODE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color:
                        isLive ? AppColors.statusGreen : AppColors.statusOrange,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onReconnect,
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: onCustomize,
              tooltip: 'Customize overview',
            ),
          ],
        ),
      ),
    );
  }
}

class _MockOverview {
  final String uptime;
  final String serverHealth;
  final String healthLabel;
  final String networkIo;
  final int activeProcesses;
  final String diskWriteSpeed;
  final String lastUpdatedLabel;

  const _MockOverview({
    required this.uptime,
    required this.serverHealth,
    required this.healthLabel,
    required this.networkIo,
    required this.activeProcesses,
    required this.diskWriteSpeed,
    required this.lastUpdatedLabel,
  });
}
