// Engine + widget tests for jelly_blob, following the bloub_bot invariants:
// sample(t) must be a pure function of time (replayable), mood changes must
// stay continuous, and frozen frames must be deterministic.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/jelly_blob/jelly_blob.dart';

/// The frame object is reused by the engine — snapshot what we compare.
List<double> _snap(JellyFrame f) => [
      f.body.start.dx, f.body.start.dy,
      for (final p in f.body.pts) ...[p.dx, p.dy],
      f.bodyX, f.bodyY, f.bodyRot, f.bodySx, f.bodySy, f.bodySkewX,
      f.faceX, f.faceY, f.faceSx, f.faceSy,
      f.armLY, f.armLRot, f.armRY, f.armRRot,
      f.armLFidgetRot, f.armRFidgetRot,
      f.blinkL, f.blinkR,
      f.eyeSx, f.eyeSy, f.eyeLOffX, f.eyeROffX,
      f.cheekOp, f.normalEyeOp, f.starOp, f.arcOp,
      f.pwOp, f.sideOp, f.hmmOp, f.sadBrowOp,
      ...f.mouthPts, f.mouthW, f.mouthOp,
      f.talkOp, f.fxOp, f.tearOp, f.angryX, f.decorOp,
      f.sh1Rx, f.sh1Op, f.sh2Rx, f.sh2Op,
      f.attX, f.attY, f.eyesGazeX, f.eyesGazeY,
      f.nodY, f.boopSx, f.boopSy, f.shakeRot,
    ];

double _delta(List<double> a, List<double> b) {
  double worst = 0;
  for (int i = 0; i < a.length; i++) {
    worst = math.max(worst, (a[i] - b[i]).abs());
  }
  return worst;
}

void main() {
  test('sample(t) is a pure function of time', () {
    final JellyBlobEngine engine = JellyBlobEngine();
    engine.setMood(JellyBlobMood.happy, 1.0);
    final List<double> first = _snap(engine.sample(1.2));
    // Reading other dates in between must not change what 1.2 renders.
    engine.sample(3.0);
    engine.sample(0.5);
    final List<double> again = _snap(engine.sample(1.2));
    expect(_delta(first, again), 0);
  });

  test('two engines given the same script render the same frames', () {
    List<double> run(double at) {
      final JellyBlobEngine engine = JellyBlobEngine();
      engine.setMood(JellyBlobMood.sad, 0.8);
      engine.setMood(JellyBlobMood.angry, 2.0);
      return _snap(engine.sample(at));
    }

    expect(_delta(run(2.3), run(2.3)), 0);
    expect(_delta(run(1.1), run(1.1)), 0);
  });

  test('a mood change landing mid-morph stays continuous', () {
    final JellyBlobEngine engine = JellyBlobEngine();
    // neutral -> sad at 1.0, then to happy at 1.15 — inside sad's ~0.42 s
    // melt. The rebase snapshots the on-screen pose, so no jump.
    engine.setMood(JellyBlobMood.sad, 1.0);
    engine.setMood(JellyBlobMood.happy, 1.15);
    final List<double> before = _snap(engine.sample(1.15));
    final List<double> after = _snap(engine.sample(1.16));
    expect(_delta(before, after), lessThan(3.0));
  });

  test('frozen poses are finite and opacities stay in range', () {
    for (final JellyBlobMood m in JellyBlobMood.values) {
      final JellyBlobEngine engine = JellyBlobEngine(mood: m);
      final JellyFrame f = engine.sample(jellyMoodPoses[m]!);
      for (final double v in _snap(f)) {
        expect(v.isFinite, isTrue, reason: 'non-finite value in $m');
      }
      for (final double op in [
        f.mouthOp, f.normalEyeOp, f.pwOp, f.sideOp, f.hmmOp,
        f.fxOp, f.decorOp, f.cheekOp, f.glossOp, f.sh1Op, f.sh2Op,
      ]) {
        expect(op, inInclusiveRange(0, 1), reason: 'opacity in $m');
      }
    }
  });

  test('idle slosh moves the feet but never the rigid top', () {
    final JellyBlobEngine engine = JellyBlobEngine();
    final JellyFrame a = engine.sample(0);
    // pts[14] is the right "foot" lobe (602, 583) — full wave weight there,
    // while the centre is deliberately damped to read as two feet
    final Offset footA = a.body.pts[14];
    final JellyFrame b = engine.sample(1.7);
    expect(b.body.start, const Offset(450, 135)); // top edge is rigid
    expect((b.body.pts[14] - footA).distance, greaterThan(0.5));
  });

  test('talking override swaps the mood mouth for the talk mouth', () {
    final JellyBlobEngine engine = JellyBlobEngine();
    engine.setTalk(JellyTalkMouth.open, 1.0);
    final JellyFrame f = engine.sample(2.0);
    expect(f.mouthOp, 0);
    expect(f.talkOp, 1);
    engine.setTalk(null, 3.0);
    final JellyFrame g = engine.sample(4.5);
    expect(g.mouthOp, 1);
    expect(g.talkOp, 0);
  });

  test('blinks are seed-deterministic and vary across seeds', () {
    double lids(int seed, double t) {
      final JellyBlobEngine e = JellyBlobEngine(seed: seed);
      final JellyFrame f = e.sample(t);
      return f.blinkL + f.blinkR * 1000;
    }

    bool differs = false;
    for (double t = 0; t < 30; t += .25) {
      expect(lids(1, t), lids(1, t));
      if ((lids(1, t) - lids(2, t)).abs() > 1e-9) differs = true;
    }
    expect(differs, isTrue, reason: 'seeds 1 and 2 blink identically');
  });

  test('boop squashes then fully recovers', () {
    final JellyBlobEngine engine = JellyBlobEngine();
    engine.boop(1.0);
    final JellyFrame mid = engine.sample(1.1);
    expect(mid.boopSy, lessThan(1));
    expect(mid.boopSx, greaterThan(1));
    final JellyFrame done = engine.sample(1.6);
    expect(done.boopSx, 1);
    expect(done.boopSy, 1);
  });

  testWidgets('mascot renders frozen and live without exceptions',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: JellyBlobMascot(
          size: 200,
          mood: JellyBlobMood.happy,
          frozenAt: jellyMoodPoses[JellyBlobMood.happy],
        ),
      ),
    ));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: JellyBlobMascot(size: 200, mood: JellyBlobMood.neutral),
      ),
    ));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // poke it — squash, no crash
    await tester.tap(find.byType(JellyBlobMascot), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('speech cloud renders and swaps its line', (tester) async {
    Widget cloud(JellyBlobMood mood) => MaterialApp(
          home: Center(child: JellyBlobSpeech(mood: mood)),
        );
    await tester.pumpWidget(cloud(JellyBlobMood.neutral));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Going somewhere?'), findsOneWidget);
    await tester.pumpWidget(cloud(JellyBlobMood.angry));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });
}
