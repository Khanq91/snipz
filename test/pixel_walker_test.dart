import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/pixel_walker/pixel_walker.dart';

Map<String, PixelSprite> _sprites() => {
  'Clawd': PixelSprite.clawd(),
  'Miu': PixelSprite.miu(),
  'Capy': PixelSprite.capy(),
  'Quac': PixelSprite.duck(),
  'Cau': PixelSprite.crab(),
  'Axo': PixelSprite.axolotl(),
};

Widget _host(
  PixelWalker walker, {
  Size size = const Size(320, 160),
  bool tickerEnabled = true,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: TickerMode(
      enabled: tickerEnabled,
      child: SizedBox.fromSize(size: size, child: walker),
    ),
  ),
);

CustomPainter _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.descendant(
        of: find.byType(PixelWalker),
        matching: find.byType(CustomPaint),
      ),
    )
    .painter!;

Future<Uint8List> _raster(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..clipRect(Offset.zero & size);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.ceil(), size.height.ceil());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = Uint8List.fromList(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return result;
}

Future<Uint8List> _capture(
  WidgetTester tester, [
  Size size = const Size(320, 160),
]) async => (await tester.runAsync(() => _raster(_painter(tester), size)))!;

int _differentPixels(Uint8List a, Uint8List b) {
  expect(a.length, b.length);
  int count = 0;
  for (int i = 0; i < a.length; i += 4) {
    if (a[i] != b[i] ||
        a[i + 1] != b[i + 1] ||
        a[i + 2] != b[i + 2] ||
        a[i + 3] != b[i + 3]) {
      count++;
    }
  }
  return count;
}

int _visiblePixels(Uint8List pixels) {
  int count = 0;
  for (int i = 3; i < pixels.length; i += 4) {
    if (pixels[i] > 0) count++;
  }
  return count;
}

List<double> _body(PixelSpritePose pose) => [
  pose.lean,
  pose.bob,
  pose.sway,
  pose.scaleX,
  pose.scaleY,
];

Future<void> _advance(WidgetTester tester, int milliseconds) async {
  for (int elapsed = 0; elapsed < milliseconds; elapsed += 20) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all mascot frames have intact pixels and an expanded walk cycle', () {
    final sprites = _sprites();
    expect(sprites.values.map((sprite) => sprite.gait).toSet(), hasLength(6));
    for (final entry in sprites.entries) {
      final sprite = entry.value;
      expect(sprite.rowCount, greaterThan(0), reason: entry.key);
      expect(sprite.colCount, greaterThan(0), reason: entry.key);
      expect(sprite.frames.length, greaterThanOrEqualTo(7), reason: entry.key);
      final drawings = <String>{};
      for (final frame in sprite.frames) {
        expect(frame, hasLength(sprite.rowCount), reason: entry.key);
        int painted = 0;
        for (final row in frame) {
          expect(row, hasLength(sprite.colCount), reason: entry.key);
          for (final pixel in row.split('')) {
            expect(
              pixel == '.' || sprite.palette.containsKey(pixel),
              isTrue,
              reason: '${entry.key}: pixel "$pixel" has no palette color',
            );
            if (pixel != '.') painted++;
          }
        }
        expect(painted, greaterThan(30), reason: entry.key);
        drawings.add(frame.join('\n'));
      }
      expect(drawings.length, greaterThanOrEqualTo(5), reason: entry.key);
    }
  });

  test('each gait has a distinct, bounded and continuous body motion', () {
    final signatures = <String>{};
    for (final entry in _sprites().entries) {
      final sprite = entry.value;
      final signature = <String>[];
      for (int step = 0; step <= 240; step++) {
        final time = step / 60;
        final pose = sprite.samplePose(time);
        expect(pose.frameIndex, inInclusiveRange(0, sprite.frames.length - 1));
        expect(pose.lean.abs(), lessThan(.4), reason: entry.key);
        expect(pose.bob.abs(), lessThan(2.5), reason: entry.key);
        expect(pose.sway.abs(), lessThan(2.5), reason: entry.key);
        expect(pose.scaleX, inInclusiveRange(.7, 1.3), reason: entry.key);
        expect(pose.scaleY, inInclusiveRange(.7, 1.3), reason: entry.key);
        signature.add(
          _body(pose).map((value) => value.toStringAsFixed(4)).join(),
        );
      }
      expect(signatures.add(signature.join('|')), isTrue, reason: entry.key);

      // The pixel drawing can change abruptly; the body must not snap at a
      // frame boundary, a cycle wrap, or after a long-running refresh.
      for (final origin in [0.0, 60.0, 3600.0]) {
        for (int step = 1; step <= 120; step++) {
          final time = origin + step / 60;
          final before = _body(sprite.samplePose(time - .00001));
          final after = _body(sprite.samplePose(time + .00001));
          for (int axis = 0; axis < before.length; axis++) {
            expect(
              (after[axis] - before[axis]).abs(),
              lessThan(.002),
              reason: '${entry.key}, t=$time, body axis=$axis',
            );
          }
        }
      }
    }
  });

  test(
    'standing and zero-motion poses rest; external reactions stay bounded',
    () {
      for (final entry in _sprites().entries) {
        final sprite = entry.value;
        final rest = sprite.samplePose(0, walking: false);
        for (final reaction in [
          sprite.samplePose(0, walking: false, readiness: 1),
          sprite.samplePose(0, walking: false, celebration: .5),
        ]) {
          expect(
            [reaction.frameIndex, ..._body(reaction)],
            isNot(orderedEquals([rest.frameIndex, ..._body(rest)])),
            reason: '${entry.key} should visibly react to the refresh phase',
          );
        }
        for (final time in [0.0, .19, 2.0, 3600.0]) {
          final stopped = sprite.samplePose(time, walking: false);
          final zeroMotion = sprite.samplePose(time, motion: 0);
          expect(stopped.frameIndex, 0, reason: entry.key);
          expect(zeroMotion.frameIndex, 0, reason: entry.key);
          expect(_body(stopped), orderedEquals(_body(rest)), reason: entry.key);
          expect(
            _body(zeroMotion),
            orderedEquals(_body(rest)),
            reason: entry.key,
          );
          for (final reaction in [0.0, .35, 1.0]) {
            final pose = sprite.samplePose(
              time,
              walking: false,
              readiness: reaction,
              celebration: 1 - reaction,
            );
            expect(_body(pose).every((value) => value.isFinite), isTrue);
            expect(pose.lean.abs(), lessThan(.4), reason: entry.key);
            expect(pose.bob.abs(), lessThan(2.5), reason: entry.key);
            expect(pose.sway.abs(), lessThan(2.5), reason: entry.key);
            expect(pose.scaleX, inInclusiveRange(.7, 1.3), reason: entry.key);
            expect(pose.scaleY, inInclusiveRange(.7, 1.3), reason: entry.key);
          }
        }
      }
    },
  );

  testWidgets('static and frozen scenes schedule no animation frames', (
    tester,
  ) async {
    for (final frozen in [false, true]) {
      await tester.pumpWidget(
        _host(
          PixelWalker(
            key: ValueKey(frozen),
            walking: frozen,
            frozenAt: frozen ? .37 : null,
            sprite: PixelSprite.miu(),
          ),
        ),
      );
      final before = await _capture(tester);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 20));
      expect(await _capture(tester), orderedEquals(before));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('frozen time selects a reproducible walking frame', (
    tester,
  ) async {
    Future<Uint8List> at(double time) async {
      await tester.pumpWidget(
        _host(
          PixelWalker(
            walking: true,
            frozenAt: time,
            sprite: PixelSprite.duck(),
          ),
        ),
      );
      return _capture(tester);
    }

    final first = await at(.13);
    final later = await at(.41);
    expect(_differentPixels(first, later), greaterThan(100));
    expect(await at(.13), orderedEquals(first));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('TickerMode resumes from its visible pose without catching up', (
    tester,
  ) async {
    final sprite = PixelSprite.axolotl();
    Widget host(bool enabled) => _host(
      PixelWalker(walking: true, sprite: sprite),
      tickerEnabled: enabled,
    );
    await tester.pumpWidget(host(true));
    await _advance(tester, 800);
    final beforePause = await _capture(tester);
    await tester.pumpWidget(host(false));
    expect(await _capture(tester), orderedEquals(beforePause));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 20));
    expect(await _capture(tester), orderedEquals(beforePause));
    await tester.pumpWidget(host(true));
    await tester.pump();
    expect(await _capture(tester), orderedEquals(beforePause));
    await _advance(tester, 200);
    expect(
      _differentPixels(beforePause, await _capture(tester)),
      greaterThan(100),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('changing live speed preserves phase and affects future travel', (
    tester,
  ) async {
    final sprite = PixelSprite.capy();
    Future<void> speed(double value) => tester.pumpWidget(
      _host(PixelWalker(walking: true, speed: value, sprite: sprite)),
    );
    await speed(1);
    await _advance(tester, 1260);
    final before = await _capture(tester);
    await speed(2.5);
    expect(await _capture(tester), orderedEquals(before));
    await _advance(tester, 200);
    final faster = await _capture(tester);
    expect(_differentPixels(before, faster), greaterThan(100));
    await speed(.4);
    expect(await _capture(tester), orderedEquals(faster));
    await _advance(tester, 200);
    expect(_differentPixels(faster, await _capture(tester)), greaterThan(20));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('compact night refresh header retains a visible crescent', (
    tester,
  ) async {
    const size = Size(320, 110);
    await tester.pumpWidget(
      _host(
        PixelWalker(
          scene: PixelWalkerScene.nightCity,
          starColor: const Color(0xFFFF00FF),
          skylineColor: Colors.transparent,
          windowColor: Colors.transparent,
          sprite: PixelSprite.clawd(color: Colors.transparent),
        ),
        size: size,
      ),
    );
    final pixels = await _capture(tester, size);
    int moonPixels = 0;
    // The moon is brighter than either star tier. Inspect its actual painted
    // pixels, so a moon whose center was placed above the clip fails this test.
    for (int y = 0; y < 70; y++) {
      for (int x = 210; x < 290; x++) {
        final i = (y * size.width.toInt() + x) * 4;
        if (pixels[i] >= 225 &&
            pixels[i + 1] < 5 &&
            pixels[i + 2] >= 225 &&
            pixels[i + 3] >= 225) {
          moonPixels++;
        }
      }
    }
    expect(moonPixels, greaterThan(40));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'all six mascots render at narrow, wide and partially revealed sizes',
    (tester) async {
      for (final size in [const Size(120, 110), const Size(480, 200)]) {
        final complete = <Uint8List>[];
        for (final sprite in _sprites().values) {
          int partialPixels = 0;
          for (final progress in [0.0, .42, 1.0]) {
            await tester.pumpWidget(
              _host(
                PixelWalker(
                  sprite: sprite,
                  scene: PixelWalkerScene.nightCity,
                  walking: true,
                  frozenAt: .27,
                  progress: progress,
                ),
                size: size,
              ),
            );
            final pixels = await _capture(tester, size);
            final visible = _visiblePixels(pixels);
            if (progress == 0) {
              expect(visible, 0);
            } else if (progress < 1) {
              expect(visible, greaterThan(100));
              partialPixels = visible;
            } else {
              expect(visible, greaterThan(partialPixels));
              complete.add(pixels);
            }
            expect(tester.takeException(), isNull);
            expect(tester.binding.transientCallbackCount, 0);
          }
        }
        for (int i = 0; i < complete.length; i++) {
          for (int j = i + 1; j < complete.length; j++) {
            expect(
              _differentPixels(complete[i], complete[j]),
              greaterThan(250),
            );
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('render sprite gait and reaction atlas for visual review', (
    tester,
  ) async {
    final output = Platform.environment['PIXEL_WALKER_REVIEW'];
    if (output == null) return;
    await tester.runAsync(() async {
      final font = File('C:/Windows/Fonts/arial.ttf');
      if (font.existsSync()) {
        await (FontLoader('Review')..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
      }
    });
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawColor(const Color(0xFF0C1018), BlendMode.src);
    void label(String text, double x, double y) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'Review',
            fontSize: 15,
            color: Color(0xFFDDE6F4),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x, y));
      painter.dispose();
    }

    const headings = [
      'Rest',
      'Step .10',
      'Step .28',
      'Step .46',
      'Ready',
      'Complete',
    ];
    for (int col = 0; col < headings.length; col++) {
      label(headings[col], col * 180 + 16, 12);
    }
    int row = 0;
    for (final entry in _sprites().entries) {
      final y = 42.0 + row * 190;
      label(entry.key, 12, y);
      for (int col = 0; col < 6; col++) {
        final walker = PixelWalker(
          sprite: entry.value,
          walking: col > 0 && col < 4,
          frozenAt: switch (col) {
            1 => .10,
            2 => .28,
            3 => .46,
            _ => 0,
          },
          readiness: col == 4 ? 1 : 0,
          celebration: col == 5 ? .5 : 0,
          skylineColor: const Color(0xFF526077),
        );
        const size = Size(174, 150);
        await tester.pumpWidget(_host(walker, size: size));
        canvas.save();
        canvas.translate(col * 180.0 + 3, y + 24);
        canvas.clipRect(Offset.zero & size);
        _painter(tester).paint(canvas, size);
        canvas.restore();
      }
      row++;
    }
    label('110 px night refresh headers', 12, 1195);
    int col = 0;
    for (final entry in _sprites().entries) {
      const size = Size(174, 110);
      await tester.pumpWidget(
        _host(
          PixelWalker(
            sprite: entry.value,
            scene: PixelWalkerScene.nightCity,
            walking: true,
            frozenAt: .27,
            skylineColor: const Color(0xFF93A1BE),
          ),
          size: size,
        ),
      );
      canvas.save();
      canvas.translate(col * 180.0 + 3, 1220);
      canvas.clipRect(Offset.zero & size);
      _painter(tester).paint(canvas, size);
      canvas.restore();
      col++;
    }
    await tester.pumpWidget(const SizedBox.shrink());
    final picture = recorder.endRecording();
    await tester.runAsync(() async {
      final image = await picture.toImage(1080, 1340);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(output).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    picture.dispose();
  });
}
