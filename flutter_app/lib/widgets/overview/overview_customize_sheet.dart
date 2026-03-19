import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysmon_dashboard/models/overview_layout.dart';
import 'package:sysmon_dashboard/providers/overview_layout_provider.dart';

class OverviewCustomizeSheet extends ConsumerWidget {
  const OverviewCustomizeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(overviewLayoutProvider);
    final notifier = ref.read(overviewLayoutProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Show, hide and reorder the main blocks of the dashboard.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: blocks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final block = blocks[index];
                  return _OverviewBlockTile(block: block, notifier: notifier);
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: notifier.resetToDefault,
                child: const Text('Reset to default'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewBlockTile extends StatelessWidget {
  final OverviewBlockConfig block;
  final OverviewLayoutNotifier notifier;

  const _OverviewBlockTile({
    required this.block,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(overviewBlockTitle(block.id)),
      subtitle: Text('Zone: ${block.zone.name}'),
      leading: Switch(
        value: block.visible,
        onChanged: (value) => notifier.setVisible(block.id, value),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => notifier.moveUp(block.id),
            icon: const Icon(Icons.keyboard_arrow_up),
            tooltip: 'Move up',
          ),
          IconButton(
            onPressed: () => notifier.moveDown(block.id),
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: 'Move down',
          ),
        ],
      ),
    );
  }
}
