// Part of bloub_bot — decor around the body: dots, 3D elliptical arcs and
// the notification pastille. Mirrors the upstream src/bot/decor.ts
// (jeremy-prt/bloub, MIT). Pure Dart, no Flutter imports.

import '_shape.dart';

/// One dot. States declare it in resting-ball-radius units; the engine
/// re-emits it scaled to viewBox units — same class in both spaces, like
/// upstream.
class BotDot {
  const BotDot({
    required this.x,
    required this.y,
    required this.r,
    required this.opacity,
    this.colorArgb,
    this.depth,
    this.shape,
    this.rotDeg = 0,
  });

  final double x;
  final double y;
  final double r;
  final double opacity;

  /// Explicit color (ARGB int); by default the renderer uses the body ink.
  final int? colorArgb;

  /// Depth mist: 0 = melts into the background, 1 = full body color. The mix
  /// happens at render time, which alone knows the chosen colors.
  final double? depth;

  /// Non-circular shape (the tilted "!"'s dot is a teardrop, not a disc), in
  /// resting-ball-radius units, centered on the origin. When present, [r] is
  /// not used for drawing.
  final List<BotPoint>? shape;

  /// Rotation applied to [shape], degrees.
  final double rotDeg;

  BotDot copyWith({double? x, double? y, double? r, double? opacity}) => BotDot(
        x: x ?? this.x,
        y: y ?? this.y,
        r: r ?? this.r,
        opacity: opacity ?? this.opacity,
        colorArgb: colorArgb,
        depth: depth,
        shape: shape,
        rotDeg: rotDeg,
      );
}

/// Geometry of one 3D elliptical arc (orbit ring, swoosh, comet ribbon), in
/// resting-ball-radius units. The engine, alone in knowing the viewBox scale,
/// rasterizes it.
class BotArcSeed {
  const BotArcSeed({
    required this.a,
    required this.k,
    required this.tilt,
    required this.speed,
    required this.phase,
    required this.sweep,
    required this.hue,
    required this.hueSpan,
    required this.width,
    required this.cx,
    required this.cy,
  });

  /// Semi-major axis, in resting-ball-radius units.
  final double a;

  /// Flattening b/a: measured <= 0.45 — orbit planes are seen edge-on.
  final double k;

  /// Tilt of the major axis on screen, radians.
  final double tilt;

  /// Turns per second.
  final double speed;
  final double phase;

  /// Fraction of the turn actually drawn.
  final double sweep;
  final double hue;
  final double hueSpan;
  final double width;
  final double cx;
  final double cy;

  BotArcSeed copyWith({double? cx}) => BotArcSeed(
        a: a,
        k: k,
        tilt: tilt,
        speed: speed,
        phase: phase,
        sweep: sweep,
        hue: hue,
        hueSpan: hueSpan,
        width: width,
        cx: cx ?? this.cx,
        cy: cy,
      );
}

/// What a state declares: seed + local time + opacity.
class BotArcSpec {
  const BotArcSpec({
    required this.id,
    required this.seed,
    required this.t,
    required this.opacity,
  });

  final String id;
  final BotArcSeed seed;
  final double t;
  final double opacity;

  BotArcSpec withPrefix(String prefix, double opacityFactor) => BotArcSpec(
      id: '$prefix$id', seed: seed, t: t, opacity: opacity * opacityFactor);
}

/// A rasterized arc: polyline split into the portion in front of the body
/// and the portion behind it (drawn before the body, hence occluded), plus a
/// hue gradient along the trace. Filled by the decor renderer.
class BotArcRender {
  const BotArcRender({
    required this.id,
    required this.front,
    required this.back,
    required this.width,
    required this.opacity,
    required this.gradX1,
    required this.gradY1,
    required this.gradX2,
    required this.gradY2,
    required this.gradArgb,
  });

  final String id;

  /// Polyline segments in front of the body. Each inner list is one
  /// contiguous run of points (an SVG M...L...L chain).
  final List<List<BotPoint>> front;
  final List<List<BotPoint>> back;
  final double width;
  final double opacity;
  final double gradX1;
  final double gradY1;
  final double gradX2;
  final double gradY2;

  /// Three gradient stops along the trace, ARGB.
  final List<int> gradArgb;
}

/* ------------------------------------------------------------- 3 dots */

/// Measured x positions of the "thinking" dots; y = 0.
const List<double> kBotDotX = [-0.557, -0.013, 0.532];
const double kBotDotR = 0.165;
const double kBotDotPeak = 1.25;

/* ------------------------------------------------- notification pastille */

/// Blue picked at the pixel.
const int kBotNotifBlue = 0xFF2496E8;

/// The pastille sits exactly on the circumference, at −42°.
const double kBotNotifAngle = -42;
const double kBotNotifDist = 1.003;

/// Resting radius; the pop peaks 14% above.
const double kBotNotifR = 0.15;
const double kBotNotifPop = 1.14;

/// The notch is a disc concentric with the pastille, subtracted from the
/// body. Constant margin (0.054 R), follows the body scale.
const double kBotNotifMargin = 0.054;
