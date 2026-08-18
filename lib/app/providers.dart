// Riverpod wiring for the viewer. The IndexLoader is provided at the
// composition root (main.dart) with rootBundle as reader — nothing else in
// the app may touch rootBundle (spec §0.4c: startup costs exactly one asset
// read, counted by tests).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snipz/core/index_loader.dart';
import 'package:snipz/core/models.dart';

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
