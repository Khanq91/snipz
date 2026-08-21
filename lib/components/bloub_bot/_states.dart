// Part of bloub_bot — the state catalog: what the bot can do, each state a
// pure pose(t). Mirrors the upstream src/bot/states.ts (jeremy-prt/bloub,
// MIT). Pure Dart, no Flutter imports. All constants are measurements taken
// off the reference video — do not round them.

import 'dart:math' as math;

import '_decor.dart';
import '_face.dart';
import '_math.dart';
import '_profiles.dart';
import '_shape.dart';

/// The full catalog, mapped on the reference video. `swirl` is an interface
/// transition upstream, not a catalog animation: it stays out of
/// [botSequence].
enum BloubBotState {
  idle,
  thinking,
  wink,
  wide,
  alert,
  notify,
  exclaim,
  sleep,
  egg,
  hexagon,
  play,
  orbit,
  swirl,
  burst,
  comet,
}

/// Everything one frame of a state declares, before transitions and
/// resting-life are layered on by the engine.
class BotPose {
  const BotPose({
    required this.sil,
    this.offX = 0,
    this.offY = 0,
    this.gaze = kBotRestGaze,
    this.split = kBotEyeSplit,
    this.eyes = const [
      BotEyeCfg(w: kBotEyeW, h: kBotEyeH),
      BotEyeCfg(w: kBotEyeW, h: kBotEyeH),
    ],
    this.eyeAlpha = 1,
    this.bodyAlpha = 1,
    this.dots = const [],
    this.arcs = const [],
    this.notif,
    this.dotsBehind = false,
  });

  /// Body silhouette, in resting-ball-radius units.
  final BotSilhouette sil;

  /// Global offset of body AND eyes.
  final double offX;
  final double offY;
  final BotGaze gaze;

  /// Half eye separation on the sphere, degrees.
  final double split;

  /// [inner eye, outer eye].
  final List<BotEyeCfg> eyes;

  /// Eye opacity: serves the faceless states.
  final double eyeAlpha;
  final double bodyAlpha;
  final List<BotDot> dots;
  final List<BotArcSpec> arcs;
  final BotNotif? notif;

  /// true = the decor passes behind the body (burst particles).
  final bool dotsBehind;
}

/// The notification pastille and its notch, in resting-ball-radius units.
class BotNotif {
  const BotNotif({
    required this.x,
    required this.y,
    required this.r,
    required this.notch,
  });

  final double x;
  final double y;
  final double r;
  final double notch;
}

class BotStateDef {
  const BotStateDef({
    required this.id,
    required this.duration,
    this.minDuration,
    required this.morph,
    required this.blinkIn,
    required this.baseBody,
    required this.baseFace,
    required this.pose,
  });

  final BloubBotState id;

  /// Hold duration when the full sequence plays.
  final double duration;

  /// Below this the animation is cut before resolving. Read off the
  /// constants in [pose], never chosen. Absent = the state ignores time or
  /// loops.
  final double? minDuration;

  /// Entry morph duration.
  final double morph;

  /// true = the entry is masked by a blink, as in the video.
  final bool blinkIn;

  /// true = the body is the "resting" silhouette, replaceable by the shape
  /// picked in the customizer. States that draw their own shape are false:
  /// there the silhouette IS the animation.
  final bool baseBody;

  /// true = the state carries the "resting" face, replaceable by the chosen
  /// expression. Only idle: other faced states keep the expression measured
  /// on the video — that is precisely what is being reproduced.
  final bool baseFace;

  final BotPose Function(double local) pose;
}

List<BotEyeCfg> _pair(double w, double h) =>
    [BotEyeCfg(w: w, h: h), BotEyeCfg(w: w, h: h)];

/// Pulse wave travelling across the three dots left to right.
double _dotPulse(double t, int index) {
  final double p = (((t - index * 0.5) / 1.5) % 1 + 1) % 1;
  final double k = p < 0.5 ? 0.5 - 0.5 * math.cos(p * botTau) : 0;
  return botClamp(k * 2);
}

/* --------------------------------------------------- non-radial shapes */

/// Bar of the upright "!": convex hull of two circles. Measured: top circle
/// (0, -0.505) r 0.132, bottom (0, +0.130) r 0.075, straight flanks — so it
/// is truncated-cone shaped (top/bottom ratio 1.76).
const double _barUprightCy = -0.1875;
final List<double> _barUpright = botProfileFromPolygon(
    botHullOfCircles(0, -0.505, 0.132, 0, 0.13, 0.075), 0, _barUprightCy);

/// Bar of the tilted "!": a pure capsule (constant width 0.269, length 0.776).
final List<double> _barItalic = botProfileFromPolygon(
    botHullOfCircles(0, -0.2535, 0.1345, 0, 0.2535, 0.1345), 0, 0);

/// The tilted "!"'s dot is not a disc: a teardrop, round end (r 0.118) on
/// the bar side and a tapered point away from it, length 0.300 along the
/// glyph axis. Centered on the round end's barycenter.
final List<BotPoint> _tear = botHullOfCircles(0, 0, 0.118, 0, 0.172, 0.012);

/// The triangle does not spin in place: its center describes a circle of
/// radius 0.213 around the origin (measured). That offset is what makes it
/// read as toppling instead of pivoting.
const double _triOrbit = 0.213;

BotSilhouette _spinningTriangle(double rot) => BotSilhouette(
      radii: kBotTriangleProfile,
      rot: rot,
      cx: -_triOrbit * math.sin(rot),
      cy: _triOrbit * math.cos(rot),
    );

final Map<BloubBotState, BotStateDef> botStates = {
  for (final BotStateDef def in _defs) def.id: def,
};

final List<BotStateDef> _defs = [
  BotStateDef(
    id: BloubBotState.idle,
    duration: 2.4,
    morph: 0.45,
    blinkIn: false,
    baseFace: true,
    baseBody: true,
    pose: (t) => BotPose(sil: botCircle(1)),
  ),

  BotStateDef(
    id: BloubBotState.thinking,
    duration: 2.6,
    morph: 0.4,
    baseFace: false,
    baseBody: false,
    blinkIn: true,
    pose: (t) {
      final double mid = _dotPulse(t, 1);
      // The side dots emerge from the ball's flanks: in the video they stay
      // fused with it for 1-2 frames before detaching.
      final double emerge = 0.3 + 0.7 * botEaseOutCubic(botClamp(t / 0.3));
      return BotPose(
        // the ball BECOMES the middle dot: the morph stays continuous
        sil: botCircle(kBotDotR * (1 + (kBotDotPeak - 1) * mid),
            cx: kBotDotX[1]),
        eyeAlpha: 0,
        dots: [
          for (final int i in const [0, 2])
            BotDot(
              x: kBotDotX[i] * emerge,
              y: 0,
              r: kBotDotR * (1 + (kBotDotPeak - 1) * _dotPulse(t, i)),
              opacity: 0.55 + 0.45 * _dotPulse(t, i),
            ),
        ],
      );
    },
  ),

  BotStateDef(
    id: BloubBotState.wink,
    duration: 1.6,
    morph: 0.3,
    blinkIn: true,
    baseFace: false,
    baseBody: true,
    pose: (t) => const BotPose(
      sil: BotSilhouette(radii: _unitRadii),
      gaze: BotGaze(yaw: -5.37, pitch: 4.55, roll: 6.7),
      split: 16.25,
      // The closed eye is not the open eye squashed: it is a horizontal dash
      // WIDER than the open eye (0.447 vs 0.236).
      eyes: [
        BotEyeCfg(w: 0.236, h: 0.464),
        BotEyeCfg(w: 0.447, h: 0.089),
      ],
    ),
  ),

  BotStateDef(
    id: BloubBotState.wide,
    duration: 1.8,
    morph: 0.55,
    blinkIn: true,
    baseFace: false,
    baseBody: true,
    pose: (t) => BotPose(
      sil: botCircle(1),
      gaze: const BotGaze(yaw: 6.92, pitch: -21.96, roll: 11.6),
      split: 18.43,
      eyes: _pair(0.356, 0.875),
    ),
  ),

  BotStateDef(
    id: BloubBotState.alert,
    duration: 2.4,
    // the "!" settles back in place at 1.6 + 0.4
    minDuration: 2,
    morph: 0.45,
    baseFace: false,
    baseBody: false,
    blinkIn: false,
    pose: (t) {
      // Measured travel: -0.087 -> +0.732 in 1.5 s, ease-in-out.
      final double p = botClamp(t / 1.5);
      final double travel = botEaseInOutCubic(p) * 0.82 - 0.087;
      final double back = t > 1.6 ? botClamp((t - 1.6) / 0.4) : 0;
      final double x = travel * (1 - back) + 0.1 * back;
      // Secondary 2.5 Hz buzz, bar and dot in phase opposition.
      final double buzz = math.sin(t * 2.5 * botTau) * 0.005;
      const double tilt = 17.7 * math.pi / 180;
      return BotPose(
        sil: BotSilhouette(
            radii: _barItalic, rot: tilt, cx: x, cy: -0.325 - buzz),
        eyeAlpha: 0,
        dots: [
          BotDot(
            // the dot follows the glyph axis, 0.580 from the bar center
            x: x - math.sin(tilt) * 0.58,
            y: -0.325 + math.cos(tilt) * 0.58 + buzz * 2.8,
            r: 0.118,
            shape: _tear,
            rotDeg: tilt * 180 / math.pi,
            opacity: 1,
          ),
        ],
      );
    },
  ),

  BotStateDef(
    id: BloubBotState.notify,
    duration: 2.2,
    morph: 0.5,
    blinkIn: true,
    baseFace: false,
    baseBody: true,
    pose: (t) {
      // Blue dot pop: peak at +14% around 0.3 s then settling.
      final double p = botClamp(t / 0.45);
      final double pop =
          1 + (kBotNotifPop - 1) * math.sin(p * math.pi) * (1 - p * 0.35);
      final double r = kBotNotifR * (p < 1 ? pop : 1);
      const double a = kBotNotifAngle * math.pi / 180;
      return BotPose(
        sil: botCircle(1),
        // the gaze goes opposite the pastille
        gaze: const BotGaze(yaw: -21.94, pitch: -5.82, roll: -12.2),
        split: 18.89,
        eyes: _pair(0.505, 0.498),
        notif: BotNotif(
          x: math.cos(a) * kBotNotifDist,
          y: math.sin(a) * kBotNotifDist,
          r: r,
          notch: r + kBotNotifMargin,
        ),
      );
    },
  ),

  BotStateDef(
    id: BloubBotState.exclaim,
    duration: 2,
    morph: 0.45,
    baseFace: false,
    baseBody: false,
    blinkIn: false,
    pose: (t) => BotPose(
      sil: BotSilhouette(radii: _barUpright, cy: _barUprightCy),
      eyeAlpha: 0,
      dots: const [BotDot(x: -0.012, y: 0.526, r: 0.113, opacity: 1)],
    ),
  ),

  BotStateDef(
    id: BloubBotState.sleep,
    duration: 2.4,
    morph: 0.5,
    baseFace: false,
    baseBody: false,
    blinkIn: false,
    pose: (t) => BotPose(
      // Measured vertical bounce: ±0.19 around +0.11, period 0.6 s.
      sil: botCircle(0.1585,
          cy: 0.11 + math.sin(t * (botTau / 0.6)) * 0.19),
      eyeAlpha: 0,
    ),
  ),

  BotStateDef(
    id: BloubBotState.egg,
    duration: 1.8,
    morph: 0.4,
    baseFace: false,
    baseBody: false,
    blinkIn: true,
    pose: (t) => BotPose(
      sil: const BotSilhouette(radii: kBotEggProfile),
      gaze: const BotGaze(yaw: 19.97, pitch: 26.01, roll: -17.1),
      // the eyes tighten like the body
      split: 11.07,
      eyes: _pair(0.164, 0.385),
    ),
  ),

  BotStateDef(
    id: BloubBotState.hexagon,
    duration: 1.6,
    morph: 0.4,
    baseFace: false,
    baseBody: false,
    blinkIn: true,
    pose: (t) => BotPose(
      sil: const BotSilhouette(radii: kBotHexagonProfile),
      gaze: const BotGaze(yaw: 23.11, pitch: 24.42, roll: -13.3),
      split: 13.37,
      eyes: _pair(0.177, 0.411),
    ),
  ),

  BotStateDef(
    id: BloubBotState.play,
    duration: 2,
    morph: 0.5,
    baseFace: false,
    baseBody: false,
    blinkIn: true,
    pose: (t) {
      // The triangle stays nearly still while the bouquet sweeps across it.
      final double fade = botClamp(t / 0.35) * botClamp((2.2 - t) / 0.5);
      return BotPose(
        sil: _spinningTriangle(0),
        gaze: const BotGaze(yaw: 12, pitch: -8, roll: -6),
        split: 15,
        eyes: _pair(0.18, 0.34),
        // the bouquet sweeps right to left over the triangle
        arcs: [
          for (int i = 0; i < kBotSwoosh.length; i++)
            BotArcSpec(
              id: 'sw$i',
              seed: kBotSwoosh[i].copyWith(cx: 0.45 - t * 0.42),
              t: t,
              opacity: fade,
            ),
        ],
      );
    },
  ),

  BotStateDef(
    id: BloubBotState.orbit,
    duration: 3.4,
    // the body finishes relaxing from triangle to ball at 1.6 + 0.9
    minDuration: 2.5,
    morph: 0.6,
    baseFace: false,
    baseBody: false,
    blinkIn: false,
    pose: (t) {
      // Measured rotation: 0.35 s ramp then 1.25 turn/s counterclockwise.
      final double ramp = botEaseInOutCubic(botClamp(t / 0.35));
      final double rot = -botTau * 1.25 * t * ramp;
      // The body relaxes from the triangle to the ball during the orbit.
      final double back = botEaseInOutCubic(botClamp((t - 1.6) / 0.9));
      final BotSilhouette tri = _spinningTriangle(rot);
      final BotSilhouette sil = BotSilhouette(
        radii: List.generate(tri.radii.length,
            (i) => tri.radii[i] + (1 - tri.radii[i]) * back,
            growable: false),
        rot: rot,
        cx: tri.cx * (1 - back),
        cy: tri.cy * (1 - back),
      );
      final double fade = botClamp(t / 0.8) * botClamp((3.6 - t) / 0.9);
      return BotPose(
        sil: sil,
        // the eyes race around the sphere ~3x faster than the silhouette
        gaze: BotGaze(
          yaw: kBotRestGaze.yaw + math.sin(t * 6.5) * 65 * (1 - back),
          pitch: -4 + back * 32,
          roll: -13,
        ),
        eyes: _pair(0.18, 0.34 + back * 0.07),
        // the rings enter one by one over 0.8 s
        arcs: [
          for (int i = 0; i < kBotRings.length; i++)
            BotArcSpec(
              id: 'rg$i',
              seed: kBotRings[i],
              t: t,
              opacity: fade * botClamp((t - i * 0.13) / 0.3),
            ),
        ],
      );
    },
  ),

  BotStateDef(
    // Interface transition upstream, not a catalog animation: it borrows
    // orbit's vocabulary but cuts it short — half the rings, 1.3 s. The two
    // base flags are its whole point: the customizer shape/expression can
    // replace body and face during the entry.
    id: BloubBotState.swirl,
    duration: 1.3,
    minDuration: 1.3,
    morph: 0.3,
    baseFace: true,
    baseBody: true,
    blinkIn: true,
    pose: (t) => BotPose(
      sil: botCircle(1),
      arcs: [
        // three rings out of orbit's six: half the bouquet is enough to
        // recognize it, and that many fewer arcs to rasterize per frame
        for (int i = 0; i < 3; i++)
          BotArcSpec(
            id: 'sw$i',
            seed: kBotRings[i],
            t: t,
            // they enter one after another then fade before the block ends,
            // so the return to rest happens on an already-clean image
            opacity: botClamp((t - i * 0.06) / 0.14) *
                botClamp((1.22 - t) / 0.34),
          ),
      ],
    ),
  ),

  BotStateDef(
    id: BloubBotState.burst,
    duration: 2.6,
    // the body is recomposed at 1.7 + 0.7
    minDuration: 2.4,
    morph: 0.4,
    baseFace: false,
    baseBody: false,
    blinkIn: false,
    pose: (t) {
      // Measured collapse: 1.0 -> 0.166 in 0.7 s, ease-out, no bounce.
      final double collapse = 1 - 0.834 * botEaseOutQuint(botClamp(t / 0.7));
      final double regrow = botEaseOutQuint(botClamp((t - 1.7) / 0.7));
      return BotPose(
        sil: botCircle(collapse + (1 - collapse) * regrow),
        eyeAlpha: botClamp((t - 1.85) / 0.4),
        dots: botParticles(t, 1),
        dotsBehind: true,
      );
    },
  ),

  BotStateDef(
    id: BloubBotState.comet,
    duration: 2.4,
    // the dot recomposes at 1.85 + 0.6 = 2.45, 0.05 s after the video cut:
    // that remainder finishes during the next fade, as in the reference.
    minDuration: 2.4,
    morph: 0.45,
    baseFace: false,
    baseBody: false,
    blinkIn: false,
    pose: (t) {
      final double collapse =
          1 - (1 - kBotCometDot) * botEaseOutQuint(botClamp(t / 0.55));
      final double regrow = botEaseOutQuint(botClamp((t - 1.85) / 0.6));
      final double fade =
          botClamp((t - 0.15) / 0.25) * botClamp((1.95 - t) / 0.3);
      return BotPose(
        // The dot drifts 0.035 down then back up (measured wobble).
        sil: botCircle(collapse + (1 - collapse) * regrow,
            cy: math.sin(botClamp(t / 1.7) * math.pi) * 0.035),
        eyeAlpha: botClamp((t - 2) / 0.35),
        arcs: [
          for (int i = 0; i < kBotCometRibbons.length; i++)
            BotArcSpec(
                id: 'cm$i', seed: kBotCometRibbons[i], t: t, opacity: fade),
        ],
      );
    },
  ),
];

/// A unit circle as a const list, for const poses.
const List<double> _unitRadii = [
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, //
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, //
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, //
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, //
];

/// Date, in local time, where each state is most readable: the pose shown by
/// thumbnails and the frozen board. Deterministic, hence comparable run to
/// run.
const Map<BloubBotState, double> botStatePoses = {
  BloubBotState.idle: 1,
  BloubBotState.thinking: 1.1,
  BloubBotState.wink: 0.8,
  BloubBotState.wide: 0.8,
  BloubBotState.alert: 0.75,
  BloubBotState.notify: 0.9,
  BloubBotState.exclaim: 0.8,
  BloubBotState.sleep: 0.45,
  BloubBotState.egg: 0.8,
  BloubBotState.hexagon: 0.8,
  BloubBotState.play: 0.9,
  BloubBotState.orbit: 1.2,
  BloubBotState.swirl: 0.5,
  BloubBotState.burst: 0.45,
  BloubBotState.comet: 1.15,
};

/// Playback order of the full sequence, mapped on the reference video.
/// `swirl` is deliberately absent: it is an interface transition, not a
/// catalog animation.
const List<BloubBotState> botSequence = [
  BloubBotState.idle,
  BloubBotState.thinking,
  BloubBotState.wink,
  BloubBotState.wide,
  BloubBotState.alert,
  BloubBotState.notify,
  BloubBotState.exclaim,
  BloubBotState.sleep,
  BloubBotState.egg,
  BloubBotState.hexagon,
  BloubBotState.play,
  BloubBotState.orbit,
  BloubBotState.burst,
  BloubBotState.comet,
];
