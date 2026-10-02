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
    color: 0xFFFB9250,
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
  CoucouMochiEngine({CoucouMochiState initial = CoucouMochiState.idle})
    : _state = initial,
      _stateAt = 0,
      _fromColor = _styles[initial]!.color;

  CoucouMochiState _state;
  double _stateAt;
  int _fromColor;
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
  double _greetAt = -100;
  double _emoteAt = -100;
  double _emoteDuration = 0;
  CoucouMochiEye? _emoteEye;
  String? _emote;
  double _hoverAt = -100;

  double _morphFrom = 0;
  double _morphTo = 0;
  double _morphAt = -100;
  double _morphDuration = .55;
  double _gulpAt = -100;

  CoucouMochiState get state => _state;

  void setState(CoucouMochiState next, double t, {bool force = false}) {
    _prune(t);
    if (!force && next == _state) return;
    _fromColor = _styles[_state]!.color;
    _state = next;
    _stateAt = t;
    if (next == CoucouMochiState.finished) {
      _emit(CoucouMochiParticleType.spark, 5, t);
    }
    if (next == CoucouMochiState.ratelimit) {
      _emit(CoucouMochiParticleType.sweat, 1, t);
    }
    if (next == CoucouMochiState.sleeping) {
      _emit(CoucouMochiParticleType.z, 1, t + .45);
    }
    if (next != CoucouMochiState.idle) {
      _emitBlink(t);
    }
  }

  /// Returns true when this tap completes the three-hit dizzy gesture.
  bool tap(double t) {
    _prune(t);
    _taps.removeWhere((at) => t - at >= 1.7);
    _taps.add(t);
    _tapAt = t;
    _emote = null;
    _emoteEye = null;
    _emoteAt = -100;
    if (_taps.length >= 3) {
      _taps.clear();
      _dizzyAt = t;
      _dizzyUntil = t + 2.7;
      _emit(CoucouMochiParticleType.star, 4, t);
      return true;
    }
    return false;
  }

  void greet(double t) {
    _prune(t);
    _greetAt = t;
    _emitBlink(t + .55);
    _emitBlink(t + 1.5);
  }

  void triggerEmote(String emote, double t, {double duration = 1.8}) {
    _prune(t);
    _emote = emote;
    _emoteAt = t;
    _emoteDuration = duration;
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
      case 'happy':
        _emit(CoucouMochiParticleType.spark, 3, t);
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
    final double k = 1 - math.exp(-14 * math.max(0.0, t - _lookAt));
    _lookFromX = _lookFromX + (_lookX - _lookFromX) * k;
    _lookFromY = _lookFromY + (_lookY - _lookFromY) * k;
    _lookX = x.clamp(-1.0, 1.0).toDouble();
    _lookY = y.clamp(-1.0, 1.0).toDouble();
    _lookAt = t;
  }

  void setHover(bool hovering, double t) {
    _prune(t);
    if (hovering) {
      _hoverAt = t;
    } else {
      _hoverAt = -100;
    }
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
    setMorph(1, t, duration: .55);
    _emitBlink(t);
  }

  CoucouMochiFrame sample(double t) {
    final bool dizzy = t < _dizzyUntil;
    final CoucouMochiState state = dizzy ? CoucouMochiState.dizzy : _state;
    final _StateStyle style = _styles[state]!;
    final double stateAge = math.max(0.0, t - (dizzy ? _dizzyAt : _stateAt));
    final double lookAge = math.max(0.0, t - _lookAt);
    final double lookEase = 1 - math.exp(-14 * lookAge);

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
    double eyeScale = 1;
    double blush = style.tint * .5;
    double hands = 0;
    double handWave = 0;

    final double tapAge = t - _tapAt;
    if (tapAge >= 0 && tapAge < .37) {
      final double p = tapAge / .37;
      scaleY *= _key(p, const [0, .19, .54, 1], const [1, .78, 1.1, 1], const [
        _out,
        _out,
        _inOut,
      ]);
      scaleX *= _key(p, const [0, .19, .54, 1], const [1, 1.16, .95, 1], const [
        _out,
        _out,
        _inOut,
      ]);
    }

    if (dizzy) {
      roll = _easeInOut(_clamp01(stateAge / 1.3)) * _tau * 2;
    } else if (state == CoucouMochiState.finished && stateAge < .95) {
      roll = _easeInOut(_clamp01(stateAge / .95)) * _tau;
    }
    if (state == CoucouMochiState.error && stateAge < .28) {
      offsetX = _key(
        stateAge / .28,
        const [0, .18, .43, .68, 1],
        const [0, .08, -.08, .05, 0],
        const [_out, _inOut, _inOut, _out],
      );
    }

    final double greetingAge = t - _greetAt;
    if (greetingAge >= 0 && greetingAge < 1.75) {
      hands = greetingAge < .25
          ? 0
          : greetingAge < 1.55
          ? _out(_clamp01((greetingAge - .25) / .28))
          : 1 - _inOut(_clamp01((greetingAge - 1.55) / .2));
      handWave = greetingAge;
      tilt = greetingAge >= .45 && greetingAge < 1.55
          ? -.06 + math.sin(_tau * 1.2 * (greetingAge - .45)) * .07
          : style.tilt;
      if (greetingAge < .46) offsetY = -.06 * _out(_clamp01(greetingAge / .22));
    }

    final double emoteAge = t - _emoteAt;
    final bool emoteOn = emoteAge >= 0 && emoteAge < _emoteDuration;
    CoucouMochiEye eye = style.eye;
    if (emoteOn && _emoteEye != null) eye = _emoteEye!;
    if (tapAge >= 0 && tapAge < .8 && !dizzy) eye = CoucouMochiEye.line;
    if (greetingAge >= 0 && greetingAge < 2) eye = CoucouMochiEye.happy;
    if (dizzy) eye = CoucouMochiEye.spiral;

    if (emoteOn && _emote == 'love') {
      blush = math.max(
        blush,
        _key(emoteAge, const [0, .3, .6], const [0, 1, 1], const [
          _out,
          _linear,
        ]),
      );
    } else if (emoteOn && _emote == 'happy') {
      blush = math.max(blush, .6 * _out(_clamp01(1 - emoteAge / .8)));
    } else if (emoteOn && _emote == 'proud') {
      blush = math.max(blush, .7 * _out(_clamp01(1 - emoteAge / .55)));
    }
    if (emoteOn && _emote == 'surprised') {
      eyeScale = _key(emoteAge, const [0, .12, .62], const [1, 1.25, 1], const [
        _out,
        _inOut,
      ]);
      offsetY -= .3 * _out(_clamp01(1 - emoteAge / .52));
    }
    if (emoteOn && _emote == 'wink') {
      tilt += .12 * _out(_clamp01(1 - emoteAge / .4));
    }
    if (emoteOn && _emote == 'proud') {
      tilt -= .14 * _out(_clamp01(1 - emoteAge / .5));
    }
    if (_hoverAt > -10 && t - _hoverAt >= 2 && t - _hoverAt < 4) {
      eyeScale = math.max(eyeScale, 1.08);
    }
    double eyeOpen = state == CoucouMochiState.sleeping ? .05 : 1;
    for (final double at in _blinkTimes(t)) {
      eyeOpen = math.min(eyeOpen, _blinkValue(t - at));
    }
    final double tintBlend = _easeOut(_clamp01(stateAge / .32));
    final int color = _mixColor(_fromColor, style.color, tintBlend);
    final double badgeScale = style.badge == null
        ? 0
        : _easeBack(_clamp01((t - _stateAt - .1) / .28));

    final double morph = _morphValue(t);
    final bool chewing = t >= _gulpAt + .46 && t < _gulpAt + 1.26;
    double slotOpen = 0;
    if (morph > .05 && t >= _gulpAt) {
      final double gulpAge = t - _gulpAt;
      final double openTarget = gulpAge < .46 ? .42 : 0;
      slotOpen =
          openTarget * (1 - math.exp(-math.max(0.0, gulpAge - .02) * 19));
      if (gulpAge >= .46) slotOpen *= math.exp(-(gulpAge - .46) * 9);
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
      badge: style.badge,
      badgeColor: style.color,
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
    _bursts.removeWhere((b) => t - b.at > 2.1);
    _blinkEvents.removeWhere((v) => t - v > 1);
  }

  List<CoucouMochiParticle> _sampleParticles(double t, CoucouMochiState state) {
    final List<CoucouMochiParticle> result = [];
    for (final _ParticleBurst burst in _bursts) {
      for (int i = 0; i < burst.count; i++) {
        final double age = t - burst.at + i * .14;
        final double life = 1.45 + _random01(burst.seed + i * 17) * .35;
        if (age <= 0 || age >= life) continue;
        final double k = age / life;
        final double alpha = k < .2 ? k / .2 : 1 - (k - .2) / .8;
        final bool isZ = burst.type == CoucouMochiParticleType.z;
        final double x =
            (_random01(burst.seed + i * 3) - .5) * .9 + (isZ ? .55 : 0);
        final double y = -.7 - _random01(burst.seed + i * 5) * .2;
        final double vx =
            (_random01(burst.seed + i * 7) - .5) * .35 + (isZ ? .18 : 0);
        final double vy = -(.45 + _random01(burst.seed + i * 11) * .35);
        result.add(
          CoucouMochiParticle(
            type: burst.type,
            x: x + vx * age,
            y: y + vy * age,
            alpha: alpha.clamp(0.0, 1.0).toDouble(),
            size: (.15 + _random01(burst.seed + i * 13) * .08) * (1 + k * .4),
            rotation: _random01(burst.seed + i * 19) * _tau + age * 2,
          ),
        );
      }
    }
    if (state == CoucouMochiState.sleeping) {
      final double asleepFor = t - _stateAt - .8;
      if (asleepFor >= 0) {
        final int current = (asleepFor / 1.3).floor();
        for (int n = math.max(0, current - 1); n <= current; n++) {
          final double at = _stateAt + .8 + n * 1.3;
          final double age = t - at;
          if (age <= 0 || age >= 1.65) continue;
          final double k = age / 1.65;
          result.add(
            CoucouMochiParticle(
              type: CoucouMochiParticleType.z,
              x: .25 + age * .18,
              y: -.84 - age * .55,
              alpha: (k < .2 ? k / .2 : 1 - (k - .2) / .8)
                  .clamp(0.0, 1.0)
                  .toDouble(),
              size: .17 * (1 + k * .4),
              rotation: .25,
            ),
          );
        }
      }
    }
    return result;
  }

  Iterable<double> _blinkTimes(double t) sync* {
    for (final double at in _blinkEvents) {
      if (t - at >= 0 && t - at < .21) yield at;
    }
    const List<double> offsets = [2.25, 5.65, 9.2, 12.5, 16.65, 20.1, 23.15];
    const double cycle = 26.4;
    final int loop = (t / cycle).floor();
    for (int n = math.max(0, loop - 1); n <= loop; n++) {
      for (final double offset in offsets) {
        final double at = n * cycle + offset;
        if (t - at >= 0 && t - at < .21) yield at;
      }
    }
  }

  double _blinkValue(double age) {
    if (age <= 0) return 1;
    if (age < .07) return _lerp(1, .06, _inOut(age / .07));
    if (age < .2) return _lerp(.06, 1, _out((age - .07) / .13));
    return 1;
  }
}

double _random01(int seed) {
  int x = seed == 0 ? 0x9e3779b9 : seed;
  x &= 0xffffffff;
  x ^= (x << 13) & 0xffffffff;
  x ^= x >> 17;
  x ^= (x << 5) & 0xffffffff;
  return (x & 0xffffffff) / 0xffffffff;
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
double _easeOut(double t) => _out(t);
double _easeInOut(double t) => _inOut(t);
double _easeBack(double t) {
  const double c1 = 1.7;
  const double c3 = c1 + 1;
  return (1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)).toDouble();
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _clamp01(double t) => t.clamp(0.0, 1.0).toDouble();
