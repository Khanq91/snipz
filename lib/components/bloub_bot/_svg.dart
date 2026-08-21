// Part of bloub_bot — SVG export: a standalone still of ANY state, and the
// animated SVG of the resting avatar (CSS keyframes on the two eye matrices,
// browser-interpolated). Mirrors the upstream export pipeline
// (src/ui/export.ts + anime.ts of jeremy-prt/bloub, MIT) with one
// difference: upstream serializes the live DOM; here the frame model is
// serialized directly — same markup, no DOM. Pure Dart, string building
// only: usable from tests and from any isolate.

import '_decor.dart';
import '_engine.dart';
import '_expressions.dart';
import '_shape.dart';
import '_skins.dart';
import '_states.dart';

/// Half side of the tight export frame, in viewBox units. Tighter than the
/// screen viewBox (158) on purpose: the screen margin houses the animated
/// states' rings, which do not exist at rest — keeping it would export an
/// image 63% empty, a tiny ball inside a profile-picture crop. 8% margin so
/// circular crops (Discord/Slack/GitHub) do not bite the silhouette.
/// ceil(100 x 1.15 x 1.08): the widest customizer shape is the squircle,
/// whose peak radius is normalized to 1.15. One frame for all eight shapes —
/// per-shape recropping would undo their to-the-eye weight normalization.
const double kBotDemiCadre = 125;

const double _tension = 1 / 6;

/// Short rounding: halves the weight of generated path strings (upstream r2).
String _n(double v) {
  final double r = (v * 100).roundToDouble() / 100;
  if (r == r.roundToDouble()) return r.toInt().toString();
  return r.toString();
}

String _hex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Closed polyline -> Catmull-Rom cubics, the same construction the painter
/// uses — one source of truth for the outline in both renderers would need a
/// shared Path type; the numbers are identical.
String _closedPathD(List<BotPoint> pts) {
  final int n = pts.length;
  if (n < 3) return '';
  final StringBuffer d = StringBuffer('M${_n(pts[0].x)} ${_n(pts[0].y)}');
  for (int i = 0; i < n; i++) {
    final BotPoint p0 = pts[(i - 1 + n) % n];
    final BotPoint p1 = pts[i];
    final BotPoint p2 = pts[(i + 1) % n];
    final BotPoint p3 = pts[(i + 2) % n];
    d.write('C${_n(p1.x + (p2.x - p0.x) * _tension)} '
        '${_n(p1.y + (p2.y - p0.y) * _tension)} '
        '${_n(p2.x - (p3.x - p1.x) * _tension)} '
        '${_n(p2.y - (p3.y - p1.y) * _tension)} '
        '${_n(p2.x)} ${_n(p2.y)}');
  }
  d.write('Z');
  return d.toString();
}

/// Capsule (stadium) centered on the origin: the exact eye shape.
String _capsuleD(double w, double h) {
  final double hw = (w < 0.01 ? 0.01 : w) / 2;
  final double hh = (h < 0.01 ? 0.01 : h) / 2;
  final double r = hw < hh ? hw : hh;
  return 'M${_n(-hw)} ${_n(-hh + r)}'
      'A${_n(r)} ${_n(r)} 0 0 1 ${_n(-hw + r)} ${_n(-hh)}'
      'L${_n(hw - r)} ${_n(-hh)}'
      'A${_n(r)} ${_n(r)} 0 0 1 ${_n(hw)} ${_n(-hh + r)}'
      'L${_n(hw)} ${_n(hh - r)}'
      'A${_n(r)} ${_n(r)} 0 0 1 ${_n(hw - r)} ${_n(hh)}'
      'L${_n(-hw + r)} ${_n(hh)}'
      'A${_n(r)} ${_n(r)} 0 0 1 ${_n(-hw)} ${_n(hh - r)}Z';
}

/// Exact closed polyline (keeps straight edges — teardrop shapes).
String _polyD(List<BotPoint> pts, double scale) {
  if (pts.length < 3) return '';
  final StringBuffer d = StringBuffer();
  for (int i = 0; i < pts.length; i++) {
    d.write('${i == 0 ? 'M' : 'L'}${_n(pts[i].x * scale)} '
        '${_n(pts[i].y * scale)}');
  }
  d.write('Z');
  return d.toString();
}

String _runsD(List<List<BotPoint>> runs) {
  final StringBuffer d = StringBuffer();
  for (final List<BotPoint> run in runs) {
    for (int i = 0; i < run.length; i++) {
      d.write('${i == 0 ? 'M' : 'L'}${_n(run[i].x)} ${_n(run[i].y)}');
    }
  }
  return d.toString();
}

String _eyeMatrix(BotRenderedEye e) =>
    'matrix(${_n(e.a)},${_n(e.b)},${_n(e.c)},${_n(e.d)},${_n(e.tx)},${_n(e.ty)})';

/// One [BotFrame] as a standalone SVG document. Same structure and draw
/// order as the live renderer: back arcs, behind-dots, paper backing +
/// masked ink (the eyes are REAL HOLES in the mask — they export opaque in
/// [paperArgb], deliberately: on a dark page real transparency would make
/// them disappear), front dots, pastille, front arcs.
///
/// [eyesAsClasses] replaces each eye's transform with class="oeil0"/"oeil1"
/// so the animated export can drive them from CSS keyframes.
String bloubBotFrameSvg(
  BotFrame frame, {
  int size = 512,
  double demiFrame = kBotDemiViewbox,
  int inkArgb = 0xFF0A0A0C,
  int paperArgb = 0xFFF9F9F9,
  bool eyesAsClasses = false,
}) {
  final String ink = _hex(inkArgb);
  final String paper = _hex(paperArgb);
  final String vb =
      '${_n(-demiFrame)} ${_n(-demiFrame)} ${_n(demiFrame * 2)} ${_n(demiFrame * 2)}';
  final String bodyD = _closedPathD(frame.body);
  final StringBuffer s = StringBuffer();
  // width/height are explicit and not cosmetic: without an intrinsic size
  // Firefox refuses to rasterize an SVG loaded into an <img>.
  s.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="$vb" '
      'width="$size" height="$size">');

  // --- defs: the mask (body white, eyes/notch black) + arc gradients ------
  s.write('<defs><mask id="bot-mask" maskUnits="userSpaceOnUse" '
      'x="${_n(-demiFrame)}" y="${_n(-demiFrame)}" '
      'width="${_n(demiFrame * 2)}" height="${_n(demiFrame * 2)}">');
  s.write('<path d="$bodyD" fill="#fff"/>');
  for (int i = 0; i < frame.eyes.length; i++) {
    final BotRenderedEye e = frame.eyes[i];
    final String place =
        eyesAsClasses ? 'class="oeil$i"' : 'transform="${_eyeMatrix(e)}"';
    s.write('<path d="${_capsuleD(e.w, e.h)}" $place '
        'opacity="${_n(e.alpha)}" fill="#000"/>');
  }
  final BotCircleRender? notch = frame.notch;
  if (notch != null) {
    s.write('<circle cx="${_n(notch.x)}" cy="${_n(notch.y)}" '
        'r="${_n(notch.r)}" fill="#000"/>');
  }
  s.write('</mask>');
  for (final BotArcRender arc in frame.arcs) {
    s.write('<linearGradient id="g-${arc.id}" gradientUnits="userSpaceOnUse" '
        'x1="${_n(arc.gradX1)}" y1="${_n(arc.gradY1)}" '
        'x2="${_n(arc.gradX2)}" y2="${_n(arc.gradY2)}">');
    for (int i = 0; i < arc.gradArgb.length; i++) {
      s.write('<stop offset="${_n(i / (arc.gradArgb.length - 1))}" '
          'stop-color="${_hex(arc.gradArgb[i])}"/>');
    }
    s.write('</linearGradient>');
  }
  s.write('</defs>');

  String arcPath(BotArcRender arc, List<List<BotPoint>> runs) =>
      '<path d="${_runsD(runs)}" fill="none" stroke="url(#g-${arc.id})" '
      'stroke-width="${_n(arc.width)}" stroke-linecap="round" '
      'opacity="${_n(arc.opacity)}"/>';

  // back half of the orbits: drawn before the body, hence occluded
  for (final BotArcRender arc in frame.arcs) {
    if (arc.back.isNotEmpty) s.write(arcPath(arc, arc.back));
  }

  String dots() {
    final StringBuffer out = StringBuffer();
    for (final BotDot dot in frame.dots) {
      final String fill = dot.colorArgb != null
          ? _hex(dot.colorArgb!)
          : (dot.depth == null ? ink : _mix(paperArgb, inkArgb, dot.depth!));
      final List<BotPoint>? shape = dot.shape;
      if (shape != null) {
        out.write('<path d="${_polyD(shape, kBotRayon)}" fill="$fill" '
            'opacity="${_n(dot.opacity)}" '
            'transform="translate(${_n(dot.x)} ${_n(dot.y)}) '
            'rotate(${_n(dot.rotDeg)})"/>');
      } else {
        out.write('<circle cx="${_n(dot.x)}" cy="${_n(dot.y)}" '
            'r="${_n(dot.r)}" fill="$fill" opacity="${_n(dot.opacity)}"/>');
      }
    }
    return out.toString();
  }

  if (frame.dotsBehind) s.write(dots());

  // Opaque backing in the page color under the body, then the ink through
  // the mask: holes show what is behind, and the back arcs/particles are
  // exactly what must NOT show through the eyes.
  s.write('<g opacity="${_n(frame.bodyAlpha)}">');
  s.write('<path d="$bodyD" fill="$paper"/>');
  s.write('<g mask="url(#bot-mask)">');
  s.write('<rect x="${_n(-demiFrame)}" y="${_n(-demiFrame)}" '
      'width="${_n(demiFrame * 2)}" height="${_n(demiFrame * 2)}" '
      'fill="$ink"/>');
  s.write('</g></g>');

  if (!frame.dotsBehind) s.write(dots());

  final BotCircleRender? notif = frame.notif;
  if (notif != null) {
    s.write('<circle cx="${_n(notif.x)}" cy="${_n(notif.y)}" '
        'r="${_n(notif.r)}" fill="${_hex(kBotNotifBlue)}"/>');
  }

  for (final BotArcRender arc in frame.arcs) {
    if (arc.front.isNotEmpty) s.write(arcPath(arc, arc.front));
  }

  s.write('</svg>');
  return s.toString();
}

String _mix(int a, int b, double t) {
  int ch(int shift) {
    final int ca = (a >> shift) & 0xFF;
    final int cb = (b >> shift) & 0xFF;
    return (ca + (cb - ca) * t).round();
  }

  return _hex((ch(16) << 16) | (ch(8) << 8) | ch(0));
}

/// Standalone still SVG of [state], frozen [at] seconds in (defaults to that
/// state's most readable instant, [botStatePoses]). Any state exports — the
/// upstream app only exports the resting avatar; the frame model makes the
/// whole catalog free.
String bloubBotSvg({
  BloubBotState state = BloubBotState.idle,
  double? at,
  int size = 512,
  double demiFrame = kBotDemiViewbox,
  int inkArgb = 0xFF0A0A0C,
  int paperArgb = 0xFFF9F9F9,
  String? expression,
  String? shape,
}) {
  final BotFrame frame = BloubBotEngine(
    initial: state,
    shape: shape == null ? null : botShapeById[shape]?.radii,
    expression: expression == null ? null : botExpressionById[expression],
  ).sample(at ?? botStatePoses[state]!);
  return bloubBotFrameSvg(frame,
      size: size,
      demiFrame: demiFrame,
      inkArgb: inkArgb,
      paperArgb: paperArgb);
}

/// KEY frames per second — not a playback rate: the browser interpolates
/// between keys, so motion is smooth at the screen's refresh rate whatever
/// their number. 30/s costs almost nothing (a key is a text matrix) and
/// follows the blink curve faithfully (fast close, slower reopen).
const int kBotAnimKeysPerSec = 30;

/// Captured duration. The first blink lands at 1.4 s and the next every
/// 1.9-4.6 s: three seconds always contain at least one. Shorter would often
/// export a ball that merely drifts.
const double kBotAnimSeconds = 3;

/// Animated SVG of the RESTING avatar: the body stays still, the two eyes
/// live (gaze drift + blinks) via CSS @keyframes on their transform
/// matrices. Same feasibility boundary as upstream, and it is measured:
/// body-morphing states change the body path (~2.5 KB) every frame — 600
/// frames make 1.5 MB before the arcs — so animated SVG only holds where the
/// silhouette is still.
///
/// The loop is seamless despite a non-periodic drift:
/// `animation-direction: alternate` plays it forward then backward, so it
/// closes on itself exactly — and a blink in reverse is still a blink.
String bloubBotAnimatedSvg({
  int size = 512,
  double demiFrame = kBotDemiCadre,
  int inkArgb = 0xFF0A0A0C,
  int paperArgb = 0xFFF9F9F9,
  int keysPerSec = kBotAnimKeysPerSec,
  double seconds = kBotAnimSeconds,
  String? expression,
  String? shape,
}) {
  final BloubBotEngine engine = BloubBotEngine(
    shape: shape == null ? null : botShapeById[shape]?.radii,
    expression: expression == null ? null : botExpressionById[expression],
  );
  final int frames = (keysPerSec * seconds).round();
  final double step = 1 / keysPerSec;

  // keys: one transform matrix per eye per frame
  final List<List<String>> keys = [];
  for (int i = 0; i < frames; i++) {
    final BotFrame f = engine.sample(i * step);
    if (f.eyes.length != 2) {
      throw StateError('resting avatar must keep both eyes visible');
    }
    keys.add([for (final BotRenderedEye e in f.eyes) _eyeMatrix(e)]);
  }

  final String base = bloubBotFrameSvg(engine.sample(0),
      size: size,
      demiFrame: demiFrame,
      inkArgb: inkArgb,
      paperArgb: paperArgb,
      eyesAsClasses: true);

  final double duration = (frames - 1) * step;
  final double pas = 100 / (frames - 1);
  final StringBuffer style = StringBuffer('<style>');
  // transform-box/transform-origin are not decorative: without them a CSS
  // transform on an SVG element rotates around its box center instead of
  // the viewBox origin, and the eye flies to the other side of the ball.
  style.write('.oeil0,.oeil1{transform-box:view-box;transform-origin:0 0;'
      'animation-duration:${duration.toStringAsFixed(3)}s;'
      'animation-iteration-count:infinite;'
      'animation-timing-function:linear;animation-direction:alternate}');
  for (int eye = 0; eye < 2; eye++) {
    style.write('.oeil$eye{animation-name:oeil$eye}');
  }
  for (int eye = 0; eye < 2; eye++) {
    style.write('@keyframes oeil$eye{');
    for (int i = 0; i < frames; i++) {
      style.write(
          '${_n(i * pas)}%{transform:${keys[i][eye]}}');
    }
    style.write('}');
  }
  style.write('</style>');

  return base.replaceFirst('</svg>', '$style</svg>');
}
