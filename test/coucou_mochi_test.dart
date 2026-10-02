import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/coucou_mochi/coucou_mochi.dart';
import 'package:snipz/components/coucou_mochi/coucou_mochi_demo.dart';

Future<void> advance(WidgetTester tester, double seconds) async {
  for (var left = seconds; left > 1e-9; left -= .01) {
    await tester.pump(
      Duration(microseconds: (math.min(.01, left) * 1e6).round()),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every sound resolves through the configured audio cache to a WAV',
    () async {
      final audio = CoucouMochiAudio();
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      expect(coucouMochiSoundNames, hasLength(28));
      for (final name in coucouMochiSoundNames) {
        final path =
            '${audio.assetCache.prefix}${CoucouMochiAudio.assetPrefix}$name.wav';
        expect(manifest.listAssets(), contains(path));
        final bytes = await audio.assetCache.loadAsset(path);
        expect(ascii.decode(bytes.buffer.asUint8List(0, 4)), 'RIFF');
        expect(ascii.decode(bytes.buffer.asUint8List(8, 4)), 'WAVE');
      }
      await audio.dispose();
    },
  );

  test(
    'direct dizzy entry rolls twice; triple taps recover after 3.3 seconds',
    () {
      final e = CoucouMochiEngine()..setState(CoucouMochiState.dizzy, 0);
      expect(e.sample(.65).roll, closeTo(math.pi * 2, 1e-9));
      expect(e.sample(.65).yaw.abs(), greaterThan(0));
      expect(e.sample(1.31).roll, 0);
      final tap = CoucouMochiEngine();
      expect(tap.tap(1), false);
      expect(tap.tap(1.2), false);
      expect(tap.tap(1.4), true);
      expect(tap.sample(4.69).state, CoucouMochiState.dizzy);
      expect(tap.sample(4.71).state, CoucouMochiState.idle);
      expect(tap.sample(4.71).eye, CoucouMochiEye.happy);
      expect(tap.tap(2), false); // Ignore further hits during recovery.
    },
  );

  test('gulp stretches the body, changes eyes and closes continuously', () {
    final e = CoucouMochiEngine()
      ..setMorph(1, 0)
      ..gulp(2);
    expect(e.sample(2.08).scaleY, closeTo(.78, 1e-9));
    expect(e.sample(2.08).scaleX, closeTo(1.28, 1e-9));
    expect(e.sample(2.08).eye, CoucouMochiEye.cup);
    final before = e.sample(2.45999), after = e.sample(2.46001);
    expect(after.slotOpen, closeTo(before.slotOpen, .001));
    expect(after.slotOpen, greaterThan(.4));
    expect(after.eye, CoucouMochiEye.happy);
    expect(after.chewing, true);
    expect(e.sample(3.3).chewing, false);
    expect(e.sample(4).slotOpen, closeTo(0, .00001));
  });

  test('yawn uses the original stretch and closes its eyes at 700ms', () {
    final e = CoucouMochiEngine()..triggerEmote('yawn', 0);
    expect(e.sample(.5).scaleY, closeTo(1.12, 1e-9));
    expect(e.sample(.5).scaleX, closeTo(.94, 1e-9));
    expect(e.sample(.69).eye, CoucouMochiEye.tired);
    expect(e.sample(.71).eye, CoucouMochiEye.closed);
    expect(e.sample(1).scaleY, 1);
  });

  test(
    'emote anticipation, holds, fades and annoyed duration match upstream',
    () {
      final surprise = CoucouMochiEngine()..triggerEmote('surprised', 0);
      expect(surprise.sample(0).offsetY, 0);
      expect(surprise.sample(.14).offsetY, closeTo(-.3, 1e-9));
      final love = CoucouMochiEngine()..triggerEmote('love', 0);
      expect(love.sample(.16).offsetY, closeTo(-.1, 1e-9));
      expect(love.sample(1.5).blush, 1);
      expect(love.sample(1.79).blush, lessThan(.001));
      final proud = CoucouMochiEngine()..triggerEmote('proud', 0);
      expect(proud.sample(0).tilt, 0);
      expect(proud.sample(1).tilt, closeTo(-.14, 1e-9));
      expect(proud.sample(1).blush, closeTo(.7, 1e-9));
      // The upstream blush tween finishes 50ms after the eye override.
      expect(proud.sample(1.8).blush, greaterThan(0));
      expect(
        proud.sample(1.80001).blush,
        closeTo(proud.sample(1.79999).blush, .001),
      );
      expect(proud.sample(1.85).blush, 0);
      final wink = CoucouMochiEngine()..triggerEmote('wink', 0);
      expect(wink.sample(0).tilt, 0);
      expect(wink.sample(1).tilt, closeTo(.12, 1e-9));
      final happy = CoucouMochiEngine()..triggerEmote('happy', 0);
      expect(happy.sample(0).blush, 0);
      expect(happy.sample(.2).blush, closeTo(.6, 1e-9));
      expect(happy.sample(.3).particles, isEmpty);
      final annoyed = CoucouMochiEngine()..triggerEmote('annoyed', 0);
      expect(annoyed.sample(.79).eye, CoucouMochiEye.line);
      expect(annoyed.sample(.81).eye, CoucouMochiEye.pill);
    },
  );

  test(
    'particles start after the event, stagger forwards and recur in ratelimit',
    () {
      final e = CoucouMochiEngine()..triggerEmote('love', 2);
      expect(e.sample(1.99).particles, isEmpty);
      expect(e.sample(2).particles, isEmpty);
      expect(e.sample(2.01).particles, hasLength(1));
      expect(e.sample(2.15).particles, hasLength(2));
      expect(e.sample(2.43).particles, hasLength(4));
      final finished = CoucouMochiEngine()
        ..setState(CoucouMochiState.finished, 0);
      expect(finished.sample(.49).particles, isEmpty);
      expect(finished.sample(.51).particles, hasLength(1));
      final rate = CoucouMochiEngine()..setState(CoucouMochiState.ratelimit, 0);
      expect([
        for (double t = 3; t < 15; t += .25) ...rate.sample(t).particles,
      ], isNotEmpty);
    },
  );

  test('greeting returns from its hop, stretches and can be interrupted', () {
    final e = CoucouMochiEngine()..greet(0);
    expect(e.sample(.22).offsetY, closeTo(-.06, 1e-9));
    expect(e.sample(.44).offsetY, closeTo(0, 1e-9));
    expect(e.sample(.35).scaleY, closeTo(.95, 1e-9));
    e.tap(.6);
    expect(e.sample(.7).eye, CoucouMochiEye.line);
    expect(e.sample(.76).hands, 0);
  });

  test(
    'approval entrance, badge exit and interrupted colors remain continuous',
    () {
      final e = CoucouMochiEngine()..setState(CoucouMochiState.approval, 0);
      expect(e.sample(.15).offsetY, closeTo(-.2, 1e-9));
      expect(e.sample(.5).badge, CoucouMochiBadge.bang);
      e.setState(CoucouMochiState.idle, 1);
      expect(e.sample(1.04).badge, CoucouMochiBadge.bang);
      expect(e.sample(1.04).badgeScale, inExclusiveRange(0, 1));
      expect(e.sample(1.11).badge, isNull);
      e.setState(CoucouMochiState.working, 2);
      final color = e.sample(2.05).bodyColor;
      e.setState(CoucouMochiState.error, 2.05);
      expect(e.sample(2.05).bodyColor, color);
    },
  );

  test('seeded blinks and particles are stable when scrubbed backwards', () {
    final e = CoucouMochiEngine()..triggerEmote('love', 0);
    final first = e.sample(.4);
    e.sample(120);
    e.sample(.1);
    final again = e.sample(.4);
    expect(again.eyeOpen, first.eyeOpen);
    expect(
      again.particles.map((p) => (p.x, p.y, p.alpha)),
      first.particles.map((p) => (p.x, p.y, p.alpha)),
    );
    final blinks = <double>[];
    bool closing = false;
    for (double t = 0; t < 60; t += .01) {
      final now = e.sample(t).eyeOpen < .9;
      if (now && !closing) blinks.add(t);
      closing = now;
    }
    expect(
      [
        for (int i = 1; i < blinks.length; i++) blinks[i] - blinks[i - 1],
      ].any((gap) => gap < .4),
      true,
    );
  });

  test('mini gaze wanders and permanent emotes have periodic motions', () {
    final e = CoucouMochiEngine(isMini: true)..setPermanentEmote('happy', 0);
    expect(e.sample(1).yaw, isNot(e.sample(3).yaw));
    expect(
      [
        for (double t = 0; t < 5; t += .1) e.sample(t).offsetY,
      ].any((y) => y < -.1),
      true,
    );
    expect(e.sample(4).eye, CoucouMochiEye.happy);
    final love = CoucouMochiEngine(isMini: true)..setPermanentEmote('love', 0);
    expect([
      for (double t = 0; t < 8; t += .2) ...love.sample(t).particles,
    ], isNotEmpty);
  });

  final reference =
      jsonDecode(
            File('test/fixtures/coucou_mochi_upstream.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  test('launch poses match 12 frames executed from the upstream TS engine', () {
    final e = CoucouMochiGreetingEngine();
    for (final raw in reference['greeting'] as List<dynamic>) {
      final row = raw as Map<String, dynamic>,
          expected = row['frame'] as Map<String, dynamic>;
      final t = (row['time'] as num).toDouble(),
          p = e.sample((row['time'] as num).toDouble(), collapseAt: 4.9);
      final values = {
        'hb': p.hb,
        'x': p.x,
        'y': p.y,
        'sx': p.sx,
        'sy': p.sy,
        'tilt': p.tilt,
        'open': p.open,
        'eyeRoll': p.eyeRoll,
        'lookX': p.lookX,
        'lookY': p.lookY,
        'handL': p.handL,
        'handR': p.handR,
        'wave': p.wave,
        'badge': p.badge,
        'tint': p.tint,
        'halo': p.halo,
        'haloBlue': p.haloBlue,
        'minis': p.minis,
        'fx': p.fx,
        'card': p.card,
        'iw': p.islandWidth,
        'ih': p.islandHeight,
      };
      for (final entry in values.entries) {
        expect(
          entry.value,
          closeTo(expected[entry.key] as num, 1e-9),
          reason: '${entry.key} at $t',
        );
      }
      expect(p.eye, expected['eye']);
    }
  });

  test(
    'upload spring and phase output match 13 upstream TS reference frames',
    () {
      final e = CoucouMochiUploadEngine()
        ..enter(0, 220, 78)
        ..move(.2, 180, 88)
        ..drop(.8);
      for (final raw in reference['upload'] as List<dynamic>) {
        final row = raw as Map<String, dynamic>,
            expected = row['frame'] as Map<String, dynamic>;
        final t = (row['time'] as num).toDouble(),
            f = e.sample((row['time'] as num).toDouble());
        final values = {
          't': f.t,
          'x': f.x,
          'y': f.y,
          'd': f.d,
          'sx': f.sx,
          'sy': f.sy,
          'morph': f.morph,
          'mouth': f.mouth,
          'tilt': f.tilt,
          'lookX': f.lookX,
          'lookY': f.lookY,
          'suck': f.suck,
          'progress': f.progress,
          'zoneAlpha': f.zoneAlpha,
          'barReveal': f.barReveal,
          'barAlpha': f.barAlpha,
          'flash': f.flash,
          'check': f.check,
          'greenWash': f.greenWash,
          'chooseAlpha': f.chooseAlpha,
        };
        for (final entry in values.entries) {
          expect(
            entry.value,
            closeTo(expected[entry.key] as num, .002),
            reason: '${entry.key} at $t',
          );
        }
        expect(f.eye, expected['eye'], reason: 'eyes at $t');
        expect(f.fileVisible, expected['fileVisible']);
      }
      final at = e.sample(1.05);
      e.sample(6);
      expect(e.sample(1.05).mouth, at.mouth);
    },
  );

  test(
    'holding a dragged file never starts upload; release starts its own clock',
    () {
      final e = CoucouMochiUploadEngine()
        ..enter(0, 220, 78)
        ..move(5, 480, 90);
      expect(e.sample(15).fileVisible, true);
      expect(e.sample(15).progress, 0);
      expect(e.sample(15).x, closeTo(480, .01));
      e.drop(16);
      expect(e.sample(16.1).suck, greaterThan(0));
      expect(e.sample(16.5).fileVisible, false);
      expect(e.sample(21).progress, 1);
    },
  );

  testWidgets(
    'hover plays entry and love cues, resets on movement and observes cooldown',
    (tester) async {
      final sounds = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: CoucouMochi(soundEnabled: false, onSound: sounds.add),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      final center = tester.getCenter(find.byType(CoucouMochi));
      await mouse.moveTo(center);
      await tester.pump();
      expect(sounds, ['hover']);
      await advance(tester, 1.5);
      await mouse.moveTo(center + const Offset(45, 0));
      await advance(tester, .5);
      expect(sounds, ['hover']);
      await advance(tester, 1.41);
      expect(sounds, ['hover', 'love']);
      await mouse.moveTo(Offset.zero);
      await mouse.moveTo(center);
      await advance(tester, 2);
      expect(sounds, ['hover', 'love']);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'greet sound is synchronized, cancelled by tap and paused with animation',
    (tester) async {
      final controller = CoucouMochiController(), sounds = <String>[];
      Widget host({bool animate = true}) => MaterialApp(
        home: Center(
          child: CoucouMochi(
            controller: controller,
            animate: animate,
            soundEnabled: false,
            onSound: sounds.add,
          ),
        ),
      );
      await tester.pumpWidget(host());
      controller.greet();
      await advance(tester, .24);
      expect(sounds, isEmpty);
      await advance(tester, .02);
      expect(sounds, ['greet']);
      sounds.clear();
      controller.greet();
      await tester.tap(find.byType(CoucouMochi));
      await advance(tester, .4);
      expect(sounds, ['slap', 'annoyed']);
      sounds.clear();
      controller.greet();
      await tester.pumpWidget(host(animate: false));
      await advance(tester, 1);
      expect(sounds, isEmpty);
      await tester.pumpWidget(host());
      await advance(tester, .3);
      expect(sounds, ['greet']);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'frozen greetings remain silent; scenes emit one cue per milestone',
    (tester) async {
      final sounds = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CoucouMochi(
            greetingOnStart: true,
            frozenAt: 1,
            soundEnabled: false,
            onSound: sounds.add,
          ),
        ),
      );
      await advance(tester, 1);
      expect(sounds, isEmpty);
      await tester.pumpWidget(
        MaterialApp(
          home: CoucouMochiScene(
            type: CoucouMochiSceneType.launch,
            soundEnabled: false,
            onSound: sounds.add,
          ),
        ),
      );
      await advance(tester, 2.8);
      expect(sounds, ['greet', 'blip']);
      await advance(tester, 3);
      expect(sounds, ['greet', 'blip']);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'all gallery variants render and survive animation at phone sizes',
    (tester) async {
      for (final variant in coucouMochiDemo.variants) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 320,
                height: 420,
                child: Builder(builder: variant.builder),
              ),
            ),
          ),
        );
        await advance(tester, 6);
        expect(tester.takeException(), isNull, reason: variant.id);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'upload scene plays drop, nine progress ticks and completion only once',
    (tester) async {
      final sounds = <String>[];
      int completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CoucouMochiScene(
            type: CoucouMochiSceneType.upload,
            soundEnabled: false,
            onSound: sounds.add,
            onComplete: () => completed++,
          ),
        ),
      );
      await advance(tester, 6);
      expect(sounds, ['approve', ...List.filled(9, 'tick'), 'approve']);
      expect(completed, 1);
      await advance(tester, 1);
      expect(completed, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'ticker mode pauses cue time instead of catching up when shown again',
    (tester) async {
      final controller = CoucouMochiController(), sounds = <String>[];
      Widget host(bool enabled) => MaterialApp(
        home: TickerMode(
          enabled: enabled,
          child: CoucouMochi(
            controller: controller,
            soundEnabled: false,
            onSound: sounds.add,
          ),
        ),
      );
      await tester.pumpWidget(host(true));
      controller.greet();
      await advance(tester, .1);
      await tester.pumpWidget(host(false));
      await advance(tester, 2);
      expect(sounds, isEmpty);
      await tester.pumpWidget(host(true));
      await advance(tester, .1);
      expect(sounds, isEmpty);
      await advance(tester, .1);
      expect(sounds, ['greet']);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'showcase can return from scenes and minis to an emote without layout errors',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 500,
                child: Builder(builder: coucouMochiDemo.builder),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Mute sounds'));
      await tester.pump();
      for (final label in [
        'Launch greeting',
        'File upload: drag or tap to replay',
        'Mini companions',
        'Love',
        'Gulp',
      ]) {
        await tester.tap(find.byTooltip(label));
        await advance(tester, .6);
        expect(tester.takeException(), isNull, reason: label);
      }
      expect(find.byType(CoucouMochi), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('render review atlas when explicitly requested', () async {
    final output = Platform.environment['MOCHI_REVIEW_OUTPUT'];
    if (output == null) return;
    final font = Platform.environment['MOCHI_REVIEW_FONT'];
    if (font != null) {
      final loader = FontLoader('Ahem')
        ..addFont(
          Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
        );
      await loader.load();
    }
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawColor(const Color(0xFF080A10), BlendMode.src);
    for (int i = 0; i < CoucouMochiState.values.length; i++) {
      c.save();
      c.translate((i % 6) * 200.0, (i ~/ 6) * 240.0);
      final e = CoucouMochiEngine()..setState(CoucouMochiState.values[i], 0);
      CoucouMochiPainter(
        frame: e.sample(
          CoucouMochiState.values[i] == CoucouMochiState.dizzy ? .05 : 1.5,
        ),
      ).paint(c, const Size(200, 240));
      c.restore();
    }
    for (int i = 0; i < 3; i++) {
      c.save();
      c.translate(i * 400.0, 500);
      CoucouMochiGreetingPainter(
        time: [.65, 1.9, 5.1][i],
        collapseAt: 4.9,
      ).paint(c, const Size(400, 93.75));
      c.restore();
      c.save();
      c.translate(i * 400.0, 650);
      final e = CoucouMochiUploadEngine()
        ..enter(0, 220, 78)
        ..move(.2, 180, 88)
        ..drop(.8);
      CoucouMochiUploadPainter(
        frame: e.sample([1.05, 2.7, 5.2][i]),
      ).paint(c, const Size(400, 110));
      c.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1200, 800);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(output).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
