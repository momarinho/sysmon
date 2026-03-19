import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysmon_dashboard/main.dart';
import 'package:sysmon_dashboard/models/overview_layout.dart';
import 'package:sysmon_dashboard/providers/overview_layout_provider.dart';

class _InMemoryOverviewLayoutStorage implements OverviewLayoutStorage {
  List<OverviewBlockConfig>? stored;

  @override
  Future<List<OverviewBlockConfig>?> load() async => stored;

  @override
  Future<void> save(List<OverviewBlockConfig> blocks) async {
    stored = blocks;
  }
}

void main() {
  testWidgets('dashboard respects hidden blocks from overview layout',
      (WidgetTester tester) async {
    final storage = _InMemoryOverviewLayoutStorage()
      ..stored = defaultOverviewLayout()
          .map((block) => block.id == OverviewBlockId.disk
              ? block.copyWith(visible: false)
              : block)
          .toList();

    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          overviewLayoutStorageProvider.overrideWithValue(storage),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CPU Usage Over Time'), findsOneWidget);
    expect(find.text('Memory Allocation'), findsOneWidget);
    expect(find.text('DISK WRITE SPEED'), findsNothing);
  });
}
