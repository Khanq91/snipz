import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/coucou_mochi/coucou_mochi.dart';
import 'package:snipz/components/coucou_mochi/coucou_mochi_demo.dart';

Future<Uint8List> raster(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.ceil(), size.height.ceil());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = Uint8List.fromList(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return result;
}

int differentPixels(Uint8List a, Uint8List b) {
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

CoucouMochiFrame displayed(WidgetTester tester) {
  final dynamic painter = tester
      .widget<CustomPaint>(
        find.descendant(
          of: find.byType(CoucouMochi),
          matching: find.byType(CustomPaint),
        ),
      )
      .painter;
  // Inspect the existing repaint signal without exposing a production test API.
  // ignore: avoid_dynamic_calls
  return painter.frames.value as CoucouMochiFrame;
}

Future<void> advance(WidgetTester tester, double seconds) async {
  for (int i = 0; i < (seconds * 50).ceil(); i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

CoucouMochiUploadEngine upload() => CoucouMochiUploadEngine()
  ..enter(0, 220, 78)
  ..move(.2, 180, 88)
  ..drop(.8);

class _Accessories extends CustomPainter {
  const _Accessories(this.time, this.joy);
  final double time, joy;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    CoucouMochiSkinPainter(
      skin: CoucouMochiSkin.nekoPudding,
      pose: CoucouMochiSkinPose(
        time: time,
        eyeWeights: {'happy': joy, 'pill': 1 - joy},
      ),
    ).paintBehind(canvas, 40, 45, 35);
  }

  @override
  bool shouldRepaint(_Accessories oldDelegate) =>
      time != oldDelegate.time || joy != oldDelegate.joy;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'late emotion transitions cannot whip the tail through a new phase',
    () async {
      for (final time in [0.0, 60.0, 3600.0, 7200.0]) {
        final a = await raster(_Accessories(time, .5), const Size(180, 150));
        final b = await raster(_Accessories(time, .501), const Size(180, 150));
        double changedChannels = 0;
        for (int i = 0; i < a.length; i++) {
          changedChannels += (a[i] - b[i]).abs() / 255;
        }
        // A tiny expression change should remain subpixel even hours later.
        expect(changedChannels, lessThan(20), reason: 'elapsed $time seconds');
      }
    },
  );

  test(
    'skins stay visually distinct and deterministic in normal, mini and mailbox',
    () async {
      for (final mini in [false, true]) {
        for (final morph in [0.0, .5, 1.0]) {
          final engine = CoucouMochiEngine(isMini: mini)..setMorph(morph, 0);
          final frame = engine.sample(1.3);
          final images = <Uint8List>[];
          for (final skin in CoucouMochiSkin.values) {
            final painter = CoucouMochiPainter(
              frame: frame,
              skin: skin,
              isMini: mini,
              bodyColor: const Color(0xFF3E86E0),
            );
            const size = Size(160, 205);
            final pixels = await raster(painter, size);
            expect(await raster(painter, size), orderedEquals(pixels));
            images.add(pixels);
          }
          for (int i = 0; i < images.length; i++) {
            for (int j = i + 1; j < images.length; j++) {
              expect(
                differentPixels(images[i], images[j]),
                greaterThan(500),
                reason: 'skin $i/$j mini=$mini morph=$morph',
              );
            }
          }
        }
      }
    },
  );

  test(
    'launch and upload retain each skin throughout their choreography',
    () async {
      final engine = upload();
      for (final time in [.55, 1.05, 1.9, 4.6]) {
        final launch = <Uint8List>[];
        final files = <Uint8List>[];
        for (final skin in CoucouMochiSkin.values) {
          launch.add(
            await raster(
              CoucouMochiGreetingPainter(time: time, skin: skin),
              const Size(640, 150),
            ),
          );
          files.add(
            await raster(
              CoucouMochiUploadPainter(frame: engine.sample(time), skin: skin),
              const Size(640, 176),
            ),
          );
        }
        for (int i = 1; i < launch.length; i++) {
          expect(
            differentPixels(launch[0], launch[i]),
            greaterThan(20),
            reason: 'launch skin=$i time=$time',
          );
          expect(
            differentPixels(files[0], files[i]),
            greaterThan(20),
            reason: 'upload skin=$i time=$time',
          );
        }
      }
    },
  );

  testWidgets('new skins preserve tap, love, dizzy, gulp and frozen clock', (
    tester,
  ) async {
    for (final skin in CoucouMochiSkin.values.skip(1)) {
      final controller = CoucouMochiController();
      int dizzy = 0;
      Widget host({bool enabled = true}) => MaterialApp(
        home: Center(
          child: TickerMode(
            enabled: enabled,
            child: CoucouMochi(
              key: ValueKey(skin),
              skin: skin,
              controller: controller,
              soundEnabled: false,
              onDizzy: () => dizzy++,
            ),
          ),
        ),
      );
      await tester.pumpWidget(host());
      await tester.longPress(find.byType(CoucouMochi));
      await advance(tester, .4);
      expect(displayed(tester).blush, greaterThan(0));
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(CoucouMochi));
        await advance(tester, .1);
      }
      expect(dizzy, 1);
      expect(displayed(tester).state, CoucouMochiState.dizzy);
      await advance(tester, 3.5);
      controller.gulp();
      await advance(tester, .8);
      expect(displayed(tester).morph, greaterThan(.9));
      expect(displayed(tester).slotOpen, greaterThan(0));
      final time = displayed(tester).time;
      await tester.pumpWidget(host(enabled: false));
      await advance(tester, 2);
      expect(displayed(tester).time, time);
      await tester.pumpWidget(host());
      await tester.pump();
      expect(displayed(tester).time, time);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });

  testWidgets(
    'dropdown reloads character and scene without replaying old commands',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Builder(builder: coucouMochiDemo.builder)),
        ),
      );
      await tester.ensureVisible(find.byTooltip('Mute sounds'));
      await tester.tap(find.byTooltip('Mute sounds'));
      await tester.pump();
      await tester.ensureVisible(find.byTooltip('Gulp'));
      await tester.tap(find.byTooltip('Gulp'));
      await advance(tester, 1);
      expect(displayed(tester).morph, greaterThan(.9));
      for (final skin in [
        CoucouMochiSkin.nekoPudding,
        CoucouMochiSkin.cloud,
        CoucouMochiSkin.original,
      ]) {
        await tester.tap(find.byKey(const ValueKey('mochi-skin-dropdown')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text(skin.label).last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.widget<CoucouMochi>(find.byType(CoucouMochi)).skin, skin);
        expect(displayed(tester).morph, 0);
        expect(displayed(tester).state, CoucouMochiState.idle);
        expect(displayed(tester).time, lessThan(.5));
        expect(find.byTooltip('Enable sounds'), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final scene in CoucouMochiSceneType.values) {
          final tooltip = scene == CoucouMochiSceneType.launch
              ? 'Launch greeting'
              : 'File upload: drag or tap to replay';
          await tester.ensureVisible(find.byTooltip(tooltip));
          await tester.tap(find.byTooltip(tooltip));
          await advance(tester, .2);
          final widget = tester.widget<CoucouMochiScene>(
            find.byType(CoucouMochiScene),
          );
          expect(widget.skin, skin);
          expect(widget.type, scene);
          expect(widget.soundEnabled, isFalse);
        }
        await tester.ensureVisible(find.byTooltip('Mini companions'));
        await tester.tap(find.byTooltip('Mini companions'));
        await tester.pump();
        final minis = tester.widgetList<CoucouMochi>(find.byType(CoucouMochi));
        expect(minis, hasLength(4));
        expect(minis.every((mini) => mini.skin == skin && mini.isMini), isTrue);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('mochi-reload-skin')));
      await tester.pump();
      expect(find.byType(CoucouMochi), findsOneWidget);
      expect(displayed(tester).morph, 0);
      expect(find.byTooltip('Enable sounds'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('render skin/emotion/scene atlas for visual review', () async {
    final output = Platform.environment['MOCHI_SKINS_REVIEW'];
    if (output == null) return;
    final font = File('C:/Windows/Fonts/arial.ttf');
    if (font.existsSync()) {
      for (final name in ['Review', 'Ahem', 'Roboto']) {
        await (FontLoader(name)..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
      }
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawColor(const Color(0xFF080A10), BlendMode.src);
    void label(String text, double x, double y) {
      final p = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'Review',
            fontSize: 16,
            color: Color(0xFFDDE6F4),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, Offset(x, y));
      p.dispose();
    }

    const moods = [
      'idle',
      'love',
      'annoyed',
      'suspicious',
      'confused',
      'chill',
      'music',
      'shy',
    ];
    for (int s = 0; s < CoucouMochiSkin.values.length; s++) {
      final skin = CoucouMochiSkin.values[s];
      final y = s * 500.0;
      label(skin.label, 20, y + 8);
      for (int i = 0; i < moods.length; i++) {
        final e = CoucouMochiEngine();
        if (moods[i] != 'idle') e.triggerEmote(moods[i], 0);
        label(moods[i], i * 160.0 + 12, y + 35);
        canvas.save();
        canvas.translate(i * 160.0, y + 40);
        CoucouMochiPainter(
          frame: e.sample(moods[i] == 'annoyed' ? .4 : 1.1),
          skin: skin,
        ).paint(canvas, const Size(160, 205));
        canvas.restore();
      }
      label('mini / mailbox / greet', 16, y + 245);
      for (int i = 0; i < 3; i++) {
        final e = CoucouMochiEngine(isMini: i == 0);
        if (i == 0) e.triggerEmote('love', 0);
        if (i == 1) e.setMorph(1, 0);
        if (i == 2) e.greet(0);
        canvas.save();
        canvas.translate(12 + i * 100.0, y + 275);
        CoucouMochiPainter(
          frame: e.sample(1),
          skin: skin,
          isMini: i == 0,
          bodyColor: const Color(0xFF8C73F2),
        ).paint(canvas, const Size(100, 128));
        canvas.restore();
      }
      label('launch', 350, y + 245);
      canvas.save();
      canvas.translate(330, y + 280);
      CoucouMochiGreetingPainter(
        time: 1.9,
        skin: skin,
      ).paint(canvas, const Size(460, 108));
      canvas.restore();
      label('upload', 820, y + 245);
      canvas.save();
      canvas.translate(800, y + 280);
      CoucouMochiUploadPainter(
        frame: upload().sample(1.05),
        skin: skin,
      ).paint(canvas, const Size(460, 127));
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1280, 1500);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(output).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
