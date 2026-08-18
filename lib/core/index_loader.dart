import 'dart:convert';

import 'models.dart';

/// Reads one asset as text. Injected (instead of calling rootBundle
/// directly) so unit tests can count exactly how many asset reads happen —
/// startup must read only assets/index.json (spec §0.4c, §8.3).
typedef AssetTextReader = Future<String> Function(String assetPath);

class IndexLoader {
  IndexLoader(this._read);

  final AssetTextReader _read;
  Future<ComponentIndex>? _index;
  final Map<String, Future<ComponentSources>> _sources = {};

  /// Loads assets/index.json exactly once; concurrent and repeated calls
  /// share the same future.
  Future<ComponentIndex> loadIndex() => _index ??= _loadIndex();

  Future<ComponentIndex> _loadIndex() async {
    final String text = await _read('assets/index.json');
    return ComponentIndex.fromJson(jsonDecode(text) as Map<String, Object?>);
  }

  /// Lazily loads `assets/sources/<id>.json` — only when a detail screen
  /// needs it (§5.0). Cached per id.
  Future<ComponentSources> loadSources(String id) =>
      _sources[id] ??= _loadSources(id);

  Future<ComponentSources> _loadSources(String id) async {
    final String text = await _read('assets/sources/$id.json');
    return ComponentSources.fromJson(jsonDecode(text) as Map<String, Object?>);
  }
}
