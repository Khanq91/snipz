// Phase 3 verify (roadmap §12): a §2.3 shader-contract paint reaches
// card/button/text with NO carrierBuilders; the text carrier renders only
// after its chip is tapped (§9.2); failed carriers disable their chip with
// the reason as tooltip; non-shader paints without builders can't reach
// text/icon/border.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/spectrum_sweep/spectrum_sweep_demo.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/features/detail/carrier_switcher.dart';

ComponentMeta _paintMeta({
  List<String> verified = const [],
  Map<String, Object?> failed = const {},
}) => ComponentMeta.fromJson({
  'id': 'test_paint',
  'title': 'Test Paint',
  'kind': 'paint',
  'tags': <Object?>[],
  'paint_source': 'shader',
  'carriers_verified': verified,
  'carriers_failed': failed,
  'scale_aware': true,
  'portability': 'single_file',
  'entry': 'test_paint.dart',
  'files': {'test_paint.dart': 'entry'},
  'vendored_from': null,
  'assets_required': <Object?>[],
  'shaders_required': <Object?>[],
  'deps': <String, Object?>{},
  'origin': 'original',
  'source': null,
  'author': 'test',
  'license': null,
  'created': '2026-08-18',
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

/// Sync gradient spec — a real ui.Shader with zero assets (decision #1).
final CarrierShaderSpec _sweepSpec = CarrierShaderSpec(
  prepare: () async => CarrierShaderHandle(
    build: (bounds, scale, time) => ui.Gradient.linear(
      bounds.topLeft,
      bounds.bottomRight,
      const [Color(0xFFFF0000), Color(0xFF0000FF)],
    ),
  ),
);

Widget _host(ComponentMeta meta, ComponentDemo demo) => MaterialApp(
  home: Scaffold(body: CarrierSwitcher(meta: meta, demo: demo)),
);

Finder _chip(Carrier c) => find.byKey(ValueKey('carrier-chip-${c.wire}'));

Finder _stage(Carrier c) => find.byKey(ValueKey('carrier-stage-${c.wire}'));

Future<void> _tapChip(WidgetTester tester, Carrier c) async {
  await tester.tap(_chip(c));
  await tester.pump(); // rebuild with the new selection
  await tester.pump(); // settle the async prepare() microtask
}

void main() {
  final ComponentDemo shaderDemo = ComponentDemo(
    id: 'test_paint',
    builder: (context) => const ColoredBox(color: Color(0xFF123456)),
    shader: _sweepSpec,
  );

  testWidgets('fullscreen by default; text carrier lazy until tapped', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_paintMeta(), shaderDemo));
    expect(_stage(Carrier.fullscreen), findsOneWidget);
    // §9.2: the saveLayer-per-frame text sample must not exist yet.
    expect(find.text('Snipz'), findsNothing);
    expect(_stage(Carrier.text), findsNothing);

    await _tapChip(tester, Carrier.text);
    expect(_stage(Carrier.text), findsOneWidget);
    expect(find.text('Snipz'), findsOneWidget);
  });

  testWidgets('shader paint reaches card and button with no carrierBuilders', (
    tester,
  ) async {
    expect(shaderDemo.carrierBuilders, isEmpty);
    await tester.pumpWidget(_host(_paintMeta(), shaderDemo));

    await _tapChip(tester, Carrier.card);
    expect(_stage(Carrier.card), findsOneWidget);

    await _tapChip(tester, Carrier.button);
    expect(_stage(Carrier.button), findsOneWidget);
    // The stage's own label — the chip row also says "Button".
    expect(
      find.descendant(of: _stage(Carrier.button), matching: find.text('Button')),
      findsOneWidget,
    );

    await _tapChip(tester, Carrier.border);
    expect(_stage(Carrier.border), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('failed carrier: chip disabled with the reason as tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _paintMeta(failed: {'icon': 'quá nhỏ, mất chi tiết'}),
        shaderDemo,
      ),
    );
    final ChoiceChip chip = tester.widget(_chip(Carrier.icon));
    expect(chip.onSelected, isNull);
    expect(
      find.byTooltip('quá nhỏ, mất chi tiết'),
      findsOneWidget,
    );
    // Tapping it must not change the stage.
    await tester.tap(_chip(Carrier.icon));
    await tester.pump();
    expect(_stage(Carrier.fullscreen), findsOneWidget);
  });

  testWidgets('non-shader paint: shape carriers embed, mask carriers disable', (
    tester,
  ) async {
    final ComponentDemo widgetDemo = ComponentDemo(
      id: 'test_paint',
      builder: (context) => const ColoredBox(color: Color(0xFF654321)),
    );
    await tester.pumpWidget(_host(_paintMeta(), widgetDemo));

    await _tapChip(tester, Carrier.card);
    expect(_stage(Carrier.card), findsOneWidget);

    for (final Carrier c in [Carrier.text, Carrier.icon, Carrier.border]) {
      final ChoiceChip chip = tester.widget(_chip(c));
      expect(chip.onSelected, isNull, reason: '$c must be unavailable');
    }
  });

  testWidgets('real seed spectrum_sweep renders card/button/text carriers', (
    tester,
  ) async {
    // The Phase 3 acceptance seed: no carrierBuilders, only the §2.3 factory.
    expect(spectrumSweepDemo.carrierBuilders, isEmpty);
    expect(spectrumSweepDemo.shader, isNotNull);
    await tester.pumpWidget(_host(_paintMeta(), spectrumSweepDemo));

    for (final Carrier c in [Carrier.card, Carrier.button, Carrier.text]) {
      await _tapChip(tester, Carrier.fullscreen);
      await _tapChip(tester, c);
      expect(_stage(c), findsOneWidget);
      // Let the sweep ticker advance a few frames on the carrier.
      await tester.pump(const Duration(milliseconds: 48));
    }
    expect(tester.takeException(), isNull);
  });
}
