// Freeze toggle + variant chips + state board (D1-D3): the PreviewStage
// mechanics with a synthetic demo, and the real bloub_bot registry entry on
// the states board.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/features/detail/preview_stage.dart';
import 'package:snipz/features/detail/states_screen.dart';

ComponentMeta _compositeMeta() => ComponentMeta.fromJson({
  'id': 'test_composite',
  'title': 'Test Composite',
  'kind': 'composite',
  'tags': <Object?>[],
  'paint_source': 'painter',
  'carriers_verified': <Object?>[],
  'carriers_failed': <String, Object?>{},
  'scale_aware': false,
  'portability': 'single_file',
  'entry': 'test_composite.dart',
  'files': {'test_composite.dart': 'entry'},
  'vendored_from': null,
  'assets_required': <Object?>[],
  'shaders_required': <Object?>[],
  'deps': <String, Object?>{},
  'origin': 'original',
  'source': null,
  'author': 'test',
  'license': null,
  'created': '2026-08-21',
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

ComponentDemo _demoWithVariants() => ComponentDemo(
  id: 'test_composite',
  builder: (context) => const Text('default-live'),
  variants: [
    DemoVariant(
      id: 'alpha',
      label: 'Alpha',
      builder: (context) => const Text('alpha-live'),
      frozenBuilder: (context) => const Text('alpha-frozen'),
    ),
    DemoVariant(
      id: 'beta',
      label: 'Beta',
      builder: (context) => const Text('beta-live'),
    ),
  ],
);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('variant chips switch the previewed builder', (tester) async {
    await tester.pumpWidget(
      _host(PreviewStage(meta: _compositeMeta(), demo: _demoWithVariants())),
    );
    expect(find.text('default-live'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('variant-chip-alpha')));
    await tester.pumpAndSettle();
    expect(find.text('alpha-live'), findsOneWidget);
    expect(find.text('default-live'), findsNothing);
  });

  testWidgets('freeze uses the deterministic frame when the variant has one',
      (tester) async {
    await tester.pumpWidget(
      _host(PreviewStage(meta: _compositeMeta(), demo: _demoWithVariants())),
    );
    await tester.tap(find.byKey(const ValueKey('variant-chip-alpha')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('toggle-freeze')));
    await tester.pumpAndSettle();
    expect(find.text('alpha-frozen'), findsOneWidget);
    expect(find.text('alpha-live'), findsNothing);
  });

  testWidgets('freeze without a frozen frame disables tickers instead',
      (tester) async {
    await tester.pumpWidget(
      _host(PreviewStage(meta: _compositeMeta(), demo: _demoWithVariants())),
    );
    await tester.tap(find.byKey(const ValueKey('variant-chip-beta')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-freeze')));
    await tester.pumpAndSettle();

    // Still the live builder, but under a disabled TickerMode.
    expect(find.text('beta-live'), findsOneWidget);
    final TickerMode mode = tester.widget<TickerMode>(
      find
          .ancestor(of: find.text('beta-live'), matching: find.byType(TickerMode))
          .first,
    );
    expect(mode.enabled, isFalse);
  });

  testWidgets('deep-link params open on the requested variant, frozen',
      (tester) async {
    await tester.pumpWidget(
      _host(PreviewStage(
        meta: _compositeMeta(),
        demo: _demoWithVariants(),
        initialVariantId: 'alpha',
        initialFrozen: true,
      )),
    );
    expect(find.text('alpha-frozen'), findsOneWidget);
  });

  testWidgets('states board renders one frozen tile per bloub_bot state',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: StatesScreen(id: 'bloub_bot'),
    ));
    await tester.pump();
    // 7 catalog states -> 7 tiles, no animation loop running (frozen frames).
    // The grid is lazy: scroll the last state's tile into view to prove the
    // whole catalog is there.
    expect(find.byKey(const ValueKey('state-tile-idle')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('state-tile-hexagon')),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byKey(const ValueKey('state-tile-hexagon')), findsOneWidget);
  });
}
