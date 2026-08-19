// Phase 5 verify (roadmap §12): share block is paste-ready (deps, import,
// file list, GitHub link); Files menu entry only for multi-file components
// and its page opens the Code page on the tapped file; Code stays lazy until
// its page is pushed; checkerboard toggle works. Code/Info/Files live behind
// the detail overflow menu (key 'detail-menu') as separate routes — there are
// no swipeable tabs. (The pre-commit block and on-device frame pacing are
// verified outside flutter test — see the phase checklist.)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/app/app.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/index_loader.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/core/prefs.dart';
import 'package:snipz/core/share_block.dart';

ComponentMeta _paintMeta() => ComponentMeta.fromJson({
  'id': 'aurora_stack',
  'title': 'Aurora Stack',
  'kind': 'paint',
  'tags': <Object?>[],
  'paint_source': 'widget',
  'carriers_verified': <Object?>[],
  'carriers_failed': {'icon': 'too small'},
  'scale_aware': true,
  'portability': 'folder',
  'entry': 'aurora_stack.dart',
  'files': {
    'aurora_stack.dart': 'entry',
    '_noise_layer.dart': 'helper',
    '_blob_painter.dart': 'helper',
  },
  'vendored_from': null,
  'assets_required': <Object?>[],
  'shaders_required': ['lib/components/x/x.frag'],
  'deps': {'blur': '^4.0.1'},
  'origin': 'reimplemented',
  'source': null,
  'author': 'Khang',
  'license': null,
  'created': '2026-08-18',
  'created_flutter': '3.44.0',
  'created_dart': '3.12.0',
  'created_deps': <String, Object?>{},
  'platforms_initial': ['android'],
  'version': '1.0.0',
  'latest_known_good': null,
  'last_verified': null,
  'status': null,
  'preview': null,
  'test_history': <Object?>[],
});

late List<String> reads;

Future<void> _pumpApp(WidgetTester tester) async {
  // Tall viewport so every tile these tests tap is built, up to glass_card
  // at #9 alphabetically (GridView.builder skips off-screen tiles).
  tester.view.physicalSize = const Size(900, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
  await tester.pump();
  await tester.pump();
}

Future<void> _openDetail(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('tile-$id')));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('detail-menu')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300)); // menu open animation
}

Future<void> _tapAndRoute(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pump(); // start route push
  await tester.pump(const Duration(milliseconds: 400)); // route fade
  await tester.pump();
}

void main() {
  test('share block is paste-ready: deps, files, import, keys, link', () {
    final String block = buildShareBlock(
      _paintMeta(),
      repoUrl: 'https://github.com/Khanq91/snipz',
    );
    expect(block, contains('Snipz component: Aurora Stack (aurora_stack)'));
    expect(block, contains('dependencies:\n  blur: ^4.0.1'));
    expect(block, contains('Copy folder: lib/components/aurora_stack/  (3 files)'));
    expect(
      block,
      contains('aurora_stack.dart, _noise_layer.dart, _blob_painter.dart'),
    );
    expect(block, contains("import 'aurora_stack/aurora_stack.dart';"));
    // The two DIFFERENT pubspec keys stay separate (§3.1.8).
    expect(block, contains('`shaders:`: lib/components/x/x.frag'));
    expect(block, isNot(contains('`assets:`')));
    expect(block, contains('Scale hint'));
    expect(block, contains('Carrier icon: FAILED — too small'));
    expect(
      block,
      contains(
        'https://github.com/Khanq91/snipz/tree/main/lib/components/aurora_stack',
      ),
    );
  });

  test('share block without deps and without remote', () {
    final ComponentMeta meta = ComponentMeta.fromJson({
      'id': 'glass_card',
      'title': 'Glass Card',
      'kind': 'carrier',
      'tags': <Object?>[],
      'paint_source': 'none',
      'carriers_verified': <Object?>[],
      'carriers_failed': <String, Object?>{},
      'scale_aware': false,
      'portability': 'single_file',
      'entry': 'glass_card.dart',
      'files': {'glass_card.dart': 'entry'},
      'vendored_from': null,
      'assets_required': <Object?>[],
      'shaders_required': <Object?>[],
      'deps': <String, Object?>{},
      'origin': 'original',
      'source': null,
      'author': 'Khang',
      'license': null,
      'created': '2026-08-18',
      'created_flutter': '3.44.0',
      'created_dart': '3.12.0',
      'created_deps': <String, Object?>{},
      'platforms_initial': ['android'],
      'version': '1.0.0',
      'latest_known_good': null,
      'last_verified': null,
      'status': null,
      'preview': null,
      'test_history': <Object?>[],
    });
    final String block = buildShareBlock(meta);
    expect(block, contains('Deps: none — Flutter SDK only'));
    expect(block, contains('(1 file)'));
    expect(block, isNot(contains('GitHub:')));
    expect(block, isNot(contains('Scale hint')));
  });

  testWidgets('single-file component has no Files menu item; Code is lazy', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openDetail(tester, 'glass_card');

    await _openMenu(tester);
    expect(find.byKey(const ValueKey('menu-files')), findsNothing);
    expect(find.byKey(const ValueKey('menu-code')), findsOneWidget);
    // Preview + open menu alone must not load sources (§5.0).
    expect(reads, ['assets/index.json']);

    await _tapAndRoute(tester, find.byKey(const ValueKey('menu-code')));
    expect(reads, ['assets/index.json', 'assets/sources/glass_card.json']);
    expect(find.byKey(const ValueKey('code-view')), findsOneWidget);
  });

  testWidgets('Files page lists roles and opens the tapped file in Code', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openDetail(tester, 'aurora_stack');

    await _openMenu(tester);
    expect(find.byKey(const ValueKey('menu-files')), findsOneWidget);
    await _tapAndRoute(tester, find.byKey(const ValueKey('menu-files')));

    expect(find.byKey(const ValueKey('file-aurora_stack.dart')), findsOne);
    await _tapAndRoute(
      tester,
      find.byKey(const ValueKey('file-_noise_layer.dart')),
    );

    // Landed on the Code page with the tapped file selected.
    final SelectableText code = tester.widget(
      find.byKey(const ValueKey('code-view')),
    );
    expect(code.data, contains('AuroraNoiseOverlay'));
    final ChoiceChip chip = tester.widget(
      find.byKey(const ValueKey('code-file-_noise_layer.dart')),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('checkerboard toggles on a framed stage', (tester) async {
    await _pumpApp(tester);
    await _openDetail(tester, 'glass_card');

    final Finder toggle = find.byKey(const ValueKey('toggle-checkerboard'));
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
