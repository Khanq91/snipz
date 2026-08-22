// Geometry of the jelly blob, transcribed 1:1 from the upstream SVG
// (viewBox 0 0 900 720). The body silhouette is kept as a structured point
// list — one start point + 14 cubic segments — so the idle bottom-wave, the
// sad melt and every in-between morph stay interpolation-compatible, exactly
// like upstream's `bottomWave` / `lerpPath` pair.

import 'dart:math' as math;
import 'dart:ui';

/// The design space every coordinate below lives in.
const Size kJellyViewBox = Size(900, 720);

// ── body silhouette ─────────────────────────────────────────────────────────

/// One body silhouette: start point + 42 cubic control/end points
/// (14 `C` segments). All silhouettes share this structure.
class JellyBodyGeom {
  JellyBodyGeom(this.start, this.pts) : assert(pts.length == 42);
  final Offset start;
  final List<Offset> pts;

  Path toPath() {
    final Path p = Path()..moveTo(start.dx, start.dy);
    for (int i = 0; i < pts.length; i += 3) {
      p.cubicTo(pts[i].dx, pts[i].dy, pts[i + 1].dx, pts[i + 1].dy,
          pts[i + 2].dx, pts[i + 2].dy);
    }
    p.close();
    return p;
  }

  /// a + (b - a) * t, element-wise — upstream's numeric `lerpPath`.
  static JellyBodyGeom lerp(JellyBodyGeom a, JellyBodyGeom b, double t) {
    if (t <= 0.0001) return a;
    if (t >= 0.9999) return b;
    return JellyBodyGeom(
      Offset.lerp(a.start, b.start, t)!,
      List<Offset>.generate(42, (i) => Offset.lerp(a.pts[i], b.pts[i], t)!),
    );
  }
}

/// Rigid top of the neutral silhouette: 3 cubic segments (9 points) from the
/// start (450,135) down the right side to (686,462).
const List<Offset> kJellyNeutralTop = [
  Offset(520, 137), Offset(580, 158), Offset(618, 200),
  Offset(652, 240), Offset(672, 290), Offset(680, 345),
  Offset(686, 390), Offset(688, 425), Offset(686, 462),
];

/// Lower rim, 11 cubic segments (33 points); the last point closes back onto
/// the start. The wave displaces these, weighted toward the two "feet".
const List<Offset> kJellyNeutralBottom = [
  Offset(684, 505), Offset(676, 530), Offset(658, 552), // right lower
  Offset(641, 569), Offset(627, 580), Offset(602, 583), // right lobe
  Offset(578, 585), Offset(561, 578), Offset(536, 577),
  Offset(510, 576), Offset(482, 585), Offset(450, 585), // bottom-centre
  Offset(418, 585), Offset(390, 576), Offset(364, 577),
  Offset(339, 578), Offset(323, 585), Offset(298, 583), // left lobe
  Offset(273, 580), Offset(259, 569), Offset(242, 552), // left lower
  Offset(224, 530), Offset(216, 505), Offset(214, 462), // rigid left side
  Offset(212, 425), Offset(214, 390), Offset(220, 345),
  Offset(228, 290), Offset(248, 240), Offset(282, 200),
  Offset(320, 158), Offset(380, 137), Offset(450, 135), // back to start
];

/// SAD melt — same 14-segment structure so neutral->sad lerps smoothly.
final JellyBodyGeom kJellySadGeom = JellyBodyGeom(const Offset(450, 168), const [
  Offset(516, 169), Offset(568, 188), Offset(604, 222),
  Offset(640, 258), Offset(662, 308), Offset(672, 364),
  Offset(678, 408), Offset(682, 444), Offset(680, 482),
  Offset(678, 522), Offset(668, 548), Offset(646, 566),
  Offset(628, 582), Offset(606, 590), Offset(580, 590),
  Offset(554, 590), Offset(530, 582), Offset(504, 583),
  Offset(482, 584), Offset(467, 593), Offset(450, 593),
  Offset(433, 593), Offset(418, 584), Offset(396, 583),
  Offset(370, 582), Offset(346, 590), Offset(320, 590),
  Offset(294, 590), Offset(272, 582), Offset(254, 566),
  Offset(232, 548), Offset(222, 522), Offset(220, 482),
  Offset(218, 444), Offset(222, 408), Offset(228, 364),
  Offset(238, 308), Offset(260, 258), Offset(296, 222),
  Offset(332, 188), Offset(384, 169), Offset(450, 168),
]);

const double _rippleAmp = 10; // gentle vertical bob at the two "feet"
const double _sloshAmp = 4; // very subtle side slip
const double _wobbleK = 0.016; // ~1.4 humps across the width

// 0 at/above the cheeks (y ~= 440), 1 at the lowest edge.
double _lowness(double y) => ((y - 440) / 145).clamp(0.0, 1.0);
// 0.3 at centre, 1 toward the lower lobes — the bottom reads as two feet
// that bob rather than one heaving mass.
double _legBias(double x) => 0.3 + 0.7 * math.min(1, (x - 450).abs() / 150);

/// The idle neutral silhouette with the bottom wave applied. [amt] (0..1)
/// fades the wobble in/out during mood transitions.
JellyBodyGeom jellyWaveGeom(double phase, double amt) {
  final List<Offset> pts = List<Offset>.of(kJellyNeutralTop, growable: true);
  for (final Offset p in kJellyNeutralBottom) {
    final double w = _lowness(p.dy) * _legBias(p.dx) * amt;
    pts.add(Offset(
      p.dx +
          w *
              (_sloshAmp * math.sin(phase) +
                  _rippleAmp * 0.22 * math.cos(_wobbleK * p.dx + phase)),
      p.dy + w * _rippleAmp * math.sin(_wobbleK * p.dx + phase),
    ));
  }
  return JellyBodyGeom(const Offset(450, 135), pts);
}

/// The neutral silhouette at rest (wave amplitude 0).
final JellyBodyGeom kJellyNeutralGeom = jellyWaveGeom(0, 0);

// ── mouths ──────────────────────────────────────────────────────────────────
// Every mood mouth is `M x y C x1 y1 x2 y2 x3 y3` — 8 numbers, so mouths
// morph by plain numeric lerp with a spring.

const Map<int, List<double>> kJellyMouths = {
  // indexed by JellyBlobMood.index (neutral, happy, sad, angry, hmm,
  // sideEye, password — see _engine.dart)
  0: [431, 409, 437, 429, 466, 429, 473, 409], // neutral
  1: [420, 402, 435, 448, 470, 448, 485, 402], // happy
  2: [431, 424, 440, 414, 464, 414, 473, 424], // sad
  3: [431, 416, 443, 422, 461, 422, 473, 416], // angry
  4: [431, 418, 443, 420, 461, 414, 473, 411], // hmm
  5: [432, 418, 445, 418, 461, 415, 474, 409], // sideEye
  6: [452, 416, 452, 416, 452, 416, 452, 416], // password (collapsed dot)
};

/// Talking mouths — 5 looping keyframes each (last == first), every frame
/// `M + 3 C + Z` = 20 numbers, morphed by numeric lerp.
const List<List<double>> kJellyTalkOpen = [
  [441, 410, 447, 405, 457, 405, 463, 410, 466, 417, 462, 424, 452, 424, 442, 424, 438, 417, 441, 410],
  [436, 408, 443, 400, 462, 400, 469, 408, 474, 421, 466, 434, 452, 434, 438, 434, 431, 421, 436, 408],
  [439, 413, 445, 408, 461, 408, 467, 413, 469, 423, 463, 430, 452, 430, 441, 430, 435, 423, 439, 413],
  [434, 411, 441, 404, 464, 404, 471, 411, 474, 422, 466, 432, 452, 432, 438, 432, 431, 422, 434, 411],
  [441, 410, 447, 405, 457, 405, 463, 410, 466, 417, 462, 424, 452, 424, 442, 424, 438, 417, 441, 410],
];

const List<List<double>> kJellyTalkWide = [
  [438, 410, 445, 404, 460, 404, 467, 410, 472, 421, 465, 432, 452, 432, 439, 432, 433, 421, 438, 410],
  [431, 407, 440, 398, 465, 398, 474, 407, 481, 424, 469, 439, 452, 439, 435, 439, 424, 424, 431, 407],
  [428, 413, 438, 404, 467, 404, 477, 413, 479, 426, 468, 435, 452, 435, 436, 435, 426, 426, 428, 413],
  [434, 409, 442, 401, 463, 401, 471, 409, 477, 423, 467, 437, 452, 437, 437, 437, 428, 423, 434, 409],
  [438, 410, 445, 404, 460, 404, 467, 410, 472, 421, 465, 432, 452, 432, 439, 432, 433, 421, 438, 410],
];

/// Builds a talk-mouth path from its 20 numbers.
Path jellyTalkPath(List<double> v) => Path()
  ..moveTo(v[0], v[1])
  ..cubicTo(v[2], v[3], v[4], v[5], v[6], v[7])
  ..cubicTo(v[8], v[9], v[10], v[11], v[12], v[13])
  ..cubicTo(v[14], v[15], v[16], v[17], v[18], v[19])
  ..close();

// ── static decoration paths (upstream `d` strings, parsed once) ─────────────

/// Minimal absolute-command SVG path parser: M, C, L, Z. Enough for every
/// static shape below; ellipses/circles are drawn directly by the painter.
Path jellyParsePath(String d) {
  final Path path = Path();
  final RegExp tok = RegExp(r'[MCLZ]|-?\d+(?:\.\d+)?');
  final List<String> tokens =
      tok.allMatches(d).map((m) => m.group(0)!).toList();
  int i = 0;
  double num_() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    final String cmd = tokens[i++];
    switch (cmd) {
      case 'M':
        path.moveTo(num_(), num_());
      case 'L':
        path.lineTo(num_(), num_());
      case 'C':
        path.cubicTo(num_(), num_(), num_(), num_(), num_(), num_());
      case 'Z':
        path.close();
    }
  }
  return path;
}

class JellyStaticPaths {
  JellyStaticPaths._();
  static final JellyStaticPaths instance = JellyStaticPaths._();

  // arms (nubs)
  final Path armLeft = jellyParsePath(
      'M216 380 C195 380 180 396 180 416 C180 438 195 452 216 452 C237 452 250 438 250 416 C250 396 237 380 216 380 Z');
  final Path armRight = jellyParsePath(
      'M684 380 C705 380 720 396 720 416 C720 438 705 452 684 452 C663 452 650 438 650 416 C650 396 663 380 684 380 Z');
  final Path armLeftShadow =
      jellyParsePath('M234 396 C214 402 208 428 220 446');
  final Path armRightShadow =
      jellyParsePath('M666 396 C686 402 692 428 680 446');

  // clipped body shading strokes
  final Path leftInnerShine = jellyParsePath('M300 210C262 300 258 430 286 512');
  final Path rightInnerShade = jellyParsePath('M672 270C698 360 684 500 616 548');

  // happy ^_^ arcs (happyEyes: smile)
  final Path happyArcLeft = jellyParsePath('M325 380 C341 330 365 330 381 380');
  final Path happyArcRight = jellyParsePath('M523 380 C539 330 563 330 579 380');

  // happy 4-point star glints (happyEyes: star)
  final Path eyeStarLeft = jellyParsePath(
      'M364 340 C366.4 349.4 367.6 350.6 377 353 C367.6 355.4 366.4 356.6 364 366 C361.6 356.6 360.4 355.4 351 353 C360.4 350.6 361.6 349.4 364 340 Z');
  final Path eyeStarRight = jellyParsePath(
      'M540 340 C542.4 349.4 543.6 350.6 553 353 C543.6 355.4 542.4 356.6 540 366 C537.6 356.6 536.4 355.4 527 353 C536.4 350.6 537.6 349.4 540 340 Z');

  // password closed eyes (curved DOWN — looking away, not happy-closed)
  final Path passwordEyeLeft = jellyParsePath('M314 353 C331 365 355 365 372 353');
  final Path passwordEyeRight = jellyParsePath('M520 353 C537 365 561 365 578 353');

  // sideEye sly brows
  final Path sideEyeBrowLeft = jellyParsePath('M314 357 C331 337 353 336 372 351');
  final Path sideEyeBrowRight = jellyParsePath('M520 357 C537 337 559 336 578 351');

  // hmm heavy lids
  final Path hmmLidLeft = jellyParsePath('M324 345 C342 336 365 337 383 345');
  final Path hmmLidRight = jellyParsePath('M521 345 C541 336 564 337 581 345');

  // sad brows
  final Path sadBrowLeft = jellyParsePath('M318 342 C342 328 370 324 392 331');
  final Path sadBrowRight = jellyParsePath('M512 331 C534 324 562 328 586 342');

  // happy open mouth
  final Path happyMouthFill = jellyParsePath(
      'M420 402 C440 384 465 384 485 402 C470 446 435 446 420 402 Z');
  final Path happyMouthTongue = jellyParsePath(
      'M438 424 C440 442 465 442 467 424 C462 418 444 418 438 424 Z');

  // sad tears
  final Path tearLeft = jellyParsePath(
      'M335 397 C324 414 326 428 338 434 C351 427 349 413 335 397Z');
  final Path tearRight = jellyParsePath(
      'M570 397 C559 414 561 428 573 434 C586 427 584 413 570 397Z');

  // angry scratch marks (three strokes, one multi-subpath path)
  final Path angryMarks = jellyParsePath(
      'M617 286 L639 268 M636 292 L660 287 M630 313 L653 329');

  // happy floating decor
  final Path happySpark = jellyParsePath(
      'M636 318 C638 332 642 336 656 338 C642 340 638 344 636 358 C634 344 630 340 616 338 C630 336 634 332 636 318 Z');
  final Path happyHeart = jellyParsePath(
      'M270 326 C264 318 252 320 252 331 C252 341 263 348 270 354 C277 348 288 341 288 331 C288 320 276 318 270 326 Z');
}

// ── pivots (transform origins measured off the fill-boxes upstream) ─────────

const Offset kJellyPivotOuter = Offset(450, 600); // whole blob, center bottom
const Offset kJellyPivotNod = Offset(450, 497); // center 78%
const Offset kJellyPivotBody = Offset(450, 585); // body, center bottom
const Offset kJellyPivotFace = Offset(452, 390);
const Offset kJellyPivotBelly = Offset(450, 504);
const Offset kJellyPivotHeadHighlight = Offset(450, 330);
const Offset kJellyPivotGloss = Offset(385, 220);
const Offset kJellyPivotEyes = Offset(452, 371);
const Offset kJellyPivotEyeLeft = Offset(353, 371);
const Offset kJellyPivotEyeRight = Offset(551, 371);
const Offset kJellyPivotCheekLeft = Offset(309, 430);
const Offset kJellyPivotCheekRight = Offset(617, 430);
const Offset kJellyPivotStarLeft = Offset(364, 353);
const Offset kJellyPivotStarRight = Offset(540, 353);
const Offset kJellyPivotArcLeft = Offset(353, 380); // center bottom of the arc
const Offset kJellyPivotArcRight = Offset(551, 380);
const Offset kJellyPivotMouth = Offset(452, 420);
const Offset kJellyPivotFx = Offset(452, 350);
const Offset kJellyPivotArmLeft = Offset(229, 407); // upstream LEFT_ARM_PIVOT
const Offset kJellyPivotArmRight = Offset(671, 407);

/// Curated asymmetric arm rest poses (dx, dy, rot-degrees) picked once per
/// widget by `seed`. Small enough to stack on the mood poses without pulling
/// a nub off the body.
const List<List<double>> kJellyArmRestPoses = [
  // lDx, lDy, lRot, rDx, rDy, rRot
  [-2, 3, -5, 2, -2, 3],
  [1, -3, 5, -2, 4, -6],
  [-3, 4, -4, 1, 1, 6],
  [3, -1, 6, -3, 2, -3],
  [-1, 2, -6, 2, -3, 4],
  [2, 5, 3, -2, -2, -5],
];
