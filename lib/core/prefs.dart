// Personal-state storage (spec §8.7): favorites, target Flutter version.
// Metadata never lives here — it is asset-time. Values are JSON strings
// (spec §11), keyed flat. The store is injected like the asset reader
// (§0.4c) so tests run against memory, the app against Hive.

import 'package:hive/hive.dart';

abstract interface class PrefsStore {
  /// Returns the stored JSON string, or null if the key was never written.
  String? read(String key);

  void write(String key, String value);
}

class HivePrefsStore implements PrefsStore {
  HivePrefsStore(this._box);

  final Box<String> _box;

  @override
  String? read(String key) => _box.get(key);

  @override
  void write(String key, String value) => _box.put(key, value);
}

/// Test double — also the graceful fallback if Hive ever fails to open.
class MemoryPrefsStore implements PrefsStore {
  final Map<String, String> _values = {};

  @override
  String? read(String key) => _values[key];

  @override
  void write(String key, String value) => _values[key] = value;
}
