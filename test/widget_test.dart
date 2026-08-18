// App-level smoke test. Uses the REAL committed artifacts (read from disk,
// synchronously — deterministic under the fake-async test clock) through a
// counting reader, extending the §0.4c guarantee to the app layer: gallery
// startup costs exactly one asset read, sources load only when the Info tab
// opens. No pumpAndSettle anywhere — aurora_stack animates forever.

import 'dart:io';

import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/widgets.dart' show GridView, Scrollable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/app/app.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/index_loader.dart';
import 'package:snipz/core/prefs.dart';

void main() {
  late List<String> reads;

  Future<void> pumpApp(WidgetTester tester) async {
    reads = <String>[];
    final IndexLoader loader = IndexLoader((path) async {
      reads.add(path);
      return File(path).readAsStringSync();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          indexLoaderProvider.overrideWithValue(loader),
          prefsStoreProvider.overrideWithValue(MemoryPrefsStore()),
        ],
        child: const SnipzApp(),
      ),
    );
    // Two pumps: resolve the index future, then build the grid.
    await tester.pump();
    await tester.pump();
  }

  // Scroll the 2-col grid until the tile is fully visible (7+ components no
  // longer fit the 800x600 test viewport). Fixed pumps, no settling.
  Future<Finder> revealTile(WidgetTester tester, String id) async {
    final Finder tile = find.byKey(ValueKey<String>('tile-$id'));
    // Target the grid's own scrollable — the filter chip row (horizontal
    // ListView) and nested thumbnail scrollables would otherwise match first.
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find
          .descendant(of: find.byType(GridView), matching: find.byType(Scrollable))
          .first,
    );
    await tester.ensureVisible(tile);
    await tester.pump();
    return tile;
  }

  testWidgets('gallery boots with exactly one asset read', (tester) async {
    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(reads, ['assets/index.json']);
    expect(find.byKey(const ValueKey<String>('tile-aurora_stack')), findsOne);
    expect(find.text('Aurora Stack'), findsOneWidget);

    // Last tile alphabetically — reachable by scrolling, still zero extra
    // asset reads (thumbnails never touch assets/sources/).
    await revealTile(tester, 'spectrum_sweep');
    expect(find.byKey(const ValueKey<String>('tile-spectrum_sweep')), findsOne);
    // Flush the one-shot entrance animations mounted while scrolling past
    // the reveal_list thumbnail.
    await tester.pump(const Duration(seconds: 3));
    expect(reads, ['assets/index.json']);
  });

  testWidgets('detail opens without extra reads; Info tab loads lazily', (
    tester,
  ) async {
    await pumpApp(tester);

    // glass_card: static carrier demo — safe to pump without settling.
    await tester.tap(await revealTile(tester, 'glass_card'));
    await tester.pump(const Duration(milliseconds: 400)); // route fade
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Preview'), findsOneWidget);
    // Preview alone must not touch assets/sources/ (§5.0 lazy rule).
    expect(reads, ['assets/index.json']);

    await tester.tap(find.text('Info'));
    await tester.pump(); // start tab transition
    await tester.pump(const Duration(milliseconds: 400)); // finish it
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(reads, ['assets/index.json', 'assets/sources/glass_card.json']);
  });
}
