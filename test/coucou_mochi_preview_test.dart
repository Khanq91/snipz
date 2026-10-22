import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/coucou_mochi/coucou_mochi.dart';
import 'package:snipz/components/coucou_mochi/coucou_mochi_demo.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/features/detail/preview_stage.dart';

ComponentMeta _meta() => ComponentMeta.fromJson({
  'id': 'coucou_mochi',
  'title': 'Coucou Mochi',
  'kind': 'composite',
  'tags': <Object?>[],
  'paint_source': 'painter',
  'carriers_verified': <Object?>[],
  'carriers_failed': <String, Object?>{},
  'scale_aware': false,
  'portability': 'folder',
  'entry': 'coucou_mochi.dart',
  'files': {'coucou_mochi.dart': 'entry'},
  'vendored_from': null,
  'assets_required': <Object?>[],
  'shaders_required': <Object?>[],
  'deps': <String, Object?>{},
  'origin': 'original',
  'source': null,
  'author': 'test',
  'license': null,
  'created': '2026-10-22',
  'created_flutter': '3.44.5',
  'created_dart': '3.12.2',
  'created_deps': <String, Object?>{},
  'platforms_initial': ['android'],
  'version': '1.0.0',
  'latest_known_good': null,
  'last_verified': null,
  'status': null,
  'preview': null,
  'test_history': <Object?>[],
});

Widget _host({String? variant, bool frozen = false}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 360,
        height: 640,
        child: PreviewStage(
          meta: _meta(),
          demo: coucouMochiDemo,
          initialVariantId: variant,
          initialFrozen: frozen,
        ),
      ),
    ),
  ),
);

Finder get _live => find.byWidgetPredicate(
  (widget) => widget is CoucouMochi && widget.frozenAt == null,
  skipOffstage: false,
);

CoucouMochiFrame _frame(WidgetTester tester, Finder mascot) {
  final dynamic painter = tester
      .widget<CustomPaint>(
        find.descendant(
          of: mascot,
          matching: find.byType(CustomPaint, skipOffstage: false),
          skipOffstage: false,
        ),
      )
      .painter;
  // Inspect the existing repaint signal without adding a production test API.
  // ignore: avoid_dynamic_calls
  return painter.frames.value as CoucouMochiFrame;
}

Future<void> _advance(WidgetTester tester, double seconds) async {
  for (int i = 0; i < (seconds * 50).ceil(); i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _selectSkin(WidgetTester tester, CoucouMochiSkin skin) async {
  await tester.tap(find.byKey(const ValueKey('mochi-skin-dropdown')));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(skin.label).last);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _mute(WidgetTester tester) async {
  await tester.ensureVisible(find.byTooltip('Mute sounds'));
  await tester.tap(find.byTooltip('Mute sounds'));
  await tester.pump();
}

void main() {
  testWidgets('viewer scrub preserves skin, mute and paused live character', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _mute(tester);
    await _selectSkin(tester, CoucouMochiSkin.cloud);
    await tester.ensureVisible(find.byTooltip('Gulp'));
    await tester.tap(find.byTooltip('Gulp'));
    await _advance(tester, 1);
    final liveState = tester.state(_live);
    final liveTime = _frame(tester, _live).time;
    expect(_frame(tester, _live).morph, greaterThan(.9));

    await tester.tap(find.byKey(const ValueKey('toggle-freeze')));
    await tester.pump();
    expect(find.byType(CoucouMochi), findsOneWidget);
    expect(find.byKey(const ValueKey('mochi-skin-dropdown')), findsOneWidget);
    expect(find.byTooltip('Gulp'), findsNothing);
    expect(
      tester.widget<CoucouMochi>(find.byType(CoucouMochi)).skin,
      CoucouMochiSkin.cloud,
    );
    expect(TickerMode.valuesOf(tester.element(_live)).enabled, isFalse);
    await _advance(tester, 2);
    expect(_frame(tester, _live).time, liveTime);
    expect(tester.state(_live), same(liveState));

    tester
        .widget<Slider>(find.byKey(const ValueKey('scrub-slider')))
        .onChanged!(13.7);
    await tester.pump();
    final scrubbed = tester.widget<CoucouMochi>(find.byType(CoucouMochi));
    expect(scrubbed.skin, CoucouMochiSkin.cloud);
    expect(scrubbed.frozenAt, closeTo(1.7, 1e-9));
    expect(scrubbed.initialEmote, CoucouMochiEmote.chill);
    expect(scrubbed.soundEnabled, isFalse);
    expect(_frame(tester, _live).time, liveTime);

    await tester.tap(find.byKey(const ValueKey('toggle-freeze')));
    await tester.pump();
    expect(find.byType(CoucouMochi), findsOneWidget);
    expect(tester.state(_live), same(liveState));
    expect(tester.widget<CoucouMochi>(_live).skin, CoucouMochiSkin.cloud);
    expect(_frame(tester, _live).time, liveTime);
    expect(_frame(tester, _live).morph, greaterThan(.9));
    expect(find.byTooltip('Enable sounds'), findsOneWidget);
    await _advance(tester, .2);
    expect(_frame(tester, _live).time, greaterThan(liveTime));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_host());
    expect(tester.widget<CoucouMochi>(_live).skin, CoucouMochiSkin.original);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('named skin variant freezes the current dropdown selection', (
    tester,
  ) async {
    await tester.pumpWidget(_host(variant: 'skin-nekoPudding'));
    expect(tester.widget<CoucouMochi>(_live).skin, CoucouMochiSkin.nekoPudding);
    await _mute(tester);
    await _selectSkin(tester, CoucouMochiSkin.cloud);
    final liveState = tester.state(_live);
    await tester.tap(find.byKey(const ValueKey('toggle-freeze')));
    await tester.pump();
    expect(find.byKey(const ValueKey('scrub-slider')), findsNothing);
    final frozen = tester.widget<CoucouMochi>(find.byType(CoucouMochi));
    expect(frozen.skin, CoucouMochiSkin.cloud);
    expect(frozen.frozenAt, 1.65);
    expect(frozen.soundEnabled, isFalse);
    expect(find.byKey(const ValueKey('mochi-skin-dropdown')), findsOneWidget);
    final time = _frame(tester, _live).time;
    await _advance(tester, 1);
    expect(_frame(tester, _live).time, time);
    await tester.tap(find.byKey(const ValueKey('toggle-freeze')));
    await tester.pump();
    expect(tester.widget<CoucouMochi>(_live).skin, CoucouMochiSkin.cloud);
    expect(tester.state(_live), same(liveState));
    expect(find.byTooltip('Enable sounds'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('frozen skin deep link starts with its own skin and no ticking', (
    tester,
  ) async {
    await tester.pumpWidget(_host(variant: 'skin-nekoPudding', frozen: true));
    expect(
      tester.widget<CoucouMochi>(find.byType(CoucouMochi)).skin,
      CoucouMochiSkin.nekoPudding,
    );
    expect(TickerMode.valuesOf(tester.element(_live)).enabled, isFalse);
    final time = _frame(tester, _live).time;
    await _advance(tester, 1);
    expect(_frame(tester, _live).time, time);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
