// Part of bloub_bot — the clockless engine: `sample(t)` is a pure function
// of time. Mirrors the upstream src/bot/engine.ts (jeremy-prt/bloub, MIT).
// Pure Dart, no Flutter imports — the whole engine is unit-testable without
// a widget tree, and pause/resume/seek all produce the same image.

import 'dart:math' as math;

import '_decor.dart';
import '_face.dart';
import '_math.dart';
import '_shape.dart';
import '_states.dart';

/// Resting ball radius, in viewBox units. Chosen, not measured: it is the
/// working unit — everything else in this folder is expressed as fractions
/// of it, which keeps the video measurements display-size independent.
const double kBotRayon = 100;

/// Half side of the displayed viewBox. Not a free value: orbit rings and the
/// comet swoosh reach 1.4x the radius (140); the margin beyond the radius
/// houses them.
const double kBotDemiViewbox = 158;

/// Where the bot aims its gaze when something external drives it. `yaw` and
/// `pitch` are ABSOLUTE directions that replace the pose's as `mix` rises —
/// the ENGINE does the blending because only it knows the pose at that
/// instant. `wander` says, separately, how much automatic drift remains.
/// `spin` is a turn to travel ALONG THE WAY, in degrees, faded to 0 on
/// arrival.
class BotLook {
  const BotLook({
    required this.yaw,
    required this.pitch,
    required this.mix,
    required this.spin,
    required this.wander,
  });

  final double yaw;
  final double pitch;
  final double mix;
  final double spin;
  final double wander;

  static const BotLook none =
      BotLook(yaw: 0, pitch: 0, mix: 0, spin: 0, wander: 1);
}

BotLook _lerpLook(BotLook a, BotLook b, double t) => BotLook(
      yaw: botLerp(a.yaw, b.yaw, t),
      pitch: botLerp(a.pitch, b.pitch, t),
      mix: botLerp(a.mix, b.mix, t),
      spin: botLerp(a.spin, b.spin, t),
      wander: botLerp(a.wander, b.wander, t),
    );

/// One eye ready to draw: capsule size (viewBox units), the affine matrix in
/// SVG matrix(a,b,c,d,e,f) sense, and the opacity.
class BotRenderedEye {
  const BotRenderedEye({
    required this.w,
    required this.h,
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.tx,
    required this.ty,
    required this.alpha,
  });

  final double w;
  final double h;
  final double a;
  final double b;
  final double c;
  final double d;
  final double tx;
  final double ty;
  final double alpha;
}

class BotCircleRender {
  const BotCircleRender({required this.x, required this.y, required this.r});

  final double x;
  final double y;
  final double r;
}

/// Everything one frame renders, in viewBox units centered on the ball.
class BotFrame {
  const BotFrame({
    required this.body,
    required this.bodyAlpha,
    required this.eyes,
    required this.dots,
    required this.dotsBehind,
    required this.arcs,
    required this.notif,
    required this.notch,
  });

  /// 64 silhouette points, posed and scaled.
  final List<BotPoint> body;
  final double bodyAlpha;
  final List<BotRenderedEye> eyes;
  final List<BotDot> dots;

  /// true = the dots pass behind the body (burst particles).
  final bool dotsBehind;
  final List<BotArcRender> arcs;
  final BotCircleRender? notif;
  final BotCircleRender? notch;
}

BotEyeCfg _lerpEye(BotEyeCfg a, BotEyeCfg b, double t) => BotEyeCfg(
      w: botLerp(a.w, b.w, t),
      h: botLerp(a.h, b.h, t),
      open: botLerp(a.open, b.open, t),
      tilt: botLerp(a.tilt, b.tilt, t),
    );

/// Interpolation of two poses. Decor crossfades in opacity, not in geometry.
BotPose _blendPose(BotPose a, BotPose b, double t) {
  final double out = 1 - t;
  return BotPose(
    sil: botBlendSil(a.sil, b.sil, t),
    offX: botLerp(a.offX, b.offX, t),
    offY: botLerp(a.offY, b.offY, t),
    gaze: BotGaze(
      yaw: botLerp(a.gaze.yaw, b.gaze.yaw, t),
      pitch: botLerp(a.gaze.pitch, b.gaze.pitch, t),
      roll: botLerp(a.gaze.roll, b.gaze.roll, t),
    ),
    split: botLerp(a.split, b.split, t),
    eyes: [_lerpEye(a.eyes[0], b.eyes[0], t), _lerpEye(a.eyes[1], b.eyes[1], t)],
    eyeAlpha: botLerp(a.eyeAlpha, b.eyeAlpha, t),
    bodyAlpha: botLerp(a.bodyAlpha, b.bodyAlpha, t),
    dots: [
      for (final BotDot d in a.dots) d.copyWith(opacity: d.opacity * out),
      for (final BotDot d in b.dots) d.copyWith(opacity: d.opacity * t),
    ],
    arcs: [
      for (final BotArcSpec r in a.arcs) r.withPrefix('a', out),
      for (final BotArcSpec r in b.arcs) r.withPrefix('b', t),
    ],
    // the pastille belongs to one of the two states, it does not blend
    notif: t < 0.5 ? a.notif : b.notif,
    dotsBehind: t < 0.5 ? a.dotsBehind : b.dotsBehind,
  );
}

/// Eye-center offset for a given (shape, state, expression). It is READ from
/// a table and interpolated, never re-solved per frame — solving per frame
/// produced visible motion artefacts in seven upstream attempts. While no
/// customizer shape replaces the body, zero is the exact value; the table
/// itself ships with the customizer phase.
({double x, double y}) _eyeOffsetTable(
    List<double>? radii, BloubBotState state, String? expressionId) {
  return const (x: 0, y: 0);
}

/// The engine. All external state enters through DATED setters — never a
/// variable read during `sample`, or the engine stops being a pure function
/// of time.
class BloubBotEngine {
  BloubBotEngine({
    this.scale = kBotRayon,
    BloubBotState initial = BloubBotState.idle,
    List<double>? shape,
    BotExpression? expression,
  })  : _cur = initial,
        _shape = shape,
        _expr = expression;

  /// Resting ball radius, in viewBox units.
  final double scale;

  BloubBotState _cur;
  BloubBotState? _prev;

  /// FROZEN departure pose, set only when a state change lands while a fade
  /// is already in progress. See [setState].
  BotPose? _departFige;
  double _tCur = 0;
  double _tPrev = 0;
  double _blinkAt = -10;

  List<double>? _shape;
  List<double>? _shapePrev;
  double _shapeAt = -10;
  BotExpression? _expr;
  BotExpression? _exprPrev;
  double _exprAt = -10;
  BotLook _look = BotLook.none;
  BotLook _lookPrev = BotLook.none;
  double _lookAt = -10;
  double _lookMorphDur = lookMorph;

  /// Morph duration when the body shape changes.
  static const double shapeMorph = 0.45;

  /// Gaze catch-up duration toward the target. Shorter than [shapeMorph]: a
  /// following gaze must look attentive, not viscous.
  static const double lookMorph = 0.24;

  BloubBotState get state => _cur;

  /// Resting expression picked in the customizer. Like the shape, it glides
  /// to the new value instead of jumping.
  void setExpression(BotExpression? expression, [double now = 0]) {
    if (identical(expression, _expr)) return;
    _exprPrev = _expr;
    _expr = expression;
    _exprAt = now;
  }

  BotExpression? _exprAtTime(double now) {
    final BotExpression? to = _expr;
    final BotExpression? from = _exprPrev;
    if (to == null || from == null) return to;
    final double k = (now - _exprAt) / shapeMorph;
    if (k >= 1) return to;
    return botBlendExpression(from, to, botEaseOutQuint(botClamp(k)));
  }

  /// Shape picked in the customizer. It only replaces the body on resting
  /// (`baseBody`) states: elsewhere the silhouette IS the animation and must
  /// not be overwritten.
  void setShape(List<double>? radii, [double now = 0]) {
    if (identical(radii, _shape)) return;
    _shapePrev = _shape;
    _shape = radii;
    _shapeAt = now;
  }

  /// Effective shape at [now], morph in progress included. Does NOT null out
  /// `_shapePrev` when the morph ends: `sample` must stay a pure function of
  /// time, so re-reading a past date must return the intermediate image.
  List<double>? _shapeAtTime(double now) {
    final List<double>? to = _shape;
    final List<double>? from = _shapePrev;
    if (to == null || from == null) return to;
    final double k = (now - _shapeAt) / shapeMorph;
    if (k >= 1) return to;
    final double t = botEaseOutQuint(botClamp(k));
    // allocates only during the morph; outside it the list is returned as-is
    return List.generate(to.length, (i) => botLerp(from[i], to[i], t),
        growable: false);
  }

  /// New gaze target, null to return to the state's own. It restarts from
  /// the CURRENT value (not the previous target): this is called on every
  /// pointer move, and restarting from the old target would step the gaze
  /// back before each catch-up — the follow would tremble instead of gliding.
  void setLook(BotLook? look, double now, [double morph = lookMorph]) {
    // A non-finite target is refused. The engine KEEPS the last one: a NaN
    // set once would propagate to every frame and the bot would never rest
    // again. The engine does not depend on callers' prudence to stay
    // replayable.
    if (look != null &&
        !(look.yaw + look.pitch + look.mix + look.spin + look.wander)
            .isFinite) {
      return;
    }
    _lookPrev = _lookAtTime(now);
    _look = look ?? BotLook.none;
    _lookAt = now;
    _lookMorphDur = morph;
  }

  BotLook _lookAtTime(double now) {
    final double k = (now - _lookAt) / _lookMorphDur;
    if (k >= 1) return _look;
    return _lerpLook(_lookPrev, _look, botEaseOutQuint(botClamp(k)));
  }

  BotPose _posed(
      BotStateDef def, double t, List<double>? shape, BotExpression? expr) {
    BotPose pose = def.pose(t);
    if (def.baseBody && shape != null) {
      // keep the pose (rotation, offset, squash) and swap only the profile
      pose = BotPose(
        sil: pose.sil.copyWith(radii: shape),
        offX: pose.offX,
        offY: pose.offY,
        gaze: pose.gaze,
        split: pose.split,
        eyes: pose.eyes,
        eyeAlpha: pose.eyeAlpha,
        bodyAlpha: pose.bodyAlpha,
        dots: pose.dots,
        arcs: pose.arcs,
        notif: pose.notif,
        dotsBehind: pose.dotsBehind,
      );
    }
    if (def.baseFace && expr != null) {
      pose = BotPose(
        sil: pose.sil,
        offX: pose.offX,
        offY: pose.offY,
        gaze: expr.gaze,
        split: expr.split,
        eyes: expr.eyes,
        eyeAlpha: pose.eyeAlpha,
        bodyAlpha: pose.bodyAlpha,
        dots: pose.dots,
        arcs: pose.arcs,
        notif: pose.notif,
        dotsBehind: pose.dotsBehind,
      );
    }
    return pose;
  }

  /// Eye offset at [now] for a given state. One morph axis: read the table
  /// on its two ENDPOINTS and interpolate with that morph's curve — never on
  /// the interpolated value, which has no identity and exists in no table
  /// (feeding it to the solver is what made earlier versions tremble).
  ({double x, double y}) _eyeOffsetAtTime(double now, BloubBotState state) {
    ({double x, double y}) onAxis(double start, double dur,
        ({double x, double y}) a, ({double x, double y}) b) {
      if (a == b) return b;
      final double k = (now - start) / dur;
      if (k >= 1) return b;
      final double t = botEaseOutQuint(botClamp(k));
      return (x: botLerp(a.x, b.x, t), y: botLerp(a.y, b.y, t));
    }

    // expression axis, for each of the two shapes in play
    ({double x, double y}) byShape(List<double>? radii) => onAxis(
          _exprAt,
          shapeMorph,
          _eyeOffsetTable(radii, state, _exprPrev?.id),
          _eyeOffsetTable(radii, state, _expr?.id),
        );

    // then the shape axis
    return onAxis(_shapeAt, shapeMorph, byShape(_shapePrev), byShape(_shape));
  }

  /// Restarts on [id] with NO previous state, like a fresh engine set on it.
  /// That is what "rewind" means here — [setState] alone cannot do it: it
  /// keeps the left state to fade it, which is exactly right in playback and
  /// exactly wrong when returning to the start of a sequence.
  void reset(BloubBotState id, double now) {
    _cur = id;
    _prev = null;
    _departFige = null;
    _tCur = now;
    _tPrev = now;
    _blinkAt = -10;
  }

  /// Origin of the fade in progress: the frozen pose if there is one, else
  /// the left state evaluated at its own elapsed time — hence still
  /// animating, which is wanted.
  BotPose? _origin(double now, List<double>? shape, BotExpression? expr) {
    if (_departFige != null) return _departFige;
    final BloubBotState? prev = _prev;
    if (prev == null) return null;
    return _posed(botStates[prev]!, math.max(0, now - _tPrev), shape, expr);
  }

  /// Composite pose at [now], fade in progress included: exactly what
  /// `sample` blends, before the resting-life and gaze layers. Extracted so
  /// [setState] can freeze it.
  BotPose _composedPose(double now) {
    final BotStateDef def = botStates[_cur]!;
    final List<double>? shape = _shapeAtTime(now);
    final BotExpression? expr = _exprAtTime(now);
    final BotPose pose = _posed(def, math.max(0, now - _tCur), shape, expr);
    final double since = now - _tCur;
    if (since >= def.morph) return pose;
    final BotPose? origin = _origin(now, shape, expr);
    if (origin == null) return pose;
    return _blendPose(origin, pose, botEaseOutQuint(botClamp(since / def.morph)));
  }

  /// Dated state change. The engine keeps only ONE slot of history, so a
  /// change landing during a fade used to replace the blend origin with the
  /// FULL pose of the state being left instead of the partially-blended
  /// frame on screen (measured: 35.9 px jump vs 8.0 px of normal motion). So
  /// the composite pose is frozen and blended from — continuous by
  /// construction, however many changes are chained. And ONLY in that case:
  /// freezing on every change would stop the left state's own animation dead
  /// for the whole fade, when outside a fade there is nothing to fix.
  void setState(BloubBotState id, double now) {
    if (id == _cur) return;
    final double morph = botStates[_cur]!.morph;
    final bool midFade = _prev != null && now - _tCur < morph;
    _departFige = midFade ? _composedPose(now) : null;
    _prev = _cur;
    _tPrev = _tCur;
    _cur = id;
    _tCur = now;
    // In the video, every shape change is masked by a blink.
    if (botStates[id]!.blinkIn) _blinkAt = now;
  }

  BotFrame sample(double now) {
    final double r = scale;
    final BotStateDef def = botStates[_cur]!;
    final List<double>? shape = _shapeAtTime(now);
    final BotExpression? expr = _exprAtTime(now);
    BotPose pose = _posed(def, math.max(0, now - _tCur), shape, expr);
    ({double x, double y}) offset = _eyeOffsetAtTime(now, _cur);

    // --- transition -------------------------------------------------------
    final double since = now - _tCur;
    // The previous state is never purged: `since < def.morph` is enough to
    // ignore it once the fade is over, and forgetting it would make the
    // engine non-replayable — the innocent-looking optimisation that breaks
    // everything.
    final BotPose? origin =
        since < def.morph ? _origin(now, shape, expr) : null;
    if (origin != null) {
      // Exponential ease-out: the measured curve. The ratio is clamped —
      // reading a date BEFORE the state change would give a negative ratio,
      // which the ease-out extrapolates thirty times too far.
      final double ratio = botEaseOutQuint(botClamp(since / def.morph));
      pose = _blendPose(origin, pose, ratio);
      // The eye offset follows the SAME curve as the silhouette that
      // motivates it.
      final BloubBotState? left = _prev;
      if (left != null) {
        final ({double x, double y}) before = _eyeOffsetAtTime(now, left);
        offset = (
          x: botLerp(before.x, offset.x, ratio),
          y: botLerp(before.y, offset.y, ratio),
        );
      }
    }

    // --- resting life -----------------------------------------------------
    final bool alive = pose.eyeAlpha > 0.01;
    final BotLook look = _lookAtTime(now);
    final BotLiveliness life = botLiveliness(now,
        wander: alive ? look.wander : 0, blink: alive);

    // The two aims REPLACE the pose's instead of adding to it (see
    // [BotLook]), and the spin is subtracted along the way. The drift is
    // added AFTER the mix — it must survive a turned head with no pointer.
    final BotGaze gaze = BotGaze(
      yaw: botLerp(pose.gaze.yaw, look.yaw, look.mix) + life.dYaw - look.spin,
      pitch: botLerp(pose.gaze.pitch, look.pitch, look.mix) + life.dPitch,
      // roll follows nothing: the head is tilted −13° in the video, and
      // rolling it with the cursor breaks that signature
      roll: pose.gaze.roll + life.dRoll,
    );

    // blink triggered by the state change, on top of the schedule
    final double forced = botClamp((now - _blinkAt) / 0.2);
    final double forcedLid = forced < 1 ? (forced * 2 - 1).abs() : 1;
    final double lid = math.min(life.lid, forcedLid);

    final double offX = pose.offX + life.driftX;
    final double offY = pose.offY + life.driftY;

    // --- body -------------------------------------------------------------
    final BotSilhouette sil = pose.sil.copyWith(
      cx: pose.sil.cx + offX,
      cy: pose.sil.cy + offY,
      sy: pose.sil.sy * life.breath,
    );
    final List<BotPoint> body = botSilPoints(sil, r);

    // --- eyes -------------------------------------------------------------
    // The eyes live on a sphere of radius 1; as soon as the silhouette is
    // not a circle, they are pulled back pro rata of the real radius in
    // their direction, else they overflow and the mask cuts them.
    double bodyRadius(double x, double y) =>
        botRadiusAtAngle(pose.sil.radii, math.atan2(y, x) - pose.sil.rot);

    final List<BotRenderedEye> eyes = [];
    if (pose.eyeAlpha > 0.01) {
      final List<BotEyePose> poses = botEyePoses(gaze, r, pose.split);
      for (int i = 0; i < 2; i++) {
        final BotEyePose e = poses[i];
        if (e.depth <= 0.02) continue;
        final BotEyeCfg cfg = pose.eyes[i];
        final double fit = bodyRadius(e.x, e.y);
        // The eye's own tilt: compose the tangent frame with a rotation in
        // the eye's plane (Basis x Rot) — mirrored tilts between the eyes.
        final double phi = cfg.tilt * math.pi / 180;
        final double cp = math.cos(phi);
        final double sp = math.sin(phi);
        final double ax = e.a * cp + e.c * sp;
        final double ay = e.b * cp + e.d * sp;
        final double cx2 = -e.a * sp + e.c * cp;
        final double cy2 = -e.b * sp + e.d * cp;
        // The blink applies AFTER all that: a vertical screen-space squash,
        // not one along the capsule's axis.
        final double k = botBlinkScale(math.min(lid, cfg.open));
        eyes.add(BotRenderedEye(
          w: cfg.w * r,
          h: cfg.h * r,
          a: ax,
          b: ay * k,
          c: cx2,
          d: cy2 * k,
          tx: e.x * fit + (offX + offset.x) * r,
          ty: e.y * fit + (offY + offset.y) * r,
          alpha: pose.eyeAlpha * botClamp(e.depth / 0.12),
        ));
      }
    }

    // --- decor ------------------------------------------------------------
    final List<BotDot> dots = [
      for (final BotDot p in pose.dots)
        if (p.opacity > 0.01 && p.r > 0.0005)
          BotDot(
            x: (p.x + offX) * r,
            y: (p.y + offY) * r,
            r: p.r * r,
            opacity: p.opacity,
            colorArgb: p.colorArgb,
            depth: p.depth,
            shape: p.shape,
            rotDeg: p.rotDeg,
          ),
    ];

    // the pastille sits on the outline: it follows the shape too
    BotCircleRender? notif;
    BotCircleRender? notch;
    final BotNotif? n = pose.notif;
    if (n != null) {
      final double nFit = bodyRadius(n.x, n.y);
      final double nx = (n.x * nFit + offX) * r;
      final double ny = (n.y * nFit + offY) * r;
      notif = BotCircleRender(x: nx, y: ny, r: n.r * r);
      notch = BotCircleRender(x: nx, y: ny, r: n.notch * r);
    }

    return BotFrame(
      body: body,
      bodyAlpha: pose.bodyAlpha,
      eyes: eyes,
      dots: dots,
      dotsBehind: pose.dotsBehind,
      // States declare arcs in resting-ball-radius units; the engine alone
      // knows the viewBox scale, so it rasterizes. (Renderer lands with the
      // decor states — until then poses declare no arcs.)
      arcs: const [],
      notif: notif,
      notch: notch,
    );
  }
}
