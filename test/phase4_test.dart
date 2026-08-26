// Phase 4 verify (roadmap §12): hand-edited fail row -> 🔴 and excluded by
// the compat filter; target-version change flips badges; multi-file shows
// the yellow folder badge with the right count; 8-months-old last_verified
// shows 🟡 stale; favorites and search filter the grid.
//
// "Hand-editing Test History" is simulated by mutating the real committed
// index.json in memory before handing it to the injected reader (§0.4c).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/app/app.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/index_loader.dart';
import 'package:snipz/core/prefs.dart';

typedef IndexMutator = void Function(Map<String, Object?> indexJson);

Map<String, Object?> _component(Map<String, Object?> index, String id) =>
    (index['components']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .firstWhere((c) => c['id'] == id);

Future<MemoryPrefsStore> _pumpApp(
  WidgetTester tester, {
  IndexMutator? mutate,
  MemoryPrefsStore? store,
}) async {
  // Tall viewport so every tile these tests assert on (up to glass_card
  // wherever it lands alphabetically — row 19 of the 2-col grid as of the
  // kinetics batch) is actually built — GridView.builder skips off-screen
  // tiles.
  tester.view.physicalSize = const Size(900, 12000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final MemoryPrefsStore prefs = store ?? MemoryPrefsStore();
  final IndexLoader loader = IndexLoader((path) async {
    String text = File(path).readAsStringSync();
    if (path == 'assets/index.json' && mutate != null) {
      final Map<String, Object?> json =
          jsonDecode(text) as Map<String, Object?>;
      mutate(json);
      text = jsonEncode(json);
    }
    return text;
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        indexLoaderProvider.overrideWithValue(loader),
        prefsStoreProvider.overrideWithValue(prefs),
      ],
      child: const SnipzApp(),
    ),
  );
  await tester.pump();
  await tester.pump();
  return prefs;
}

Finder _badgeIn(String id) => find.byKey(ValueKey('badge-compat-$id'));

String _badgeText(WidgetTester tester, String id) =>
    tester.widget<Text>(_badgeIn(id)).data!;

void main() {
  testWidgets('hand-edited fail row -> 🔴 badge and compat filter hides it', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      mutate: (index) {
        final Map<String, Object?> aurora = _component(index, 'aurora_stack');
        // The manual edit the roadmap asks for: last verify was a fail — at
        // the index's own build version, so it is exact for the default
        // target regardless of which Flutter built the artifacts.
        aurora['test_history'] = [
          {
            'date': '2026-08-18',
            'flutter': index['_generated_flutter'],
            'dart': '3.12.2',
            'deps_resolved': '—',
            'platform': 'android',
            'result': 'fail',
            'note': 'hand-edited for Phase 4 verify',
          },
        ];
        aurora['latest_known_good'] = null;
      },
    );

    expect(_badgeText(tester, 'aurora_stack'), '🔴');
    // Un-edited, verified neighbour stays green. (blur_text would be 🟡 —
    // the react-bits ports have no Test History yet.)
    expect(_badgeText(tester, 'glass_card'), '🟢');

    await tester.tap(find.byKey(const ValueKey('filter-compat')));
    await tester.pump();
    expect(find.byKey(const ValueKey('tile-aurora_stack')), findsNothing);
    expect(find.byKey(const ValueKey('tile-glass_card')), findsOneWidget);
  });

  testWidgets('changing target version in settings flips badges', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      mutate: (index) {
        // Give the dropdown a second known version (§8.2 options come from
        // Test History).
        final Map<String, Object?> glass = _component(index, 'glass_card');
        (glass['test_history']! as List<Object?>).add({
          'date': '2026-08-18',
          'flutter': '3.50.0',
          'dart': '3.13.0',
          'deps_resolved': '—',
          'platform': 'android',
          'result': 'pass',
          'note': '—',
        });
      },
    );

    // Default target 3.44.5: exact pass row -> green.
    expect(_badgeText(tester, 'aurora_stack'), '🟢');

    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('target-flutter-dropdown')));
    await tester.pump(const Duration(milliseconds: 300)); // menu open
    // .last: the closed DropdownButton pre-lays-out every item too — the
    // overlay menu copy comes later in the tree.
    await tester.tap(find.byKey(const ValueKey('target-option-3.50.0')).last);
    await tester.pump(const Duration(milliseconds: 300)); // menu close
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    // aurora: no row @3.50.0, lkg 3.44.5 < target -> 🟡 unknown.
    expect(_badgeText(tester, 'aurora_stack'), '🟡');
    // glass_card: exact pass @3.50.0 -> stays green.
    expect(_badgeText(tester, 'glass_card'), '🟢');
  });

  testWidgets('multi-file component shows folder badge with file count', (
    tester,
  ) async {
    await _pumpApp(tester);
    final Finder badge = find.byKey(
      const ValueKey('badge-portability-aurora_stack'),
    );
    expect(badge, findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.text('folder (3)')),
      findsOneWidget,
    );
    // Single-file component for contrast.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('badge-portability-blur_text')),
        matching: find.text('single'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('last_verified 8 months ago -> 🟡 stale', (tester) async {
    await _pumpApp(
      tester,
      mutate: (index) {
        final Map<String, Object?> aurora = _component(index, 'aurora_stack');
        aurora['last_verified'] = DateTime.now()
            .subtract(const Duration(days: 240))
            .toIso8601String()
            .substring(0, 10);
      },
    );
    expect(_badgeText(tester, 'aurora_stack'), '🟡');
  });

  testWidgets('favorite star persists to the store; ★ filter narrows grid', (
    tester,
  ) async {
    final MemoryPrefsStore prefs = await _pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('favorite-aurora_stack')));
    await tester.pump();
    expect(prefs.read('favorites'), '["aurora_stack"]');

    await tester.tap(find.byKey(const ValueKey('filter-favorites')));
    await tester.pump();
    expect(find.byKey(const ValueKey('tile-aurora_stack')), findsOneWidget);
    expect(find.byKey(const ValueKey('tile-blur_text')), findsNothing);
  });

  testWidgets('search filters by title and tag', (tester) async {
    await _pumpApp(tester);

    await tester.enterText(
      find.byKey(const ValueKey('gallery-search')),
      'aurora',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('tile-aurora_stack')), findsOneWidget);
    expect(find.byKey(const ValueKey('tile-blur_text')), findsNothing);
  });
}
