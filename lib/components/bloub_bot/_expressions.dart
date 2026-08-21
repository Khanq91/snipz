// Part of bloub_bot — the customizer's 16 resting expressions. Mirrors the
// upstream src/bot/expressions.ts (jeremy-prt/bloub, MIT). Pure Dart.
//
// The face is only two capsules, so everything plays on four levers: head
// orientation, eye separation, per-eye proportions, and each eye's own tilt.
// The tilt is what unlocks anger and sadness: they need MIRRORED tilts (tops
// converging or diverging), impossible with head roll alone which tilts both
// eyes the same way. Only the resting state carries this expression — the
// video's expressive states (wink, wide, notify) keep their measured one.

import '_face.dart';

BotEyeCfg _eye(double w, double h, [double tilt = 0, double open = 1]) =>
    BotEyeCfg(w: w, h: h, tilt: tilt, open: open);

/// Both eyes identical, mirrored tilts when [tilt] is given.
List<BotEyeCfg> _pair(double w, double h, [double tilt = 0, double open = 1]) =>
    [_eye(w, h, tilt, open), _eye(w, h, -tilt, open)];

final List<BotExpression> kBotExpressions = List.unmodifiable([
  BotExpression(
    // the pose measured frame by frame on the reference video
    id: 'neutre',
    gaze: kBotRestGaze,
    split: kBotEyeSplit,
    eyes: [_eye(kBotEyeW, kBotEyeH), _eye(kBotEyeW, kBotEyeH)],
  ),
  BotExpression(
    id: 'attentif',
    gaze: const BotGaze(yaw: 4, pitch: 5, roll: -4),
    split: 16,
    eyes: _pair(0.21, 0.44),
  ),
  BotExpression(
    id: 'surpris',
    gaze: const BotGaze(yaw: 3, pitch: -3, roll: 0),
    split: 19,
    eyes: _pair(0.45, 0.47),
  ),
  BotExpression(
    id: 'excite',
    gaze: const BotGaze(yaw: 6, pitch: -14, roll: 0),
    split: 19.5,
    eyes: _pair(0.4, 0.56, -10),
  ),
  BotExpression(
    // squinted arc eyes: the tops converge slightly
    id: 'heureux',
    gaze: const BotGaze(yaw: 5, pitch: 9, roll: 0),
    split: 17,
    eyes: _pair(0.27, 0.17, 14),
  ),
  BotExpression(
    id: 'hilare',
    gaze: const BotGaze(yaw: 4, pitch: 14, roll: 0),
    split: 18,
    eyes: _pair(0.34, 0.13, 20),
  ),
  BotExpression(
    // eye tops converging hard toward the center + narrowed eyes
    id: 'colere',
    gaze: const BotGaze(yaw: 3, pitch: 7, roll: 0),
    split: 17,
    eyes: _pair(0.34, 0.15, 30),
  ),
  BotExpression(
    // the opposite: tops diverge, and the gaze falls
    id: 'triste',
    gaze: const BotGaze(yaw: 3, pitch: -13, roll: 0),
    split: 16,
    eyes: _pair(0.22, 0.4, -28),
  ),
  BotExpression(
    id: 'effraye',
    gaze: const BotGaze(yaw: 2, pitch: -20, roll: 0),
    split: 20.5,
    eyes: _pair(0.4, 0.6),
  ),
  BotExpression(
    // one eye distinctly more closed than the other
    id: 'mefiant',
    gaze: const BotGaze(yaw: 12, pitch: 6, roll: -6),
    split: 16,
    eyes: [_eye(0.21, 0.4), _eye(0.22, 0.15)],
  ),
  BotExpression(
    // asymmetric on both axes: mismatched sizes AND tilts. The squinted eye
    // is deliberately flat (ratio 1.6): near-round, its tilt would not read.
    id: 'confus',
    gaze: const BotGaze(yaw: -14, pitch: 3, roll: 8),
    split: 16.5,
    eyes: [_eye(0.2, 0.44, -18), _eye(0.28, 0.17, 14)],
  ),
  BotExpression(
    // the head leans: roll is what carries curiosity
    id: 'curieux',
    gaze: const BotGaze(yaw: 16, pitch: -9, roll: -15),
    split: 16.5,
    eyes: [_eye(0.24, 0.46, -8), _eye(0.2, 0.38, -8)],
  ),
  BotExpression(
    id: 'fier',
    gaze: const BotGaze(yaw: 5, pitch: 17, roll: 0),
    split: 17,
    eyes: _pair(0.3, 0.15, 18),
  ),
  BotExpression(
    id: 'timide',
    gaze: const BotGaze(yaw: -19, pitch: -14, roll: -7),
    split: 14,
    eyes: _pair(0.17, 0.3),
  ),
  BotExpression(
    // horizontal slits and a gaze drifting sideways
    id: 'blase',
    gaze: const BotGaze(yaw: -22, pitch: 2, roll: 0),
    split: 16,
    eyes: _pair(0.3, 0.12),
  ),
  BotExpression(
    // half-fallen lids: goes through `open`, the vertical screen squash,
    // the same mechanism as the blink
    id: 'somnolent',
    gaze: const BotGaze(yaw: 6, pitch: -9, roll: -3),
    split: 16,
    eyes: _pair(0.2, 0.42, 0, 0.42),
  ),
]);

final Map<String, BotExpression> botExpressionById = Map.unmodifiable({
  for (final BotExpression e in kBotExpressions) e.id: e,
});

const String kBotDefaultExpression = 'neutre';
