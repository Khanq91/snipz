// Engine tests for bloub_bot — ported from the upstream engine.test.ts
// invariants. The engine layer has no Flutter imports, so nothing is pumped:
// these are plain unit tests over sample(t).

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/bloub_bot/bloub_bot.dart';

/// Largest distance between corresponding silhouette points of two frames.
double _bodyDelta(BotFrame a, BotFrame b) {
  double worst = 0;
  for (int i = 0; i < a.body.length; i++) {
    final double dx = a.body[i].x - b.body[i].x;
    final double dy = a.body[i].y - b.body[i].y;
    worst = math.max(worst, math.sqrt(dx * dx + dy * dy));
  }
  return worst;
}

void _expectSameFrame(BotFrame a, BotFrame b) {
  expect(_bodyDelta(a, b), 0);
  expect(a.eyes.length, b.eyes.length);
  for (int i = 0; i < a.eyes.length; i++) {
    expect(a.eyes[i].tx, b.eyes[i].tx);
    expect(a.eyes[i].ty, b.eyes[i].ty);
    expect(a.eyes[i].alpha, b.eyes[i].alpha);
  }
  expect(a.dots.length, b.dots.length);
}

void main() {
  test('sample(t) is a pure function of time', () {
    final engine = BloubBotEngine();
    engine.setState(BloubBotState.wide, 1.0);
    final BotFrame first = engine.sample(1.2);
    // Reading other dates in between must not change what 1.2 renders —
    // the innocent-looking cleanup that breaks replayability.
    engine.sample(3.0);
    engine.sample(0.5);
    final BotFrame again = engine.sample(1.2);
    _expectSameFrame(first, again);
  });

  test('two engines given the same script render the same frames', () {
    BotFrame run(double at) {
      final engine = BloubBotEngine();
      engine.setState(BloubBotState.thinking, 0.8);
      engine.setState(BloubBotState.egg, 2.0);
      return engine.sample(at);
    }

    _expectSameFrame(run(2.3), run(2.3));
    _expectSameFrame(run(1.1), run(1.1));
  });

  test('a state change landing mid-fade stays continuous', () {
    final engine = BloubBotEngine();
    // idle -> wide at t=1, then back to idle at t=1.1 — inside wide's 0.55 s
    // morph. Upstream measured a 35.9 px jump here before the composite pose
    // was frozen; continuity now holds by construction.
    engine.setState(BloubBotState.wide, 1.0);
    engine.setState(BloubBotState.idle, 1.1);
    final BotFrame before = engine.sample(1.1);
    final BotFrame after = engine.sample(1.101);
    expect(_bodyDelta(before, after), lessThan(1.5));
  });

  test('reading a date before the state change does not explode', () {
    final engine = BloubBotEngine();
    engine.setState(BloubBotState.wide, 2.0);
    // Negative fade ratio would be extrapolated by the ease-out without the
    // clamp; the silhouette must stay near the unit ball (radius 100 + drift).
    final BotFrame frame = engine.sample(1.5);
    for (final BotPoint p in frame.body) {
      expect(math.sqrt(p.x * p.x + p.y * p.y), lessThan(160));
    }
  });

  test('frozen poses are deterministic across engines', () {
    for (final BloubBotState state in botSequence) {
      final BotFrame a = BloubBotEngine(initial: state)
          .sample(botStatePoses[state]!);
      final BotFrame b = BloubBotEngine(initial: state)
          .sample(botStatePoses[state]!);
      _expectSameFrame(a, b);
    }
  });

  test('the blink calendar closes the eyes around 1.4 s', () {
    // First scheduled blink starts at 1.4 and lasts 0.18 s.
    expect(botLiveliness(1.48).lid, lessThan(0.25));
    expect(botLiveliness(1.0).lid, 1);
  });

  test('faceless states render no eyes; faced states render two', () {
    final sleeping = BloubBotEngine(initial: BloubBotState.sleep).sample(1);
    expect(sleeping.eyes, isEmpty);
    final idle = BloubBotEngine().sample(1);
    expect(idle.eyes.length, 2);
    // Both eyes face the viewer at rest, at full opacity.
    for (final BotRenderedEye eye in idle.eyes) {
      expect(eye.alpha, 1);
    }
  });

  test('thinking replaces the face with dots', () {
    final frame =
        BloubBotEngine(initial: BloubBotState.thinking).sample(1.1);
    expect(frame.eyes, isEmpty);
    expect(frame.dots.length, 2); // side dots; the ball IS the middle dot
  });
}
