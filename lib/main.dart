import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snipz/app/app.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/index_loader.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // Composition root — the ONLY place that touches rootBundle
        // (§0.4c: keeps asset reads countable by injecting the reader).
        indexLoaderProvider.overrideWithValue(
          IndexLoader(rootBundle.loadString),
        ),
      ],
      child: const SnipzApp(),
    ),
  );
}
