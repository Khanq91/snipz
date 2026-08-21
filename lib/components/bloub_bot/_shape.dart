// Part of bloub_bot — silhouettes as radial profiles, mirroring the upstream
// src/bot/shape.ts (jeremy-prt/bloub, MIT). Pure Dart, no Flutter imports.

import 'dart:math' as math;

import '_math.dart';
import '_profiles.dart';

typedef BotPoint = ({double x, double y});

final List<double> _cos = List.unmodifiable(List.generate(
    kBotProfileSamples, (i) => math.cos(i / kBotProfileSamples * botTau)));
final List<double> _sin = List.unmodifiable(List.generate(
    kBotProfileSamples, (i) => math.sin(i / kBotProfileSamples * botTau)));

/// A silhouette = a radial profile r(theta) plus a pose. Everything goes
/// through profiles sampled at the SAME angles, so two arbitrary shapes have
/// one-to-one points and morphing reduces to a lerp of radii — that is what
/// makes transitions clean without a path-morphing library.
class BotSilhouette {
  const BotSilhouette({
    required this.radii,
    this.rot = 0,
    this.cx = 0,
    this.cy = 0,
    this.sx = 1,
    this.sy = 1,
  });

  final List<double> radii;

  /// Profile rotation, radians.
  final double rot;

  /// Center offset, in resting-ball-radius units.
  final double cx;
  final double cy;

  /// Squash & stretch, applied in SCREEN space (after rotation).
  final double sx;
  final double sy;

  BotSilhouette copyWith({
    List<double>? radii,
    double? rot,
    double? cx,
    double? cy,
    double? sx,
    double? sy,
  }) =>
      BotSilhouette(
        radii: radii ?? this.radii,
        rot: rot ?? this.rot,
        cx: cx ?? this.cx,
        cy: cy ?? this.cy,
        sx: sx ?? this.sx,
        sy: sy ?? this.sy,
      );
}

/// Perfect circle: the neutral base (dot, bubble, fade target).
BotSilhouette botCircle(double radius,
        {double rot = 0, double cx = 0, double cy = 0, double sx = 1, double sy = 1}) =>
    BotSilhouette(
        radii: List.filled(kBotProfileSamples, radius),
        rot: rot,
        cx: cx,
        cy: cy,
        sx: sx,
        sy: sy);

/// Interpolation of two silhouettes. Rotation goes the SHORTEST way round:
/// +170° to −170° must not spin the long way.
BotSilhouette botBlendSil(BotSilhouette a, BotSilhouette b, double t) {
  final List<double> radii = List.generate(
      kBotProfileSamples, (i) => botLerp(a.radii[i], b.radii[i], t),
      growable: false);
  double dRot = b.rot - a.rot;
  while (dRot > math.pi) {
    dRot -= botTau;
  }
  while (dRot < -math.pi) {
    dRot += botTau;
  }
  return BotSilhouette(
    radii: radii,
    rot: a.rot + dRot * t,
    cx: botLerp(a.cx, b.cx, t),
    cy: botLerp(a.cy, b.cy, t),
    sx: botLerp(a.sx, b.sx, t),
    sy: botLerp(a.sy, b.sy, t),
  );
}

/// Projects the silhouette to screen points. [scale] = resting ball radius in
/// viewBox units. Order matters and is measured: rotation, then squash in
/// screen space, then translation.
List<BotPoint> botSilPoints(BotSilhouette s, double scale) {
  final double cr = math.cos(s.rot);
  final double sr = math.sin(s.rot);
  return List.generate(kBotProfileSamples, (i) {
    final double r = s.radii[i];
    final double x = r * _cos[i];
    final double y = r * _sin[i];
    final double rx = x * cr - y * sr;
    final double ry = x * sr + y * cr;
    return (x: (rx * s.sx + s.cx) * scale, y: (ry * s.sy + s.cy) * scale);
  }, growable: false);
}

/// Profile radius in an arbitrary direction, interpolating between the two
/// neighbouring samples. Anything sitting "on" the body (eyes, notification
/// pastille) is re-anchored with this when the silhouette is not a circle —
/// without it an eye placed at 0.62 radius leaves a shape whose edge is at
/// 0.55 in that direction, and the mask crops it.
double botRadiusAtAngle(List<double> radii, double angle) {
  final int n = radii.length;
  final double t = (((angle / botTau) % 1) + 1) % 1 * n;
  final int i = t.floor();
  return botLerp(radii[i % n], radii[(i + 1) % n], t - i);
}

/// Arbitrary closed polygon -> radial profile, by ray casting from (cx, cy).
/// Serves the shapes that are not natural r(theta) (the "!" bar). Computed
/// once at load, never in the render loop.
List<double> botProfileFromPolygon(List<BotPoint> poly, double cx, double cy) {
  final List<double> radii = List.filled(kBotProfileSamples, 0);
  final int n = poly.length;
  for (int k = 0; k < kBotProfileSamples; k++) {
    final double dx = _cos[k];
    final double dy = _sin[k];
    double best = 0;
    for (int i = 0; i < n; i++) {
      final BotPoint a = poly[i];
      final BotPoint b = poly[(i + 1) % n];
      final double ex = b.x - a.x;
      final double ey = b.y - a.y;
      final double den = dx * ey - dy * ex;
      if (den.abs() < 1e-9) continue;
      final double px = a.x - cx;
      final double py = a.y - cy;
      final double t = (px * ey - py * ex) / den; // distance along the ray
      final double u = (px * dy - py * dx) / den; // position on the edge
      if (t > best && u >= 0 && u <= 1) best = t;
    }
    radii[k] = best;
  }
  return radii;
}

/// Convex hull of two circles: the truncated-cone bar of the upright "!".
List<BotPoint> botHullOfCircles(
    double x1, double y1, double r1, double x2, double y2, double r2,
    [int steps = 96]) {
  final double dx = x2 - x1;
  final double dy = y2 - y1;
  final double dist = math.max(math.sqrt(dx * dx + dy * dy), 1e-6);
  // angle of the outer common tangents
  final double base = math.atan2(dy, dx);
  final double spread = math.acos(botClamp((r1 - r2) / dist, -1, 1));
  final List<BotPoint> pts = [];
  final int half = steps ~/ 2;
  // arc of the big circle
  for (int i = 0; i <= half; i++) {
    final double a = base + spread + (botTau - 2 * spread) * i / half;
    pts.add((x: x1 + math.cos(a) * r1, y: y1 + math.sin(a) * r1));
  }
  // arc of the small circle
  for (int i = 0; i <= half; i++) {
    final double a = base - spread + 2 * spread * i / half;
    pts.add((x: x2 + math.cos(a) * r2, y: y2 + math.sin(a) * r2));
  }
  return pts;
}
