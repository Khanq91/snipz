// The session flag ("đợt"): SESSION.yaml → index.json `session` → gallery
// "✦ New" filter chip + NEW/FIX tile badges. Uses the real committed
// artifacts like widget_test.dart, so these tests also pin that the current
// SESSION.yaml actually flows through the pipeline.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/app/app.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/index_loader.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/core/prefs.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    final IndexLoader loader = IndexLoader(
      (path) async => File(path).readAsStringSync(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          indexLoaderProvider.overrideWithValue(loader),
          prefsStoreProvider.overrideWithValue(MemoryPrefsStore()),
        ],
        child: const SnipzApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  test('SessionInfo parses and flags from index.json', () {
    final Map<String, Object?> json =
        jsonDecode(File('assets/index.json').readAsStringSync())
            as Map<String, Object?>;
    final ComponentIndex index = ComponentIndex.fromJson(json);
    final SessionInfo? session = index.session;
    expect(session, isNotNull,
        reason: 'SESSION.yaml exists, so the index must embed it');
    expect(session!.id, isNotEmpty);
    expect(session.flagOf('additive_creature'), SessionFlag.added);
    expect(session.flagOf('jelly_blob'), SessionFlag.fixed);
    expect(session.flagOf('aurora_stack'), isNull);
    expect(session.contains('drum_clock'), isTrue);
  });

  test('SessionInfo tolerates an index without a session block', () {
    final Map<String, Object?> json =
        jsonDecode(File('assets/index.json').readAsStringSync())
            as Map<String, Object?>;
    json['session'] = null;
    expect(ComponentIndex.fromJson(json).session, isNull);
  });

  testWidgets('gallery: ✦ New chip filters to the session; badges show', (
    tester,
  ) async {
    await pumpApp(tester);

    // badge on the first tile (additive_creature is in `added`)
    expect(
      find.byKey(const ValueKey<String>('session-badge-additive_creature')),
      findsOneWidget,
    );

    // enable the session filter
    await tester.tap(find.byKey(const ValueKey<String>('filter-session')));
    await tester.pump();

    // in-session tiles remain (bloub_bot is `fixed` and sorts 2nd of 19)…
    expect(
      find.byKey(const ValueKey<String>('tile-additive_creature')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('tile-bloub_bot')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('session-badge-bloub_bot')),
      findsOneWidget,
    );

    // …while an out-of-session component that would otherwise be on the
    // first screen is gone
    expect(
      find.byKey(const ValueKey<String>('tile-animated_content')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('tile-aurora_stack')),
      findsNothing,
    );
  });
}
