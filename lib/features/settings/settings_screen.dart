// Settings (spec §8.2): the target Flutter version every compat badge
// compares against. The app cannot read the machine's Flutter at runtime
// (decision #2) — the user picks the version of the project they are about
// to paste into. Default = the index's `_generated_flutter`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/compat.dart';
import 'package:snipz/core/models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ComponentIndex> index = ref.watch(indexProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: index.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load index.json\n$error')),
        data: (data) => ListView(
          children: [
            ListTile(
              title: const Text('Target Flutter version'),
              subtitle: Text(
                'Badge compat so với version này — chọn theo project sắp '
                'paste vào, không phải máy build index.\n'
                'Default: ${data.generatedFlutter} (lúc build index)',
              ),
              trailing: _TargetDropdown(index: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetDropdown extends ConsumerWidget {
  const _TargetDropdown({required this.index});

  final ComponentIndex index;

  /// Every version the vault has ever seen: index build version + every Test
  /// History row + every latest_known_good. Sorted descending.
  List<String> _options() {
    final Set<String> versions = {index.generatedFlutter};
    for (final ComponentMeta m in index.components) {
      versions.addAll(m.testHistory.map((r) => r.flutter));
      final String? lkg = m.latestKnownGood;
      if (lkg != null) versions.add(lkg);
    }
    final List<String> sorted = versions.toList()
      ..sort((a, b) => compareFlutterVersions(b, a));
    return sorted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String target =
        ref.watch(effectiveTargetProvider) ?? index.generatedFlutter;
    final List<String> options = _options();
    if (!options.contains(target)) options.insert(0, target);
    return DropdownButton<String>(
      key: const ValueKey('target-flutter-dropdown'),
      value: target,
      items: [
        for (final String v in options)
          DropdownMenuItem(
            value: v,
            child: Text(
              v == index.generatedFlutter ? '$v (default)' : v,
              key: ValueKey('target-option-$v'),
            ),
          ),
      ],
      onChanged: (v) {
        // Picking the index default clears the override (follows future
        // index rebuilds); anything else is stored in Hive.
        ref
            .read(targetFlutterOverrideProvider.notifier)
            .set(v == index.generatedFlutter ? null : v);
      },
    );
  }
}
