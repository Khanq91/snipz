/// Shape Morph
/// Origin: adapted — radial-profile morphing core of jeremy-prt/bloub (MIT)
/// Deps: flutter only
/// Flutter: 3.47.1
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Every shape is sampled at the SAME number of angles, so any two shapes
/// have points that correspond one to one and a morph reduces to a linear
/// interpolation of radii — no path-morphing package needed. 64 samples keep
/// the outline pixel-smooth even at ~600 px (measured upstream).
const int radialShapeSamples = 64;

const double _tau = math.pi * 2;

double _clamp(double v, [double lo = 0, double hi = 1]) =>
    v < lo ? lo : (v > hi ? hi : v);

double _lerp(double a, double b, double t) => a + (b - a) * t;

final List<double> _cos = List.unmodifiable(List.generate(
    radialShapeSamples, (i) => math.cos(i / radialShapeSamples * _tau)));
final List<double> _sin = List.unmodifiable(List.generate(
    radialShapeSamples, (i) => math.sin(i / radialShapeSamples * _tau)));

/// One closed shape as a radial profile `r(theta)` plus a pose.
///
/// Radii are in "unit radius" terms: 1.0 is the nominal shape radius, and
/// [toPath] maps that unit to pixels. `rot` rotates the profile;
/// `sx`/`sy` squash & stretch in SCREEN space (applied after rotation, like
/// the upstream engine); `cx`/`cy` shift the center in unit-radius terms.
///
/// Limitation inherent to r(theta): the outline must be visible from the
/// center (star-convex). Anything else goes through [RadialShape.polygon],
/// which ray-casts and keeps the farthest hit — an approximation.
@immutable
class RadialShape {
  RadialShape(List<double> radii,
      {this.rot = 0, this.cx = 0, this.cy = 0, this.sx = 1, this.sy = 1})
      : assert(radii.length == radialShapeSamples,
            'radii must have $radialShapeSamples samples'),
        radii = List.unmodifiable(radii);

  /// Perfect circle of the given unit radius — the neutral base.
  factory RadialShape.circle([double radius = 1]) =>
      RadialShape(List.filled(radialShapeSamples, radius));

  /// Superellipse |x/sx|^n + |y/sy|^n = 1. n = 2 is an ellipse, n ≈ 4 the
  /// classic squircle.
  factory RadialShape.superellipse(double n, {double sx = 1, double sy = 1}) {
    return RadialShape(List.generate(radialShapeSamples, (i) {
      final double c = math.pow((_cos[i] / sx).abs(), n).toDouble();
      final double s = math.pow((_sin[i] / sy).abs(), n).toDouble();
      return math.pow(c + s, -1 / n).toDouble();
    }));
  }

  /// Arbitrary closed polygon -> radial profile, by ray casting from
  /// (cx, cy). Screen coordinates (y down). Compute once, never per frame.
  factory RadialShape.polygon(List<Offset> points,
      {double cx = 0, double cy = 0}) {
    return RadialShape(_profileFromPolygon(points, cx, cy));
  }

  /// Regular polygon with rounded corners, inscribed in [radius]. Corners are
  /// rounded by a Minkowski sum with a disc of [cornerRadius]: vertices sit at
  /// `radius - cornerRadius` and each becomes an arc of that radius.
  factory RadialShape.regularPolygon(int sides,
      {double radius = 1, double cornerRadius = 0.15, double rotationDeg = 0}) {
    final double rot = rotationDeg * math.pi / 180;
    final List<Offset> verts = List.generate(sides, (i) {
      // clockwise on screen: theta grows with y down
      final double a = rot + i / sides * _tau;
      return Offset(math.cos(a) * (radius - cornerRadius),
          math.sin(a) * (radius - cornerRadius));
    });
    return RadialShape(
        _profileFromPolygon(_roundedPolygon(verts, cornerRadius), 0, 0));
  }

  /// Union of discs: r(theta) is the farthest ray/circle intersection. Exact
  /// as long as the origin lies INSIDE the union — this is what gives cloud
  /// bumps without any path booleans.
  factory RadialShape.unionOfCircles(
      List<({double x, double y, double r})> circles) {
    final List<double> out = List.filled(radialShapeSamples, 0);
    for (int i = 0; i < radialShapeSamples; i++) {
      final double dx = _cos[i];
      final double dy = _sin[i];
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
    return RadialShape(out);
  }

  /// Convex hull of two discs — a capsule-like bar with straight flanks
  /// (upstream this is the "!" glyph bar). Center of the profile is the
  /// origin, so keep it inside the hull.
  factory RadialShape.capsuleHull(
      {required Offset a,
      required double ra,
      required Offset b,
      required double rb}) {
    return RadialShape(
        _profileFromPolygon(_hullOfCircles(a.dx, a.dy, ra, b.dx, b.dy, rb), 0, 0));
  }

  final List<double> radii;

  /// Profile rotation, radians.
  final double rot;

  /// Center offset, in unit-radius terms.
  final double cx;
  final double cy;

  /// Squash & stretch, applied in screen space AFTER rotation.
  final double sx;
  final double sy;

  RadialShape copyWith({double? rot, double? cx, double? cy, double? sx, double? sy}) =>
      RadialShape(radii,
          rot: rot ?? this.rot,
          cx: cx ?? this.cx,
          cy: cy ?? this.cy,
          sx: sx ?? this.sx,
          sy: sy ?? this.sy);

  /// Rescales so the largest radius equals [max] — makes shapes weigh the
  /// same to the eye when cycling through them.
  RadialShape normalized([double max = 1]) {
    final double peak = radii.reduce(math.max);
    if (peak <= 0) return this;
    final double k = max / peak;
    return RadialShape([for (final r in radii) r * k],
        rot: rot, cx: cx, cy: cy, sx: sx, sy: sy);
  }

  /// Profile radius in an arbitrary direction (radians, screen space, before
  /// pose). Interpolates between the two neighbouring samples. Useful to
  /// anchor something ON the outline (a badge, a notch).
  double radiusAt(double angle) {
    final double t = (((angle / _tau) % 1) + 1) % 1 * radialShapeSamples;
    final int i = t.floor();
    return _lerp(radii[i % radialShapeSamples],
        radii[(i + 1) % radialShapeSamples], t - i);
  }

  /// Interpolation of two shapes: lerp of radii, rotation along the SHORTEST
  /// arc (going from +170° to −170° must not spin the long way round).
  static RadialShape lerp(RadialShape a, RadialShape b, double t) {
    final List<double> radii = List.generate(radialShapeSamples,
        (i) => _lerp(a.radii[i], b.radii[i], t), growable: false);
    double dRot = b.rot - a.rot;
    while (dRot > math.pi) {
      dRot -= _tau;
    }
    while (dRot < -math.pi) {
      dRot += _tau;
    }
    return RadialShape(radii,
        rot: a.rot + dRot * t,
        cx: _lerp(a.cx, b.cx, t),
        cy: _lerp(a.cy, b.cy, t),
        sx: _lerp(a.sx, b.sx, t),
        sy: _lerp(a.sy, b.sy, t));
  }

  /// Samples a whole keyframe sequence at position [t] in `[0, n-1]`
  /// (`[0, n]` wrapping back to the first shape when [loop] is true). This is
  /// the pure "sample" form; [ShapeMorph] is just a painter over it.
  static RadialShape sequence(List<RadialShape> shapes, double t,
      {bool loop = false}) {
    assert(shapes.isNotEmpty);
    if (shapes.length == 1) return shapes.first;
    final int n = shapes.length;
    final double span = loop ? n.toDouble() : (n - 1).toDouble();
    final double p = loop ? ((t % span) + span) % span : _clamp(t, 0, span);
    final int i = math.min(p.floor(), span.ceil() - 1);
    final double frac = p - i;
    final RadialShape a = shapes[i % n];
    final RadialShape b = shapes[(i + 1) % n];
    return frac == 0 ? a : lerp(a, b, frac);
  }

  /// Builds the closed [Path]: unit radius 1 maps to [radius] pixels around
  /// [center]. The polyline goes through Catmull-Rom cubics ([tension] 1/6 —
  /// the upstream value; 0 gives a straight-edged polygon).
  Path toPath({required double radius, Offset center = Offset.zero,
      double tension = 1 / 6}) {
    final double cr = math.cos(rot);
    final double sr = math.sin(rot);
    final List<Offset> pts = List.generate(radialShapeSamples, (i) {
      final double r = radii[i];
      final double x = r * _cos[i];
      final double y = r * _sin[i];
      // rotation, then squash in screen space, then translation
      final double rx = x * cr - y * sr;
      final double ry = x * sr + y * cr;
      return Offset(center.dx + (rx * sx + cx) * radius,
          center.dy + (ry * sy + cy) * radius);
    }, growable: false);
    return _closedPath(pts, tension);
  }

  /// Convenience: path centered in [size], unit radius = `shortestSide / 2 *`
  /// [fit].
  Path toPathIn(Size size, {double fit = 0.9, double tension = 1 / 6}) =>
      toPath(
          radius: size.shortestSide / 2 * fit,
          center: size.center(Offset.zero),
          tension: tension);
}

/// Tween for [RadialShape] — plug shapes straight into an
/// `AnimationController` / `TweenSequence`.
class RadialShapeTween extends Tween<RadialShape> {
  RadialShapeTween({super.begin, super.end});

  @override
  RadialShape lerp(double t) => RadialShape.lerp(begin!, end!, t);
}

/// Draws the morph between [shapes] at position [t] (see
/// [RadialShape.sequence] for the meaning of [t] and [loop]).
///
/// Stateless on purpose: time comes in as a plain param, so a frozen frame is
/// just a fixed [t] — drive it from any animation (see the demo).
class ShapeMorph extends StatelessWidget {
  const ShapeMorph({
    super.key,
    required this.shapes,
    required this.t,
    this.loop = false,
    this.color = const Color(0xFF222222),
    this.fit = 0.9,
    this.tension = 1 / 6,
  });

  final List<RadialShape> shapes;

  /// Position in the keyframe sequence, `[0, shapes.length - 1]`
  /// (`[0, shapes.length]` when [loop] is true).
  final double t;

  /// Wrap the last segment back to the first shape.
  final bool loop;

  final Color color;

  /// Fraction of the shortest side the unit radius occupies.
  final double fit;

  /// Catmull-Rom smoothing; 0 keeps straight edges.
  final double tension;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShapeMorphPainter(
        shape: RadialShape.sequence(shapes, t, loop: loop),
        color: color,
        fit: fit,
        tension: tension,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ShapeMorphPainter extends CustomPainter {
  const _ShapeMorphPainter({
    required this.shape,
    required this.color,
    required this.fit,
    required this.tension,
  });

  final RadialShape shape;
  final Color color;
  final double fit;
  final double tension;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(shape.toPathIn(size, fit: fit, tension: tension),
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ShapeMorphPainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.fit != fit ||
      old.tension != tension;
}

/// Clips any child to a radial shape — images, video, containers. Rebuild the
/// clipper with a new (possibly lerped) [shape] to animate the clip.
class RadialShapeClipper extends CustomClipper<Path> {
  const RadialShapeClipper(this.shape, {this.fit = 1, this.tension = 1 / 6});

  final RadialShape shape;
  final double fit;
  final double tension;

  @override
  Path getClip(Size size) => shape.toPathIn(size, fit: fit, tension: tension);

  @override
  bool shouldReclip(RadialShapeClipper old) =>
      old.shape != shape || old.fit != fit || old.tension != tension;
}

/* ------------------------------------------------------------ internals */

/// Closed polyline -> Catmull-Rom cubics. With 64 points, centered tangents
/// are plenty: `c1 = p1 + (p2 - p0)·k`, `c2 = p2 - (p3 - p1)·k`.
Path _closedPath(List<Offset> pts, double tension) {
  final Path path = Path();
  final int n = pts.length;
  if (n < 3) return path;
  path.moveTo(pts[0].dx, pts[0].dy);
  for (int i = 0; i < n; i++) {
    final Offset p0 = pts[(i - 1 + n) % n];
    final Offset p1 = pts[i];
    final Offset p2 = pts[(i + 1) % n];
    final Offset p3 = pts[(i + 2) % n];
    path.cubicTo(
      p1.dx + (p2.dx - p0.dx) * tension,
      p1.dy + (p2.dy - p0.dy) * tension,
      p2.dx - (p3.dx - p1.dx) * tension,
      p2.dy - (p3.dy - p1.dy) * tension,
      p2.dx,
      p2.dy,
    );
  }
  path.close();
  return path;
}

/// Ray casting from (cx, cy): keeps the farthest edge hit per sample angle.
/// O(samples × edges), run once at construction, never in a paint loop.
List<double> _profileFromPolygon(List<Offset> poly, double cx, double cy) {
  final List<double> radii = List.filled(radialShapeSamples, 0);
  final int n = poly.length;
  for (int k = 0; k < radialShapeSamples; k++) {
    final double dx = _cos[k];
    final double dy = _sin[k];
    double best = 0;
    for (int i = 0; i < n; i++) {
      final Offset a = poly[i];
      final Offset b = poly[(i + 1) % n];
      final double ex = b.dx - a.dx;
      final double ey = b.dy - a.dy;
      final double den = dx * ey - dy * ex;
      if (den.abs() < 1e-9) continue;
      final double px = a.dx - cx;
      final double py = a.dy - cy;
      final double t = (px * ey - py * ex) / den; // distance along the ray
      final double u = (px * dy - py * dx) / den; // position on the edge
      if (t > best && u >= 0 && u <= 1) best = t;
    }
    radii[k] = best;
  }
  return radii;
}

/// Convex hull of two circles (the outer common tangents plus both arcs).
List<Offset> _hullOfCircles(
    double x1, double y1, double r1, double x2, double y2, double r2,
    [int steps = 96]) {
  final double dx = x2 - x1;
  final double dy = y2 - y1;
  final double dist = math.max(math.sqrt(dx * dx + dy * dy), 1e-6);
  final double base = math.atan2(dy, dx);
  final double spread = math.acos(_clamp((r1 - r2) / dist, -1, 1));
  final List<Offset> pts = [];
  final int half = steps ~/ 2;
  for (int i = 0; i <= half; i++) {
    final double a = base + spread + (_tau - 2 * spread) * i / half;
    pts.add(Offset(x1 + math.cos(a) * r1, y1 + math.sin(a) * r1));
  }
  for (int i = 0; i <= half; i++) {
    final double a = base - spread + 2 * spread * i / half;
    pts.add(Offset(x2 + math.cos(a) * r2, y2 + math.sin(a) * r2));
  }
  return pts;
}

/// Rounded polygon via Minkowski sum with a disc: each edge is pushed out by
/// [rc], each vertex becomes an arc of radius [rc]. Expects a clockwise
/// polygon in screen coordinates (y down).
List<Offset> _roundedPolygon(List<Offset> verts, double rc, [int arcSteps = 10]) {
  final int n = verts.length;
  final List<Offset> out = [];
  double normalAngle(Offset a, Offset b) {
    final double dx = b.dx - a.dx;
    final double dy = b.dy - a.dy;
    final double len = math.max(math.sqrt(dx * dx + dy * dy), 1e-9);
    // clockwise + y down: the outward normal is (dy, -dx)
    return math.atan2(-dx / len, dy / len);
  }

  for (int i = 0; i < n; i++) {
    final Offset prev = verts[(i - 1 + n) % n];
    final Offset cur = verts[i];
    final Offset next = verts[(i + 1) % n];
    final double a0 = normalAngle(prev, cur);
    final double a1 = normalAngle(cur, next);
    double d = a1 - a0;
    while (d > math.pi) {
      d -= _tau;
    }
    while (d < -math.pi) {
      d += _tau;
    }
    for (int k = 0; k <= arcSteps; k++) {
      final double a = a0 + d * k / arcSteps;
      out.add(Offset(cur.dx + math.cos(a) * rc, cur.dy + math.sin(a) * rc));
    }
  }
  return out;
}
