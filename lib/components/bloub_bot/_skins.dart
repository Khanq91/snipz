// Part of bloub_bot — the customizer's shapes and colors. Mirrors the
// upstream src/bot/skins.ts (jeremy-prt/bloub, MIT). Pure Dart.
//
// Unlike the animation silhouettes (_profiles.dart), these are NOT measured
// on the video: they are built analytically from the original customizer's
// grid. Two distinct sources, deliberately — animated states must stay
// faithful to the video, base shapes are a user's choice.

import 'dart:math' as math;

import '_math.dart';
import '_profiles.dart';
import '_shape.dart';

class BotShape {
  const BotShape({required this.id, required this.radii});

  final String id;
  final List<double> radii;
}

class BotColor {
  const BotColor({required this.id, required this.argb});

  final String id;
  final int argb;
}

/* --------------------------------------------------- profile constructors */

final List<double> _angles = List.unmodifiable(List.generate(
    kBotProfileSamples, (i) => i / kBotProfileSamples * botTau));

/// Brings the peak radius to [max] so all shapes weigh the same to the eye.
List<double> _normalize(List<double> radii, [double max = 1]) {
  final double peak = radii.reduce(math.max);
  if (peak <= 0) return radii;
  final double k = max / peak;
  return [for (final double r in radii) r * k];
}

/// Superellipse |x|^n + |y|^n = 1: n = 4.2 is the customizer's squircle.
List<double> _superellipse(double n) => [
      for (final double a in _angles)
        math.pow(
                math.pow(math.cos(a).abs(), n) +
                    math.pow(math.sin(a).abs(), n),
                -1 / n)
            .toDouble(),
    ];

/// Union of discs: r(theta) = the farthest ray/circle intersection. Exact as
/// long as the origin is inside the union — the cloud's bumps without path
/// booleans.
List<double> _unionOfCircles(List<({double x, double y, double r})> circles) {
  final List<double> out = List.filled(kBotProfileSamples, 0);
  for (int i = 0; i < kBotProfileSamples; i++) {
    final double dx = math.cos(_angles[i]);
    final double dy = math.sin(_angles[i]);
    double best = 0;
    for (final c in circles) {
      final double b = dx * c.x + dy * c.y;
      final double disc = b * b - (c.x * c.x + c.y * c.y - c.r * c.r);
      if (disc < 0) continue;
      final double t = b + math.sqrt(disc);
      if (t > best) best = t;
    }
    out[i] = best;
  }
  return out;
}

/// Rounded polygon via Minkowski sum with a disc: vertices sit at the target
/// radius MINUS the corner radius, each becoming an arc. Clockwise polygon
/// (screen space, y down).
List<BotPoint> _roundedPolygon(List<BotPoint> verts, double rc,
    [int arcSteps = 10]) {
  final int n = verts.length;
  final List<BotPoint> out = [];
  double normalAngle(BotPoint a, BotPoint b) {
    final double dx = b.x - a.x;
    final double dy = b.y - a.y;
    final double len = math.max(math.sqrt(dx * dx + dy * dy), 1e-9);
    return math.atan2(-dx / len, dy / len);
  }

  for (int i = 0; i < n; i++) {
    final BotPoint prev = verts[(i - 1 + n) % n];
    final BotPoint cur = verts[i];
    final BotPoint next = verts[(i + 1) % n];
    final double a0 = normalAngle(prev, cur);
    final double a1 = normalAngle(cur, next);
    double d = a1 - a0;
    while (d > math.pi) {
      d -= botTau;
    }
    while (d < -math.pi) {
      d += botTau;
    }
    for (int k = 0; k <= arcSteps; k++) {
      final double a = a0 + d * k / arcSteps;
      out.add((x: cur.x + math.cos(a) * rc, y: cur.y + math.sin(a) * rc));
    }
  }
  return out;
}

List<double> _regularPolygon(
    int sides, double radius, double rc, double rotationDeg) {
  final double rot = rotationDeg * math.pi / 180;
  final List<BotPoint> verts = List.generate(sides, (i) {
    final double a = rot + i / sides * botTau;
    return (x: math.cos(a) * (radius - rc), y: math.sin(a) * (radius - rc));
  });
  return botProfileFromPolygon(_roundedPolygon(verts, rc), 0, 0);
}

/* ---------------------------------------------------------------- shapes */

/// Pebble: a circle deformed by two low harmonics — irregular but smooth.
final List<double> _pebble = _normalize(
    [
      for (final double a in _angles)
        1 + 0.075 * math.cos(2 * a + 0.5) + 0.035 * math.cos(3 * a + 2.1),
    ],
    1.02);

/// Cloud: union of bumps, wide at the bottom, two lobes on top.
final List<double> _cloud = _normalize(
    _unionOfCircles(const [
      (x: -0.44, y: 0.2, r: 0.54),
      (x: 0.46, y: 0.2, r: 0.5),
      (x: 0.02, y: 0.3, r: 0.6),
      (x: -0.24, y: -0.3, r: 0.48),
      (x: 0.3, y: -0.24, r: 0.44),
    ]),
    1.02);

/// Droplet: big disc at the bottom, tapered point on top.
final List<double> _droplet = _normalize(
    botProfileFromPolygon(botHullOfCircles(0, 0.28, 0.66, 0, -0.96, 0.05), 0, 0),
    1.04);

/// Lying capsule: hull of two side-by-side discs.
final List<double> _capsule =
    botProfileFromPolygon(botHullOfCircles(-0.42, 0, 0.62, 0.42, 0, 0.62), 0, 0);

final List<BotShape> kBotShapes = List.unmodifiable([
  BotShape(id: 'cercle', radii: List.filled(kBotProfileSamples, 1)),
  BotShape(id: 'galet', radii: _pebble),
  // 1.15 and not 1.02: on a superellipse the max radius is the diagonal, so
  // normalizing on it yields a shape that looks smaller than the circle.
  BotShape(id: 'squircle', radii: _normalize(_superellipse(4.2), 1.15)),
  BotShape(id: 'capsule', radii: _capsule),
  // -90°: one vertex toward the top of the screen (y points down)
  BotShape(id: 'triangle', radii: _regularPolygon(3, 1.12, 0.34, -90)),
  // 0°: vertices left and right, hence flat top and bottom edges
  BotShape(id: 'hexagone', radii: _regularPolygon(6, 1.04, 0.26, 0)),
  BotShape(id: 'nuage', radii: _cloud),
  BotShape(id: 'goutte', radii: _droplet),
]);

/// Indexed by plain string: callers query with values re-read from prefs or
/// props, hence unvalidated.
final Map<String, BotShape> botShapeById = Map.unmodifiable({
  for (final BotShape s in kBotShapes) s.id: s,
});

const String kBotDefaultShape = 'cercle';

/* ---------------------------------------------------------------- colors */

/// The original customizer's palette.
const List<BotColor> kBotColors = [
  BotColor(id: 'encre', argb: 0xFF0A0A0C),
  BotColor(id: 'brun', argb: 0xFF8B5E3C),
  BotColor(id: 'rouge', argb: 0xFFE8483F),
  BotColor(id: 'orange', argb: 0xFFF08A24),
  BotColor(id: 'ambre', argb: 0xFFF0B429),
  BotColor(id: 'vert', argb: 0xFF3ECF8E),
  BotColor(id: 'turquoise', argb: 0xFF2FBFA0),
  BotColor(id: 'bleu', argb: 0xFF3B93F0),
  BotColor(id: 'violet', argb: 0xFF8B5CF6),
  BotColor(id: 'rose', argb: 0xFFE152B0),
  BotColor(id: 'gris', argb: 0xFFA3A3A3),
  BotColor(id: 'creme', argb: 0xFFF1EFE9),
];

final Map<String, BotColor> botColorById = Map.unmodifiable({
  for (final BotColor c in kBotColors) c.id: c,
});

const String kBotDefaultColor = 'encre';
