// Pure, time-addressable Mochi animation model.
//
// Adapted from the public Coucou desktop BotEngine. No Flutter, wall clock,
// or unseeded randomness enters sample(t): user events are dated by the
// widget and the same input/event history always returns the same frame.

import 'dart:math' as math;

const double _tau = math.pi * 2;

enum CoucouMochiState {
  idle,
  working,
  thinking,
  searching,
  approval,
  question,
  error,
  finished,
  ratelimit,
  sleeping,
  dizzy,
}

enum CoucouMochiEye {
  pill,
  wide,
  dot,
  line,
  flat,
  happy,
  closed,
  spiral,
  heart,
  star,
  tired,
  wink,
  cup,
}

enum CoucouMochiBadge { dots, bang, question, dot }

enum CoucouMochiParticleType { heart, star, spark, sweat, z }

class CoucouMochiParticle {
  const CoucouMochiParticle({
    required this.type,
    required this.x,
    required this.y,
    required this.alpha,
    required this.size,
    required this.rotation,
  });

  final CoucouMochiParticleType type;
  final double x;
  final double y;
  final double alpha;
  final double size;
  final double rotation;
}

class CoucouMochiFrame {
  const CoucouMochiFrame({
    required this.time,
    required this.state,
    required this.bodyColor,
    required this.tint,
    required this.eye,
    required this.eyeOpen,
    required this.eyeScale,
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.tilt,
    required this.scaleX,
    required this.scaleY,
    required this.offsetX,
    required this.offsetY,
    required this.blush,
    required this.badge,
    required this.badgeColor,
    required this.badgeScale,
    required this.hands,
    required this.handWave,
    required this.morph,
    required this.slotOpen,
    required this.chewing,
    required this.particles,
  });

  final double time;
  final CoucouMochiState state;
  final int bodyColor;
  final double tint;
  final CoucouMochiEye eye;
  final double eyeOpen;
  final double eyeScale;
  final double yaw;
  final double pitch;
  final double roll;
  final double tilt;
  final double scaleX;
  final double scaleY;
  final double offsetX;
  final double offsetY;
  final double blush;
  final CoucouMochiBadge? badge;
  final int badgeColor;
  final double badgeScale;
  final double hands;
  final double handWave;
  final double morph;
  final double slotOpen;
  final bool chewing;
  final List<CoucouMochiParticle> particles;
}

class _StateStyle {
  const _StateStyle({
    required this.color,
    required this.tint,
    required this.eye,
    this.badge,
    this.bounces = false,
    this.scans = false,
    this.breathes = false,
    this.sweat = false,
    this.lookX = 0,
    this.lookY = 0,
    this.tilt = 0,
  });

  final int color;
  final double tint;
  final CoucouMochiEye eye;
  final CoucouMochiBadge? badge;
  final bool bounces;
  final bool scans;
  final bool breathes;
  final bool sweat;
  final double lookX;
  final double lookY;
  final double tilt;
}

const Map<CoucouMochiState, _StateStyle> _styles = {
  CoucouMochiState.idle: _StateStyle(
    color: 0xFFE6E9EE,
    tint: 0,
    eye: CoucouMochiEye.pill,
  ),
  CoucouMochiState.working: _StateStyle(
    color: 0xFF3B9EFF,
    tint: .72,
    eye: CoucouMochiEye.pill,
    badge: CoucouMochiBadge.dots,
  ),
  CoucouMochiState.thinking: _StateStyle(
    color: 0xFF8B5CF6,
    tint: .72,
    eye: CoucouMochiEye.pill,
    badge: CoucouMochiBadge.dots,
    lookX: .55,
    lookY: .55,
  ),
  CoucouMochiState.searching: _StateStyle(
    color: 0xFF6365F2,
    tint: .72,
    eye: CoucouMochiEye.pill,
    badge: CoucouMochiBadge.dots,
    scans: true,
  ),
  CoucouMochiState.approval: _StateStyle(
    color: 0xFFF5A524,
    tint: .78,
    eye: CoucouMochiEye.wide,
    badge: CoucouMochiBadge.bang,
    bounces: true,
  ),
  CoucouMochiState.question: _StateStyle(
    color: 0xFF22D3EE,
    tint: .75,
    eye: CoucouMochiEye.pill,
    badge: CoucouMochiBadge.question,
    tilt: .17,
  ),
  CoucouMochiState.error: _StateStyle(
    color: 0xFFF4505E,
    tint: .78,
    eye: CoucouMochiEye.flat,
    badge: CoucouMochiBadge.dot,
  ),
  CoucouMochiState.finished: _StateStyle(
    color: 0xFF34D499,
    tint: .35,
    eye: CoucouMochiEye.happy,
    badge: CoucouMochiBadge.dot,
  ),
  CoucouMochiState.ratelimit: _StateStyle(
    color: 0xFFFB923C,
    tint: .72,
    eye: CoucouMochiEye.tired,
    badge: CoucouMochiBadge.dot,
    sweat: true,
  ),
  CoucouMochiState.sleeping: _StateStyle(
    color: 0xFF94A2B8,
    tint: .32,
    eye: CoucouMochiEye.closed,
    breathes: true,
  ),
  CoucouMochiState.dizzy: _StateStyle(
    color: 0xFFF472B6,
    tint: .70,
    eye: CoucouMochiEye.spiral,
  ),
};

class _ParticleBurst {
  const _ParticleBurst(this.type, this.count, this.at, this.seed);
  final CoucouMochiParticleType type;
  final int count;
  final double at;
  final int seed;
}

/// Stateful event source with a pure sample(t) output.
///
/// The widget calls event methods with its Ticker clock. State, gaze, emotes,
/// and particle bursts are retained as dated inputs; [sample] only evaluates
/// those inputs and never advances hidden time.
class CoucouMochiEngine {
  CoucouMochiEngine({
    CoucouMochiState initial = CoucouMochiState.idle,
    this.isMini = false,
    this.behaviorSeed = 41,
  }) : _state = initial,
       _stateAt = 0,
       _fromColor = _styles[initial]!.color;

  final bool isMini;
  final int behaviorSeed;
  String? _permanentEmote;
  double _miniAt = 0;
  void setPermanentEmote(String? emote, double t) {
    _permanentEmote = emote;
    _miniAt = t;
  }

  CoucouMochiState _state;
  double _stateAt;
  int _fromColor;
  CoucouMochiFrame? _stateFrom;
  CoucouMochiFrame? _emoteFrom;
  CoucouMochiBadge? _oldBadge;
  int _oldBadgeColor = 0;
  double _oldBadgeScale = 0;
  double _badgeAt = 0;
  final List<double> _taps = [];
  final List<_ParticleBurst> _bursts = [];
  int _seed = 41;

  double _lookX = 0;
  double _lookY = 0;
  double _lookFromX = 0;
  double _lookFromY = 0;
  double _lookAt = 0;

  double _tapAt = -100;
  double _dizzyAt = -100;
  double _dizzyUntil = -100;
  CoucouMochiFrame? _dizzyFrom;
  double _greetAt = -100;
  double _greetInterruptedAt = -100;
  double _interruptedHands = 0;
  double _emoteAt = -100;
  double _emoteDuration = 0;
  CoucouMochiEye? _emoteEye;
  String? _emote;
  double _hoverAt = -100;
  double _hoverFrom = 1;
  bool _hovering = false;

  double _morphFrom = 0;
  double _morphTo = 0;
  double _morphAt = -100;
  double _morphDuration = .55;
  double _gulpAt = -100;

  CoucouMochiState get state => _state;
  bool isDizzy(double t) =>
      _state == CoucouMochiState.dizzy || (t >= _dizzyAt && t < _dizzyUntil);

  void setState(CoucouMochiState next, double t, {bool force = false}) {
    _prune(t);
    if (!force && next == _state) return;
    final previous = sample(t);
    final prev = _state;
    _stateFrom = previous;
    _fromColor = previous.bodyColor;
    if (previous.badge != _styles[next]!.badge ||
        previous.badgeColor != _styles[next]!.color) {
      _oldBadge = previous.badge;
      _oldBadgeColor = previous.badgeColor;
      _oldBadgeScale = previous.badgeScale;
      _badgeAt = t;
    }
    _state = next;
    _stateAt = t;
    if (next == CoucouMochiState.finished) {
      _emit(CoucouMochiParticleType.spark, 5, t + .5);
    }
    if (next == CoucouMochiState.ratelimit) {
      _emit(CoucouMochiParticleType.sweat, 1, t);
    }
    if (next == CoucouMochiState.question ||
        (![
              CoucouMochiState.finished,
              CoucouMochiState.error,
              CoucouMochiState.approval,
              CoucouMochiState.dizzy,
              CoucouMochiState.ratelimit,
            ].contains(next) &&
            (prev != CoucouMochiState.idle || next != CoucouMochiState.idle))) {
      _emitBlink(t);
    }
  }

  /// Returns true when this tap completes the three-hit dizzy gesture.
  bool tap(double t) {
    interruptGreet(t);
    if (isDizzy(t)) return false;
    _prune(t);
    _taps.removeWhere((at) => t - at >= 1.7);
    _taps.add(t);
    _tapAt = t;
    _emote = null;
    _emoteEye = null;
    _emoteAt = -100;
    if (_taps.length >= 3) {
      _taps.clear();
      _dizzyFrom = sample(t);
      _oldBadge = _dizzyFrom!.badge;
      _oldBadgeColor = _dizzyFrom!.badgeColor;
      _oldBadgeScale = _dizzyFrom!.badgeScale;
      _badgeAt = t;
      _dizzyAt = t;
      _dizzyUntil = t + 3.3;
      return true;
    }
    return false;
  }

  void greet(double t) {
    _prune(t);
    _greetAt = t;
    _greetInterruptedAt = -100;
    _emitBlink(t + .55);
    _emitBlink(t + 1.5);
  }

  void interruptGreet(double t) {
    if (_greetAt < 0 || t >= _greetAt + 2.05) return;
    _interruptedHands = sample(t).hands;
    _greetInterruptedAt = t;
    _blinkEvents.removeWhere(
      (at) =>
          at > t &&
          ((at - _greetAt - .55).abs() < .001 ||
              (at - _greetAt - 1.5).abs() < .001),
    );
  }

  void triggerEmote(String emote, double t, {double duration = 1.8}) {
    _prune(t);
    _emoteFrom = sample(t);
    _emote = emote;
    _emoteAt = t;
    _emoteDuration = emote == 'annoyed' ? .8 : math.max(.6, duration);
    _emoteEye = switch (emote) {
      'love' => CoucouMochiEye.heart,
      'surprised' => CoucouMochiEye.dot,
      'proud' => CoucouMochiEye.star,
      'wink' => CoucouMochiEye.wink,
      'yawn' => CoucouMochiEye.tired,
      'happy' => CoucouMochiEye.happy,
      'annoyed' => CoucouMochiEye.line,
      _ => null,
    };
    switch (emote) {
      case 'love':
        _emit(CoucouMochiParticleType.heart, 4, t);
        break;
      case 'proud':
        _emit(CoucouMochiParticleType.star, 5, t);
        break;
      case 'yawn':
        _emit(CoucouMochiParticleType.z, 2, t + .7);
        break;
      default:
        break;
    }
  }

  void setLook(double x, double y, double t) {
    _prune(t);
    final double k = 1 - math.pow(.0025, math.max(0.0, t - _lookAt)).toDouble();
    _lookFromX = _lookFromX + (_lookX - _lookFromX) * k;
    _lookFromY = _lookFromY + (_lookY - _lookFromY) * k;
    _lookX = x.clamp(-1.0, 1.0).toDouble();
    _lookY = y.clamp(-1.0, 1.0).toDouble();
    _lookAt = t;
  }

  void setHover(bool hovering, double t) {
    _prune(t);
    _hoverFrom = sample(t).eyeScale;
    _hoverAt = t;
    _hovering = hovering;
    if (hovering) _emitBlink(t);
  }

  void setMorph(double target, double t, {double? duration}) {
    _prune(t);
    _morphFrom = _morphValue(t);
    _morphTo = target.clamp(0.0, 1.0).toDouble();
    _morphAt = t;
    _morphDuration = duration ?? (target > .5 ? .55 : .65);
  }

  void gulp(double t) {
    _prune(t);
    _gulpAt = t;
    _emitBlink(t);
  }

  CoucouMochiFrame sample(double t) {
    final bool tappedDizzy = t >= _dizzyAt && t < _dizzyUntil;
    final bool dizzy = tappedDizzy || _state == CoucouMochiState.dizzy;
    final CoucouMochiState state = tappedDizzy
        ? CoucouMochiState.dizzy
        : _state;
    final _StateStyle style = _styles[state]!;
    final double stateAge = math.max(
      0.0,
      t - (tappedDizzy ? _dizzyAt : _stateAt),
    );
    final double lookAge = math.max(0.0, t - _lookAt);
    final double lookEase = 1 - math.pow(.0025, lookAge).toDouble();

    double yaw = (_lookFromX + (_lookX - _lookFromX) * lookEase) * .62;
    double pitch = (_lookFromY + (_lookY - _lookFromY) * lookEase) * .5;
    if (style.lookX != 0 || style.lookY != 0) {
      yaw = yaw * .35 + style.lookX * .55;
      pitch = pitch * .3 + style.lookY * .5;
    }
    if (style.scans) {
      yaw = math.sin(t * 2.6) * .6;
      pitch = -.06;
    }
    if (state == CoucouMochiState.sleeping) {
      yaw = 0;
      pitch = -.14;
    }
    if (dizzy) yaw = math.sin(stateAge * 9) * .25;

    final double breathing = style.breathes ? math.sin(t * 1.8) * .035 : 0;
    double scaleY = 1 + breathing;
    double scaleX = 1 - breathing * .57;
    double offsetY = style.bounces ? -math.sin(t * 5.2).abs() * .07 : 0;
    double offsetX = 0;
    double tilt = style.tilt;
    double roll = 0;
    double eyeScale = _hoverAt < 0
        ? 1
        : _lerp(
            _hoverFrom,
            _hovering ? 1.08 : 1,
            1 - math.pow(.0008, math.max(0, t - _hoverAt)).toDouble(),
          );
    double blush = style.tint * .5;
    double hands = 0;
    double handWave = 0;

    // Preserve the current pose on state changes; upstream eases its targets
    // at these two exponential rates instead of snapping to the new pose.
    if (_stateFrom != null && !tappedDizzy) {
      final lookK = 1 - math.pow(.0025, stateAge).toDouble();
      final k = 1 - math.pow(.0008, stateAge).toDouble();
      yaw = _lerp(_stateFrom!.yaw, yaw, lookK);
      pitch = _lerp(_stateFrom!.pitch, pitch, lookK);
      tilt = _lerp(_stateFrom!.tilt, tilt, k);
      scaleX = _lerp(_stateFrom!.scaleX, scaleX, k);
      scaleY = _lerp(_stateFrom!.scaleY, scaleY, k);
      offsetY = _lerp(_stateFrom!.offsetY, offsetY, k);
    }

    final double tapAge = t - _tapAt;
    if (tapAge >= 0 && tapAge < .37) {
      final double p = tapAge;
      scaleY *= _key(p, const [0, .07, .2, .37], const [1, .78, 1.1, 1], const [
        _out,
        _out,
        _inOut,
      ]);
      scaleX *= _key(
        p,
        const [0, .07, .2, .37],
        const [1, 1.16, .95, 1],
        const [_out, _out, _inOut],
      );
    }

    if (dizzy && stateAge < 1.3) {
      roll = _easeInOut(_clamp01(stateAge / 1.3)) * _tau * 2;
    } else if (state == CoucouMochiState.finished && stateAge < .95) {
      roll = _easeInOut(_clamp01(stateAge / .95)) * _tau;
    }
    if (state == CoucouMochiState.error && stateAge < .28) {
      offsetX = _key(
        stateAge,
        const [0, .05, .12, .19, .28],
        const [0, .08, -.08, .05, 0],
        const [_out, _inOut, _inOut, _out],
      );
    }
    if (state == CoucouMochiState.approval && stateAge < .45) {
      offsetY = _key(
        stateAge,
        const [0, .15, .45],
        [_stateFrom?.offsetY ?? 0, -.2, 0],
        const [_out, _easeBack],
      );
    }

    final double greetingAge = t - _greetAt;
    final greetingInterrupted =
        _greetInterruptedAt >= _greetAt && t >= _greetInterruptedAt;
    if (greetingAge >= 0 && greetingAge < 1.75 && !greetingInterrupted) {
      hands = greetingAge < .25
          ? 0
          : greetingAge < 1.55
          ? _out(_clamp01((greetingAge - .25) / .28))
          : 1 - _inOut(_clamp01((greetingAge - 1.55) / .2));
      handWave = greetingAge;
      tilt = greetingAge >= .45 && greetingAge < 1.55
          ? -.06 + math.sin(_tau * 1.2 * (greetingAge - .45)) * .07
          : style.tilt;
      if (greetingAge < .44) {
        offsetY = _key(
          greetingAge,
          const [0, .22, .44],
          const [0, -.06, 0],
          const [_out, _easeBack],
        );
      }
      if (greetingAge >= .25 && greetingAge < .61) {
        scaleY = _key(
          greetingAge - .25,
          const [0, .1, .36],
          const [1, .95, 1],
          const [_out, _easeBack],
        );
        scaleX = _key(
          greetingAge - .25,
          const [0, .1, .36],
          const [1, 1.04, 1],
          const [_out, _easeBack],
        );
      }
    }
    if (greetingInterrupted && t < _greetInterruptedAt + .15) {
      hands = _interruptedHands * (1 - _inOut((t - _greetInterruptedAt) / .15));
    }

    final double emoteAge = t - _emoteAt;
    final bool emoteOn = emoteAge >= 0 && emoteAge < _emoteDuration;
    CoucouMochiEye eye = style.eye;
    if (emoteOn && _emoteEye != null) eye = _emoteEye!;
    if (tapAge >= 0 && tapAge < .8 && !dizzy) eye = CoucouMochiEye.line;
    if (greetingAge >= 0 &&
        greetingAge < 2.05 &&
        !greetingInterrupted &&
        _greetAt >= _emoteAt &&
        _greetAt >= _tapAt) {
      eye = CoucouMochiEye.happy;
    }
    if (dizzy) eye = CoucouMochiEye.spiral;
    final recoveryAge = t - _dizzyUntil;
    if (_dizzyUntil > 0 &&
        recoveryAge >= 0 &&
        recoveryAge < 1.8 &&
        _emoteAt < _dizzyUntil &&
        _tapAt < _dizzyUntil) {
      eye = CoucouMochiEye.happy;
      blush = math.max(
        blush,
        _key(recoveryAge, const [0, .2, .8], const [0, .6, 0], const [
          _out,
          _inOut,
        ]),
      );
    }

    if (emoteOn && _emote == 'love') {
      blush = math.max(
        blush,
        _key(
          emoteAge,
          [0, .3, _emoteDuration - .3, _emoteDuration],
          [_emoteFrom?.blush ?? 0, 1, 1, 0],
          const [_out, _linear, _inOut],
        ),
      );
      if (emoteAge < .46) {
        offsetY = _key(
          emoteAge,
          const [0, .16, .46],
          [_emoteFrom?.offsetY ?? 0, -.1, 0],
          const [_out, _easeBack],
        );
      }
    } else if (emoteOn && _emote == 'happy') {
      blush = math.max(
        blush,
        _key(
          emoteAge,
          const [0, .2, .8],
          [_emoteFrom?.blush ?? 0, .6, 0],
          const [_out, _inOut],
        ),
      );
    } else if (_emote == 'proud' &&
        emoteAge >= 0 &&
        emoteAge < _emoteDuration + .05) {
      blush = math.max(
        blush,
        _key(
          emoteAge,
          [0, .25, _emoteDuration - .25, _emoteDuration + .05],
          [_emoteFrom?.blush ?? 0, .7, .7, 0],
          const [_out, _linear, _inOut],
        ),
      );
    }
    if (emoteOn && _emote == 'surprised') {
      eyeScale = _key(emoteAge, const [0, .12, .62], const [1, 1.25, 1], const [
        _out,
        _inOut,
      ]);
      if (emoteAge < .52) {
        offsetY = _key(
          emoteAge,
          const [0, .14, .52],
          [_emoteFrom?.offsetY ?? 0, -.3, 0],
          const [_out, _easeBack],
        );
      }
    }
    if (emoteOn && _emote == 'wink') {
      tilt = _key(
        emoteAge,
        [0, .16, _emoteDuration - .24, _emoteDuration],
        [_emoteFrom?.tilt ?? 0, .12, .12, 0],
        const [_out, _linear, _inOut],
      );
    }
    if (emoteOn && _emote == 'proud') {
      tilt = _key(
        emoteAge,
        [0, .22, _emoteDuration - .28, _emoteDuration],
        [_emoteFrom?.tilt ?? 0, -.14, -.14, 0],
        const [_out, _linear, _inOut],
      );
    }
    if (emoteOn && _emote == 'yawn') {
      scaleY = _key(emoteAge, const [0, .5, 1], const [1, 1.12, 1], const [
        _inOut,
        _inOut,
      ]);
      scaleX = _key(emoteAge, const [0, .5, 1], const [1, .94, 1], const [
        _inOut,
        _inOut,
      ]);
      if (emoteAge >= .7) eye = CoucouMochiEye.closed;
    }
    double eyeOpen = state == CoucouMochiState.sleeping ? .05 : 1;
    if (state != CoucouMochiState.sleeping && !dizzy) {
      for (final double at in _blinkTimes(t)) {
        eyeOpen = math.min(eyeOpen, _blinkValue(t - at));
      }
    }
    final recovered =
        _dizzyUntil > 0 && t >= _dizzyUntil && _stateAt < _dizzyUntil;
    final colorAge = recovered ? t - _dizzyUntil : stateAge;
    final double tintBlend = 1 - math.pow(.002, colorAge).toDouble();
    final int color = _mixColor(
      recovered
          ? _styles[CoucouMochiState.dizzy]!.color
          : tappedDizzy
          ? _dizzyFrom!.bodyColor
          : _fromColor,
      style.color,
      tintBlend,
    );
    final recoveringBadge = recovered && _dizzyUntil > _badgeAt;
    final double badgeAge = t - (recoveringBadge ? _dizzyUntil : _badgeAt);
    final double badgeScale = badgeAge < .1
        ? (recoveringBadge ? 0 : _oldBadgeScale) *
              (1 - _inOut(_clamp01(badgeAge / .09)))
        : style.badge == null
        ? 0
        : _easeBack(_clamp01((badgeAge - .1) / .28));

    final double morph = _morphValue(t);
    final bool chewing = t >= _gulpAt + .46 && t < _gulpAt + 1.26;
    final double gulpAge = t - _gulpAt;
    final double slotOpen = math.max(
      0,
      .42 * (_springStep(gulpAge) - _springStep(gulpAge - .46)),
    );
    if (gulpAge >= 0 && gulpAge < .43 && _gulpAt >= _tapAt) {
      scaleY = _key(
        gulpAge,
        const [0, .08, .21, .43],
        const [1, .78, 1.18, 1],
        const [_out, _out, _easeBack],
      );
      scaleX = _key(
        gulpAge,
        const [0, .08, .21, .43],
        const [1, 1.28, .92, 1],
        const [_out, _out, _easeBack],
      );
    }
    if (morph > .5) {
      if (chewing) {
        eye = CoucouMochiEye.happy;
      } else if ((gulpAge >= 0 && gulpAge < .46) || slotOpen > .1) {
        eye = CoucouMochiEye.cup;
      }
    }

    if (isMini) {
      final amp = style.breathes ? .07 : .04;
      scaleY = 1 + math.sin(t * (style.breathes ? 1.8 : 2.2)) * amp;
      scaleX =
          1 -
          math.sin(t * (style.breathes ? 1.8 : 2.2)) *
              (style.breathes ? amp * .57 : .02);
      if (!style.scans && style.lookX == 0 && !dizzy && !style.breathes) {
        double at = 0, fromX = 0, fromY = 0;
        for (int n = 0; at <= t; n++) {
          final x = (-.88 + _random01(behaviorSeed + n * 5) * 1.76) * .62;
          final y = (-.55 + _random01(behaviorSeed + n * 5 + 1)) * .5;
          final next = at + .5 + _random01(behaviorSeed + n * 5 + 2) * 1.5;
          final k = 1 - math.pow(.0025, math.min(t, next) - at).toDouble();
          fromX = _lerp(fromX, x, k);
          fromY = _lerp(fromY, y, k);
          at = next;
        }
        yaw = fromX;
        pitch = fromY;
      }
      if (_permanentEmote != null && _permanentEmote != 'wink' && !emoteOn) {
        eye = switch (_permanentEmote) {
          'love' => CoucouMochiEye.heart,
          'happy' => CoucouMochiEye.happy,
          'annoyed' => CoucouMochiEye.line,
          'proud' => CoucouMochiEye.star,
          'yawn' => CoucouMochiEye.tired,
          'surprised' => CoucouMochiEye.dot,
          _ => eye,
        };
      }
      final times = _miniTimes(t).toList();
      if (times.isNotEmpty) {
        final age = t - times.last;
        switch (_permanentEmote) {
          case 'happy':
            if (age < .48) {
              offsetY = _key(
                age,
                const [0, .12, .32, .48],
                const [0, -.3, .03, 0],
                const [_out, _inOut, _easeBack],
              );
            }
            if (age < .57) {
              scaleY = _key(
                age,
                const [0, .08, .21, .37, .57],
                const [1, .82, 1.18, .88, 1],
                const [_out, _out, _inOut, _easeBack],
              );
              scaleX = _key(
                age,
                const [0, .08, .21, .37, .57],
                const [1, 1.15, .88, 1.06, 1],
                const [_out, _out, _inOut, _easeBack],
              );
            }
          case 'annoyed':
            if (age < .505) {
              yaw = _key(
                age,
                const [0, .05, .14, .22, .295, .365, .505],
                const [0, -.65, .65, -.5, .4, -.2, 0],
                const [_out, _inOut, _inOut, _inOut, _inOut, _out],
              );
            }
          case 'wink':
            if (age < .55) eye = CoucouMochiEye.wink;
            if (age < .62) {
              tilt = _key(
                age,
                const [0, .1, .42, .62],
                const [0, .13, .13, 0],
                const [_out, _linear, _inOut],
              );
            }
          case 'love':
            if (age < .74) {
              tilt = _key(
                age,
                const [0, .18, .52, .74],
                const [0, -.1, .1, 0],
                const [_out, _inOut, _inOut],
              );
            }
        }
      }
    }

    return CoucouMochiFrame(
      time: t,
      state: state,
      bodyColor: color,
      tint: style.tint,
      eye: eye,
      eyeOpen: eyeOpen.clamp(0.0, 1.0).toDouble(),
      eyeScale: eyeScale,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      tilt: tilt,
      scaleX: scaleX,
      scaleY: scaleY,
      offsetX: offsetX,
      offsetY: offsetY,
      blush: blush.clamp(0.0, 1.0).toDouble(),
      badge: badgeAge < .1 ? (recoveringBadge ? null : _oldBadge) : style.badge,
      badgeColor: badgeAge < .1 ? _oldBadgeColor : style.color,
      badgeScale: badgeScale.clamp(0.0, 1.12).toDouble(),
      hands: hands,
      handWave: handWave,
      morph: morph,
      slotOpen: slotOpen,
      chewing: chewing,
      particles: _sampleParticles(t, state),
    );
  }

  double _morphValue(double t) {
    if (_morphAt < 0) return _morphTo;
    return _lerp(
      _morphFrom,
      _morphTo,
      _easeInOut(_clamp01((t - _morphAt) / _morphDuration)),
    );
  }

  void _emitBlink(double t) {
    _blinkEvents.add(t);
  }

  final List<double> _blinkEvents = [];
  void _emit(CoucouMochiParticleType type, int count, double at) {
    if (count <= 0) return;
    _bursts.add(_ParticleBurst(type, count, at, _seed++));
  }

  void _prune(double t) {
    _bursts.removeWhere((b) => t - b.at > 3);
    _blinkEvents.removeWhere((v) => t - v > 1);
  }

  List<CoucouMochiParticle> _sampleParticles(double t, CoucouMochiState state) {
    final List<CoucouMochiParticle> result = [];
    final bursts = <_ParticleBurst>[..._bursts];
    if (isMini && _permanentEmote == 'love') {
      for (final at in _miniTimes(t)) {
        if (t - at < 3) {
          bursts.add(
            _ParticleBurst(
              CoucouMochiParticleType.heart,
              2,
              at,
              behaviorSeed + at.hashCode,
            ),
          );
        }
      }
    }
    if (state == CoucouMochiState.sleeping ||
        (!isMini && _styles[state]!.sweat)) {
      final current = ((t - _stateAt) / 1.3).floor();
      for (int n = math.max(1, current - 2); n <= current; n++) {
        if (state == CoucouMochiState.sleeping || _random01(700 + n) < .5) {
          bursts.add(
            _ParticleBurst(
              state == CoucouMochiState.sleeping
                  ? CoucouMochiParticleType.z
                  : CoucouMochiParticleType.sweat,
              1,
              _stateAt + n * 1.3,
              900 + n,
            ),
          );
        }
      }
    }
    for (final burst in bursts) {
      for (int i = 0; i < burst.count; i++) {
        final age = t - burst.at - i * .14;
        final seed = burst.seed * 101 + i * 31;
        final life = 1.3 + _random01(seed + 1) * .5;
        if (age <= 0 || age >= life) continue;
        final k = age / life;
        final isZ = burst.type == CoucouMochiParticleType.z;
        final x = (_random01(seed + 2) - .5) * .9 + (isZ ? .55 : 0);
        final y = -.7 - _random01(seed + 3) * .2;
        final vx = (_random01(seed + 4) - .5) * .35 + (isZ ? .18 : 0);
        final vy = -(.45 + _random01(seed + 5) * .35);
        final rotation = switch (burst.type) {
          CoucouMochiParticleType.heart => math.sin(age * 6) * .3,
          CoucouMochiParticleType.star => _random01(seed + 6) * _tau + age * 2,
          CoucouMochiParticleType.spark => _random01(seed + 6) * _tau,
          _ => 0.0,
        };
        result.add(
          CoucouMochiParticle(
            type: burst.type,
            x: x + vx * age,
            y: y + vy * age,
            alpha: _clamp01(k < .2 ? k / .2 : 1 - (k - .2) / .8),
            size: (.15 + _random01(seed + 7) * .08) * (1 + k * .4),
            rotation: rotation,
          ),
        );
      }
    }
    return result;
  }

  Iterable<double> _blinkTimes(double t) sync* {
    for (final double at in _blinkEvents) {
      if (t - at >= 0 && t - at < .21) yield at;
    }
    // Seeded scheduling retains the original random intervals and double blinks,
    // while sampling out of order remains reproducible for gallery scrubbing.
    while (_ambientBlinks.last < t) {
      final n = _ambientBlinks.length;
      _ambientBlinks.add(_ambientBlinks.last + 2.2 + _random01(3100 + n) * 3.2);
    }
    for (int n = 0; n < _ambientBlinks.length; n++) {
      final at = _ambientBlinks[n];
      if (t - at >= 0 && t - at < .21) yield at;
      if (_random01(4100 + n) < .22 && t - at >= .23 && t - at < .44) {
        yield at + .23;
      }
    }
  }

  final List<double> _ambientBlinks = [1.5 + _random01(3000) * 2];

  Iterable<double> _miniTimes(double t) sync* {
    double at = _miniAt + .8 + _random01(behaviorSeed + 100) * 1.7;
    for (int n = 0; at <= t; n++) {
      yield at;
      final r = _random01(behaviorSeed + 200 + n);
      at += switch (_permanentEmote) {
        'happy' => 2.2 + r * 1.2,
        'annoyed' => 3 + r * 2.5,
        'wink' => 2.2 + r * 2,
        'love' => 2.6 + r * 1.5,
        _ => 3 + r * 2,
      };
    }
  }

  double _blinkValue(double age) {
    if (age <= 0) return 1;
    if (age < .07) return _lerp(1, .06, _inOut(age / .07));
    if (age < .2) return _lerp(.06, 1, _out((age - .07) / .13));
    return 1;
  }
}

double _random01(int seed) => math.Random(seed).nextDouble();

// Closed-form step response of the upstream mouth spring (0.25 s, damping .6).
// Subtracting a second step at close time preserves both position and velocity.
double _springStep(double t) {
  if (t <= 0) return 0;
  final omega = _tau / .25;
  final wd = omega * .8;
  return 1 -
      math.exp(-.6 * omega * t) * (math.cos(wd * t) + .75 * math.sin(wd * t));
}

int _mixColor(int a, int b, double t) {
  int channel(int shift) {
    final int av = (a >> shift) & 0xff;
    final int bv = (b >> shift) & 0xff;
    return _lerp(av.toDouble(), bv.toDouble(), t).round();
  }

  return (channel(24) << 24) |
      (channel(16) << 16) |
      (channel(8) << 8) |
      channel(0);
}

double _key(
  double t,
  List<double> times,
  List<double> values,
  List<double Function(double)> eases,
) {
  if (t <= times.first) return values.first;
  if (t >= times.last) return values.last;
  for (int i = 0; i < times.length - 1; i++) {
    if (t <= times[i + 1]) {
      final double p = _clamp01((t - times[i]) / (times[i + 1] - times[i]));
      return _lerp(values[i], values[i + 1], eases[i](p));
    }
  }
  return values.last;
}

double _linear(double t) => t;
double _out(double t) => 1 - math.pow(1 - t, 3).toDouble();
double _inOut(double t) =>
    t < .5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
double _easeInOut(double t) => _inOut(t);
double _easeBack(double t) {
  const double c1 = 1.7;
  const double c3 = c1 + 1;
  return (1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)).toDouble();
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _clamp01(double t) => t.clamp(0.0, 1.0).toDouble();
