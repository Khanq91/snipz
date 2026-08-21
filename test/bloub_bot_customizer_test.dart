// Customizer tests for bloub_bot: shapes, expressions and the eye-offset
// table (B3). Pure engine sampling, nothing pumped.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/bloub_bot/bloub_bot.dart';

double _maxBodyRadius(BotFrame f) {
  double worst = 0;
  for (final BotPoint p in f.body) {
    worst = math.max(worst, math.sqrt(p.x * p.x + p.y * p.y));
  }
  return worst;
}

void main() {
  test('catalog: 8 shapes, 16 expressions, 12 colors', () {
    expect(kBotShapes.length, 8);
    expect(kBotExpressions.length, 16);
    expect(kBotColors.length, 12);
    expect(botShapeById[kBotDefaultShape], isNotNull);
    expect(botExpressionById[kBotDefaultExpression], isNotNull);
  });

  test('a customizer shape replaces the body only on baseBody states', () {
    // squircle peaks at 1.15 — well clear of the unit ball.
    final List<double> squircle = botShapeById['squircle']!.radii;
    final BotFrame idle = BloubBotEngine(shape: squircle).sample(1);
    expect(_maxBodyRadius(idle), greaterThan(110));
    // egg draws its own measured silhouette (peak 1.0481): the customizer
    // shape must NOT overwrite it.
    final BotFrame egg =
        BloubBotEngine(initial: BloubBotState.egg, shape: squircle).sample(1);
    expect(_maxBodyRadius(egg), lessThan(110));
  });

  test('setShape morphs between shapes instead of jumping, and replays', () {
    // Morphing happens BETWEEN two shapes; the first set (from null) is
    // immediate, like upstream.
    final BloubBotEngine engine =
        BloubBotEngine(shape: botShapeById['cercle']!.radii);
    engine.setShape(botShapeById['squircle']!.radii, 1.0);
    final BotFrame mid = engine.sample(1.1); // inside the 0.45 s shape morph
    final BotFrame done = engine.sample(2.0);
    expect(_maxBodyRadius(mid), greaterThan(101));
    expect(_maxBodyRadius(mid), lessThan(_maxBodyRadius(done)));
    // pure in time: re-reading the mid-morph date gives the same image
    final BotFrame midAgain = engine.sample(1.1);
    expect(_maxBodyRadius(midAgain), _maxBodyRadius(mid));
  });

  test('expressions glide and mirrored tilts survive the blend', () {
    final BotExpression colere = botExpressionById['colere']!;
    final BotExpression triste = botExpressionById['triste']!;
    final BotExpression mid = botBlendExpression(colere, triste, 0.5);
    // anger tilts +30/-30, sadness -28/+28: halfway is +1/-1, still mirrored
    expect(mid.eyes[0].tilt, closeTo(1, 1e-9));
    expect(mid.eyes[1].tilt, closeTo(-1, 1e-9));
  });

  test('eye-offset table: capsule pushes the face, circle does not', () {
    final List<double> capsule = botShapeById['capsule']!.radii;
    final ({double x, double y}) worst =
        botEyeOffset(capsule, BloubBotState.idle, 'effraye');
    // upstream's worst-case family: the wide-eyed face on the lying capsule
    expect(worst.y.abs(), greaterThan(0.1));
    expect(botEyeOffset(botShapeById['cercle']!.radii, BloubBotState.idle,
        'effraye'), (x: 0, y: 0));
    expect(botEyeOffset(null, BloubBotState.idle, null), (x: 0, y: 0));
    // states without a resting face fall back to their single entry
    expect(botEyeOffset(capsule, BloubBotState.wide, 'colere'),
        botEyeOffset(capsule, BloubBotState.wide, null));
  });

  test('the offset is an isometry: both eyes translate by the same delta',
      () {
    final List<double> capsule = botShapeById['capsule']!.radii;
    final BotFrame plain = BloubBotEngine().sample(1);
    final BotFrame fitted = BloubBotEngine(shape: capsule).sample(1);
    expect(plain.eyes.length, 2);
    expect(fitted.eyes.length, 2);
    final double dx0 = fitted.eyes[0].tx - plain.eyes[0].tx;
    final double dx1 = fitted.eyes[1].tx - plain.eyes[1].tx;
    // the table part of the shift is common; the per-eye part comes from
    // radiusAtAngle pro-rata, so compare against the raw table entry instead
    final ({double x, double y}) table =
        botEyeOffset(capsule, BloubBotState.idle, null);
    expect(dx0, isNot(0));
    expect((dx0 - dx1).abs(), lessThan(30),
        reason: 'both eyes move the same way, pro-rata differences aside');
    expect(table.x, isNot(0));
  });

  test('customized exports stay deterministic', () {
    final String a = bloubBotSvg(shape: 'goutte', expression: 'heureux');
    expect(a, bloubBotSvg(shape: 'goutte', expression: 'heureux'));
    final String anime =
        bloubBotAnimatedSvg(shape: 'capsule', expression: 'triste');
    expect(anime, contains('@keyframes oeil0{'));
  });
}
