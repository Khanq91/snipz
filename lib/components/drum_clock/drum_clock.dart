/// DrumClock
/// Origin: reimplemented — port of the "clock playback controls" example
/// from anime.js v4 (juliangarnier/anime,
/// examples/clock-playback-controls): a digital clock whose digits sit on
/// 3D drums that snap-roll with an overshoot bezier, driven by a timeline
/// you can pause, reverse, retime and glide-seek.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

const double _kDayMs = 24 * 3600 * 1000;

/// Drives a [DrumClock]: the clock's own time, its speed and glide-seeks.
/// One controller per clock. All transitions mirror the upstream buttons:
/// speed ramps ease out(3) over 1.5s, seeks glide inOut(3) over 1.5s.
class DrumClockController extends ChangeNotifier {
  DrumClockController({
    Duration initialTime = const Duration(hours: 10, minutes: 8, seconds: 30),
    double speed = 1,
    bool playing = true,
  })  : _timeMs = initialTime.inMilliseconds % _kDayMs,
        _speed = speed,
        _playing = playing;

  double _timeMs;
  double _speed;
  bool _playing;

  // speed ramp
  double? _speedFrom, _speedTo;
  double _speedElapsed = 0, _speedDur = 0;

  // glide seek
  double? _seekFrom, _seekTo;
  double _seekElapsed = 0, _seekDur = 0;

  /// Clock time within the day, in ms.
  double get timeOfDayMs => _timeMs;

  Duration get time => Duration(milliseconds: _timeMs.round());
  double get speed => _speed;
  bool get playing => _playing;

  void play() {
    _playing = true;
    notifyListeners();
  }

  void pause() {
    _playing = false;
    notifyListeners();
  }

  /// Flips playback direction (upstream REVERSE).
  void reverse() {
    _speed = -_speed;
    _speedFrom = _speedTo = null;
    notifyListeners();
  }

  /// Ramps toward [target] (upstream SLOW MO / NORMAL / SPEED UP).
  void setSpeed(double target,
      {Duration ramp = const Duration(milliseconds: 1500)}) {
    if (ramp == Duration.zero) {
      _speed = target;
      _speedFrom = _speedTo = null;
    } else {
      _speedFrom = _speed;
      _speedTo = target;
      _speedElapsed = 0;
      _speedDur = ramp.inMicroseconds / 1e6;
    }
    notifyListeners();
  }

  /// Glides the clock itself to [target] time-of-day (upstream SEEK).
  void seekTo(Duration target,
      {Duration glide = const Duration(milliseconds: 1500)}) {
    final double t = target.inMilliseconds % _kDayMs;
    if (glide == Duration.zero) {
      _timeMs = t;
      _seekFrom = _seekTo = null;
    } else {
      _seekFrom = _timeMs;
      _seekTo = t;
      _seekElapsed = 0;
      _seekDur = glide.inMicroseconds / 1e6;
    }
    notifyListeners();
  }

  /// Jumps without animation.
  void jumpTo(Duration target) => seekTo(target, glide: Duration.zero);

  static double _outPow(double p, double n) =>
      1 - math.pow(1 - p.clamp(0.0, 1.0), n).toDouble();

  static double _inOutPow(double p, double n) {
    p = p.clamp(0.0, 1.0);
    return p < .5
        ? math.pow(2 * p, n) / 2
        : 1 - math.pow(2 - 2 * p, n) / 2;
  }

  /// Called by the widget's ticker.
  void _advance(double dt) {
    if (_speedTo != null) {
      _speedElapsed += dt;
      final double p = _speedDur == 0 ? 1 : _speedElapsed / _speedDur;
      _speed = _speedFrom! + (_speedTo! - _speedFrom!) * _outPow(p, 3);
      if (p >= 1) {
        _speed = _speedTo!;
        _speedFrom = _speedTo = null;
      }
    }
    if (_seekTo != null) {
      _seekElapsed += dt;
      final double p = _seekDur == 0 ? 1 : _seekElapsed / _seekDur;
      // glide the shortest way around the day wrap
      double delta = _seekTo! - _seekFrom!;
      if (delta > _kDayMs / 2) delta -= _kDayMs;
      if (delta < -_kDayMs / 2) delta += _kDayMs;
      _timeMs = (_seekFrom! + delta * _inOutPow(p, 3)) % _kDayMs;
      if (_timeMs < 0) _timeMs += _kDayMs;
      if (p >= 1) {
        _timeMs = _seekTo!;
        _seekFrom = _seekTo = null;
      }
      return; // seek owns the clock while gliding
    }
    if (_playing) {
      _timeMs = (_timeMs + dt * 1000 * _speed) % _kDayMs;
      if (_timeMs < 0) _timeMs += _kDayMs;
    }
  }
}

/// HH:MM:SS.cc on 3D digit drums — slow digits snap-roll 650ms before each
/// change with an overshoot bezier, the centisecond drums spin continuously.
class DrumClock extends StatefulWidget {
  const DrumClock({
    super.key,
    this.controller,
    this.showCentis = true,
    this.fontSize = 40,
    this.color = const Color(0xFFEDEAE4),
    this.backgroundColor = const Color(0xFF191817),
    this.fontFamily = 'monospace',
    this.animate = true,
    this.frozenAt,
  });

  /// External driver; null creates an internal one (10:08:30, playing).
  final DrumClockController? controller;

  /// False hides the two fast centisecond drums.
  final bool showCentis;

  final double fontSize;
  final Color color;

  /// Also feeds the top/bottom depth fade. `transparent` disables the fade.
  final Color backgroundColor;

  final String fontFamily;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders the clock parked at this time-of-day (in seconds) —
  /// no ticker, no controller (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<DrumClock> createState() => _DrumClockState();
}

class _DrumClockState extends State<DrumClock>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  DrumClockController? _internal;
  double _lastTick = 0;

  DrumClockController get _controller =>
      widget.controller ?? (_internal ??= DrumClockController());

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    final double t = elapsed.inMicroseconds / 1e6;
    // clamp: 64ms for app-resume gaps, 0 floor for ticker restarts
    final double dt = (t - _lastTick).clamp(0.0, .064);
    _lastTick = t;
    _controller._advance(dt);
    _frame.value++;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(DrumClock old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  void _syncTicker() {
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool run = widget.animate && widget.frozenAt == null && !reduced;
    if (run && !_ticker.isActive) {
      _lastTick = 0;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _internal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _frame,
      builder: (context, _, _) {
        final double ms = widget.frozenAt != null
            ? (widget.frozenAt! * 1000) % _kDayMs
            : _controller.timeOfDayMs;
        final TextStyle style = TextStyle(
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w600,
          color: widget.color,
          height: 1,
        );
        final List<Widget> slots = <Widget>[
          _drum(_SlotKind.h10, ms, style),
          _drum(_SlotKind.h1, ms, style),
          _colon(':', style),
          _drum(_SlotKind.m10, ms, style),
          _drum(_SlotKind.m1, ms, style),
          _colon(':', style),
          _drum(_SlotKind.s10, ms, style),
          _drum(_SlotKind.s1, ms, style),
          if (widget.showCentis) ...<Widget>[
            _colon('.', style),
            _drum(_SlotKind.c10, ms, style),
            _drum(_SlotKind.c1, ms, style),
          ],
        ];
        final Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: slots,
        );
        if (widget.backgroundColor.a == 0) return row;
        // depth fade: drum tops/bottoms sink into the background
        final Color bg = widget.backgroundColor;
        return DecoratedBox(
          decoration: BoxDecoration(color: bg),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: widget.fontSize * .4,
                vertical: widget.fontSize * .55),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const <Color>[
                  Color(0x00FFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: const <double>[.02, .32, .68, .98],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: row,
            ),
          ),
        );
      },
    );
  }

  Widget _colon(String ch, TextStyle style) {
    return SizedBox(
      width: widget.fontSize * .42,
      child: Center(child: Text(ch, style: style)),
    );
  }

  Widget _drum(_SlotKind kind, double ms, TextStyle style) {
    final double rot = _drumRotation(kind, ms); // degrees
    final double radius = widget.fontSize * 1.45;
    final List<Widget> faces = <Widget>[];
    for (int k = 0; k < 10; k++) {
      // negated so fresh digits roll in from the top, like the CSS original
      final double phi = -(k * 36 + rot) * math.pi / 180;
      final double c = math.cos(phi);
      if (c <= .02) continue; // backface + rim culling
      final Matrix4 m = Matrix4.identity()
        ..setEntry(3, 2, -0.0009)
        ..rotateX(phi)
        ..translateByDouble(0.0, 0.0, -radius, 1.0);
      faces.add(Transform(
        transform: m,
        alignment: Alignment.center,
        child: Center(
          child: Text(
            '$k',
            style: style.copyWith(
              color: style.color!.withValues(
                  alpha: (c * 1.4).clamp(0.0, 1.0)),
            ),
          ),
        ),
      ));
    }
    return SizedBox(
      width: widget.fontSize * .68,
      height: widget.fontSize * 2.1,
      child: Stack(fit: StackFit.expand, children: faces),
    );
  }

  /// Drum angle in degrees for [kind] at clock ms — static at -36°×digit,
  /// snap-rolling through the 650ms before each digit change (overshoot
  /// bezier), or spinning linearly for the centisecond drums.
  static double _drumRotation(_SlotKind kind, double ms) {
    final double period = kind.periodMs;
    if (!kind.canStop) {
      return -(ms / period) * 36;
    }
    final int d0 = kind.digit(ms);
    final double boundary = kind.nextChange(ms);
    final double untilChange = boundary - ms;
    double rot = -36.0 * d0;
    if (untilChange <= 650) {
      final int d1 = kind.digit(boundary % _kDayMs);
      final int steps = (d1 - d0) % 10 == 0 ? 10 : (d1 - d0 + 10) % 10;
      final double e = _overshootBezier((650 - untilChange) / 650);
      rot -= 36.0 * steps * e;
    }
    return rot;
  }

  /// cubic-bezier(1, 0, .6, 1.2) — waits, then whips past and settles back.
  static double _overshootBezier(double p) {
    p = p.clamp(0.0, 1.0);
    if (p == 0 || p == 1) return p;
    // solve x(u) = p by bisection (x is monotone for css-valid handles)
    double lo = 0, hi = 1;
    for (int i = 0; i < 32; i++) {
      final double u = (lo + hi) / 2;
      final double x =
          3 * u * (1 - u) * (1 - u) * 1.0 + 3 * u * u * (1 - u) * .6 +
              u * u * u;
      if (x < p) {
        lo = u;
      } else {
        hi = u;
      }
    }
    final double u = (lo + hi) / 2;
    return 3 * u * (1 - u) * (1 - u) * 0.0 +
        3 * u * u * (1 - u) * 1.2 +
        u * u * u;
  }
}

/// The seven drum roles. Digit + next-change are exact functions of clock
/// ms, so wraps (23→00, 59→00) roll the leftover steps in one snap — the
/// upstream special cases fall out for free.
enum _SlotKind {
  h10(36000000, true),
  h1(3600000, true),
  m10(600000, true),
  m1(60000, true),
  s10(10000, true),
  s1(1000, true),
  c10(100, false),
  c1(10, false);

  const _SlotKind(this.periodMs, this.canStop);

  /// Nominal ms between digit steps (display cadence for the fast drums).
  final double periodMs;

  /// False = continuous linear spin (upstream `canStop`).
  final bool canStop;

  int digit(double ms) {
    switch (this) {
      case _SlotKind.h10:
        return (ms ~/ 3600000) ~/ 10;
      case _SlotKind.h1:
        return (ms ~/ 3600000) % 10;
      case _SlotKind.m10:
        return ((ms ~/ 60000) % 60) ~/ 10;
      case _SlotKind.m1:
        return ((ms ~/ 60000) % 60) % 10;
      case _SlotKind.s10:
        return ((ms ~/ 1000) % 60) ~/ 10;
      case _SlotKind.s1:
        return ((ms ~/ 1000) % 60) % 10;
      case _SlotKind.c10:
        return ((ms ~/ 100) % 10).toInt();
      case _SlotKind.c1:
        return ((ms ~/ 10) % 10).toInt();
    }
  }

  /// Absolute ms of the next digit change after [ms].
  double nextChange(double ms) {
    switch (this) {
      case _SlotKind.h10:
        final double h = ms / 3600000;
        if (h < 10) return 10 * 3600000;
        if (h < 20) return 20 * 3600000;
        return _kDayMs;
      default:
        return (ms / periodMs).floorToDouble() * periodMs + periodMs;
    }
  }
}
