enum OverviewBlockId {
  kpis,
  cpu,
  memory,
  disk,
  network,
  services,
}

enum OverviewZone {
  top,
  main,
  side,
  bottom,
}

class OverviewBlockConfig {
  final OverviewBlockId id;
  final bool visible;
  final int order;
  final OverviewZone zone;

  const OverviewBlockConfig({
    required this.id,
    required this.visible,
    required this.order,
    required this.zone,
  });

  OverviewBlockConfig copyWith({
    bool? visible,
    int? order,
    OverviewZone? zone,
  }) {
    return OverviewBlockConfig(
      id: id,
      visible: visible ?? this.visible,
      order: order ?? this.order,
      zone: zone ?? this.zone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.name,
      'visible': visible,
      'order': order,
      'zone': zone.name,
    };
  }

  factory OverviewBlockConfig.fromJson(Map<String, dynamic> json) {
    return OverviewBlockConfig(
      id: OverviewBlockId.values.byName(json['id'] as String),
      visible: json['visible'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      zone: OverviewZone.values.byName(json['zone'] as String),
    );
  }
}

List<OverviewBlockConfig> defaultOverviewLayout() {
  return const [
    OverviewBlockConfig(
      id: OverviewBlockId.kpis,
      visible: true,
      order: 0,
      zone: OverviewZone.top,
    ),
    OverviewBlockConfig(
      id: OverviewBlockId.cpu,
      visible: true,
      order: 0,
      zone: OverviewZone.main,
    ),
    OverviewBlockConfig(
      id: OverviewBlockId.memory,
      visible: true,
      order: 0,
      zone: OverviewZone.side,
    ),
    OverviewBlockConfig(
      id: OverviewBlockId.disk,
      visible: true,
      order: 1,
      zone: OverviewZone.side,
    ),
    OverviewBlockConfig(
      id: OverviewBlockId.network,
      visible: false,
      order: 0,
      zone: OverviewZone.bottom,
    ),
    OverviewBlockConfig(
      id: OverviewBlockId.services,
      visible: false,
      order: 1,
      zone: OverviewZone.bottom,
    ),
  ];
}

List<OverviewBlockConfig> sortedOverviewBlocks(
    List<OverviewBlockConfig> blocks) {
  final result = [...blocks];
  result.sort((left, right) {
    final zoneCompare = left.zone.index.compareTo(right.zone.index);
    if (zoneCompare != 0) {
      return zoneCompare;
    }
    return left.order.compareTo(right.order);
  });
  return result;
}

List<OverviewBlockConfig> visibleBlocksForZone(
  List<OverviewBlockConfig> blocks,
  OverviewZone zone,
) {
  final result = blocks
      .where((block) => block.zone == zone && block.visible)
      .toList()
    ..sort((left, right) => left.order.compareTo(right.order));
  return result;
}

String overviewBlockTitle(OverviewBlockId id) {
  switch (id) {
    case OverviewBlockId.kpis:
      return 'KPI cards';
    case OverviewBlockId.cpu:
      return 'CPU';
    case OverviewBlockId.memory:
      return 'Memory';
    case OverviewBlockId.disk:
      return 'Disk';
    case OverviewBlockId.network:
      return 'Network';
    case OverviewBlockId.services:
      return 'Services';
  }
}
