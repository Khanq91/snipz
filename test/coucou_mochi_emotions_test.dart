import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/coucou_mochi/coucou_mochi.dart';
import 'package:snipz/components/coucou_mochi/coucou_mochi_demo.dart';

const emotions = {
  'suspicious': 2.4,
  'confused': 2.8,
  'chill': 6.0,
  'music': 4.0,
  'shy': 3.0,
};

List<Object?> signature(CoucouMochiFrame f) => [
  f.time,
  f.state.name,
  f.bodyColor,
  f.eye.name,
  f.eyeOpen,
  f.eyeScale,
  f.yaw,
  f.pitch,
  f.tilt,
  f.scaleX,
  f.scaleY,
  f.offsetX,
  f.offsetY,
  f.blush,
  f.leftEyeHeight,
  f.rightEyeHeight,
  f.badge?.name,
  f.badgeScale,
  f.eyeWeights?.map((key, value) => MapEntry(key.name, value)),
  [
    for (final p in f.particles)
      [p.type.name, p.x, p.y, p.alpha, p.rotation, p.size],
  ],
];

void samePose(CoucouMochiFrame a, CoucouMochiFrame b, {double epsilon = 1e-6}) {
  final av = [
    a.yaw,
    a.pitch,
    a.tilt,
    a.scaleX,
    a.scaleY,
    a.offsetX,
    a.offsetY,
    a.blush,
    a.eyeOpen,
    a.eyeScale,
    a.leftEyeHeight,
    a.rightEyeHeight,
  ];
  final bv = [
    b.yaw,
    b.pitch,
    b.tilt,
    b.scaleX,
    b.scaleY,
    b.offsetX,
    b.offsetY,
    b.blush,
    b.eyeOpen,
    b.eyeScale,
    b.leftEyeHeight,
    b.rightEyeHeight,
  ];
  for (int i = 0; i < av.length; i++) {
    expect(av[i], closeTo(bv[i], epsilon), reason: 'pose field $i');
  }
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
  // Inspect the existing repaint signal without adding a production test API.
  // ignore: avoid_dynamic_calls
  return painter.frames.value as CoucouMochiFrame;
}

Future<void> advance(WidgetTester tester, double seconds) async {
  for (double left = seconds; left > 1e-9; left -= .02) {
    await tester.pump(
      Duration(microseconds: (math.min(.02, left) * 1e6).round()),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P1 side-eye and confused have distinct gaze, lids and double blink',
    () {
      final side = CoucouMochiEngine()..triggerEmote('suspicious', 0);
      final f = side.sample(.6);
      expect(f.yaw, closeTo(.36, 1e-9));
      expect(f.leftEyeHeight, lessThan(f.rightEyeHeight));
      expect(f.tilt, closeTo(-.075, 1e-9));
      expect(f.bodyColor, CoucouMochiEngine().sample(.6).bodyColor);
      expect(f.particles, isEmpty);
      final confused = CoucouMochiEngine(initial: CoucouMochiState.question)
        ..triggerEmote('confused', 0);
      expect(confused.sample(.9).tilt, closeTo(-.19, 1e-9));
      expect(confused.sample(1.6).tilt, closeTo(-.10, 1e-9));
      for (final t in [1.05, 1.34]) {
        expect(confused.sample(t).eyeOpen, closeTo(.06, 1e-8));
      }
      expect(confused.sample(1.21).eyeOpen, closeTo(1, 1e-8));
      final q = confused.sample(.9);
      expect(q.badge, CoucouMochiBadge.question);
      expect(
        q.particles.where((p) => p.type == CoucouMochiParticleType.question),
        hasLength(1),
      );
      expect(q.particles.single.x, greaterThan(.5));
      expect(q.leftEyeHeight, greaterThan(q.rightEyeHeight));
      expect(confused.sample(2.2).particles, isEmpty);
    },
  );

  test(
    'P2 chill breathes upright; P3 shy avoids gaze with continuous blush',
    () {
      final chill = CoucouMochiEngine()..triggerEmote('chill', 0, loop: true);
      expect(chill.sample(.8).scaleY, closeTo(1.025, 1e-9));
      expect(chill.sample(2.4).scaleY, closeTo(.975, 1e-9));
      expect(chill.sample(2.4).pitch, 0);
      expect(chill.sample(2.4).leftEyeHeight, closeTo(.46, 1e-9));
      expect(chill.sample(2.4).particles, isEmpty);
      final shy = CoucouMochiEngine()..triggerEmote('shy', 0);
      expect(shy.sample(0).blush, 0);
      expect(shy.sample(.225).blush, closeTo(.5, 1e-9));
      expect(shy.sample(.45).blush, 1);
      expect(shy.sample(.45).yaw, 0);
      expect(shy.sample(.8).yaw, closeTo(-.27, 1e-9));
      expect(shy.sample(.8).pitch, lessThan(0));
      expect(shy.sample(2.7).blush, closeTo(.5, 1e-9));
      expect(shy.sample(3).blush, 0);
      expect(shy.sample(1).eye, CoucouMochiEye.pill);
      expect(shy.sample(1).particles, isEmpty);
    },
  );

  test(
    'every finite emote starts at displayed pose and returns to live state',
    () {
      for (final entry in emotions.entries) {
        for (final state in [
          CoucouMochiState.idle,
          CoucouMochiState.thinking,
          CoucouMochiState.searching,
          CoucouMochiState.sleeping,
        ]) {
          final e = CoucouMochiEngine(initial: state)..setLook(.7, .2, 0);
          final base = CoucouMochiEngine(initial: state)..setLook(.7, .2, 0);
          final before = e.sample(10);
          e.triggerEmote(entry.key, 10);
          samePose(e.sample(10), before);
          expect(e.sample(11).bodyColor, base.sample(11).bodyColor);
          expect(e.sample(11).badge, base.sample(11).badge);
          expect(e.isEmoting(10 + entry.value - .001), isTrue);
          expect(e.isEmoting(10 + entry.value), isFalse);
          samePose(
            e.sample(10 + entry.value + .01),
            base.sample(10 + entry.value + .01),
          );
          samePose(
            e.sample(10 + entry.value - .00001),
            e.sample(10 + entry.value + .00001),
            epsilon: .002,
          );
        }
      }
    },
  );

  test('replacement, stop and state change preserve the displayed pose', () {
    for (final next in [...emotions.keys, 'love']) {
      final e = CoucouMochiEngine(initial: CoucouMochiState.working)
        ..triggerEmote('music', 0, loop: true);
      final before = e.sample(1.4);
      e.triggerEmote(next, 1.4);
      samePose(e.sample(1.4), before);
      final stopped = e.sample(1.6);
      e.stopEmote(1.6);
      samePose(e.sample(1.6), stopped);
      samePose(
        e.sample(2.3),
        CoucouMochiEngine(initial: CoucouMochiState.working).sample(2.3),
      );
    }
    final e = CoucouMochiEngine()..triggerEmote('chill', 0, loop: true);
    final before = e.sample(2);
    e.setState(CoucouMochiState.thinking, 2);
    samePose(e.sample(2), before);
    expect(e.isEmoting(2.1), isFalse);
    expect(e.sample(3).state, CoucouMochiState.thinking);
    expect(e.sample(3).yaw, greaterThan(.25));
  });

  test('greeting, gulp and dizzy preempt emotes; direct input ends loops', () {
    for (final name in ['chill', 'music']) {
      final e = CoucouMochiEngine()..triggerEmote(name, 0, loop: true);
      e.greet(1);
      expect(e.isEmoting(1.1), isFalse);
      expect(e.triggerEmote('shy', 1.2), isFalse);
      expect(e.sample(1.8).hands, greaterThan(0));
      expect(e.triggerEmote(name, 3.1, loop: true), isTrue);
      e.gulp(4);
      expect(e.isEmoting(4.1), isFalse);
      expect(e.triggerEmote('confused', 4.2), isFalse);
      e.triggerEmote(name, 6, loop: true);
      e.tap(7);
      e.tap(7.1);
      expect(e.tap(7.2), isTrue);
      expect(e.triggerEmote('shy', 7.3), isFalse);
      expect(e.sample(7.4).eye, CoucouMochiEye.spiral);
      expect(e.isEmoting(11), isFalse);
      e.triggerEmote(name, 12, loop: true);
      e.setLook(.8, .8, 13);
      expect(e.isEmoting(13.1), isFalse);
      e.triggerEmote(name, 14, loop: true);
      e.setHover(true, 15);
      expect(e.isEmoting(15.1), isFalse);
    }
    final e = CoucouMochiEngine()..triggerEmote('suspicious', 0);
    e.setLook(-1, -1, .4);
    expect(e.sample(.8).yaw, closeTo(.36, 1e-9));
  });

  test(
    '60 second loops are bounded, continuous, FPS independent and scrubbable',
    () {
      for (final name in ['chill', 'music']) {
        for (final mini in [false, true]) {
          final e = CoucouMochiEngine(isMini: mini)
            ..triggerEmote(name, 0, loop: true, bpm: 137);
          final fresh = CoucouMochiEngine(isMini: mini)
            ..triggerEmote(name, 0, loop: true, bpm: 137);
          final watch = Stopwatch()..start();
          for (int n = 0; n <= 3600; n++) {
            final f = e.sample(n / 60);
            expect(f.particles.length, lessThanOrEqualTo(4));
            expect(
              f.particles.every((p) => p.type == CoucouMochiParticleType.note),
              isTrue,
            );
          }
          watch.stop();
          final later = Stopwatch()..start();
          for (int n = 0; n <= 3600; n++) {
            e.sample(3600 + n / 60);
          }
          later.stop();
          // Timing is diagnostic, not a flaky device-performance assertion.
          debugPrint(
            '$name mini=$mini: 60s sample=${watch.elapsedMilliseconds}ms, '
            'hour-later sample=${later.elapsedMilliseconds}ms',
          );
          for (final t in [60.0, .7, 4.0, 6.0, 2.9, 59.95]) {
            expect(signature(e.sample(t)), signature(fresh.sample(t)));
          }
          for (final t in [4.0, 6.0, 60.0]) {
            samePose(
              e.sample(t - .000001),
              e.sample(t + .000001),
              epsilon: .0001,
            );
          }
          expect(e.isEmoting(3600), isTrue);
          e.stopEmote(60);
          expect(e.isEmoting(61), isFalse);
        }
      }
      final a = CoucouMochiEngine()
        ..triggerEmote('music', 0, loop: true, bpm: 100);
      final b = CoucouMochiEngine()
        ..triggerEmote('music', 0, loop: true, bpm: 200);
      expect(a.sample(1.5).scaleY, closeTo(b.sample(.75).scaleY, 1e-9));
    },
  );

  test(
    'invalid loop, BPM and duration inputs fail without corrupting pose',
    () {
      final e = CoucouMochiEngine()..triggerEmote('chill', 0, loop: true);
      final before = signature(e.sample(1));
      expect(() => e.triggerEmote('shy', 1, loop: true), throwsArgumentError);
      for (final bpm in [double.nan, double.infinity, 0.0, 241.0]) {
        expect(() => e.triggerEmote('music', 1, bpm: bpm), throwsArgumentError);
      }
      expect(() => e.triggerEmote('shy', 1, duration: -1), throwsArgumentError);
      expect(signature(e.sample(1)), before);
    },
  );

  test(
    'bounded blink cache preserves the original sequence after a long scrub',
    () {
      final e = CoucouMochiEngine();
      final snapshots = [
        for (int n = 0; n < 500; n++) signature(e.sample(n / 10)),
      ];
      e.sample(7200);
      for (int n = 499; n >= 0; n--) {
        expect(signature(e.sample(n / 10)), snapshots[n]);
      }
    },
  );

  testWidgets(
    'clock pauses music across TickerMode, animate and frozen scrub',
    (tester) async {
      final controller = CoucouMochiController();
      final sounds = <String>[];
      Widget host({bool enabled = true, bool animate = true, double? frozen}) =>
          MaterialApp(
            home: Center(
              child: TickerMode(
                enabled: enabled,
                child: CoucouMochi(
                  controller: controller,
                  initialEmote: CoucouMochiEmote.music,
                  emoteLoop: true,
                  musicBpm: 137,
                  soundEnabled: false,
                  animate: animate,
                  frozenAt: frozen,
                  onSound: sounds.add,
                ),
              ),
            ),
          );
      await tester.pumpWidget(host());
      await advance(tester, 1.4);
      final before = signature(displayed(tester));
      await tester.pumpWidget(host(enabled: false));
      await advance(tester, 5);
      expect(signature(displayed(tester)), before);
      await tester.pumpWidget(host());
      await tester.pump();
      expect(signature(displayed(tester)), before);
      await advance(tester, .2);
      final beforeFreeze = signature(displayed(tester));
      await tester.pumpWidget(host(animate: false));
      await advance(tester, 3);
      expect(signature(displayed(tester)), beforeFreeze);
      await tester.pumpWidget(host(frozen: .8));
      final frozen = signature(displayed(tester));
      await tester.pumpWidget(host(frozen: 9));
      await tester.pumpWidget(host(frozen: .8));
      expect(signature(displayed(tester)), frozen);
      await tester.pumpWidget(host());
      await tester.pump();
      expect(signature(displayed(tester)), beforeFreeze);
      expect(sounds, isEmpty);
      controller.stopEmote();
      await advance(tester, .7);
      expect(displayed(tester).leftEyeHeight, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'new emotes are silent; optional question cue fires once and respects mute',
    (tester) async {
      final controller = CoucouMochiController();
      final sounds = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: CoucouMochi(
              controller: controller,
              soundEnabled: false,
              volume: 0,
              onSound: sounds.add,
            ),
          ),
        ),
      );
      for (final emote in CoucouMochiEmote.values.where(
        (e) => emotions.containsKey(e.name),
      )) {
        controller.emote(emote);
        await advance(tester, .4);
      }
      expect(sounds, isEmpty);
      controller.emote(CoucouMochiEmote.confused, questionCue: true);
      await advance(tester, 4);
      expect(sounds, [
        'question',
      ]); // onSound observes requests even while muted.
      controller.greet();
      controller.emote(CoucouMochiEmote.confused, questionCue: true);
      await advance(tester, .5);
      expect(sounds, ['question', 'greet']);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('demo exposes five previews and music-only BPM at narrow sizes', (
    tester,
  ) async {
    for (final name in emotions.keys) {
      expect(
        coucouMochiDemo.variants.any(
          (v) => v.id == name && v.frozenBuilder != null,
        ),
        isTrue,
      );
    }
    for (final size in [
      const Size(320, 500),
      const Size(280, 420),
      const Size(568, 280),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Builder(builder: coucouMochiDemo.builder),
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.byTooltip('Mute sounds'));
      await tester.tap(find.byTooltip('Mute sounds'));
      await tester.ensureVisible(find.text('music'));
      await tester.tap(find.text('music'));
      await tester.pump();
      expect(find.text('100 BPM'), findsOneWidget);
      expect(find.text('Loop'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Loop'));
      await tester.tap(find.text('Loop'));
      await tester.pump();
      await tester.ensureVisible(find.text('Stop emote'));
      await tester.tap(find.text('Stop emote'));
      await tester.pump();
      expect(find.text('100 BPM'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  test(
    'render emotions at normal, thumbnail and mini sizes for visual review',
    () async {
      final output = Platform.environment['MOCHI_EMOTIONS_REVIEW'];
      if (output == null) return;
      final loader = FontLoader('Review')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('C:/Windows/Fonts/arial.ttf').readAsBytesSync(),
            ),
          ),
        );
      await loader.load();
      final defaultFont = FontLoader('Ahem')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('C:/Windows/Fonts/arial.ttf').readAsBytesSync(),
            ),
          ),
        );
      await defaultFont.load();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawColor(const Color(0xFF080A10), BlendMode.src);
      int col = 0;
      for (final name in emotions.keys) {
        void label(String text, double y) {
          final tp = TextPainter(
            text: TextSpan(
              text: text,
              style: const TextStyle(
                fontFamily: 'Review',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(col * 240.0 + 12, y));
          tp.dispose();
        }

        label(name, 10);
        for (int row = 0; row < 4; row++) {
          final mini = row == 2;
          final width = row == 0 || row == 3 ? 220.0 : 80.0;
          final e = CoucouMochiEngine(
            isMini: mini,
            initial: row == 3
                ? CoucouMochiState.question
                : CoucouMochiState.idle,
          )..triggerEmote(name, 0);
          canvas.save();
          canvas.translate(
            col * 240.0 + (240 - width) / 2,
            [35.0, 325.0, 465.0, 605.0][row],
          );
          CoucouMochiPainter(
            frame: e.sample(name == 'confused' ? .85 : 1.65),
            isMini: mini,
            bodyColor: mini ? const Color(0xFF3E86E0) : null,
          ).paint(canvas, Size(width, width * 1.28));
          canvas.restore();
        }
        label('220 / 80 / mini / badge', 910);
        col++;
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(1200, 950);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(output).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      await File('$output.json').writeAsString(jsonEncode(emotions));
    },
  );
}
