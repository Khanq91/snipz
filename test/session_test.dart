// The session flag ("đợt"): SESSION.yaml → index.json `session` → gallery
// "✦ New" filter chip + NEW/FIX tile badges. Uses the real committed
// artifacts like widget_test.dart, so these tests also pin that the current
// SESSION.yaml actually flows through the pipeline.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/app/app.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/index_loader.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/core/prefs.dart';
import 'package:yaml/yaml.dart';

Set<String> _stringIds(Object? value) =>
    value is Iterable<Object?> ? value.map((id) => '$id').toSet() : <String>{};

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
    final YamlMap source =
        loadYaml(File('SESSION.yaml').readAsStringSync())! as YamlMap;
    expect(
      session,
      isNotNull,
      reason: 'SESSION.yaml exists, so the index must embed it',
    );
    expect(session!.id, '${source['id']}');
    expect(
      session.title,
      source['title'] == null ? null : '${source['title']}',
    );
    expect(session.date, '${source['date']}');
    expect(session.added, _stringIds(source['added']));
    expect(session.fixed, _stringIds(source['fixed']));
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
    final Map<String, Object?> json =
        jsonDecode(File('assets/index.json').readAsStringSync())
            as Map<String, Object?>;
    final ComponentIndex index = ComponentIndex.fromJson(json);
    final SessionInfo session = index.session!;
    expect(session.isEmpty, isFalse);
    final String componentId = index.components
        .firstWhere((component) => session.contains(component.id))
        .id;
    final String outsideId = index.components
        .firstWhere((component) => !session.contains(component.id))
        .id;
    final Finder outsideTile = find.byKey(ValueKey<String>('tile-$outsideId'));
    await tester.scrollUntilVisible(
      outsideTile,
      500,
      scrollable: find.descendant(
        of: find.byType(GridView).first,
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(outsideTile, findsOneWidget);

    // Narrow the lazy grid to the current batch before checking its tile and badge.
    await tester.tap(find.byKey(const ValueKey<String>('filter-session')));
    await tester.pump();

    // A current-batch component remains, with the matching badge.
    final Finder tile = find.byKey(ValueKey<String>('tile-$componentId'));
    await tester.scrollUntilVisible(
      tile,
      500,
      scrollable: find.descendant(
        of: find.byType(GridView).first,
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(tile, findsOneWidget);
    final Finder badge = find.byKey(
      ValueKey<String>('session-badge-$componentId'),
    );
    expect(badge, findsOneWidget);
    final SessionFlag flag = session.flagOf(componentId)!;
    expect(
      find.descendant(
        of: badge,
        matching: find.text(flag == SessionFlag.added ? '✦ NEW' : 'FIX'),
      ),
      findsOneWidget,
    );

    // …while out-of-session components that would otherwise be on the
    // first screen are gone
    expect(outsideTile, findsNothing);
  });
}
