// Part of bloub_bot — framework-free math helpers, mirroring the upstream
// src/bot/math.ts (jeremy-prt/bloub, MIT). No Flutter imports: everything in
// the engine layer stays testable from plain Dart.

import 'dart:math' as math;

const double botTau = math.pi * 2;

double botClamp(double v, [double lo = 0, double hi = 1]) =>
    v < lo ? lo : (v > hi ? hi : v);

double botLerp(double a, double b, double t) => a + (b - a) * t;

/// Measured on the reference video: transitions are exponential ease-outs,
/// with no body overshoot. The only springy effects are local (the
/// notification pop, eye opening) and are written inside the state concerned.
double botEaseOutCubic(double t) {
  final double u = 1 - t;
  return 1 - u * u * u;
}

double botEaseInOutCubic(double t) {
  if (t < 0.5) return 4 * t * t * t;
  final double u = -2 * t + 2;
  return 1 - u * u * u / 2;
}

double botEaseOutQuint(double t) {
  final double u = 1 - t;
  return 1 - u * u * u * u * u;
}

/// Periodic 1D noise: loops seamlessly over [period]. Used for the gaze
/// drift. Deterministic — same t, same value — which is what keeps
/// `sample(t)` a pure function of time.
double botLoopNoise(double t, double period, [double seed = 0]) {
  final double p = t / period * botTau;
  return 0.55 * math.sin(p + seed) +
      0.3 * math.sin(2 * p + seed * 1.7 + 1.1) +
      0.15 * math.sin(3 * p + seed * 2.3 + 2.4);
}
