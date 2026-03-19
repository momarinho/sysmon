import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sysmon_dashboard/models/overview_layout.dart';

const _overviewLayoutKey = 'sysmon.overview.layout.v1';

abstract class OverviewLayoutStorage {
  Future<List<OverviewBlockConfig>?> load();
  Future<void> save(List<OverviewBlockConfig> blocks);
}

class SharedPreferencesOverviewLayoutStorage implements OverviewLayoutStorage {
  @override
  Future<List<OverviewBlockConfig>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_overviewLayoutKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return null;
    }

    return decoded
        .whereType<Map>()
        .map((item) => OverviewBlockConfig.fromJson(
              item.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ))
        .toList();
  }

  @override
  Future<void> save(List<OverviewBlockConfig> blocks) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = blocks.map((block) => block.toJson()).toList();
    await prefs.setString(_overviewLayoutKey, jsonEncode(payload));
  }
}

final overviewLayoutStorageProvider = Provider<OverviewLayoutStorage>((ref) {
  return SharedPreferencesOverviewLayoutStorage();
});

final overviewLayoutProvider =
    StateNotifierProvider<OverviewLayoutNotifier, List<OverviewBlockConfig>>(
        (ref) {
  return OverviewLayoutNotifier(ref.watch(overviewLayoutStorageProvider));
});

class OverviewLayoutNotifier extends StateNotifier<List<OverviewBlockConfig>> {
  final OverviewLayoutStorage _storage;

  OverviewLayoutNotifier(this._storage)
      : super(sortedOverviewBlocks(defaultOverviewLayout())) {
    _load();
  }

  Future<void> _load() async {
    final stored = await _storage.load();
    if (stored == null || stored.isEmpty) {
      return;
    }

    state = _normalize(stored);
  }

  Future<void> setVisible(OverviewBlockId id, bool visible) async {
    state = _normalize(
      state
          .map((block) =>
              block.id == id ? block.copyWith(visible: visible) : block)
          .toList(),
    );
    await _storage.save(state);
  }

  Future<void> toggleBlock(OverviewBlockId id) async {
    final current = state.firstWhere((block) => block.id == id);
    await setVisible(id, !current.visible);
  }

  Future<void> moveUp(OverviewBlockId id) async {
    await _move(id, direction: -1);
  }

  Future<void> moveDown(OverviewBlockId id) async {
    await _move(id, direction: 1);
  }

  Future<void> resetToDefault() async {
    state = sortedOverviewBlocks(defaultOverviewLayout());
    await _storage.save(state);
  }

  Future<void> _move(OverviewBlockId id, {required int direction}) async {
    final current = state.firstWhere((block) => block.id == id);
    final inZone = state.where((block) => block.zone == current.zone).toList()
      ..sort((left, right) => left.order.compareTo(right.order));

    final index = inZone.indexWhere((block) => block.id == id);
    final targetIndex = index + direction;
    if (index < 0 || targetIndex < 0 || targetIndex >= inZone.length) {
      return;
    }

    final currentBlock = inZone[index];
    final targetBlock = inZone[targetIndex];

    state = _normalize(
      state.map((block) {
        if (block.id == currentBlock.id) {
          return block.copyWith(order: targetBlock.order);
        }
        if (block.id == targetBlock.id) {
          return block.copyWith(order: currentBlock.order);
        }
        return block;
      }).toList(),
    );
    await _storage.save(state);
  }

  List<OverviewBlockConfig> _normalize(List<OverviewBlockConfig> blocks) {
    final merged = <OverviewBlockId, OverviewBlockConfig>{
      for (final block in defaultOverviewLayout()) block.id: block,
      for (final block in blocks) block.id: block,
    };

    final byZone = <OverviewZone, List<OverviewBlockConfig>>{};
    for (final block in merged.values) {
      byZone.putIfAbsent(block.zone, () => []).add(block);
    }

    final normalized = <OverviewBlockConfig>[];
    for (final zone in OverviewZone.values) {
      final items = byZone[zone] ?? const <OverviewBlockConfig>[];
      items.sort((left, right) => left.order.compareTo(right.order));
      for (var index = 0; index < items.length; index++) {
        normalized.add(items[index].copyWith(order: index));
      }
    }

    return sortedOverviewBlocks(normalized);
  }
}
