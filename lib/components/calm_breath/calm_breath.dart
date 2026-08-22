/// Calm Breath
/// Origin: adapted — port of BreathScreen.tsx from mortspace's FeralUI
/// calm-app screen set (React + motion): a 4-2-5 guided breathing orb while
/// the "water" of the session drains down a wavy shoreline as the minute
/// runs out. Rebuilt with Flutter widgets + CustomPainter waves.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Curve _soft = Cubic(.22, 1, .3, 1);
const Curve _breathEase = Cubic(.45, 0, .3, 1);

/// Water/ink theme of the breath screen. Two presets ship: [mint] and
/// [ocean] — the in-screen droplet button toggles between them.
class CalmBreathTheme {
  const CalmBreathTheme({
    required this.ink,
    required this.halo,
    required this.ripple,
    required this.crest,
    required this.crestFade,
    required this.surf1,
    required this.surf2,
    required this.mid,
    required this.deep,
    required this.pearl,
    required this.bgTint1,
    required this.bgTint2,
    required this.bgTop,
    required this.bgBottom,
  });

  final Color ink, halo, ripple, crest, crestFade, surf1, surf2, mid, deep;
  final List<Color> pearl; // 4 stops of the core orb
  final Color bgTint1, bgTint2, bgTop, bgBottom;

  static const CalmBreathTheme mint = CalmBreathTheme(
    ink: Color(0xFF2F6B56),
    halo: Color(0x665EC5A0),
    ripple: Color(0xA646AC88),
    crest: Color(0xFFD6F7E7),
    crestFade: Color(0xFFA9E4C9),
    surf1: Color(0xFFC6F2DD),
    surf2: Color(0xFF7FD0AF),
    mid: Color(0xFF5DB998),
    deep: Color(0xFF3F9C7E),
    pearl: [
      Color(0xFFF0FCF5),
      Color(0xFFD3F2E0),
      Color(0xFFA9E0C5),
      Color(0xFF93D5B7)
    ],
    bgTint1: Color(0x525EC5A0),
    bgTint2: Color(0x4D7EDEC4),
    bgTop: Color(0xFFF4FDF8),
    bgBottom: Color(0xFFDDF3E8),
  );

  static const CalmBreathTheme ocean = CalmBreathTheme(
    ink: Color(0xFF2D5F86),
    halo: Color(0x6660AAE1),
    ripple: Color(0xA6428CC8),
    crest: Color(0xFFDFF3FF),
    crestFade: Color(0xFFA6D8F4),
    surf1: Color(0xFFC8E9FC),
    surf2: Color(0xFF7CC3EF),
    mid: Color(0xFF57A8DD),
    deep: Color(0xFF3B86C4),
    pearl: [
      Color(0xFFEEF9FF),
      Color(0xFFD3ECFC),
      Color(0xFFA9D8F5),
      Color(0xFF93CDF1)
    ],
    bgTint1: Color(0x5260AAE1),
    bgTint2: Color(0x4D82CDF0),
    bgTop: Color(0xFFF3FAFF),
    bgBottom: Color(0xFFDDEEFB),
  );
}

/// Guided wind-down: "Breathe in / Hold / Breathe out" (4-2-5 s) on a pearl
/// orb while the session water sinks with the countdown. Pause, skip and a
/// mint/ocean theme toggle included. Fills its box (designed at 390x844).
class CalmBreathScreen extends StatefulWidget {
  const CalmBreathScreen({
    super.key,
    this.onNext,
    this.totalSeconds = 60,
    this.startWithOcean = false,
    this.title = 'Wind down',
    this.animate = true,
  });

  /// Called when skipped, and ~1.6 s after the countdown completes.
  final VoidCallback? onNext;
  final int totalSeconds;
  final bool startWithOcean;
  final String title;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmBreathScreen> createState() => _CalmBreathScreenState();
}

class _CalmBreathScreenState extends State<CalmBreathScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  double _last = 0;
  double _bt = 0; // breathing/session clock — freezes while paused
  bool _paused = false;
  late bool _ocean = widget.startWithOcean;
  bool _notified = false;

  bool get _still =>
      !widget.animate || MediaQuery.maybeDisableAnimationsOf(context) == true;

  bool get _done => _bt >= widget.totalSeconds;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) {
      final double now = e.inMicroseconds / 1e6;
      final double dt = math.min(.064, now - _last);
      _last = now;
      if (!_paused && !_done) _bt += dt;
      if (_done) {
        if (_doneAt == 0) {
          _doneAt = now;
        } else if (!_notified && now - _doneAt > 1.6) {
          _notified = true;
          widget.onNext?.call();
        }
      }
      _t.value = now;
    });
  }

  double _doneAt = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _ticker.stop();
      _t.value = 99;
      _bt = 14.5; // mid-session: water partly down, "breathe out" phase
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  double _ease(double t, double t0, double dur, [Curve c = _soft]) =>
      c.transform(((t - t0) / dur).clamp(0.0, 1.0));

  /// Breath scale target 1..1.3 as a pure function of the session clock
  /// (in 4 s, hold 2 s, out 5 s — an 11 s cycle).
  double _breathVal() {
    if (_done) return 1;
    final double u = _bt % 11;
    if (u < 4) return 1 + .3 * _breathEase.transform(u / 4);
    if (u < 6) return 1.3;
    return 1.3 - .3 * _breathEase.transform((u - 6) / 5);
  }

  String get _label {
    if (_done) return 'Well done';
    if (_paused) return 'Paused';
    final double u = _bt % 11;
    return u < 4 ? 'Breathe in' : (u < 6 ? 'Hold' : 'Breathe out');
  }

  @override
  Widget build(BuildContext context) {
    final CalmBreathTheme th =
        _ocean ? CalmBreathTheme.ocean : CalmBreathTheme.mint;
    return ClipRect(
      child: LayoutBuilder(builder: (context, box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        return ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, t, _) {
            final double left =
                math.max(0, widget.totalSeconds - _bt).toDouble();
            final double val = _breathVal();
            // water top: enters from below, then tracks the countdown
            final double levelPct =
                10 + (left / widget.totalSeconds) * 94;
            final double waterY =
                ui.lerpDouble(104, levelPct, math.min(1, t))! / 100 * h;
            final int secs = left.ceil();
            return Stack(
              fit: StackFit.expand,
              children: [
                // airy backdrop
                Opacity(
                  opacity: _ease(t, 0, .6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -.52),
                        radius: 1.1,
                        colors: [th.bgTop, th.bgBottom],
                        stops: const [0, .66],
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: _ease(t, 0, .6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-.6, -.72),
                        radius: .8,
                        colors: [th.bgTint1, th.bgTint1.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
                // session water with waves + breath swell
                Transform.translate(
                  offset: Offset(0, waterY + (val - 1) * -34),
                  child: CustomPaint(
                    size: Size(w, h),
                    painter: _WavesPainter(theme: th, t: _still ? 0 : t),
                  ),
                ),
                // header
                Positioned(
                  top: 96,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _ease(t, .18, .55),
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - _ease(t, .18, .55))),
                      child: Column(
                        children: [
                          Text(
                            widget.title.toUpperCase(),
                            style: TextStyle(
                              color: th.ink.withValues(alpha: .68),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: th.ink,
                              fontSize: 20.8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.2,
                              fontFeatures: const [
                                ui.FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // breathing orb
                Center(
                  child: _orb(t, th, val),
                ),
                // theme toggle
                Positioned(
                  top: 54,
                  left: 16,
                  child: _glassRound(
                    t: _ease(t, .5, .45),
                    onTap: () => setState(() => _ocean = !_ocean),
                    child: CustomPaint(
                      size: const Size(18, 18),
                      painter: _DropPainter(
                          _ocean ? CalmBreathTheme.mint : CalmBreathTheme.ocean),
                    ),
                  ),
                ),
                // skip
                Positioned(
                  top: 54,
                  right: 16,
                  child: _glassRound(
                    t: _ease(t, .5, .45),
                    onTap: widget.onNext,
                    child: Icon(Icons.chevron_right_rounded,
                        size: 24, color: th.ink),
                  ),
                ),
                // pause / resume
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 36,
                  child: Opacity(
                    opacity: _ease(t, .5, .5),
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - _ease(t, .5, .5))),
                      child: Center(
                        child: _PressScale(
                          pressed: .93,
                          onTap: () => setState(() => _paused = !_paused),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: BackdropFilter(
                              filter:
                                  ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                              child: Container(
                                height: 46,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(23),
                                  color:
                                      Colors.white.withValues(alpha: .32),
                                  border: Border.all(
                                      color: const Color(0x47FFFFFF)),
                                  boxShadow: [
                                    BoxShadow(
                                      offset: const Offset(0, 14),
                                      blurRadius: 30,
                                      spreadRadius: -18,
                                      color: th.deep
                                          .withValues(alpha: .6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                          milliseconds: 280),
                                      transitionBuilder: (child, a) =>
                                          RotationTransition(
                                        turns: Tween(begin: -.25, end: 0.0)
                                            .animate(a),
                                        child: ScaleTransition(
                                            scale: a,
                                            child: FadeTransition(
                                                opacity: a,
                                                child: child)),
                                      ),
                                      child: Icon(
                                        _paused
                                            ? Icons.play_arrow_rounded
                                            : Icons.pause_rounded,
                                        key: ValueKey<bool>(_paused),
                                        size: 19,
                                        color: th.ink,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                          milliseconds: 240),
                                      child: Text(
                                        _paused ? 'Resume' : 'Pause',
                                        key: ValueKey<bool>(_paused),
                                        style: TextStyle(
                                          color: th.ink,
                                          fontSize: 13.8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _orb(double t, CalmBreathTheme th, double val) {
    final double orbIn = _ease(t, .3, .8);
    final double cycleU = _done ? 99 : _bt % 11;
    final double rippleP = (cycleU / 3.6).clamp(0.0, 1.0);
    return Opacity(
      opacity: orbIn.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: .82 + .18 * orbIn,
        child: SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // halo breathes at full depth
              Transform.scale(
                scale: val,
                child: Container(
                  width: 196,
                  height: 196,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        th.halo,
                        th.halo.withValues(alpha: .16),
                        th.halo.withValues(alpha: 0),
                      ],
                      stops: const [0, .54, .72],
                    ),
                  ),
                ),
              ),
              // once-per-cycle ripple ring
              if (!_still && !_done && rippleP < 1)
                Transform.scale(
                  scale: .55 + .95 * Curves.easeOut.transform(rippleP),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: th.ripple.withValues(
                            alpha: th.ripple.a * (.45 * (1 - rippleP))),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              // pearl core breathes at half depth
              Transform.scale(
                scale: 1 + (val - 1) * .5,
                child: Container(
                  width: 108,
                  height: 108,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-.24, -.4),
                      colors: [
                        Colors.white,
                        th.pearl[0],
                        th.pearl[1],
                        th.pearl[2],
                        th.pearl[3],
                      ],
                      stops: const [0, .3, .58, .84, 1],
                    ),
                    border: Border.all(color: const Color(0x8CFFFFFF)),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 22),
                        blurRadius: 40,
                        spreadRadius: -18,
                        color: th.deep.withValues(alpha: .6),
                      ),
                      BoxShadow(
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                        spreadRadius: -2,
                        color: th.deep.withValues(alpha: .25),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: _soft,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0, .12),
                                end: Offset.zero)
                            .animate(a),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _label,
                      key: ValueKey<String>(_label),
                      style: TextStyle(
                        color: th.ink,
                        fontSize: 14.1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassRound(
      {required double t, VoidCallback? onTap, required Widget child}) {
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: .8 + .2 * t,
        child: _PressScale(
          pressed: .88,
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .42),
                  border: Border.all(color: const Color(0x40FFFFFF)),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(0, 6),
                      blurRadius: 18,
                      spreadRadius: -10,
                      color: Color(0x4D325A5A),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The other theme's droplet, previewing what the toggle switches to.
class _DropPainter extends CustomPainter {
  const _DropPainter(this.next);
  final CalmBreathTheme next;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final Path drop = Path()
      ..moveTo(12, 3.2)
      ..cubicTo(12.32, 3.2, 12.62, 3.35, 12.81, 3.61)
      ..cubicTo(13.96, 5.21, 18.1, 11.16, 18.1, 14.18)
      ..arcToPoint(const Offset(5.9, 14.18),
          radius: const Radius.circular(6.1), largeArc: true)
      ..cubicTo(5.9, 11.16, 10.04, 5.21, 11.19, 3.61)
      ..cubicTo(11.38, 3.35, 11.68, 3.2, 12, 3.2)
      ..close();
    canvas.drawPath(
        drop,
        Paint()
          ..shader = ui.Gradient.radial(const Offset(8.2, 6.2), 15, [
            next.surf1,
            next.mid,
            next.deep,
          ], const [
            0,
            .48,
            1,
          ]));
    canvas.save();
    canvas.translate(9.9, 9.2);
    canvas.rotate(-24 * math.pi / 180);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 2.2, height: 3.3),
        Paint()..color = const Color(0xEBFFFFFF));
    canvas.restore();
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(12.2, 16.9), width: 6.2, height: 2.8),
        Paint()
          ..color = const Color(0x57FFFFFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .7));
  }

  @override
  bool shouldRepaint(_DropPainter old) => old.next != next;
}

/// Two drifting sine shorelines + the solid body of water below them, in the
/// upstream 390x800 design space, drawn from y=-71 above its origin.
class _WavesPainter extends CustomPainter {
  const _WavesPainter({required this.theme, required this.t});
  final CalmBreathTheme theme;
  final double t;

  Path _wave(double y0, double amp, double period, double fillTo, double w) {
    final Path p = Path();
    final double half = period / 2;
    double x = -period;
    p.moveTo(x, y0);
    bool up = true;
    while (x < w + period) {
      p.quadraticBezierTo(
          x + period / 4, y0 + (up ? -amp : amp), x + half, y0);
      x += half;
      up = !up;
    }
    p.lineTo(x, fillTo);
    p.lineTo(-period, fillTo);
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 390;
    canvas.scale(s);
    const double w = 390;
    canvas.translate(0, -71);
    canvas.clipRect(const Rect.fromLTWH(-20, 0, 430, 2000));

    final Paint body = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 20),
        const Offset(0, 800),
        [theme.surf1, theme.surf2, theme.mid, theme.deep],
        const [0, .08, .45, 1],
      );

    // back crest (light, slow, drifts right)
    final double x1 = (t % 13) / 13 * 340;
    final double y1 = -2.4 * (.5 - .5 * math.cos(2 * math.pi * t / 6.2)) * 2;
    canvas.save();
    canvas.translate(x1, y1);
    canvas.drawPath(
        _wave(38, 9, 340, 73, w + 340),
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 29),
            const Offset(0, 75),
            [
              theme.crest.withValues(alpha: .6),
              theme.crestFade.withValues(alpha: .18),
              theme.crestFade.withValues(alpha: 0),
            ],
            const [0, .7, 1],
          ));
    canvas.restore();

    // front shoreline (main body, drifts left)
    final double x2 = -(t % 8.5) / 8.5 * 240;
    final double y2 = 2.6 * (.5 - .5 * math.cos(2 * math.pi * t / 4.8)) * 2;
    canvas.save();
    canvas.translate(x2, y2);
    canvas.drawPath(_wave(46, 13, 240, 92, w + 240), body);
    canvas.restore();

    // solid water below the shoreline
    canvas.drawRect(const Rect.fromLTWH(-20, 88, 430, 1600), body);
  }

  @override
  bool shouldRepaint(_WavesPainter old) =>
      old.t != t || old.theme != theme;
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, this.onTap, this.pressed = .97});
  final Widget child;
  final VoidCallback? onTap;
  final double pressed;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressed : 1,
        duration: const Duration(milliseconds: 220),
        curve: const Cubic(.34, 1.56, .64, 1),
        child: widget.child,
      ),
    );
  }
}
