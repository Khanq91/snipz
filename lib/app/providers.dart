// Riverpod wiring for the viewer. The IndexLoader is provided at the
// composition root (main.dart) with rootBundle as reader — nothing else in
// the app may touch rootBundle (spec §0.4c: startup costs exactly one asset
// read, counted by tests).

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snipz/core/index_loader.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/core/prefs.dart';

/// Overridden in main.dart (and in widget tests with a counting reader).
final Provider<IndexLoader> indexLoaderProvider = Provider<IndexLoader>(
  (ref) => throw UnimplementedError(
    'indexLoaderProvider must be overridden at the composition root',
  ),
);

/// The single startup read of assets/index.json (§8.3). IndexLoader caches
/// the future, so re-watching never re-reads.
final FutureProvider<ComponentIndex> indexProvider =
    FutureProvider<ComponentIndex>(
      (ref) => ref.watch(indexLoaderProvider).loadIndex(),
    );

/// Lazy per-component sources — only watched from the detail Info tab (§5.0).
final sourcesProvider = FutureProvider.family<ComponentSources, String>(
  (ref, id) => ref.watch(indexLoaderProvider).loadSources(id),
);

/// Overridden in main.dart with Hive; tests use MemoryPrefsStore (§8.7).
final Provider<PrefsStore> prefsStoreProvider = Provider<PrefsStore>(
  (ref) => throw UnimplementedError(
    'prefsStoreProvider must be overridden at the composition root',
  ),
);

/// Favorited component ids (Hive-backed, JSON string list).
final NotifierProvider<FavoritesNotifier, Set<String>> favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  static const String _key = 'favorites';

  @override
  Set<String> build() {
    final String? raw = ref.watch(prefsStoreProvider).read(_key);
    if (raw == null) return const {};
    return (jsonDecode(raw) as List<Object?>).map((e) => '$e').toSet();
  }

  void toggle(String id) {
    final Set<String> next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
    ref.read(prefsStoreProvider).write(_key, jsonEncode(next.toList()..sort()));
  }
}

/// The user's explicit target-version choice; null = follow the index's
/// `_generated_flutter` (decision #2).
final NotifierProvider<TargetFlutterNotifier, String?>
targetFlutterOverrideProvider = NotifierProvider<TargetFlutterNotifier, String?>(
  TargetFlutterNotifier.new,
);

class TargetFlutterNotifier extends Notifier<String?> {
  static const String _key = 'target_flutter';

  @override
  String? build() {
    final String? raw = ref.watch(prefsStoreProvider).read(_key);
    if (raw == null) return null;
    return jsonDecode(raw) as String?;
  }

  void set(String? version) {
    state = version;
    ref.read(prefsStoreProvider).write(_key, jsonEncode(version));
  }
}

/// Effective target Flutter version every badge compares against (§8.2).
/// Null only while the index is still loading.
final Provider<String?> effectiveTargetProvider = Provider<String?>((ref) {
  final String? chosen = ref.watch(targetFlutterOverrideProvider);
  if (chosen != null) return chosen;
  return ref.watch(indexProvider).value?.generatedFlutter;
});
