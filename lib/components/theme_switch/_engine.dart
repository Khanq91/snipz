// ignore_for_file: constant_identifier_names

/// ThemeSwitch — physics engine
/// Origin: reimplemented from Pin-UI theme-switch-engine.ts
/// Deps: flutter only (dart:math)
/// Internal file. Do not import directly — use theme_switch.dart.
library;

import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// Public enums & data types
// ─────────────────────────────────────────────────────────────────────────────

enum LiquidTheme { light, dark }

enum SwitchEffect { droplet, rain, diwali }

// ─────────────────────────────────────────────────────────────────────────────
// Theme colours
// ─────────────────────────────────────────────────────────────────────────────

class ThemeColors {
  static const Map<LiquidTheme, ThemePalette> _map = {
    LiquidTheme.light: ThemePalette(bg: 0xFFFFFFFF, ring: 0x1A000000, btn: 0xFFEFEFEF, btnHover: 0xFFE7E7E7, icon: 0xFF4C4C4C, segBg: 0xFFF5F5F5, segThumb: 0xFFFFFFFF, segText: 0xFF8A8A8A, segActive: 0xFF1F1F1F),
    LiquidTheme.dark: ThemePalette(bg: 0xFF141414, ring: 0x1AFFFFFF, btn: 0xFF1F1F1F, btnHover: 0xFF262626, icon: 0xFFFFFFFF, segBg: 0xFF1A1A1A, segThumb: 0xFF2A2A2A, segText: 0xFF7A7A7A, segActive: 0xFFF2F2F2),
  };

  static ThemePalette of(LiquidTheme t) => _map[t]!;
}

class ThemePalette {
  final int bg, ring, btn, btnHover, icon, segBg, segThumb, segText, segActive;
  const ThemePalette({required this.bg, required this.ring, required this.btn, required this.btnHover, required this.icon, required this.segBg, required this.segThumb, required this.segText, required this.segActive});
}

// ─────────────────────────────────────────────────────────────────────────────
// Math helpers
// ─────────────────────────────────────────────────────────────────────────────

double clampD(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);
double easeOutCubic(double p) => 1 - math.pow(1 - p, 3).toDouble();
double easeInOutCubic(double p) => p < 0.5 ? 4 * p * p * p : 1 - math.pow(-2 * p + 2, 3) / 2;

// ─────────────────────────────────────────────────────────────────────────────
// Lobe / Spot — shared puddle maths (Rain + Diwali)
// ─────────────────────────────────────────────────────────────────────────────

class PuddleLobe {
  final double dx, dy, s;
  const PuddleLobe(this.dx, this.dy, this.s);
}

class Spot {
  final double x, y;
  final double bornMs; // ms
  final double r0, rmax;
  final double tauMs;
  final double creepPxPerS;
  final List<PuddleLobe> lobes;

  const Spot({
    required this.x,
    required this.y,
    required this.bornMs,
    required this.r0,
    required this.rmax,
    this.tauMs = _kSpreadTauMs,
    this.creepPxPerS = _kCreepPxPerS,
    this.lobes = const [],
  });

  static const double _kSpreadTauMs = 260;
  static const double _kCreepPxPerS = 14;
}

double puddleBase(Spot p, double tMs) {
  final double age = math.max(0, tMs - p.bornMs);
  return p.r0 + (p.rmax - p.r0) * (1 - math.exp(-age / p.tauMs)) + (p.creepPxPerS * age) / 1000;
}

/// Smallest uniform scale k at which the spots' circles cover every pixel.
double coverageScale(List<Spot> spots, double tMs, double w, double h) {
  final int n = spots.length;
  if (n == 0) return 1;
  final double cell = math.max(40, math.max(w, h) / 48);
  final int cols = (w / cell).ceil();
  final int rows = (h / cell).ceil();
  final double half = math.sqrt(math.pow(w / cols, 2) + math.pow(h / rows, 2)) / 2;
  final List<double> bases = List.filled(n, 0);
  double maxBase = 0;
  for (int i = 0; i < n; i++) {
    bases[i] = puddleBase(spots[i], tMs);
    if (bases[i] > maxBase) maxBase = bases[i];
  }
  final double B = cell * 2;
  final int nx = math.max(1, (w / B).ceil());
  final int ny = math.max(1, (h / B).ceil());
  final List<List<int>> buckets = List.generate(nx * ny, (_) => <int>[]);
  for (int i = 0; i < n; i++) {
    final int bx = clampD((spots[i].x / B).floorToDouble(), 0, nx - 1).toInt();
    final int by = clampD((spots[i].y / B).floorToDouble(), 0, ny - 1).toInt();
    buckets[by * nx + bx].add(i);
  }
  final int maxRing = math.max(nx, ny);
  double worst = 1;
  for (int iy = 0; iy < rows; iy++) {
    for (int ix = 0; ix < cols; ix++) {
      final double x = ((ix + 0.5) * w) / cols;
      final double y = ((iy + 0.5) * h) / rows;
      final int cbx = clampD((x / B).floorToDouble(), 0, nx - 1).toInt();
      final int cby = clampD((y / B).floorToDouble(), 0, ny - 1).toInt();
      double best = double.infinity;
      for (int r = 0; r <= maxRing; r++) {
        if (r >= 1 && ((r - 1) * B + half) / maxBase >= best) break;
        for (int gy = cby - r; gy <= cby + r; gy++) {
          if (gy < 0 || gy >= ny) continue;
          for (int gx = cbx - r; gx <= cbx + r; gx++) {
            if (gx < 0 || gx >= nx) continue;
            if (math.max((gx - cbx).abs(), (gy - cby).abs()) != r) continue;
            for (final int q in buckets[gy * nx + gx]) {
              final double need = (math.sqrt(math.pow(x - spots[q].x, 2) + math.pow(y - spots[q].y, 2)) + half) / bases[q];
              if (need < best) best = need;
            }
          }
        }
      }
      if (best > worst) worst = best;
    }
  }
  return worst * 1.01;
}

// ─────────────────────────────────────────────────────────────────────────────
// DROPLET physics
// ─────────────────────────────────────────────────────────────────────────────

const double kDropGravity = 4000; // px/s²
const double kDropEntryV = 250; // px/s
const double kDropMaxStretch = 0.2;
const double kDropStretchPerV = 1 / 10000;
const double kDropW = 22;
const double kDropH = 30;
const double kDropSquashMs = 220;
const double kDropFloodDelayMs = 50;
const double kDropFloodMs = 800;
const double kDropRippleMs = 900;
const double kDropRippleStaggerMs = 120;
const double kDropFloodEasePow = 3.5; // approximation of cubic-bezier drawer

class DropFrame {
  final double offsetT; // 0..1
  final double ty; // translateY px relative to initial y0
  final double sx, sy;
  const DropFrame(this.offsetT, this.ty, this.sx, this.sy);
}

class DropFallPlan {
  final List<DropFrame> frames;
  final double durationMs;
  final double impactSy;
  const DropFallPlan(this.frames, this.durationMs, this.impactSy);
}

DropFallPlan planDropFall(double cy) {
  final double distance = cy + 8;
  final double g = kDropGravity;
  final double v0 = kDropEntryV;
  final double T = (-v0 + math.sqrt(v0 * v0 + 2 * g * distance)) / g;
  final List<DropFrame> frames = [];
  double lastSy = 1;
  for (int i = 0, steps = 30; i <= steps; i++) {
    final double t = (T * i) / steps;
    final double s = v0 * t + 0.5 * g * t * t;
    final double sy = 1 + math.min(kDropMaxStretch, (v0 + g * t) * kDropStretchPerV);
    final double sx = 1 / math.sqrt(sy);
    lastSy = sy;
    frames.add(DropFrame(i / steps, s - distance, sx, sy));
  }
  return DropFallPlan(frames, T * 1000, lastSy);
}

/// Squash phases: 3 keyframes over squashMs.
/// Returns [sx, sy, opacity] at p in [0,1].
(double sx, double sy, double opacity) dropSquashFrame(double p, double impactSy) {
  // Phase 0→0.3: (1/√impactSy, impactSy) → (1.55, 0.5)
  // Phase 0.3→1:  (1.55, 0.5) → (2.4, 0.12), opacity 1→0
  if (p < 0.3) {
    final double q = p / 0.3;
    final double startSy = impactSy;
    final double startSx = 1 / math.sqrt(startSy);
    return (startSx + (1.55 - startSx) * q, startSy + (0.5 - startSy) * q, 1);
  } else {
    final double q = (p - 0.3) / 0.7;
    return (1.55 + (2.4 - 1.55) * q, 0.5 + (0.12 - 0.5) * q, 1 - q);
  }
}

/// Circle flood radius at progress p (0..1) using drawer curve.
double floodRadiusAt(double p, double R) {
  // Approximate cubic-bezier(0.32, 0.72, 0, 1) with pow
  final double ep = 1 - math.pow(1 - p, 2.2).toDouble();
  return ep * R;
}

// ─────────────────────────────────────────────────────────────────────────────
// RAIN physics
// ─────────────────────────────────────────────────────────────────────────────

const int kRainSpawnMs = 900;
const double kRainWindDeg = 9;
const double kRainPuddleArea = 85 * 85;
const int kRainMinPuddles = 30;
const int kRainMaxPuddles = 170;
const double kRainAmbientRatio = 1.4;
const double kRainSplashGravity = 2400;
const double kRainRippleMs = 420;
const double kRainMergeMs = 460;
const double kRainTailMs = 380;

class RainDrop {
  final double z;
  final double speed; // px/s
  final double len; // px
  final double width;
  final double alpha;
  final double x0, y0;
  final double landX, landY;
  final double spawnMs;
  final double landMs;
  final bool isPuddle;
  final bool isHero;
  final Spot? spot;
  bool landed;

  RainDrop({
    required this.z,
    required this.speed,
    required this.len,
    required this.width,
    required this.alpha,
    required this.x0,
    required this.y0,
    required this.landX,
    required this.landY,
    required this.spawnMs,
    required this.landMs,
    required this.isPuddle,
    this.isHero = false,
    this.spot,
    this.landed = false,
  });
}

class SplashParticle {
  double x, y, vx, vy;
  final double r;
  final double bornMs;
  final double lifeMs;
  SplashParticle({required this.x, required this.y, required this.vx, required this.vy, required this.r, required this.bornMs, required this.lifeMs});
}

class RippleRing {
  final double x, y, bornMs, rmax, z;
  RippleRing({required this.x, required this.y, required this.bornMs, required this.rmax, required this.z});
}

class RainPlan {
  final List<RainDrop> drops;
  final double tanWind;
  final double scale;
  final double mergeStartMs;
  final double mergeK;
  RainPlan({required this.drops, required this.tanWind, required this.scale, required this.mergeStartMs, required this.mergeK});
}

Spot _makeRainSpot(RainDrop d, double scale, math.Random rng) {
  final List<PuddleLobe> lobes = [];
  final int nl = 3 + rng.nextInt(3);
  for (int l = 0; l < nl; l++) {
    final double a = rng.nextDouble() * math.pi * 2;
    final double off = 0.55 + rng.nextDouble() * 0.3;
    lobes.add(PuddleLobe(math.cos(a) * off, math.sin(a) * off, 0.28 + rng.nextDouble() * 0.18));
  }
  final int ns = 2 + rng.nextInt(4);
  for (int m = 0; m < ns; m++) {
    final double a = rng.nextDouble() * math.pi * 2;
    final double off = 1.2 + rng.nextDouble() * 0.7;
    lobes.add(PuddleLobe(math.cos(a) * off, math.sin(a) * off, 0.06 + rng.nextDouble() * 0.08));
  }
  final double rmax = d.isHero
      ? 64 * scale * (0.9 + rng.nextDouble() * 0.25)
      : (10 + 38 * d.z) * scale * (0.9 + rng.nextDouble() * 0.25);
  return Spot(x: d.landX, y: d.landY, bornMs: d.landMs, r0: 1.5 + 2.5 * d.z, rmax: rmax, lobes: lobes);
}

/// Stratified random points (Poisson-ish, no large gaps).
List<({double x, double y})> _stratified(int n, double w, double h, math.Random rng) {
  final int cols = math.max(1, math.sqrt(n * w / h).round());
  final int rows = math.max(1, (n / cols).ceil());
  final List<(int, int)> cells = [for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++) (c, r)];
  for (int i = cells.length - 1; i > 0; i--) {
    final int j = rng.nextInt(i + 1);
    final tmp = cells[i]; cells[i] = cells[j]; cells[j] = tmp;
  }
  final double cw = w / cols, ch = h / rows;
  return cells.take(n).map((cr) => (x: (cr.$1 + rng.nextDouble()) * cw, y: (cr.$2 + rng.nextDouble()) * ch)).toList();
}

RainPlan planRain(double w, double h, double buttonX, double buttonY, math.Random rng) {
  final double tanWind = math.tan(kRainWindDeg * math.pi / 180);
  final int nP = clampD((w * h / kRainPuddleArea).roundToDouble(), kRainMinPuddles.toDouble(), kRainMaxPuddles.toDouble()).toInt();
  final int nA = (nP * kRainAmbientRatio).round();
  final double scale = clampD(math.sqrt(w * h / (1280 * 800)), 0.75, 1.35);

  RainDrop makeDrop(double z, double landX, double landY, bool puddle) {
    final double speed = 1300 + 1500 * z;
    final double len = (16 + 40 * z) * scale;
    final double y0 = -len - rng.nextDouble() * 80;
    final double spawnMs = kRainSpawnMs * math.sqrt(rng.nextDouble());
    final double x0 = landX - tanWind * (landY - y0);
    final double landMs = spawnMs + ((landY - y0) / speed) * 1000;
    return RainDrop(z: z, speed: speed, len: len, width: 0.8 + 1.4 * z, alpha: 0.3 + 0.6 * z, x0: x0, y0: y0, landX: landX, landY: landY, spawnMs: spawnMs, landMs: landMs, isPuddle: puddle);
  }

  final List<RainDrop> drops = [];
  for (final p in _stratified(nP, w, h, rng)) {
    drops.add(makeDrop(0.55 + rng.nextDouble() * 0.45, p.x, p.y, true));
  }
  for (int i = 0; i < nA; i++) {
    drops.add(makeDrop(0.1 + rng.nextDouble() * 0.4, (-0.05 + rng.nextDouble() * 1.1) * w, (0.05 + rng.nextDouble() * 0.97) * h, false));
  }
  // Hero drop lands on the button center
  {
    final double z = 1.0;
    final double speed = 1300 + 1500 * z;
    final double len = (16 + 40 * z) * scale;
    final double y0h = -len - rng.nextDouble() * 80;
    final double x0h = buttonX - tanWind * (buttonY - y0h);
    final double travel = ((buttonY - y0h) / speed) * 1000;
    final double heroLandMs = math.max(travel + 40, kRainSpawnMs * 0.55 + travel * 0.5);
    final double heroSpawnMs = heroLandMs - travel;
    drops.add(RainDrop(z: z, speed: speed, len: len, width: 0.8 + 1.4 * z, alpha: 0.3 + 0.6 * z, x0: x0h, y0: y0h, landX: buttonX, landY: buttonY, spawnMs: heroSpawnMs, landMs: heroLandMs, isPuddle: true, isHero: true));
  }

  // Assign spots
  double lastLandMs = 0;
  final List<Spot> spots = [];
  for (int i = 0; i < drops.length; i++) {
    final d = drops[i];
    if (!d.isPuddle) continue;
    if (d.landMs > lastLandMs) lastLandMs = d.landMs;
    final Spot spot = _makeRainSpot(d, scale, rng);
    drops[i] = RainDrop(z: d.z, speed: d.speed, len: d.len, width: d.width, alpha: d.alpha, x0: d.x0, y0: d.y0, landX: d.landX, landY: d.landY, spawnMs: d.spawnMs, landMs: d.landMs, isPuddle: d.isPuddle, isHero: d.isHero, spot: spot, landed: false);
    spots.add(spot);
  }
  final double mergeStartMs = lastLandMs + 40;
  final double mergeK = math.max(1.0, coverageScale(spots, mergeStartMs + kRainMergeMs, w, h));
  return RainPlan(drops: drops, tanWind: tanWind, scale: scale, mergeStartMs: mergeStartMs, mergeK: mergeK);
}

// ─────────────────────────────────────────────────────────────────────────────
// DIWALI physics
// ─────────────────────────────────────────────────────────────────────────────

const double kDiwaliLaunchGapMs = 45;
const double kDiwaliMinBurstDist = 110;
const double kDiwaliDragK = 2.4;
const double kDiwaliGravity = 40;
const double kDiwaliBloomTauMs = 420;
const double kDiwaliSettleMs = 300;
const double kDiwaliMergeMs = 440;
const double kDiwaliTrailSparksPerS = 110;

class Star {
  final double x0, y0, vx, vy;
  final double bornMs;
  final double r0, rmax;
  const Star({required this.x0, required this.y0, required this.vx, required this.vy, required this.bornMs, required this.r0, required this.rmax});
}

/// Closed-form star position under air drag + gravity.
({double x, double y}) starPos(Star d, double tMs) {
  final double age = math.max(0, (tMs - d.bornMs) / 1000);
  const double k = kDiwaliDragK;
  const double g = kDiwaliGravity;
  final double e = 1 - math.exp(-k * age);
  return (x: d.x0 + (d.vx / k) * e, y: d.y0 + (g / k) * age + ((d.vy - g / k) * e) / k);
}

double dotRadius(Star d, double tMs) {
  final double age = math.max(0, tMs - d.bornMs);
  return d.r0 + (d.rmax - d.r0) * (1 - math.exp(-age / kDiwaliBloomTauMs));
}

class Shell {
  final double x0, y0; // origin (button center)
  final double tx, ty; // burst target
  final double launchMs;
  final double flightMs;
  final double burstMs;
  final bool isRing;
  final bool crackle;
  final double speed;
  final double curve;
  final List<Star> stars;
  bool launched;
  bool burstDone;
  double sparkDebt;
  ({double x, double y})? prevPos;

  Shell({
    required this.x0, required this.y0, required this.tx, required this.ty,
    required this.launchMs, required this.flightMs, required this.burstMs,
    required this.isRing, required this.crackle, required this.speed, required this.curve,
    required this.stars,
    this.launched = false, this.burstDone = false, this.sparkDebt = 0, this.prevPos,
  });
}

class DiwaliSpark {
  double x, y, vx, vy;
  final double bornMs, lifeMs, size;
  DiwaliSpark({required this.x, required this.y, required this.vx, required this.vy, required this.bornMs, required this.lifeMs, required this.size});
}

class DiwaliPlan {
  final List<Shell> shells;
  final List<Star> stars;
  final Spot ignition;
  final double scale;
  final double mergeStartMs;
  final double mergeK;
  DiwaliPlan({required this.shells, required this.stars, required this.ignition, required this.scale, required this.mergeStartMs, required this.mergeK});
}

List<Star> _makeStars(Shell s, double scale, double cellR, math.Random rng) {
  final List<Star> stars = [];
  final int count = ((s.isRing ? 110 : 140) * math.sqrt(scale)).round();
  final double tilt = rng.nextDouble() * math.pi;
  final double squash = 0.45 + rng.nextDouble() * 0.35;
  for (int i = 0; i < count; i++) {
    final double a = (i / count) * math.pi * 2 + (rng.nextDouble() - 0.5) * 0.12;
    double v;
    if (s.isRing) {
      v = s.speed * (i % 3 != 0 ? (0.96 + rng.nextDouble() * 0.08) : math.sqrt(rng.nextDouble()));
    } else if (i % 2 == 1) {
      final double c = rng.nextDouble() * 2 - 1;
      v = s.speed * math.sqrt(1 - c * c) * (0.9 + rng.nextDouble() * 0.15);
    } else {
      v = s.speed * math.sqrt(rng.nextDouble()) * (0.95 + rng.nextDouble() * 0.10);
    }
    double vx = math.cos(a) * v;
    double vy = math.sin(a) * v;
    if (s.isRing && i % 3 != 0) {
      final double rx = vx;
      final double ry = vy * squash;
      vx = rx * math.cos(tilt) - ry * math.sin(tilt);
      vy = rx * math.sin(tilt) + ry * math.cos(tilt);
    }
    stars.add(Star(
      x0: s.tx, y0: s.ty, vx: vx, vy: vy, bornMs: s.burstMs,
      r0: 1.4 * math.min(1.3, scale + 0.2),
      rmax: cellR * 0.17 * (0.75 + rng.nextDouble() * 0.5),
    ));
  }
  return stars;
}

DiwaliPlan planDiwali(double w, double h, double originX, double originY, math.Random rng) {
  final double scale = clampD(math.sqrt(w * h / (1280 * 800)), 0.7, 1.3);
  final int target = clampD((w * h / 110000).roundToDouble(), 6, 14).toInt();
  final int cols = math.max(2, math.sqrt(target * w / h).round());
  final int rows = math.max(2, (target / cols).round());
  final double cw = w / cols;
  final double ch = h / rows;
  final double cellR = math.sqrt(cw * ch) / 2;
  final double reach = 1.25 * math.sqrt(cw * cw + ch * ch) / 2;
  final double minDist = kDiwaliMinBurstDist * scale;

  final List<({double x, double y, double d})> pts = [];
  for (int gy = 0; gy < rows; gy++) {
    for (int gx = 0; gx < cols; gx++) {
      double x = (gx + 0.5 + (rng.nextDouble() - 0.5) * 0.56) * cw;
      double y = (gy + 0.5 + (rng.nextDouble() - 0.5) * 0.56) * ch;
      double d = math.sqrt(math.pow(x - originX, 2) + math.pow(y - originY, 2));
      if (d < minDist) {
        final double a = d > 0.001 ? math.atan2(y - originY, x - originX) : rng.nextDouble() * math.pi * 2;
        x = originX + math.cos(a) * minDist;
        y = originY + math.sin(a) * minDist;
        d = minDist;
      }
      pts.add((x: x, y: y, d: d));
    }
  }
  pts.sort((a, b) => a.d.compareTo(b.d));

  final List<Shell> shells = [];
  for (int i = 0; i < pts.length; i++) {
    final p = pts[i];
    final double launchMs = i * kDiwaliLaunchGapMs + rng.nextDouble() * 25;
    final double flightMs = clampD(240 + p.d * 0.5, 300, 640);
    shells.add(Shell(
      x0: originX, y0: originY, tx: p.x, ty: p.y,
      launchMs: launchMs, flightMs: flightMs, burstMs: launchMs + flightMs,
      isRing: i % 4 == 3, crackle: rng.nextDouble() < 0.3,
      speed: reach * kDiwaliDragK * (0.92 + rng.nextDouble() * 0.16),
      curve: (rng.nextDouble() - 0.5) * 0.24 * p.d,
      stars: [],
    ));
  }

  final List<Star> allStars = [];
  for (final s in shells) {
    s.stars.addAll(_makeStars(s, scale, cellR, rng));
    allStars.addAll(s.stars);
  }

  final Spot ignition = Spot(x: originX, y: originY, bornMs: 0, r0: 28, rmax: 52 * math.max(1.0, scale), tauMs: 160, creepPxPerS: 0, lobes: []);

  final double lastBurstMs = shells.fold(0.0, (m, s) => math.max(m, s.burstMs));
  final double mergeStartMs = lastBurstMs + kDiwaliSettleMs;
  final double tEnd = mergeStartMs + kDiwaliMergeMs;

  final List<Spot> final_ = allStars.map((d) {
    final p = starPos(d, tEnd);
    final double r = dotRadius(d, tEnd);
    return Spot(x: p.x, y: p.y, bornMs: 0, r0: r, rmax: r, tauMs: 1, creepPxPerS: 0);
  }).toList();
  final_.add(ignition);

  final double mergeK = math.max(1.0, coverageScale(final_, tEnd, w, h));
  return DiwaliPlan(shells: shells, stars: allStars, ignition: ignition, scale: scale, mergeStartMs: mergeStartMs, mergeK: mergeK);
}

/// Rocket position at time t (ms since toggle).
({double x, double y}) rocketPos(Shell s, double tMs) {
  final double p = clampD((tMs - s.launchMs) / s.flightMs, 0, 1);
  final double e = 1 - (1 - p) * (1 - p);
  final double dx = s.tx - s.x0;
  final double dy = s.ty - s.y0;
  final double len = math.sqrt(dx * dx + dy * dy);
  final double safLen = len < 0.001 ? 1 : len;
  final double bow = math.sin(math.pi * e) * s.curve;
  return (x: s.x0 + dx * e - (dy / safLen) * bow, y: s.y0 + dy * e + (dx / safLen) * bow);
}

// ─────────────────────────────────────────────────────────────────────────────
// Button spring simulation (simple damped oscillator)
// ─────────────────────────────────────────────────────────────────────────────

class ButtonSpring {
  static const double _zeta = 0.35; // damping ratio
  static const double _omega = 2 * math.pi / 0.52; // natural frequency (rad/s)
  static final double _wd = _omega * math.sqrt(1 - _zeta * _zeta);

  /// Returns scale at [ageSeconds] after the press started, compressing to [depth] fraction.
  static double scale(double ageSeconds, {double depth = 0.08}) {
    // Press: 0..0.09s → compress to (1-depth)
    if (ageSeconds < 0.09) {
      return 1 - depth * (ageSeconds / 0.09);
    }
    // Spring release from compressed state
    final double t = ageSeconds - 0.09;
    final double compressed = 1 - depth;
    final double x = 1 - math.exp(-_zeta * _omega * t) * (math.cos(_wd * t) + (_zeta * _omega / _wd) * math.sin(_wd * t));
    return compressed + (1 - compressed) * x;
  }
}
