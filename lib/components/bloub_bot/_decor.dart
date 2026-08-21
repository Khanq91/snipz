// Part of bloub_bot — decor around the body: dots, 3D elliptical arcs and
// the notification pastille. Mirrors the upstream src/bot/decor.ts
// (jeremy-prt/bloub, MIT). Pure Dart, no Flutter imports.

import 'dart:math' as math;

import '_math.dart';
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

/* ------------------------------------------------------------------ colors */

/// The rings are not flat colors: the video shows a full hue wheel at
/// constant luminosity, with a gradient along each trace. Measured:
/// S 45-62%, L 50-67%.
int botWheel(double hue, [double s = 0.55, double l = 0.62]) {
  final double h = ((hue % 360) + 360) % 360;
  final double c = (1 - (2 * l - 1).abs()) * s;
  final double x = c * (1 - ((h / 60) % 2 - 1).abs());
  final double m = l - c / 2;
  final List<double> rgb = h < 60
      ? [c, x, 0]
      : h < 120
          ? [x, c, 0]
          : h < 180
              ? [0, c, x]
              : h < 240
                  ? [0, x, c]
                  : h < 300
                      ? [x, 0, c]
                      : [c, 0, x];
  int ch(double v) => ((v + m) * 255).round().clamp(0, 255);
  return 0xFF000000 | (ch(rgb[0]) << 16) | (ch(rgb[1]) << 8) | ch(rgb[2]);
}

/* --------------------------------------------------------- 3D arc render */

/// Projects a tilted 3D circle orthographically. The circle lives in the
/// plane spanned by u (in-screen) and v (plunging into depth); the z
/// component splits the arc in two: the back half is drawn before the body,
/// hence occluded by it. That real depth sort is what makes the rings read
/// as orbits and not as a flat drawing.
BotArcRender botArcRender(BotArcSeed seed, double t, double scale, String id,
    [double opacity = 1]) {
  final double spin = seed.phase + t * seed.speed * botTau;
  final double cu = math.cos(seed.tilt);
  final double su = math.sin(seed.tilt);
  final double kz = math.sqrt(math.max(0, 1 - seed.k * seed.k));

  const int n = 64;
  final double span = seed.sweep * botTau;
  final List<List<BotPoint>> front = [];
  final List<List<BotPoint>> back = [];
  bool? prevBehind;

  for (int i = 0; i <= n; i++) {
    final double th = spin + i / n * span;
    final double ct = math.cos(th);
    final double st = math.sin(th);
    // u = (cos tilt, sin tilt, 0) ; v = (-sin tilt * k, cos tilt * k, kz)
    final double x = seed.a * (ct * cu + st * -su * seed.k) + seed.cx;
    final double y = seed.a * (ct * su + st * cu * seed.k) + seed.cy;
    final double z = seed.a * st * kz;

    final bool behind = z < 0;
    final List<List<BotPoint>> side = behind ? back : front;
    if (behind != prevBehind || side.isEmpty) side.add([]);
    side.last.add((x: x * scale, y: y * scale));
    prevBehind = behind;
  }

  final double gx = math.cos(seed.tilt) * seed.a * scale;
  final double gy = math.sin(seed.tilt) * seed.a * scale;
  return BotArcRender(
    id: id,
    front: front,
    back: back,
    width: seed.width * scale,
    opacity: opacity,
    gradX1: seed.cx * scale - gx,
    gradY1: seed.cy * scale - gy,
    gradX2: seed.cx * scale + gx,
    gradY2: seed.cy * scale + gy,
    gradArgb: [
      botWheel(seed.hue),
      botWheel(seed.hue + seed.hueSpan * 0.5),
      botWheel(seed.hue + seed.hueSpan),
    ],
  );
}

/* ------------------------------------------------------------------ arcs */

/// Nested arc bouquet sweeping the triangle just before the orbits. Seen
/// nearly edge-on (hence the hairpin shape), rmax 1.37. Analytic, no RNG.
final List<BotArcSeed> kBotSwoosh = List.unmodifiable(List.generate(
    4,
    (i) => BotArcSeed(
          a: 0.78 + i * 0.2,
          k: 0.05 + i * 0.02,
          tilt: -0.62 + i * 0.05,
          speed: 0.3,
          phase: 0.06 * i,
          sweep: 0.4,
          hue: 95 + i * 62,
          hueSpan: 100,
          width: 0.05,
          cx: 0,
          cy: -0.12,
        )));

/// Radius of the comet's dot, measured at 0.129.
const double kBotCometDot = 0.129;

/* ------------------------------------------------------------ particles */

/// Burst particles do not fly straight: they spiral toward the center
/// (radius x0.75 per frame, +100 deg/s) while growing, and pass behind the
/// core where they are swallowed. Rows: birth, angle, rho (vendored — see
/// the tables note below).
List<BotDot> botParticles(double t, double scale) {
  final List<BotDot> out = [];
  for (final List<double> p in kBotBurstParticles) {
    final double u = t - p[0];
    if (u < 0 || u > 0.62) continue;
    final double rho = p[2] * math.pow(0.75, u * 10);
    final double a = p[1] + u * 100 * math.pi / 180;
    out.add(BotDot(
      x: math.cos(a) * rho * scale,
      y: math.sin(a) * rho * scale,
      r: (0.04 + 0.028 * botClamp(u / 0.55)) * scale,
      depth: botClamp(1 - rho / 0.8),
      opacity: botClamp(u / 0.06) * botClamp((0.62 - u) / 0.08),
    ));
  }
  return out;
}

/* ------------------------------------------------------ vendored tables */

// Upstream builds these at module load with a seeded mulberry32 (seeds
// 0xa11ce, 0xc0e7, 0xbeef). Porting JS RNG semantics (Math.imul, >>> 0) is
// where silent drift creeps in, so the tables are the RNG's OUTPUT instead,
// regenerated with node from the bloub checkout — same nature as the
// measured profiles.

/// 6 rings, semi-major 1.30-1.40 (clearly larger than the ball), flattening
/// always <= 0.45, thickness ~0.055, ~3.3 turns/s.
const List<BotArcSeed> kBotRings = [
  BotArcSeed(a: 1.3743155926233157, k: 0.27493661139160397, tilt: 0.11163715459406376, speed: 3.5312514966120943, phase: 3.5215805556682933, sweep: 0.7452879050048068, hue: 4.53815097687766, hueSpan: 63.32831121515483, width: 0.0526062230002135, cx: 0, cy: 0.1),
  BotArcSeed(a: 1.3478030681610107, k: 0.3169440078549087, tilt: 1.0093109920668266, speed: 3.4112522192532198, phase: 6.146908005905841, sweep: 0.6468076598481275, hue: 81.64599264739081, hueSpan: 66.51980398222804, width: 0.06018400430120528, cx: 0, cy: 0.1),
  BotArcSeed(a: 1.396025489922613, k: 0.40733767822384837, tilt: 1.1039764153167309, speed: 3.6806644265307114, phase: 1.0627643605614534, sweep: 0.8412599016679451, hue: 149.84371276572347, hueSpan: 61.366802947595716, width: 0.056177541773766285, cx: 0, cy: 0.1),
  BotArcSeed(a: 1.3853965060785414, k: 0.3961880846880376, tilt: 1.9961215903193246, speed: 3.015525759500451, phase: 1.1164722730487298, sweep: 0.6740480975364335, hue: 185.79063047189265, hueSpan: 108.99123252835125, width: 0.051692712741903964, cx: 0, cy: 0.1),
  BotArcSeed(a: 1.3750752961495891, k: 0.41330388756468894, tilt: 2.554288128433131, speed: 3.306340780830942, phase: 5.341917949124536, sweep: 0.8341249540331773, hue: 269.8505696724169, hueSpan: 73.29493375495076, width: 0.05261907224263996, cx: 0, cy: 0.1),
  BotArcSeed(a: 1.3038241447415204, k: 0.3598543989472091, tilt: 3.0157889269994764, speed: 3.219781908742152, phase: 2.6741883493986927, sweep: 0.6721552689792588, hue: 327.09959444822744, hueSpan: 87.62834109831601, width: 0.055451622528955344, cx: 0, cy: 0.1),
];

/// The comet: the dot does NOT cross the screen — it stays put and the trail
/// orbits it. Ellipse a = 0.85, b = 0.15, major axis at +34°, 4 ribbons,
/// ~210 deg/s, 10-20° phase lag between ribbons.
const List<BotArcSeed> kBotCometRibbons = [
  BotArcSeed(a: 0.81175, k: 0.13411764705882354, tilt: 0.5409119456780721, speed: 0.5833333333333334, phase: 0.005392308376729488, sweep: 0.34, hue: 4.084076266735792, hueSpan: 80, width: 0.095, cx: 0, cy: 0),
  BotArcSeed(a: 0.8372499999999999, k: 0.16235294117647062, tilt: 0.5759119456780721, speed: 0.5833333333333334, phase: -0.04118510032072663, sweep: 0.34, hue: 96.50942041072994, hueSpan: 80, width: 0.095, cx: 0, cy: 0),
  BotArcSeed(a: 0.8627499999999999, k: 0.19058823529411767, tilt: 0.610911945678072, speed: 0.5833333333333334, phase: -0.07967805009707808, sweep: 0.34, hue: 186.99650775175542, hueSpan: 80, width: 0.095, cx: 0, cy: 0),
  BotArcSeed(a: 0.8882499999999999, k: 0.21882352941176472, tilt: 0.6459119456780721, speed: 0.5833333333333334, phase: -0.13066693757101894, sweep: 0.34, hue: 267.1045708376914, hueSpan: 80, width: 0.095, cx: 0, cy: 0),
];

/// 5 burst particles: birth, angle, rho.
const List<List<double>> kBotBurstParticles = [
  [0, 4.177982462013857, 0.635673837615177],
  [0.2, 4.0229110931374725, 0.6313722840510309],
  [0.4, 6.147502175935408, 0.618599854754284],
  [0.6000000000000001, 4.462918449781453, 0.6759336668113246],
  [0.8, 0.8942033099685366, 0.726892370074056],
];
