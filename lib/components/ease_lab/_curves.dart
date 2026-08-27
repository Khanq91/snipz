// GSAP ease reimplementations (behavior of v3.15) as Flutter [Curve]s.
// Pure math, no code copied: CustomEase's flatten+LUT engine, CustomWiggle,
// CustomBounce (+ squash companion), SlowMo, RoughEase, ExpoScaleEase.
//
// Several of these END AT 0 (wiggle, squash, slow-mo yoyo, bounce endAtStart)
// — they oscillate around the start value instead of travelling 0 → 1. Drive
// them through a Tween whose `end` is the PEAK amplitude; the animated value
// returns to `begin` on completion. They override [Curve.transform] to skip
// the framework's `t == 1 → 1` shortcut.

import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Piecewise-cubic-Bézier ease — the CustomEase engine.
///
/// [values] is a flat list `[x0,y0, c1x,c1y,c2x,c2y, x1,y1, ...]` of
/// absolute cubic segments (length `6n + 2`), x monotonically covering
/// 0 → 1 (auto-rescaled). Each cubic is flattened by adaptive de Casteljau
/// subdivision into a polyline, then bucketed into a uniform lookup table so
/// [transform] is O(1) — same approach as the original.
class CubicPathEase extends Curve {
  CubicPathEase(List<double> values, {int precision = 1})
    : assert(values.length >= 8),
      assert((values.length - 2) % 6 == 0),
      assert(precision >= 1) {
    _build(List<double>.of(values), precision);
  }

  /// A plain `cubic-bezier(x1, y1, x2, y2)` (CSS-style) ease.
  CubicPathEase.bezier(double x1, double y1, double x2, double y2)
    : this(<double>[0, 0, x1, y1, x2, y2, 1, 1]);

  // Flattened polyline (xs strictly increasing) and its uniform-bucket LUT.
  late final List<double> _xs;
  late final List<double> _ys;
  late final List<int> _buckets;
  late final int _bucketCount;

  void _build(List<double> v, int precision) {
    // Rescale x to land exactly on [0, 1] (y passes through untouched — the
    // wiggle/squash paths legitimately live in [-1, 1] or end at 0).
    final double tx = -v[0];
    final double sx = 1 / (v[v.length - 2] + tx);
    for (int i = 0; i < v.length; i += 2) {
      v[i] = (v[i] + tx) * sx;
    }

    final double threshold = 1 / (precision * 200000);
    final List<double> px = <double>[v[0]];
    final List<double> py = <double>[v[1]];
    for (int i = 0; i + 7 < v.length; i += 6) {
      _flatten(
        v[i], v[i + 1], v[i + 2], v[i + 3],
        v[i + 4], v[i + 5], v[i + 6], v[i + 7],
        threshold, px, py, 0,
      );
    }

    // Drop backwards/duplicate x so the polyline is a function of x.
    final List<double> xs = <double>[px[0]];
    final List<double> ys = <double>[py[0]];
    double minGap = 1;
    for (int i = 1; i < px.length; i++) {
      if (px[i] <= xs.last || px[i] > 1.0000001) continue;
      minGap = math.min(minGap, px[i] - xs.last);
      xs.add(math.min(1, px[i]));
      ys.add(py[i]);
    }
    if (xs.last < 1) {
      xs.add(1);
      ys.add(py.last);
    }
    _xs = xs;
    _ys = ys;

    _bucketCount = math.min(2000, (1 / math.max(minGap, 0.0005)).floor() + 1);
    _buckets = List<int>.filled(_bucketCount, 0);
    int seg = 0;
    for (int b = 0; b < _bucketCount; b++) {
      final double x = b / _bucketCount;
      while (seg + 2 < xs.length && xs[seg + 1] <= x) {
        seg++;
      }
      _buckets[b] = seg;
    }
  }

  /// Adaptive subdivision of one cubic; appends interior+end points.
  void _flatten(
    double x1, double y1, double x2, double y2,
    double x3, double y3, double x4, double y4,
    double threshold, List<double> px, List<double> py, int depth,
  ) {
    final double dx = x4 - x1, dy = y4 - y1;
    final double d2 = ((x2 - x4) * dy - (y2 - y4) * dx).abs();
    final double d3 = ((x3 - x4) * dy - (y3 - y4) * dx).abs();
    final double d = d2 + d3;
    if (depth < 12 && d * d > threshold * (dx * dx + dy * dy)) {
      final double x12 = (x1 + x2) / 2, y12 = (y1 + y2) / 2;
      final double x23 = (x2 + x3) / 2, y23 = (y2 + y3) / 2;
      final double x34 = (x3 + x4) / 2, y34 = (y3 + y4) / 2;
      final double xa = (x12 + x23) / 2, ya = (y12 + y23) / 2;
      final double xb = (x23 + x34) / 2, yb = (y23 + y34) / 2;
      final double xm = (xa + xb) / 2, ym = (ya + yb) / 2;
      _flatten(x1, y1, x12, y12, xa, ya, xm, ym, threshold, px, py, depth + 1);
      _flatten(xm, ym, xb, yb, x34, y34, x4, y4, threshold, px, py, depth + 1);
    } else {
      px.add(x4);
      py.add(y4);
    }
  }

  @override
  double transform(double t) {
    assert(t >= 0 && t <= 1);
    if (t <= 0) return _ys.first;
    if (t >= 1) return _ys.last;
    int i = _buckets[math.min((t * _bucketCount).floor(), _bucketCount - 1)];
    while (i + 2 < _xs.length && _xs[i + 1] <= t) {
      i++;
    }
    final double gap = math.max(_xs[i + 1] - _xs[i], 1e-9);
    return _ys[i] + (t - _xs[i]) / gap * (_ys[i + 1] - _ys[i]);
  }
}

/// Amplitude/timing profiles for [WiggleEase] (GSAP CustomWiggle `type`).
enum WiggleType {
  /// Big wiggles first, decaying to rest (default).
  easeOut,

  /// Ramp in, wiggle hardest mid-way, settle.
  easeInOut,

  /// A drawn-back start — winds up before wiggling (warps timing, not
  /// amplitude).
  anticipate,

  /// Full amplitude the whole way, hard stop.
  uniform,

  /// Random amplitudes per wiggle (deterministic per [WiggleEase.seed]).
  random,
}

/// Oscillating ease: swings the value ± around the START and settles back on
/// it. Maps 0 → 0 and **1 → 0**; output spans [-1, 1] — tween to the peak
/// amplitude (e.g. rotation `end: 30°` wiggles ±30° and returns to 0).
class WiggleEase extends Curve {
  WiggleEase({
    this.wiggles = 10,
    this.type = WiggleType.easeOut,
    Curve? timingEase,
    Curve? amplitudeEase,
    this.seed = 7,
  }) : assert(wiggles >= 1) {
    _path = _buildPath(wiggles, type, timingEase, amplitudeEase, seed);
  }

  final int wiggles;
  final WiggleType type;

  /// Seed for [WiggleType.random] amplitudes.
  final int seed;

  late final CubicPathEase _path;

  // GSAP's four envelope curves (start at their resting amplitude, y is the
  // amplitude of wiggle i at progress i/wiggles).
  static final CubicPathEase _envEaseOut = CubicPathEase(const <double>[
    0, 1, 0.7, 1, 0.6, 0, 1, 0,
  ]);
  static final CubicPathEase _envEaseInOut = CubicPathEase(const <double>[
    0, 0, 0.1, 0, 0.24, 1, 0.444, 1, 0.644, 1, 0.6, 0, 1, 0,
  ]);
  static final CubicPathEase _envAnticipate = CubicPathEase(const <double>[
    0, 0, 0, 0.222, 0.024, 0.386, 0, 0.4, 0.18, 0.455, 0.65, 0.646, 0.7,
    0.67, 0.9, 0.76, 1, 0.846, 1, 1,
  ]);
  static final CubicPathEase _envUniform = CubicPathEase(const <double>[
    0, 0, 0, 0.95, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0,
  ]);

  static CubicPathEase _buildPath(
    int wiggles,
    WiggleType type,
    Curve? timingEase,
    Curve? amplitudeEase,
    int seed,
  ) {
    final double inc = 1 / wiggles;
    double x = inc / 2;
    final bool anticipate = type == WiggleType.anticipate;

    double Function(double) yEase = switch (type) {
      WiggleType.easeInOut => _envEaseInOut.transform,
      WiggleType.uniform => _envUniform.transform,
      _ => _envEaseOut.transform,
    };
    double Function(double) xEase = anticipate
        ? _envAnticipate.transform
        : (double p) => p;
    if (timingEase != null) xEase = timingEase.transform;
    // A standard 0→1 ease is flipped into a decay envelope (GSAP inverts
    // non-custom amplitudeEases).
    if (amplitudeEase != null) {
      final Curve amp = amplitudeEase;
      yEase = (double p) => 1 - amp.transform(p);
    }

    double easedX = xEase(x);
    double y = anticipate ? -yEase(x) : yEase(x);
    final List<double> path = <double>[0, 0, easedX / 4, 0, easedX / 2, y,
        easedX, y];

    if (type == WiggleType.random) {
      // Handles follow the local tangent so anchors don't stall.
      final math.Random rng = math.Random(seed);
      path.length = 4;
      double nextX = xEase(inc);
      double nextY = rng.nextDouble() * 2 - 1;
      for (int i = 2; i < wiggles; i++) {
        x = nextX;
        y = nextY;
        nextX = xEase(inc * i);
        nextY = rng.nextDouble() * 2 - 1;
        final double angle = math.atan2(
          nextY - path[path.length - 3],
          nextX - path[path.length - 4],
        );
        final double handleX = math.cos(angle) * inc;
        final double handleY = math.sin(angle) * inc;
        path.addAll(<double>[
          x - handleX, y - handleY, x, y, x + handleX, y + handleY,
        ]);
      }
      path.addAll(<double>[nextX, 0, 1, 0]);
    } else {
      for (int i = 1; i < wiggles; i++) {
        path.addAll(<double>[xEase(x + inc / 2), y]);
        x += inc;
        y = (y > 0 ? -1 : 1) * yEase(i * inc);
        easedX = xEase(x);
        path.addAll(<double>[xEase(x - inc / 2), y, easedX, y]);
      }
      path.addAll(<double>[
        xEase(x + inc / 4), y, xEase(x + inc / 4), 0, 1, 0,
      ]);
    }
    return CubicPathEase(path);
  }

  @override
  double transform(double t) {
    assert(t >= 0 && t <= 1);
    return _path.transform(t);
  }
}

/// Shared generator for [BounceEase]/[SquashEase] (GSAP CustomBounce): a
/// parameterized ball-drop plus a time-synchronized squash profile.
({List<double> bounce, List<double> squash}) _customBouncePaths({
  required double strength,
  required double squash,
  required bool endAtStart,
}) {
  const double max = 0.999;
  double decay = math.min(max, strength);
  final double decayX = decay;
  double gap = squash / 100;
  final double originalGap = gap;
  double slope = 1 / 0.03;
  double w = 0.2;
  double h = 1;
  double prevX = 0.1;
  final List<double> path = <double>[0, 0, 0.07, 0, 0.1, 1, 0.1, 1];
  final List<double> squashPath = <double>[0, 0, 0, 0, 0.1, 0, 0.1, 0];

  for (int i = 0; i < 200; i++) {
    w *= decayX * ((decayX + 1) / 2);
    h *= decay * decay;
    double nextX = prevX + w;
    double x = prevX + w * 0.49;
    final double y = 1 - h;
    double cp1 = prevX + h / slope;
    double cp2 = x + (x - cp1) * 0.8;

    if (gap > 0) {
      prevX += gap;
      cp1 += gap;
      x += gap;
      cp2 += gap;
      nextX += gap;
      final double squish = gap / originalGap;
      squashPath.addAll(<double>[
        prevX - gap, 0,
        prevX - gap, squish,
        prevX - gap / 2, squish, // center peak anchor
        prevX, squish,
        prevX, 0,
        prevX, 0, // base anchor
        prevX, squish * -0.6, // departure stretch
        prevX + (nextX - prevX) / 6, 0,
        nextX, 0,
      ]);
      path.addAll(<double>[prevX - gap, 1, prevX, 1, prevX, 1]);
      gap *= decay * decay;
    }

    path.addAll(<double>[
      prevX, 1, cp1, y, x, y, cp2, y, nextX, 1, nextX, 1,
    ]);
    decay *= 0.95; // later bounces die faster
    slope = h / (nextX - cp2); // mirror the incoming slope: sharp V at impact
    prevX = nextX;
    if (y > max) break;
  }

  if (endAtStart) {
    double x = -0.1;
    path.insertAll(0, <double>[x, 1, x, 1, -0.07, 0]);
    if (originalGap > 0) {
      final double g = originalGap * 2.5; // longer anticipation squash
      x -= g;
      path.insertAll(0, <double>[x, 1, x, 1, x, 1]);
      squashPath.removeRange(0, 6);
      squashPath.insertAll(0, <double>[
        x, 0, x, 0, x, 1, x + g / 2, 1, x + g, 1, x + g, 0, x + g, 0,
        x + g, -0.6, x + g + 0.033, 0,
      ]);
      for (int i = 0; i < squashPath.length; i += 2) {
        squashPath[i] -= x;
      }
    }
    for (int i = 0; i < path.length; i += 2) {
      path[i] -= x;
      path[i + 1] = 1 - path[i + 1];
    }
  }
  return (bounce: path, squash: squashPath);
}

/// Configurable ball-drop bounce (GSAP CustomBounce). 0 → 1 with decaying
/// rebounds; [strength] 0..0.999 = energy kept per bounce. [squash] > 0
/// inserts floor-contact holds sized to match a [SquashEase] built with the
/// SAME parameters. [endAtStart] plays drop-and-return (ends at 0).
class BounceEase extends Curve {
  BounceEase({this.strength = 0.7, this.squash = 0, this.endAtStart = false})
    : assert(strength >= 0 && strength < 1),
      assert(squash >= 0) {
    _path = CubicPathEase(
      _customBouncePaths(
        strength: strength,
        squash: squash,
        endAtStart: endAtStart,
      ).bounce,
    );
  }

  final double strength;
  final double squash;
  final bool endAtStart;
  late final CubicPathEase _path;

  @override
  double transform(double t) {
    assert(t >= 0 && t <= 1);
    return _path.transform(t);
  }
}

/// The squash-and-stretch companion of [BounceEase] — 0 in flight, rises to
/// 1 exactly at each floor contact, dips negative (stretch) on departure.
/// Ends at 0. Drive `scaleX/scaleY` with it while [BounceEase] (same
/// [strength]/[squash]) drives the position, from one shared controller.
class SquashEase extends Curve {
  SquashEase({this.strength = 0.7, this.squash = 3, this.endAtStart = false})
    : assert(strength >= 0 && strength < 1),
      assert(squash > 0) {
    _path = CubicPathEase(
      _customBouncePaths(
        strength: strength,
        squash: squash,
        endAtStart: endAtStart,
      ).squash,
    );
  }

  final double strength;
  final double squash;
  final bool endAtStart;
  late final CubicPathEase _path;

  @override
  double transform(double t) {
    assert(t >= 0 && t <= 1);
    return _path.transform(t);
  }
}

/// Fast in → long constant-velocity middle → fast out (GSAP SlowMo).
/// [linearRatio] = fraction of time spent in the middle; [power] = how much
/// of the value range the middle consumes (0 = fully linear across).
/// [yoyoMode] returns a 0 → 1 → 0 pulse instead — pair it with a normal
/// SlowMo driving position to fade in/out around the linear cruise.
class SlowMoEase extends Curve {
  const SlowMoEase({
    this.linearRatio = 0.7,
    this.power = 0.7,
    this.yoyoMode = false,
  }) : assert(linearRatio >= 0 && linearRatio <= 1),
       assert(power >= 0 && power <= 1);

  final double linearRatio;
  final double power;
  final bool yoyoMode;

  @override
  double transform(double t) {
    assert(t >= 0 && t <= 1);
    final double pow = linearRatio < 1 ? power : 0;
    final double p1 = (1 - linearRatio) / 2;
    final double p3 = p1 + linearRatio;
    final double r = t + (0.5 - t) * pow;
    if (t < p1) {
      final double q = 1 - t / p1;
      return yoyoMode ? 1 - q * q : r - q * q * q * q * r;
    }
    if (t > p3) {
      final double q = (t - p3) / p1;
      if (yoyoMode) return t == 1 ? 0 : 1 - q * q;
      return r + (t - r) * q * q * q * q;
    }
    return yoyoMode ? 1 : r;
  }
}

/// Where [RoughEase] jitter is tapered away to nothing.
/// `atEnd` = GSAP "out" (smooth landing), `atStart` = GSAP "in".
enum RoughTaper { none, atStart, atEnd, both }

/// Jitter/static: the value snaps between scattered points around a
/// [template] curve (GSAP RoughEase). Deterministic per [seed].
class RoughEase extends Curve {
  RoughEase({
    this.points = 20,
    double strength = 1,
    this.taper = RoughTaper.none,
    this.randomize = true,
    this.clamp = false,
    this.template,
    this.seed = 17,
  }) : assert(points >= 2) {
    final double str = strength * 0.4;
    final math.Random rng = math.Random(seed);
    final List<({double x, double y})> pts = <({double x, double y})>[];
    for (int i = points - 1; i >= 0; i--) {
      final double x = randomize ? rng.nextDouble() : (1 / points) * i;
      double y = template?.transform(x) ?? x;
      final double bump = switch (taper) {
        RoughTaper.none => str,
        RoughTaper.atEnd => (1 - x) * (1 - x) * str,
        RoughTaper.atStart => x * x * str,
        RoughTaper.both when x < 0.5 => (x * 2) * (x * 2) * 0.5 * str,
        RoughTaper.both => ((1 - x) * 2) * ((1 - x) * 2) * 0.5 * str,
      };
      if (randomize) {
        y += rng.nextDouble() * bump - bump * 0.5;
      } else if (i.isOdd) {
        y += bump * 0.5;
      } else {
        y -= bump * 0.5;
      }
      if (clamp) y = y.clamp(0.0, 1.0);
      pts.add((x: x, y: y));
    }
    pts.sort((a, b) => a.x.compareTo(b.x));

    final List<double> xs = <double>[0];
    final List<double> ys = <double>[0];
    for (final ({double x, double y}) p in pts) {
      if (p.x > xs.last && p.x < 1) {
        xs.add(p.x);
        ys.add(p.y);
      }
    }
    xs.add(1);
    ys.add(1);
    _xs = xs;
    _ys = ys;
  }

  final int points;
  final RoughTaper taper;
  final bool randomize;
  final bool clamp;
  final Curve? template;
  final int seed;

  late final List<double> _xs;
  late final List<double> _ys;

  @override
  double transformInternal(double t) {
    // Binary search for the segment containing t (pure — no cursor state).
    int lo = 0, hi = _xs.length - 2;
    while (lo < hi) {
      final int mid = (lo + hi + 1) >> 1;
      if (_xs[mid] <= t) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final double gap = math.max(_xs[lo + 1] - _xs[lo], 1e-9);
    return _ys[lo] + (t - _xs[lo]) / gap * (_ys[lo + 1] - _ys[lo]);
  }
}

/// Perceptually-linear zoom (GSAP ExpoScaleEase): remaps progress so a scale
/// tween from [start] to [end] LOOKS constant-rate (geometric interpolation
/// `start·(end/start)^t`) instead of blasting then crawling. Both must be > 0
/// and must match the tween's actual scale range.
class ExpoScaleEase extends Curve {
  ExpoScaleEase(this.start, this.end, [this.inner])
    : assert(start > 0),
      assert(end > 0),
      assert(start != end),
      _p1 = math.log(end / start),
      _p2 = end - start;

  final double start;
  final double end;

  /// Optional ease layered inside the remap.
  final Curve? inner;

  final double _p1;
  final double _p2;

  @override
  double transformInternal(double t) {
    final double f = inner?.transform(t) ?? t;
    return (start * math.exp(_p1 * f) - start) / _p2;
  }
}
