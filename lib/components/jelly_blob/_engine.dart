// Pure-time model of the jelly blob. One frame = sample(t) — no ticker, no
// wall clock, no unseeded randomness in here, so a frame is reproducible to
// the pixel (frozenAt, thumbnails, golden tests). The widget dates events
// (mood change, poke, gaze...) on its own clock and the engine answers with
// closed-form springs/keyframes from those dates, which keeps chained
// changes continuous — same scheme as bloub_bot/_engine.dart.
//
// Upstream (feral-blob) drives ~15 SVG groups with framer-motion variants;
// each group has ONE transition per mood, so each group maps to one channel
// here: a from-pose snapshot + a spring (closed form, overshoots like the
// original) or a duration ease toward the mood's target pose. Targets may
// themselves loop in time (breathing, tears, talk mouth) — the blend then
// chases the moving target, which is exactly how the original tweens into a
// repeating keyframe animation.

import 'dart:math' as math;

import '_geom.dart';

/// Face + body expression. Order matters — it indexes the mood tables.
enum JellyBlobMood { neutral, happy, sad, angry, hmm, sideEye, password }

/// Happy-mood eye style: open sparkly star glints, or closed `^_^` arcs.
enum JellyHappyEyes { star, smile }

/// Talking-mouth override — flip per keystroke for a "reads along" effect.
enum JellyTalkMouth { open, wide }

/// Calm moods share the neutral silhouette and its bottom slosh.
const Set<JellyBlobMood> kJellyIdleMoods = {
  JellyBlobMood.neutral,
  JellyBlobMood.hmm,
  JellyBlobMood.sideEye,
  JellyBlobMood.password,
};

/// A readable still instant per mood (all before the first blink at ~1.6 s) —
/// feed to `frozenAt` for thumbnails and state boards.
const Map<JellyBlobMood, double> jellyMoodPoses = {
  JellyBlobMood.neutral: 0.0,
  JellyBlobMood.happy: 1.1,
  JellyBlobMood.sad: 1.2,
  JellyBlobMood.angry: 0.6,
  JellyBlobMood.hmm: 0.5,
  JellyBlobMood.sideEye: 0.5,
  JellyBlobMood.password: 0.5,
};

// ── math helpers ────────────────────────────────────────────────────────────

double _easeInOut(double t) => t < 0.5
    ? 4 * t * t * t
    : 1 - math.pow(-2 * t + 2, 3) / 2;
double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();
double _easeIn(double t) => t * t * t;
double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Closed-form progress (0→1, may overshoot) of a spring at rest released
/// toward 1 — matches a framer-motion `type:'spring'` transition.
double _springP(double tau, double k, double c, double m) {
  if (tau <= 0) return 0;
  final double w = math.sqrt(k / m);
  final double zeta = c / (2 * math.sqrt(k * m));
  if (zeta < 1) {
    final double wd = w * math.sqrt(1 - zeta * zeta);
    final double e = math.exp(-zeta * w * tau);
    return 1 - e * (math.cos(wd * tau) + (zeta * w / wd) * math.sin(wd * tau));
  }
  final double e = math.exp(-w * tau);
  return 1 - e * (1 + w * tau);
}

class _Blend {
  const _Blend.spring(this.k, this.c, [this.m = 1, this.delay = 0]) : dur = 0;
  const _Blend.ease(this.dur, [this.delay = 0])
      : k = 0,
        c = 0,
        m = 1;
  final double k, c, m, delay, dur;

  double p(double tau) {
    tau -= delay;
    if (tau <= 0) return 0;
    if (k > 0) return _springP(tau, k, c, m);
    if (tau >= dur) return 1;
    return _easeOut(tau / dur);
  }
}

/// One animated group: snapshot pose + blend toward a (possibly moving)
/// target pose. Rebase AFTER a sample() so `cur` is fresh.
class _Chan {
  _Chan(int dim)
      : from = List<double>.filled(dim, 0),
        cur = List<double>.filled(dim, 0);
  final List<double> from;
  final List<double> cur;
  double t0 = -1e9;
  _Blend blend = const _Blend.ease(0.001);

  void eval(double t, List<double> target) {
    final double p = blend.p(t - t0);
    for (int i = 0; i < cur.length; i++) {
      cur[i] = from[i] + (target[i] - from[i]) * p;
    }
  }

  void rebase(double t, _Blend b) {
    for (int i = 0; i < from.length; i++) {
      from[i] = cur[i];
    }
    t0 = t;
    blend = b;
  }
}

/// Looping keyframes, easeInOut per segment (framer `repeat: Infinity`).
double _loopKeys(double tau, double dur, List<double> vals,
    [List<double>? times]) {
  if (tau < 0) tau = 0;
  final double u = (tau % dur) / dur;
  final int n = vals.length;
  for (int i = 0; i < n - 1; i++) {
    final double a = times?[i] ?? i / (n - 1);
    final double b = times?[i + 1] ?? (i + 1) / (n - 1);
    if (u <= b || i == n - 2) {
      final double local = ((u - a) / (b - a)).clamp(0.0, 1.0);
      return _lerp(vals[i], vals[i + 1], _easeInOut(local));
    }
  }
  return vals.last;
}

/// One-shot keyframes over absolute times (seconds), clamped at both ends.
double _keys(double tau, List<double> times, List<double> vals) {
  if (tau <= times.first) return vals.first;
  if (tau >= times.last) return vals.last;
  for (int i = 0; i < times.length - 1; i++) {
    if (tau <= times[i + 1]) {
      final double local = (tau - times[i]) / (times[i + 1] - times[i]);
      return _lerp(vals[i], vals[i + 1], _easeInOut(local));
    }
  }
  return vals.last;
}

class _Rng {
  _Rng(int seed) : _s = (seed == 0 ? 0x9e3779b9 : seed) & 0xffffffff;
  int _s;
  double next() {
    // xorshift32 — deterministic across platforms
    _s ^= (_s << 13) & 0xffffffff;
    _s ^= _s >> 17;
    _s ^= (_s << 5) & 0xffffffff;
    return _s / 0xffffffff;
  }
}

// ── happy hop (squash-and-stretch, overshoot baked into the keys) ───────────

const List<double> _hopT = [0, .2, .44, .68, .88, 1.05];
const List<double> _hopYBody = [0, -22, -6, -10.9, -9.7, -10];
const List<double> _hopSx = [1, 1, 1.05, 1, 1, 1];
const List<double> _hopSy = [1, 1.06, .96, 1.005, 1, 1];
const List<double> _hopYArm = [0, -19, -5, -9.8, -8.6, -9];
const List<double> _armRotT = [0, .3, .55, .75];
const List<double> _armRotHappy = [0, -9.5, -7.4, -8]; // left; right mirrors

// ── blink & fidget schedules (seeded, looping — "loop noise") ───────────────

class _Blink {
  _Blink(this.start, this.dur, this.eyes); // eyes: 0 both, 1 left, 2 right
  final double start, dur;
  final int eyes;
}

class _FidgetSeg {
  _FidgetSeg(this.end, this.rot, this.lift);
  final double end; // cumulative end time of this segment
  final double rot, lift;
}

/// Blink lid curve: snaps shut (easeIn), opens softer (easeOut).
double _dip(double u) {
  if (u <= 0 || u >= 1) return 1;
  if (u < .42) return _lerp(1, 0.04, _easeIn(u / .42));
  return _lerp(0.04, 1, _easeOut((u - .42) / .58));
}

// ── the per-frame output ────────────────────────────────────────────────────

/// Everything the painter needs for one frame. Mutable — the engine reuses
/// one instance per sample().
class JellyFrame {
  JellyBodyGeom body = kJellyNeutralGeom;

  // outer group (gaze-lean + poke squash + overpoke shake)
  double attX = 0, attY = 0, boopSx = 1, boopSy = 1, shakeRot = 0;
  // typing nod
  double nodX = 0, nodY = 0, nodRot = 0, nodSx = 1, nodSy = 1;
  // body group
  double bodyX = 0, bodyY = 0, bodyRot = 0, bodySx = 1, bodySy = 1,
      bodySkewX = 0;
  // face group
  double faceX = 0, faceY = 0, faceRot = 0, faceSx = 1, faceSy = 1;
  // arms: rest pose (fixed per seed) + mood pose + fidget
  double armRestLDx = 0, armRestLDy = 0, armRestLRot = 0;
  double armRestRDx = 0, armRestRDy = 0, armRestRRot = 0;
  double armLY = 0, armLRot = 0, armLS = 1;
  double armRY = 0, armRRot = 0, armRS = 1;
  double armLFidgetRot = 0, armLFidgetLift = 0;
  double armRFidgetRot = 0, armRFidgetLift = 0;
  // belly glow / head highlights / gloss
  double bellyX = 0, bellyY = 0, bellySx = 1, bellySy = 1;
  double headHlY = 0, headHlSx = 1, headHlSy = 1, headHlOp = 1;
  double glossOp = .92, glossGazeX = 0, glossGazeY = 0;
  double topDotOp = .84, mainHlOp = .96;
  // eyes
  double eyesGazeX = 0, eyesGazeY = 0;
  double eyeSx = 1, eyeSy = 1, eyeYOff = 0;
  double eyeLOffX = 0, eyeLOffY = 0, eyeROffX = 0, eyeROffY = 0;
  double blinkL = 1, blinkR = 1, blinkLSx = 1, blinkRSx = 1;
  double normalEyeOp = 1, starOp = 0, starScale = .5, arcOp = 0, arcSy = .4;
  // cheeks
  double cheekX = 0, cheekY = 0, cheekSx = 1, cheekSy = 1, cheekOp = .76;
  // overlay faces
  double pwOp = 0, pwBobY = 0, sideOp = 0, hmmOp = 0;
  double sadBrowOp = 0, sadBrowY = -2;
  // mouths
  double happyMouthOp = 0;
  final List<double> mouthPts = List<double>.filled(8, 0);
  double mouthW = 8, mouthOp = 1;
  double talkOp = 0;
  final List<double> talkPts = List<double>.filled(20, 0);
  double talkY = 0, talkSx = 1, talkSy = 1;
  // emotion fx + happy decor
  double fxOp = 0, fxScale = .9, fxY = 0;
  double tearOp = 0, tearY = 0, angryX = 0, angryOp = 0;
  double decorOp = 0, sparkY = 0, heartY = 0;
  // ground shadow (two ellipses)
  double sh1Rx = 212, sh1Ry = 31, sh1Op = .46;
  double sh2Rx = 137, sh2Ry = 15, sh2Op = .14;
}

// ── the engine ──────────────────────────────────────────────────────────────

class JellyBlobEngine {
  JellyBlobEngine({
    JellyBlobMood mood = JellyBlobMood.neutral,
    JellyHappyEyes happyEyes = JellyHappyEyes.star,
    this.seed = 0,
  })  : _mood = mood,
        _happyEyes = happyEyes {
    _buildBlinks();
    _fidgetL = _buildFidget(seed * 31 + 1);
    _fidgetR = _buildFidget(seed * 31 + 2);
    final List<double> rest =
        kJellyArmRestPoses[seed.abs() % kJellyArmRestPoses.length];
    _frame
      ..armRestLDx = rest[0]
      ..armRestLDy = rest[1]
      ..armRestLRot = rest[2]
      ..armRestRDx = rest[3]
      ..armRestRDy = rest[4]
      ..armRestRRot = rest[5];
    _amtStart = _amtGoal = kJellyIdleMoods.contains(mood) ? 1 : 0;
    _fromGeom = mood == JellyBlobMood.sad ? kJellySadGeom : kJellyNeutralGeom;
  }

  /// Varies the blink rhythm, the arm fidget and the arm rest pose between
  /// instances. Same seed = same animation, frame for frame.
  final int seed;

  JellyBlobMood _mood;
  JellyBlobMood get mood => _mood;
  JellyHappyEyes _happyEyes;
  JellyTalkMouth? _talk;
  bool _nod = false;
  double _gazeX = 0, _gazeY = 0, _gazeAmount = 0;

  double _tMood = 0; // when the current mood arrived (loop/keys origin)
  bool _hasTransitioned = false;
  late JellyBodyGeom _fromGeom;
  double _amtStart = 1, _amtGoal = 1;
  double _tNodOn = 0, _tTalkOn = 0, _tTalkSwitch = -1e9;
  final List<double> _talkFrom = List<double>.filled(20, 0);
  double _tBoop = -1e9, _tShake = -1e9;

  late List<_Blink> _blinks;
  late double _blinkPeriod;
  late List<_FidgetSeg> _fidgetL, _fidgetR;

  final JellyFrame _frame = JellyFrame();

  // channels (dims documented at their target builders below)
  final _Chan _cBody = _Chan(6);
  final _Chan _cFace = _Chan(5);
  final _Chan _cArmL = _Chan(3);
  final _Chan _cArmR = _Chan(3);
  final _Chan _cBelly = _Chan(4);
  final _Chan _cHeadHl = _Chan(4);
  final _Chan _cGloss = _Chan(1);
  final _Chan _cTopDot = _Chan(1);
  final _Chan _cMainHl = _Chan(1);
  final _Chan _cEyeT = _Chan(3);
  final _Chan _cEyeL = _Chan(2);
  final _Chan _cEyeR = _Chan(2);
  final _Chan _cCheek = _Chan(5);
  final _Chan _cNormEye = _Chan(1);
  final _Chan _cStar = _Chan(2);
  final _Chan _cArc = _Chan(2);
  final _Chan _cPw = _Chan(1);
  final _Chan _cSide = _Chan(1);
  final _Chan _cHmm = _Chan(1);
  final _Chan _cSadBrow = _Chan(2);
  final _Chan _cHappyMouth = _Chan(1);
  final _Chan _cMouth = _Chan(9);
  final _Chan _cMouthOp = _Chan(1);
  final _Chan _cTalkOp = _Chan(1);
  final _Chan _cFx = _Chan(3);
  final _Chan _cDecor = _Chan(1);
  final _Chan _cShadow = _Chan(6);
  final _Chan _cAtt = _Chan(2);
  final _Chan _cEyeGaze = _Chan(2);
  final _Chan _cGlossGaze = _Chan(2);
  final _Chan _cNod = _Chan(1);

  // ── events (all dated on the caller's clock) ──────────────────────────────

  void setMood(JellyBlobMood m, double t) {
    if (m == _mood) return;
    sample(t); // refresh every channel's cur + the on-screen silhouette
    _fromGeom = _frame.body;
    _amtStart = _currentAmt(t);
    _amtGoal = kJellyIdleMoods.contains(m) ? 1 : 0;
    _tMood = t;
    _hasTransitioned = true;
    _mood = m;
    _cBody.rebase(t, _bodyBlend(m));
    _cFace.rebase(t, _faceBlend(m));
    _cArmL.rebase(t, _armBlend(m, false));
    _cArmR.rebase(t, _armBlend(m, true));
    _cBelly.rebase(t, _softBlend(m));
    _cHeadHl.rebase(t, _softBlend(m));
    _cGloss.rebase(t, _softBlend(m));
    _cTopDot.rebase(t, const _Blend.ease(.2));
    _cMainHl.rebase(t, const _Blend.ease(.16));
    _cEyeT.rebase(t, const _Blend.spring(240, 17, 1, .05));
    _cEyeL.rebase(t, const _Blend.spring(240, 17, 1, .05));
    _cEyeR.rebase(t, const _Blend.spring(240, 17, 1, .05));
    _cCheek.rebase(t, const _Blend.spring(220, 18, 1, .05));
    _cNormEye.rebase(t, const _Blend.ease(.13));
    _cStar.rebase(t,
        _Blend.spring(300, 16, 1, m == JellyBlobMood.happy ? .12 : 0));
    _cArc.rebase(t,
        _Blend.spring(260, 18, 1, m == JellyBlobMood.happy ? .1 : 0));
    _cPw.rebase(t, const _Blend.ease(.13));
    _cSide.rebase(t, const _Blend.ease(.13));
    _cHmm.rebase(t, const _Blend.ease(.15));
    _cSadBrow.rebase(t, const _Blend.ease(.16));
    _cHappyMouth.rebase(
        t, _Blend.ease(.18, m == JellyBlobMood.happy ? .1 : 0));
    _cMouth.rebase(t, const _Blend.spring(240, 16, 1, .05));
    _cMouthOp.rebase(t, const _Blend.ease(.1));
    _cFx.rebase(t, _fxBlend(m));
    _cDecor.rebase(t, _Blend.ease(.22, m == JellyBlobMood.happy ? .14 : 0));
    _cShadow.rebase(t, const _Blend.spring(260, 20));
  }

  void setGaze(double x, double y, double? intensity, double t) {
    final double gx = x.clamp(-16.0, 18.0);
    final double gy = y.clamp(-10.0, 10.0);
    final double amount =
        intensity ?? math.min(1, math.sqrt(gx * gx + gy * gy) / 16);
    if (gx == _gazeX && gy == _gazeY && amount == _gazeAmount) return;
    sample(t);
    _gazeX = gx;
    _gazeY = gy;
    _gazeAmount = amount;
    _cAtt.rebase(t, const _Blend.spring(180, 18));
    _cEyeGaze.rebase(t, const _Blend.spring(220, 20));
    _cGlossGaze.rebase(t, const _Blend.spring(180, 18));
  }

  void setNod(bool v, double t) {
    if (v == _nod) return;
    sample(t);
    _nod = v;
    if (v) _tNodOn = t;
    _cNod.rebase(t, const _Blend.spring(260, 20));
  }

  void setTalk(JellyTalkMouth? m, double t) {
    if (m == _talk) return;
    sample(t);
    if (m != null && _talk == null) _tTalkOn = t;
    if (m != null && _talk != null) {
      // open<->wide mid-talk: morph from the on-screen mouth
      for (int i = 0; i < 20; i++) {
        _talkFrom[i] = _frame.talkPts[i];
      }
      _tTalkSwitch = t;
    }
    _talk = m;
    _cTalkOp.rebase(t, const _Blend.ease(.1));
    _cMouthOp.rebase(t, const _Blend.ease(.1));
  }

  void setHappyEyes(JellyHappyEyes e, double t) {
    if (e == _happyEyes) return;
    sample(t);
    _happyEyes = e;
    _cNormEye.rebase(t, const _Blend.ease(.13));
    _cStar.rebase(t, const _Blend.spring(300, 16));
    _cArc.rebase(t, const _Blend.spring(260, 18));
  }

  /// Poke squash — cartoon boop, origin center-bottom.
  void boop(double t) => _tBoop = t;

  /// Overpoke protest shake.
  void shake(double t) => _tShake = t;

  // ── sampling ──────────────────────────────────────────────────────────────

  double _currentAmt(double t) =>
      _amtGoal + (_amtStart - _amtGoal) * math.exp(-2.2 * (t - _tMood));

  JellyFrame sample(double t) {
    final JellyFrame f = _frame;
    final double tau = t - _tMood;
    final bool idle = kJellyIdleMoods.contains(_mood);

    // body silhouette: idle slosh / mood shape, morphed from the snapshot
    final double amt = _currentAmt(t);
    final JellyBodyGeom rest = idle
        ? jellyWaveGeom(t * 0.7, amt)
        : (_mood == JellyBlobMood.sad ? kJellySadGeom : kJellyNeutralGeom);
    final double morph =
        _hasTransitioned ? math.min(1, tau * 2.4) : 1.0;
    f.body = morph >= 1
        ? rest
        : JellyBodyGeom.lerp(_fromGeom, rest, _easeInOut(morph));

    // groups
    _cBody.eval(t, _bodyTarget(tau));
    f
      ..bodyX = _cBody.cur[0]
      ..bodyY = _cBody.cur[1]
      ..bodyRot = _cBody.cur[2]
      ..bodySx = _cBody.cur[3]
      ..bodySy = _cBody.cur[4]
      ..bodySkewX = _cBody.cur[5];

    _cFace.eval(t, _faceTarget(tau));
    f
      ..faceX = _cFace.cur[0]
      ..faceY = _cFace.cur[1]
      ..faceRot = _cFace.cur[2]
      ..faceSx = _cFace.cur[3]
      ..faceSy = _cFace.cur[4];

    _cArmL.eval(t, _armTarget(tau, false));
    f
      ..armLY = _cArmL.cur[0]
      ..armLRot = _cArmL.cur[1]
      ..armLS = _cArmL.cur[2];
    _cArmR.eval(t, _armTarget(tau, true));
    f
      ..armRY = _cArmR.cur[0]
      ..armRRot = _cArmR.cur[1]
      ..armRS = _cArmR.cur[2];

    // arm fidget rides on top, faded by idle-ness (amt)
    final double fidL = amt;
    f.armLFidgetRot = _fidgetVal(_fidgetL, t, 0) * fidL;
    f.armLFidgetLift = _fidgetVal(_fidgetL, t, 1) * fidL;
    f.armRFidgetRot = _fidgetVal(_fidgetR, t + 1.37, 0) * fidL;
    f.armRFidgetLift = _fidgetVal(_fidgetR, t + 1.37, 1) * fidL;

    _cBelly.eval(t, _bellyTarget());
    f
      ..bellyX = _cBelly.cur[0]
      ..bellyY = _cBelly.cur[1]
      ..bellySx = _cBelly.cur[2]
      ..bellySy = _cBelly.cur[3];

    _cHeadHl.eval(t, _headHlTarget());
    f
      ..headHlY = _cHeadHl.cur[0]
      ..headHlSx = _cHeadHl.cur[1]
      ..headHlSy = _cHeadHl.cur[2]
      ..headHlOp = _cHeadHl.cur[3].clamp(0.0, 1.0);

    _cGloss.eval(t, [_glossTarget()]);
    f.glossOp = _cGloss.cur[0].clamp(0.0, 1.0);
    _cTopDot.eval(t, [_mood == JellyBlobMood.sad ? 0 : .84]);
    f.topDotOp = _cTopDot.cur[0].clamp(0.0, 1.0);
    final bool starMode =
        _mood == JellyBlobMood.happy && _happyEyes == JellyHappyEyes.star;
    _cMainHl.eval(t, [starMode ? 0 : .96]);
    f.mainHlOp = _cMainHl.cur[0].clamp(0.0, 1.0);

    _cEyeT.eval(t, _eyeTTarget());
    f
      ..eyeSx = _cEyeT.cur[0]
      ..eyeSy = _cEyeT.cur[1]
      ..eyeYOff = _cEyeT.cur[2];

    _cEyeL.eval(t, _eyeOffTarget(false));
    f
      ..eyeLOffX = _cEyeL.cur[0]
      ..eyeLOffY = _cEyeL.cur[1];
    _cEyeR.eval(t, _eyeOffTarget(true));
    f
      ..eyeROffX = _cEyeR.cur[0]
      ..eyeROffY = _cEyeR.cur[1];

    _cCheek.eval(t, _cheekTarget());
    f
      ..cheekX = _cCheek.cur[0]
      ..cheekY = _cCheek.cur[1]
      ..cheekSx = _cCheek.cur[2]
      ..cheekSy = _cCheek.cur[3]
      ..cheekOp = _cCheek.cur[4].clamp(0.0, 1.0);

    final bool eyesHidden = _mood == JellyBlobMood.password ||
        _mood == JellyBlobMood.sideEye ||
        (_mood == JellyBlobMood.happy && _happyEyes == JellyHappyEyes.smile);
    _cNormEye.eval(t, [eyesHidden ? 0 : 1]);
    f.normalEyeOp = _cNormEye.cur[0].clamp(0.0, 1.0);
    _cStar.eval(t, starMode ? const [1, 1] : const [0, .5]);
    f
      ..starOp = _cStar.cur[0].clamp(0.0, 1.0)
      ..starScale = _cStar.cur[1];
    final bool smileMode =
        _mood == JellyBlobMood.happy && _happyEyes == JellyHappyEyes.smile;
    _cArc.eval(t, smileMode ? const [1, 1] : const [0, .4]);
    f
      ..arcOp = _cArc.cur[0].clamp(0.0, 1.0)
      ..arcSy = _cArc.cur[1];

    _cPw.eval(t, [_mood == JellyBlobMood.password ? 1 : 0]);
    f.pwOp = _cPw.cur[0].clamp(0.0, 1.0);
    f.pwBobY = _mood == JellyBlobMood.password
        ? _loopKeys(tau, 2.8, const [0, -1.5, 0])
        : 0;
    _cSide.eval(t, [_mood == JellyBlobMood.sideEye ? 1 : 0]);
    f.sideOp = _cSide.cur[0].clamp(0.0, 1.0);
    _cHmm.eval(t, [_mood == JellyBlobMood.hmm ? .52 : 0]);
    f.hmmOp = _cHmm.cur[0].clamp(0.0, 1.0);
    _cSadBrow.eval(
        t, _mood == JellyBlobMood.sad ? const [1, 0] : const [0, -2]);
    f
      ..sadBrowOp = _cSadBrow.cur[0].clamp(0.0, 1.0)
      ..sadBrowY = _cSadBrow.cur[1];

    _cHappyMouth.eval(t, [_mood == JellyBlobMood.happy ? 1 : 0]);
    f.happyMouthOp = _cHappyMouth.cur[0].clamp(0.0, 1.0);

    final List<double> mouth = kJellyMouths[_mood.index]!;
    _cMouth.eval(t, [
      ...mouth,
      _mood == JellyBlobMood.sad ? 9 : 8,
    ]);
    for (int i = 0; i < 8; i++) {
      f.mouthPts[i] = _cMouth.cur[i];
    }
    f.mouthW = _cMouth.cur[8];
    _cMouthOp.eval(
        t, [_talk != null || _mood == JellyBlobMood.password ? 0 : 1]);
    f.mouthOp = _cMouthOp.cur[0].clamp(0.0, 1.0);

    _cTalkOp.eval(t, [_talk != null ? 1 : 0]);
    f.talkOp = _cTalkOp.cur[0].clamp(0.0, 1.0);
    if (f.talkOp > 0) {
      final List<List<double>> keysList =
          _talk == JellyTalkMouth.wide ? kJellyTalkWide : kJellyTalkOpen;
      final double talkTau = t - _tTalkOn;
      final double u = (talkTau % .56) / .56;
      final int seg = math.min(3, (u * 4).floor());
      final double local = _easeInOut((u * 4 - seg).clamp(0.0, 1.0));
      final double switchBlend =
          math.min(1.0, (t - _tTalkSwitch) / .15).clamp(0.0, 1.0);
      for (int i = 0; i < 20; i++) {
        final double v =
            _lerp(keysList[seg][i], keysList[seg + 1][i], local);
        f.talkPts[i] = _lerp(_talkFrom[i], v, switchBlend);
      }
      f.talkY = _loopKeys(talkTau, .56, const [0, -.5, .35, -.2, 0]);
      f.talkSx = _loopKeys(talkTau, .56, const [1, 1.03, .96, 1.04, 1]);
      f.talkSy = _loopKeys(talkTau, .56, const [.94, 1.04, .98, 1.02, .94]);
    }

    _cFx.eval(t, _fxTarget());
    f
      ..fxOp = _cFx.cur[0].clamp(0.0, 1.0)
      ..fxScale = _cFx.cur[1]
      ..fxY = _cFx.cur[2];
    if (_mood == JellyBlobMood.sad) {
      f.tearOp = _loopKeys(tau, 2.2, const [.72, .94, .72]);
      f.tearY = _loopKeys(tau, 2.2, const [0, 5, 0]);
    } else {
      f.tearOp = 0;
      f.tearY = 0;
    }
    f.angryOp = _mood == JellyBlobMood.angry ? 1 : 0;
    f.angryX = _mood == JellyBlobMood.angry
        ? _loopKeys(tau, .32, const [0, 4, -3, 0])
        : 0;

    _cDecor.eval(t, [_mood == JellyBlobMood.happy ? 1 : 0]);
    f.decorOp = _cDecor.cur[0].clamp(0.0, 1.0);
    f.sparkY = _mood == JellyBlobMood.happy
        ? _loopKeys(tau, 1.6, const [-4, -12, -4])
        : 0;
    f.heartY = _mood == JellyBlobMood.happy
        ? _loopKeys(math.max(0, tau - .3), 1.8, const [-3, -11, -3])
        : 0;

    _cShadow.eval(t, _shadowTarget(tau));
    f
      ..sh1Rx = _cShadow.cur[0]
      ..sh1Ry = _cShadow.cur[1]
      ..sh1Op = _cShadow.cur[2].clamp(0.0, 1.0)
      ..sh2Rx = _cShadow.cur[3]
      ..sh2Ry = _cShadow.cur[4]
      ..sh2Op = _cShadow.cur[5].clamp(0.0, 1.0);

    // gaze lean + eye/gloss follow
    _cAtt.eval(t, [_gazeX * .18, _gazeY * .08 + _gazeAmount * 1.5]);
    f
      ..attX = _cAtt.cur[0]
      ..attY = _cAtt.cur[1];
    _cEyeGaze.eval(t, [_gazeX, _gazeY]);
    f
      ..eyesGazeX = _cEyeGaze.cur[0]
      ..eyesGazeY = _cEyeGaze.cur[1];
    _cGlossGaze.eval(t, [_gazeX * -.08, _gazeY * .04]);
    f
      ..glossGazeX = _cGlossGaze.cur[0]
      ..glossGazeY = _cGlossGaze.cur[1];

    // typing nod (loop scaled by its blend so it eases in and out)
    _cNod.eval(t, [_nod ? 1 : 0]);
    final double nodB = _cNod.cur[0].clamp(0.0, 1.0);
    if (nodB > 0) {
      final double nt = t - _tNodOn;
      const List<double> times = [0, .22, .48, .7, .88, 1];
      f.nodX = _loopKeys(nt, 1.18, const [0, 2.2, -1.8, 1.3, -.8, 0], times) *
          nodB;
      f.nodY = _loopKeys(nt, 1.18, const [0, 3.2, -1.2, 2, -.5, 0], times) *
          nodB;
      f.nodRot =
          _loopKeys(nt, 1.18, const [0, -1.6, 1.35, -.75, .45, 0], times) *
              nodB;
      f.nodSx = 1 +
          (_loopKeys(nt, 1.18,
                      const [1, 1.024, .987, 1.014, .996, 1], times) -
                  1) *
              nodB;
      f.nodSy = 1 +
          (_loopKeys(nt, 1.18,
                      const [1, .984, 1.012, .992, 1.005, 1], times) -
                  1) *
              nodB;
    } else {
      f.nodX = 0;
      f.nodY = 0;
      f.nodRot = 0;
      f.nodSx = 1;
      f.nodSy = 1;
    }

    // blink
    final double lidL = _lid(t, 1);
    final double lidR = _lid(t, 2);
    f.blinkL = lidL;
    f.blinkR = lidR;
    // cartoon squash: eyes widen as the lid comes down
    f.blinkLSx = _lerp(1.08, 1, ((lidL - .05) / .95).clamp(0.0, 1.0));
    f.blinkRSx = _lerp(1.08, 1, ((lidR - .05) / .95).clamp(0.0, 1.0));

    // poke squash + overpoke shake
    final double boopTau = t - _tBoop;
    if (boopTau >= 0 && boopTau < .5) {
      f.boopSy = _keys(boopTau, const [0, .1, .25, .39, .5],
          const [1, .86, 1.08, .97, 1]);
      f.boopSx = 1 + (1 - f.boopSy) * .9;
    } else {
      f.boopSx = 1;
      f.boopSy = 1;
    }
    final double shakeTau = t - _tShake;
    f.shakeRot = shakeTau >= 0 && shakeTau < .8
        ? _keys(shakeTau, const [0, .11, .23, .34, .46, .57, .69, .8],
            const [0, -6, 6, -5, 5, -3, 3, 0])
        : 0;

    return f;
  }

  // ── per-group mood targets & transitions ──────────────────────────────────

  List<double> _bodyTarget(double tau) {
    switch (_mood) {
      case JellyBlobMood.neutral:
        return [
          0,
          _loopKeys(tau, 4.2, const [0, -3, 0]),
          0,
          _loopKeys(tau, 4.2, const [1, .992, 1]),
          _loopKeys(tau, 4.2, const [1, 1.012, 1]),
          0,
        ];
      case JellyBlobMood.password:
        return [
          0,
          _loopKeys(tau, 3.8, const [0, -2, 0]),
          0,
          _loopKeys(tau, 3.8, const [1, .996, 1]),
          _loopKeys(tau, 3.8, const [1, 1.008, 1]),
          0,
        ];
      case JellyBlobMood.sideEye:
        return const [-4, 1, -1.2, 1, 1, 0];
      case JellyBlobMood.hmm:
        return const [0, 0, 0, 1, 1, 2.5];
      case JellyBlobMood.happy:
        return [
          0,
          _keys(tau, _hopT, _hopYBody),
          0,
          _keys(tau, _hopT, _hopSx),
          _keys(tau, _hopT, _hopSy),
          0,
        ];
      case JellyBlobMood.sad:
        return const [0, 0, 0, 1, 1, 0]; // the path morph IS the melt
      case JellyBlobMood.angry:
        return const [0, 5, 0, 1, .95, 0];
    }
  }

  _Blend _bodyBlend(JellyBlobMood m) {
    switch (m) {
      case JellyBlobMood.sideEye:
        return const _Blend.spring(190, 18);
      case JellyBlobMood.happy:
        return const _Blend.ease(.15);
      case JellyBlobMood.sad:
        return const _Blend.spring(130, 20, 1.05);
      case JellyBlobMood.angry:
        return const _Blend.spring(260, 8, .7);
      default:
        return const _Blend.spring(200, 18);
    }
  }

  List<double> _faceTarget(double tau) {
    switch (_mood) {
      case JellyBlobMood.sideEye:
        return const [-7, 2, -2, 1, .98];
      case JellyBlobMood.password:
        return const [-4, 3, -3, 1, 1];
      case JellyBlobMood.hmm:
        return const [0, 0, 0, 1, 1];
      case JellyBlobMood.neutral:
        return [0, _loopKeys(tau, 3.2, const [0, -2, 0]), 0, 1, 1];
      case JellyBlobMood.happy:
        return [0, _keys(tau, _hopT, _hopYBody), 0, 1, 1];
      case JellyBlobMood.sad:
        return const [0, 12, 0, 1, 1];
      case JellyBlobMood.angry:
        return const [0, 7, 0, 1, .96];
    }
  }

  _Blend _faceBlend(JellyBlobMood m) {
    switch (m) {
      case JellyBlobMood.happy:
        return const _Blend.ease(.15, .05);
      case JellyBlobMood.sad:
        return const _Blend.spring(145, 18, .95, .04);
      case JellyBlobMood.angry:
        return const _Blend.spring(260, 9, .7, .05);
      case JellyBlobMood.password:
        return const _Blend.spring(210, 17, 1, .04);
      default:
        return const _Blend.spring(210, 18, 1, .05);
    }
  }

  List<double> _armTarget(double tau, bool right) {
    final double side = right ? -1 : 1;
    switch (_mood) {
      case JellyBlobMood.happy:
        return [
          _keys(tau, _hopT, _hopYArm),
          _keys(tau, _armRotT, _armRotHappy) * side,
          1,
        ];
      case JellyBlobMood.sad:
        return [13, 12 * side, .96];
      case JellyBlobMood.angry:
        return [2, -3 * side, 1];
      case JellyBlobMood.password:
        return [0, -2 * side, 1];
      default:
        return const [0, 0, 1];
    }
  }

  _Blend _armBlend(JellyBlobMood m, bool right) {
    switch (m) {
      case JellyBlobMood.happy:
        return _Blend.ease(.15, right ? .12 : .1);
      case JellyBlobMood.sad:
        return const _Blend.spring(135, 18, .95, .1);
      case JellyBlobMood.angry:
        return const _Blend.spring(250, 10, .8, .08);
      default:
        return const _Blend.spring(200, 16, 1, .1);
    }
  }

  List<double> _bellyTarget() => _mood == JellyBlobMood.sad
      ? const [0, 20, 1.02, .98]
      : const [0, 0, 1, 1];

  List<double> _headHlTarget() => _mood == JellyBlobMood.sad
      ? const [22, .96, .96, .9]
      : const [0, 1, 1, 1];

  _Blend _softBlend(JellyBlobMood m) {
    switch (m) {
      case JellyBlobMood.sad:
        return const _Blend.spring(150, 20, .85);
      case JellyBlobMood.happy:
        return const _Blend.spring(220, 12);
      case JellyBlobMood.angry:
        return const _Blend.spring(240, 12);
      default:
        return const _Blend.spring(200, 20);
    }
  }

  double _glossTarget() {
    switch (_mood) {
      case JellyBlobMood.sideEye:
        return .86;
      case JellyBlobMood.password:
        return .88;
      case JellyBlobMood.hmm:
        return .9;
      case JellyBlobMood.neutral:
        return .92;
      case JellyBlobMood.happy:
        return .95;
      case JellyBlobMood.sad:
        return .82;
      case JellyBlobMood.angry:
        return .86;
    }
  }

  List<double> _eyeTTarget() {
    switch (_mood) {
      case JellyBlobMood.sideEye:
        return const [1.04, .64, 3];
      case JellyBlobMood.password:
        return const [.9, .38, 3];
      case JellyBlobMood.hmm:
        return const [1, .78, 2];
      case JellyBlobMood.neutral:
        return const [1, 1, 0];
      case JellyBlobMood.happy:
        return const [1.05, 1.04, -2];
      case JellyBlobMood.sad:
        return const [1.1, 1.16, 4];
      case JellyBlobMood.angry:
        return const [1.1, .48, 2];
    }
  }

  List<double> _eyeOffTarget(bool right) {
    switch (_mood) {
      case JellyBlobMood.sideEye:
        return right ? const [-10, 1] : const [-5, 1];
      case JellyBlobMood.password:
        return const [-3, 0];
      case JellyBlobMood.hmm:
        return const [-9, 1];
      case JellyBlobMood.neutral:
        return const [0, 0];
      case JellyBlobMood.happy:
        return const [0, -1];
      case JellyBlobMood.sad:
        return right ? const [-5, 5] : const [5, 5];
      case JellyBlobMood.angry:
        return right ? const [-3, 3] : const [3, 3];
    }
  }

  List<double> _cheekTarget() {
    switch (_mood) {
      case JellyBlobMood.sideEye:
        return const [-3, 3, .9, .82, .48];
      case JellyBlobMood.password:
        return const [0, 2, .86, .76, .38];
      case JellyBlobMood.hmm:
        return const [0, 0, 1, 1, .7];
      case JellyBlobMood.neutral:
        return const [0, 0, 1, 1, .76];
      case JellyBlobMood.happy:
        return const [0, -1, 1.1, 1.1, .88];
      case JellyBlobMood.sad:
        return const [0, 8, 1.04, .8, .72];
      case JellyBlobMood.angry:
        return const [0, 2, 1.08, .94, .9];
    }
  }

  List<double> _fxTarget() {
    switch (_mood) {
      case JellyBlobMood.happy:
        return const [1, 1, 0];
      case JellyBlobMood.sad:
        return const [1, 1, 12];
      case JellyBlobMood.angry:
        return const [1, 1, 0];
      default:
        return const [0, .9, 0];
    }
  }

  _Blend _fxBlend(JellyBlobMood m) {
    switch (m) {
      case JellyBlobMood.happy:
        return const _Blend.ease(.24, .12);
      case JellyBlobMood.sad:
        return const _Blend.ease(.28, .12);
      case JellyBlobMood.angry:
        return const _Blend.ease(.2, .08);
      default:
        return const _Blend.ease(.18);
    }
  }

  List<double> _shadowTarget(double tau) {
    switch (_mood) {
      case JellyBlobMood.neutral:
        return [
          212, 31, _loopKeys(tau, 3.2, const [.46, .36, .46]),
          137, 15, _loopKeys(tau, 3.2, const [.14, .10, .14]),
        ];
      case JellyBlobMood.happy:
        return const [152, 22, .28, 104, 12, .08];
      case JellyBlobMood.sad:
        return const [248, 36, .52, 158, 18, .16];
      case JellyBlobMood.hmm:
        return const [218, 31, .42, 136, 15, .12];
      case JellyBlobMood.sideEye:
        return const [216, 31, .40, 134, 15, .12];
      default: // angry, password
        return const [238, 34, .50, 156, 18, .15];
    }
  }

  // ── blink & fidget ────────────────────────────────────────────────────────

  void _buildBlinks() {
    final _Rng rng = _Rng(seed * 2654435761 + 0x1234567);
    final List<_Blink> events = [];
    double t = 1.6 + rng.next() * .7;
    for (int n = 0; n < 48; n++) {
      final double r = rng.next();
      if (r < .1) {
        events.add(_Blink(t, .22, rng.next() < .5 ? 1 : 2));
        t += .22;
      } else if (r < .32) {
        events.add(_Blink(t, .15, 0));
        events.add(_Blink(t + .15, .15, 0));
        t += .3;
      } else if (r < .42) {
        events.add(_Blink(t, .46, 0));
        t += .46;
      } else {
        events.add(_Blink(t, .2, 0));
        t += .2;
      }
      t += 2.0 + rng.next() * 3.0;
    }
    _blinks = events;
    _blinkPeriod = t;
  }

  double _lid(double t, int eye) {
    final double u = t % _blinkPeriod;
    for (final _Blink b in _blinks) {
      if (u < b.start) break;
      if (u < b.start + b.dur && (b.eyes == 0 || b.eyes == eye)) {
        return _dip((u - b.start) / b.dur);
      }
    }
    return 1;
  }

  List<_FidgetSeg> _buildFidget(int s) {
    final _Rng rng = _Rng(s * 2654435761 + 0x89abcd);
    final List<_FidgetSeg> segs = [];
    double t = 0;
    for (int n = 0; n < 23; n++) {
      t += 1.1 + rng.next() * 1.7;
      segs.add(_FidgetSeg(
          t, (rng.next() - .5) * 9, (rng.next() - .5) * 4));
    }
    // close the loop back at rest so the wrap is seamless
    t += 1.1 + rng.next() * 1.7;
    segs.add(_FidgetSeg(t, 0, 0));
    return segs;
  }

  double _fidgetVal(List<_FidgetSeg> segs, double t, int what) {
    final double u = t % segs.last.end;
    double prevEnd = 0, prevRot = 0, prevLift = 0;
    for (final _FidgetSeg s in segs) {
      if (u <= s.end) {
        final double local = _easeInOut(
            ((u - prevEnd) / (s.end - prevEnd)).clamp(0.0, 1.0));
        return what == 0
            ? _lerp(prevRot, s.rot, local)
            : _lerp(prevLift, s.lift, local);
      }
      prevEnd = s.end;
      prevRot = s.rot;
      prevLift = s.lift;
    }
    return 0;
  }
}
