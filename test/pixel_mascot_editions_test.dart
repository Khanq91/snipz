import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/pixel_walker/pixel_walker.dart';

const _names = ['Clawd', 'Miu', 'Capy', 'Quac', 'Cau', 'Axo'];

List<PixelSprite> _sprites(PixelSpriteVersion version) => [
  PixelSprite.clawd(version: version),
  PixelSprite.miu(version: version),
  PixelSprite.capy(version: version),
  PixelSprite.duck(version: version),
  PixelSprite.crab(version: version),
  PixelSprite.axolotl(version: version),
];

Widget _host(PixelWalker walker, Size size) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: SizedBox.fromSize(size: size, child: walker),
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
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = Uint8List.fromList(data!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'editions retain legacy art and cache distinct high resolution cycles',
    () {
      final legacy = _sprites(PixelSpriteVersion.v1);
      for (final version in PixelSpriteVersion.values.skip(1)) {
        final sprites = _sprites(version);
        final again = _sprites(version);
        for (int i = 0; i < sprites.length; i++) {
          final sprite = sprites[i];
          final reason = '${version.name} ${_names[i]}';
          expect(sprite, same(again[i]), reason: reason);
          expect(sprite.version, version);
          expect(sprite.gait, legacy[i].gait);
          expect(sprite.pixelRatio, 3);
          expect(sprite.rowCount, 36);
          expect(sprite.colCount, 48);
          expect(sprite.frames, hasLength(17));
          expect(
            sprite.frames.map((f) => f.join()).toSet().length,
            greaterThanOrEqualTo(10),
            reason: reason,
          );
          for (final frame in sprite.frames) {
            expect(frame, hasLength(36));
            for (final row in frame) {
              expect(row, hasLength(48));
              for (final pixel in row.split('')) {
                expect(
                  pixel == '.' || sprite.palette.containsKey(pixel),
                  isTrue,
                  reason: '$reason has unpainted color $pixel',
                );
              }
            }
          }
          // Loop boundary should be another small step, not a reset pose.
          int delta(List<String> a, List<String> b) {
            int count = 0;
            for (int r = 0; r < a.length; r++) {
              for (int c = 0; c < a[r].length; c++) {
                if (a[r][c] != b[r][c]) count++;
              }
            }
            return count;
          }

          final changes = [
            for (int f = 1; f < 16; f++)
              delta(sprite.frames[f], sprite.frames[f + 1]),
          ];
          final largest = changes.reduce((a, b) => a > b ? a : b);
          expect(
            delta(sprite.frames.last, sprite.frames[1]),
            lessThanOrEqualTo(largest + 24),
            reason: reason,
          );
          final before = sprite.samplePose(
            (1 - 1e-7) / sprite.walkCyclesPerSecond,
          );
          final after = sprite.samplePose(
            (1 + 1e-7) / sprite.walkCyclesPerSecond,
          );
          expect(before.bob, closeTo(after.bob, 1e-5));
          expect(before.sway, closeTo(after.sway, 1e-5));
          expect(before.lean, closeTo(after.lean, 1e-5));
        }
      }
      for (final sprite in legacy) {
        expect(sprite.version, PixelSpriteVersion.v1);
        expect(sprite.pixelRatio, 1);
        expect(sprite.frames, hasLength(7));
      }
      final v2 = _sprites(PixelSpriteVersion.v2);
      final v3 = _sprites(PixelSpriteVersion.v3);
      for (int i = 0; i < v2.length; i++) {
        expect(v2[i].frames.first, isNot(equals(v3[i].frames.first)));
      }
    },
  );

  test('custom colors do not mutate cached edition palettes', () {
    for (final version in PixelSpriteVersion.values.skip(1)) {
      final original = PixelSprite.duck(version: version);
      final before = Map<String, Color>.of(original.palette);
      final custom = PixelSprite.duck(
        version: version,
        body: Colors.blue,
        beak: Colors.green,
        eye: Colors.red,
      );
      expect(custom.frames, same(original.frames));
      expect(custom.palette['X'], Colors.blue);
      expect(
        custom.palette[version == PixelSpriteVersion.v2 ? 'A' : 'D'],
        Colors.green,
      );
      expect(custom.palette['E'], Colors.red);
      expect(original.palette, before);
      // An explicit original V1 color is still a custom color in V2/V3.
      expect(
        PixelSprite.duck(
          version: version,
          body: const Color(0xFFF2DE96),
        ).palette['X'],
        const Color(0xFFF2DE96),
      );
    }
  });

  testWidgets(
    'new art fits compact headers with grounded feet and no idle ticker',
    (tester) async {
      const size = Size(120, 110);
      for (final version in PixelSpriteVersion.values.skip(1)) {
        for (final sprite in _sprites(version)) {
          await tester.pumpWidget(
            _host(
              PixelWalker(
                sprite: sprite,
                skylineColor: Colors.transparent,
                windowColor: Colors.transparent,
                starColor: Colors.transparent,
              ),
              size,
            ),
          );
          final pixels = (await tester.runAsync(
            () => _raster(_painter(tester), size),
          ))!;
          int minX = 120, maxX = -1, minY = 110, maxY = -1;
          for (int y = 0; y < 110; y++) {
            for (int x = 0; x < 120; x++) {
              if (pixels[(y * 120 + x) * 4 + 3] == 0) continue;
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
            }
          }
          expect(minX, greaterThan(0));
          expect(maxX, lessThan(119));
          expect(minY, greaterThanOrEqualTo(35));
          expect(maxY, inInclusiveRange(103, 107));
          expect(maxY - minY, greaterThan(38));
          expect(tester.binding.transientCallbackCount, 0);
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'render edition portraits, gait strips and compact headers for review',
    (tester) async {
      final output = Platform.environment['PIXEL_EDITION_REVIEW'];
      if (output == null) return;
      await tester.runAsync(() async {
        await Directory(output).create(recursive: true);
        final font = File('C:/Windows/Fonts/arial.ttf');
        if (font.existsSync()) {
          await (FontLoader('Review')..addFont(
                Future.value(ByteData.sublistView(await font.readAsBytes())),
              ))
              .load();
        }
      });

      void label(
        Canvas canvas,
        String text,
        double x,
        double y, {
        double size = 16,
        Color color = const Color(0xFFC5CBD8),
      }) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: 'Review',
              fontSize: size,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, Offset(x, y));
        painter.dispose();
      }

      Future<void> paintWalker(
        Canvas canvas,
        PixelWalker walker,
        double x,
        double y,
        Size size, {
        double zoom = 1,
      }) async {
        await tester.pumpWidget(_host(walker, size));
        canvas.save();
        canvas.translate(x, y);
        canvas.scale(zoom);
        canvas.clipRect(Offset.zero & size);
        _painter(tester).paint(canvas, size);
        canvas.restore();
      }

      Future<void> save(
        ui.PictureRecorder recorder,
        int width,
        int height,
        String name,
      ) async {
        final picture = recorder.endRecording();
        await tester.runAsync(() async {
          final image = await picture.toImage(width, height);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$output/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        picture.dispose();
      }

      final portraits = ui.PictureRecorder();
      final canvas = Canvas(portraits)
        ..drawColor(const Color(0xFF15151E), BlendMode.src);
      label(
        canvas,
        'SNIPZ / PIXEL COMPANIONS',
        24,
        18,
        size: 24,
        color: const Color(0xFFFFE7C7),
      );
      label(
        canvas,
        'Original + two new families / actual Flutter rendering, enlarged 2x',
        24,
        51,
      );
      for (final version in PixelSpriteVersion.values) {
        final y = 93.0 + version.index * 240;
        label(
          canvas,
          switch (version) {
            PixelSpriteVersion.v1 => 'V1 / ORIGINAL',
            PixelSpriteVersion.v2 => 'V2 / MOCHI BUDDIES',
            PixelSpriteVersion.v3 => 'V3 / POCKET PALS',
          },
          24,
          y,
          size: 20,
          color: const Color(0xFFFFC98F),
        );
        final sprites = _sprites(version);
        for (int i = 0; i < sprites.length; i++) {
          final x = i * 240.0;
          label(canvas, _names[i], x + 24, y + 36, size: 15);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 10, y + 62, 222, 167),
              const Radius.circular(12),
            ),
            Paint()..color = const Color(0xFF20222D),
          );
          await paintWalker(
            canvas,
            PixelWalker(
              sprite: sprites[i],
              skylineColor: Colors.transparent,
              starColor: Colors.transparent,
              windowColor: Colors.transparent,
            ),
            x + 1,
            y + 61,
            const Size(120, 84),
            zoom: 2,
          );
        }
      }
      await save(portraits, 1440, 824, 'mascot-editions');

      final strips = ui.PictureRecorder();
      final stripCanvas = Canvas(strips)
        ..drawColor(const Color(0xFF161923), BlendMode.src);
      int row = 0;
      for (final version in PixelSpriteVersion.values.skip(1)) {
        final sprites = _sprites(version);
        for (int i = 0; i < sprites.length; i++) {
          final sprite = sprites[i];
          final y = row * 122.0;
          label(
            stripCanvas,
            '${version.name.toUpperCase()} ${_names[i]} / one walk cycle',
            12,
            y + 4,
          );
          for (int f = 0; f < 8; f++) {
            await paintWalker(
              stripCanvas,
              PixelWalker(
                sprite: sprite,
                walking: true,
                frozenAt: (f / 8 + .02) / sprite.walkCyclesPerSecond,
                skylineColor: Colors.transparent,
              ),
              f * 150.0,
              y + 20,
              const Size(150, 100),
            );
          }
          row++;
        }
      }
      await save(strips, 1200, 1464, 'walk-cycles');

      final headers = ui.PictureRecorder();
      final headerCanvas = Canvas(headers)
        ..drawColor(const Color(0xFF0F1320), BlendMode.src);
      row = 0;
      for (final version in PixelSpriteVersion.values.skip(1)) {
        for (final scene in PixelWalkerScene.values) {
          final y = row * 150.0;
          label(
            headerCanvas,
            '${version.name.toUpperCase()} / ${scene.name} / 110px refresh header',
            12,
            y + 8,
          );
          final sprites = _sprites(version);
          for (int i = 0; i < sprites.length; i++) {
            await paintWalker(
              headerCanvas,
              PixelWalker(
                sprite: sprites[i],
                scene: scene,
                walking: true,
                frozenAt: .23,
                backgroundColor: const Color(0xFF0F1320),
                skylineColor: const Color(0xFF7484A0),
              ),
              i * 200.0,
              y + 35,
              const Size(196, 110),
            );
          }
          row++;
        }
      }
      await save(headers, 1200, 600, 'refresh-headers');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
