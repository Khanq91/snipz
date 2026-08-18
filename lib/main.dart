import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:snipz/app/app.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/index_loader.dart';
import 'package:snipz/core/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        // Composition root — the ONLY place that touches rootBundle
        // (§0.4c: keeps asset reads countable by injecting the reader).
        indexLoaderProvider.overrideWithValue(
          IndexLoader(rootBundle.loadString),
        ),
        prefsStoreProvider.overrideWithValue(await _openPrefs()),
      ],
      child: const SnipzApp(),
    ),
  );
}

/// Personal state only (§8.7) — if Hive can't open, the app still works,
/// just without persistence.
Future<PrefsStore> _openPrefs() async {
  try {
    await Hive.initFlutter();
    return HivePrefsStore(await Hive.openBox<String>('prefs'));
  } catch (_) {
    return MemoryPrefsStore();
  }
}
