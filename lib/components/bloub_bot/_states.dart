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

/// The catalog. Body-only states for now; the decor states (alert, notify,
/// exclaim, play, orbit, swirl, burst, comet) join with the decor renderer.
enum BloubBotState { idle, thinking, wink, wide, sleep, egg, hexagon }

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
  BloubBotState.sleep: 0.45,
  BloubBotState.egg: 0.8,
  BloubBotState.hexagon: 0.8,
};

/// Playback order of the full sequence, mapped on the reference video
/// (restricted to the states in the catalog so far).
const List<BloubBotState> botSequence = [
  BloubBotState.idle,
  BloubBotState.thinking,
  BloubBotState.wink,
  BloubBotState.wide,
  BloubBotState.sleep,
  BloubBotState.egg,
  BloubBotState.hexagon,
];
