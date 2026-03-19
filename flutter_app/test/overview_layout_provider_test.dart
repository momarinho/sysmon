import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  test('provider uses default layout and can toggle visibility', () async {
    final storage = _InMemoryOverviewLayoutStorage();
    final container = ProviderContainer(
      overrides: [
        overviewLayoutStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    final initial = container.read(overviewLayoutProvider);
    expect(
      initial.firstWhere((block) => block.id == OverviewBlockId.cpu).visible,
      isTrue,
    );

    await container.read(overviewLayoutProvider.notifier).setVisible(
          OverviewBlockId.cpu,
          false,
        );

    final updated = container.read(overviewLayoutProvider);
    expect(
      updated.firstWhere((block) => block.id == OverviewBlockId.cpu).visible,
      isFalse,
    );
    expect(storage.stored, isNotNull);
  });

  test('moveDown swaps order inside same zone', () async {
    final storage = _InMemoryOverviewLayoutStorage();
    final container = ProviderContainer(
      overrides: [
        overviewLayoutStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    await container.read(overviewLayoutProvider.notifier).moveDown(
          OverviewBlockId.memory,
        );

    final updated = container.read(overviewLayoutProvider);
    final memory =
        updated.firstWhere((block) => block.id == OverviewBlockId.memory);
    final disk =
        updated.firstWhere((block) => block.id == OverviewBlockId.disk);

    expect(memory.order, 1);
    expect(disk.order, 0);
    expect(memory.zone, OverviewZone.side);
    expect(disk.zone, OverviewZone.side);
  });
}
