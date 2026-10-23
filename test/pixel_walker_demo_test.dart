import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/pixel_walker/pixel_walker.dart';
import 'package:snipz/components/pixel_walker/pixel_walker_demo.dart';
import 'package:snipz/components/pull_reveal_refresh/pull_reveal_refresh.dart';
import 'package:snipz/components/pull_reveal_refresh/pull_reveal_refresh_demo.dart';

Widget _host(WidgetBuilder builder, {Size size = const Size(360, 520)}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: size,
            child: Builder(builder: builder),
          ),
        ),
      ),
    );

PixelWalker _walker(WidgetTester tester) =>
    tester.widget<PixelWalker>(find.byType(PixelWalker));

Future<void> _tapControl(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(
    target,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(target);
  await tester.pump();
}

Future<void> _selectVersion(WidgetTester tester, String label) async {
  final picker = find.byKey(const ValueKey('pixel-version'));
  await tester.scrollUntilVisible(
    picker,
    -120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(picker);
  // A live walker keeps ticking, so wait only for the dropdown transition.
  await tester.pump(const Duration(milliseconds: 350));
  await tester.tap(find.text(label).last);
  await tester.pump(const Duration(milliseconds: 350));
}

Future<TestGesture> _pullToReady(WidgetTester tester) async {
  final top = tester.getTopLeft(find.byType(ListView));
  final gesture = await tester.startGesture(top + const Offset(90, 120));
  await gesture.moveBy(const Offset(0, 24));
  await tester.pump();
  await gesture.moveBy(const Offset(0, 60));
  await tester.pump();
  expect(_walker(tester).walking, isFalse);
  expect(_walker(tester).progress, inExclusiveRange(0.0, 1.0));
  await gesture.moveBy(const Offset(0, 180));
  await tester.pump();
  expect(_walker(tester).progress, 1);
  expect(_walker(tester).readiness, 1);
  expect(_walker(tester).walking, isFalse);
  return gesture;
}

Future<void> _startRefresh(WidgetTester tester) async {
  final gesture = await _pullToReady(tester);
  await gesture.up();
  await tester.pump();
  expect(_walker(tester).walking, isTrue);
  expect(_walker(tester).readiness, 0);
}

void main() {
  testWidgets('version changes retain mascot, scene, speed and frozen phase', (
    tester,
  ) async {
    await tester.pumpWidget(_host(pixelWalkerDemo.builder));
    expect(_walker(tester).sprite!.version, PixelSpriteVersion.v2);
    await _tapControl(tester, 'Đêm — cao tầng, núi, mây');
    await _tapControl(tester, 'Axo');
    await _tapControl(tester, 'Xem từng nhịp');
    final speed = find.byKey(const ValueKey('pixel-speed'));
    tester.widget<Slider>(speed).onChanged!(1.3);
    await tester.pump();
    final scrub = find.byKey(const ValueKey('pixel-scrub'));
    await tester.ensureVisible(scrub);
    tester.widget<Slider>(scrub).onChanged!(2.75);
    await tester.pump();
    final state = tester.state(find.byType(PixelWalker));
    final originalSprite = _walker(tester).sprite;

    for (final (version, label) in [
      (PixelSpriteVersion.v1, 'V1 · Original'),
      (PixelSpriteVersion.v3, 'V3 · Pocket pals'),
      (PixelSpriteVersion.v2, 'V2 · Mochi buddies'),
    ]) {
      await _selectVersion(tester, label);
      final walker = _walker(tester);
      expect(walker.sprite!.version, version);
      expect(walker.sprite!.gait, PixelGait.axolotl);
      expect(walker.scene, PixelWalkerScene.nightCity);
      expect(walker.speed, 1.3);
      expect(walker.frozenAt, 2.75);
      expect(walker.walking, isTrue);
      expect(tester.state(find.byType(PixelWalker)), same(state));
      expect(tester.takeException(), isNull);
    }
    expect(_walker(tester).sprite, same(originalSprite));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'six mascot picks and scene survive local frame scrub and resume',
    (tester) async {
      await tester.pumpWidget(_host(pixelWalkerDemo.builder));
      await _tapControl(tester, 'Đêm — cao tầng, núi, mây');
      for (final (label, gait) in [
        ('Clawd', PixelGait.clawd),
        ('Miu', PixelGait.miu),
        ('Capy', PixelGait.capy),
        ('Quạc', PixelGait.duck),
        ('Cáu', PixelGait.crab),
        ('Axo', PixelGait.axolotl),
      ]) {
        await _tapControl(tester, label);
        expect(_walker(tester).sprite!.gait, gait);
        expect(_walker(tester).scene, PixelWalkerScene.nightCity);
      }
      final state = tester.state(find.byType(PixelWalker));
      await _tapControl(tester, 'Xem từng nhịp');
      expect(_walker(tester).frozenAt, .38);
      final slider = find.byKey(const ValueKey('pixel-scrub'));
      await tester.ensureVisible(slider);
      tester.widget<Slider>(slider).onChanged!(2.75);
      await tester.pump();
      expect(_walker(tester).frozenAt, 2.75);
      expect(_walker(tester).sprite!.gait, PixelGait.axolotl);
      expect(_walker(tester).scene, PixelWalkerScene.nightCity);
      expect(tester.state(find.byType(PixelWalker)), same(state));
      // Let control ink/chip animations finish; the frozen mascot stays idle.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      await _tapControl(tester, 'Xem từng nhịp');
      expect(_walker(tester).frozenAt, isNull);
      expect(_walker(tester).walking, isTrue);
      expect(_walker(tester).sprite!.gait, PixelGait.axolotl);
      expect(_walker(tester).scene, PixelWalkerScene.nightCity);
      expect(tester.state(find.byType(PixelWalker)), same(state));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('both demos fit narrow and landscape preview stages', (
    tester,
  ) async {
    for (final size in [const Size(240, 260), const Size(480, 260)]) {
      for (final demo in [pixelWalkerDemo, pullRevealRefreshDemo]) {
        await tester.pumpWidget(_host(demo.builder, size: size));
        expect(tester.takeException(), isNull);
        for (final label in [
          'V1 · Original',
          'V3 · Pocket pals',
          'V2 · Mochi buddies',
        ]) {
          await _selectVersion(tester, label);
          expect(tester.takeException(), isNull);
        }
        // Force controls and list tiles beyond the first viewport to layout.
        await tester.drag(find.byType(ListView), const Offset(0, -450));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets('refresh keeps scene and species when changing art versions', (
    tester,
  ) async {
    await tester.pumpWidget(_host(pullRevealRefreshDemo.builder));
    await tester.tap(find.text('Cảnh: thành phố'));
    await tester.pump();
    await tester.tap(find.text('Mascot: Clawd'));
    await tester.pump();
    await tester.tap(find.text('Mascot: Miu (mèo)'));
    await tester.pump();
    await _selectVersion(tester, 'V3 · Pocket pals');
    // Selecting a lower control scrolls the list. A refresh gesture starts
    // at the actual top, just as it does when used in the app.
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump();
    await _startRefresh(tester);
    expect(_walker(tester).sprite!.version, PixelSpriteVersion.v3);
    expect(_walker(tester).sprite!.gait, PixelGait.capy);
    expect(_walker(tester).scene, PixelWalkerScene.nightCity);
    final state = tester.state(find.byType(PixelWalker));

    // Changing art while a request is active must not restart the header.
    await _selectVersion(tester, 'V1 · Original');
    expect(_walker(tester).sprite!.version, PixelSpriteVersion.v1);
    expect(_walker(tester).sprite!.gait, PixelGait.capy);
    expect(_walker(tester).scene, PixelWalkerScene.nightCity);
    expect(_walker(tester).walking, isTrue);
    expect(tester.state(find.byType(PixelWalker)), same(state));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump();
    expect(
      find.text('Kéo xuống để refresh — đã refresh 1 lần'),
      findsOneWidget,
    );
    expect(find.byType(PixelWalker), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'pull demo holds completion gesture before collapse and can repeat',
    (tester) async {
      await tester.pumpWidget(_host(pullRevealRefreshDemo.builder));
      expect(find.byType(PullRevealRefresh), findsOneWidget);
      expect(find.byType(PixelWalker), findsNothing);
      for (int count = 1; count <= 2; count++) {
        await _startRefresh(tester);
        await tester.pump(const Duration(milliseconds: 220));
        expect(
          tester.getSize(find.byType(PixelWalker)).height,
          closeTo(110, .01),
        );
        expect(_walker(tester).celebration, 0);
        expect(_walker(tester).motion, 1);
        await tester.pump(const Duration(milliseconds: 2780));
        await tester.pump(const Duration(milliseconds: 120));
        final early = _walker(tester).celebration;
        expect(early, inExclusiveRange(0.0, 1.0));
        expect(_walker(tester).motion, closeTo(1 - early, 1e-9));
        expect(_walker(tester).progress, 1);
        expect(
          tester.getSize(find.byType(PixelWalker)).height,
          closeTo(110, .01),
        );
        expect(
          find.text('Kéo xuống để refresh — đã refresh ${count - 1} lần'),
          findsOneWidget,
        );
        await tester.pump(const Duration(milliseconds: 120));
        expect(_walker(tester).celebration, greaterThan(early));
        expect(
          tester.getSize(find.byType(PixelWalker)).height,
          closeTo(110, .01),
        );
        await tester.pump(const Duration(milliseconds: 160));
        expect(
          find.text('Kéo xuống để refresh — đã refresh $count lần'),
          findsOneWidget,
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(PixelWalker), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('leaving the pull demo during loading or completion is safe', (
    tester,
  ) async {
    for (final completing in [false, true]) {
      await tester.pumpWidget(_host(pullRevealRefreshDemo.builder));
      await _startRefresh(tester);
      if (completing) {
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 100));
        expect(_walker(tester).celebration, greaterThan(0));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      // Drain the simulated request as well as a cancelled finish controller.
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    }
  });
}
