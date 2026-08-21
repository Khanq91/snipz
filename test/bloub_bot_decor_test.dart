// Decor-state tests for bloub_bot: rings, particles, pastille, the "!"
// glyphs and the comet — all still pure engine sampling, nothing pumped.

import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/bloub_bot/bloub_bot.dart';

void main() {
  test('orbit renders six rings split into front and back runs', () {
    final BotFrame frame =
        BloubBotEngine(initial: BloubBotState.orbit).sample(1.2);
    expect(frame.arcs.length, 6);
    for (final BotArcRender arc in frame.arcs) {
      // a ~72% sweep of a tilted ellipse crosses the screen plane: both
      // halves exist, and the depth split is what sells the orbit
      expect(arc.front, isNotEmpty);
      expect(arc.back, isNotEmpty);
      expect(arc.gradArgb.length, 3);
    }
  });

  test('swirl borrows three rings and cleans up before the block ends', () {
    final BotFrame mid =
        BloubBotEngine(initial: BloubBotState.swirl).sample(0.5);
    expect(mid.arcs.length, 3);
    final BotFrame end =
        BloubBotEngine(initial: BloubBotState.swirl).sample(1.28);
    expect(end.arcs, isEmpty, reason: 'faded before the return to rest');
  });

  test('burst collapses the body and spirals particles behind it', () {
    final BotFrame frame =
        BloubBotEngine(initial: BloubBotState.burst).sample(0.45);
    expect(frame.dotsBehind, isTrue);
    expect(frame.dots, isNotEmpty);
    for (final BotDot dot in frame.dots) {
      expect(dot.depth, isNotNull, reason: 'particles carry depth mist');
    }
    // collapsed core: every silhouette point well inside the resting radius
    for (final BotPoint p in frame.body) {
      expect(p.x.abs(), lessThan(60));
      expect(p.y.abs(), lessThan(60));
    }
  });

  test('notify pops the pastille on the outline with its notch', () {
    final BotFrame frame =
        BloubBotEngine(initial: BloubBotState.notify).sample(0.9);
    expect(frame.notif, isNotNull);
    expect(frame.notch, isNotNull);
    expect(frame.notch!.r, greaterThan(frame.notif!.r));
    // pastille sits on the circumference, upper right (angle −42°)
    expect(frame.notif!.x, greaterThan(0));
    expect(frame.notif!.y, lessThan(0));
  });

  test('alert draws the tilted bar with a teardrop dot', () {
    final BotFrame frame =
        BloubBotEngine(initial: BloubBotState.alert).sample(0.75);
    expect(frame.eyes, isEmpty);
    expect(frame.dots.length, 1);
    expect(frame.dots.first.shape, isNotNull, reason: 'a teardrop, not a disc');
  });

  test('comet keeps the dot in place while ribbons orbit it', () {
    final BotFrame frame =
        BloubBotEngine(initial: BloubBotState.comet).sample(1.15);
    expect(frame.arcs.length, 4);
    // the core has collapsed to the measured comet dot (r 0.129 -> ~13 units)
    for (final BotPoint p in frame.body) {
      expect(p.x.abs(), lessThan(20));
    }
    // ribbons faded out by 1.95 s
    final BotFrame late =
        BloubBotEngine(initial: BloubBotState.comet).sample(2.1);
    expect(late.arcs, isEmpty);
  });

  test('every catalog state still exports a still SVG', () {
    for (final BloubBotState state in botSequence) {
      final String svg = bloubBotSvg(state: state);
      expect(svg, endsWith('</svg>'));
    }
    // orbit's SVG carries the ring gradients
    expect(bloubBotSvg(state: BloubBotState.orbit),
        contains('<linearGradient id="g-rg0"'));
  });
}
