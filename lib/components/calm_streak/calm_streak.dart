/// Calm Streak
/// Origin: adapted — port of StreakScreen.tsx from mortspace's FeralUI
/// calm-app screen set (React + motion). The layered flame is the upstream
/// SVG (paths parsed procedurally, mask/clip redone with Path.combine).
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Curve _soft = Cubic(.22, 1, .3, 1);
const Curve _bouncy = Cubic(.34, 1.45, .5, 1);

const String _shellD =
    'M12.3555 1.17975C12.6333 1.22007 12.8835 1.42661 13.3828 1.8399C14.5704 2.8229 15.6975 3.87361 16.7432 5.01569C17.7733 6.14079 18.827 7.46472 19.627 8.88092C20.4224 10.2894 21.0058 11.8567 21.0059 13.4503C21.0058 18.9618 16.2992 22 12.0059 22.0001C7.71247 22.0001 3.00593 18.9618 3.00586 13.4503C3.00601 11.6543 3.31206 9.81195 3.64062 7.99908C3.79551 7.14453 3.87278 6.71677 4.0918 6.49615C4.28495 6.30176 4.54241 6.19717 4.81641 6.20123C5.1273 6.20598 5.47988 6.45692 6.18457 6.95807L8.20117 8.39166L10.9971 2.40631C11.2819 1.79667 11.4252 1.49135 11.6592 1.336C11.8588 1.20356 12.1184 1.1454 12.3555 1.17975ZM12 11.0001C10.8333 11.0001 8.50023 14.7613 8.5 16.6251C8.50004 18.4372 9.98124 19.9144 11.8398 19.9952C11.8929 19.998 11.9463 20.0001 12 20.0001C12.0534 20.0001 12.1065 19.9979 12.1592 19.9952C14.0182 19.9149 15.5 18.4375 15.5 16.6251C15.4998 14.7613 13.1667 11.0001 12 11.0001Z';
const String _coreD =
    'M7 16.5C7.00033 14.015 10.3333 9 12 9C13.6667 9 16.9997 14.015 17 16.5C17 18.9853 14.7614 21 12 21C9.23858 21 7 18.9853 7 16.5Z';

// deterministic confetti burst (upstream formula)
final List<_Confetto> _kConfetti = List.generate(30, (i) {
  final double spread = (((i * 53) % 100) / 100) * 2 - 1;
  return _Confetto(
    xMid: spread * 110,
    xEnd: spread * 150,
    rise: 60 + ((i * 31) % 70).toDouble(),
    fall: 100 + ((i * 23) % 50).toDouble(),
    size: 5 + ((i * 29) % 5).toDouble(),
    strip: i % 3 == 0,
    rot: spread * 320,
    color: const [
      Color(0xFFF5A814),
      Color(0xFFFF9D4D),
      Color(0xFFFFCF67),
      Color(0xFFE77C4F),
      Color(0xFFFFD97A),
      Color(0xFFFFB36B),
    ][i % 6],
    delay: .55 + ((i * 17) % 12) * .02,
  );
});

class _Confetto {
  const _Confetto({
    required this.xMid,
    required this.xEnd,
    required this.rise,
    required this.fall,
    required this.size,
    required this.strip,
    required this.rot,
    required this.color,
    required this.delay,
  });
  final double xMid, xEnd, rise, fall, size, rot, delay;
  final bool strip;
  final Color color;
}

/// Streak celebration: a flickering flame, a confetti burst, the day count
/// thumping up to seven, the week of checks and a warm CTA. Fills whatever
/// box it is given (designed at 390x844).
class CalmStreakScreen extends StatefulWidget {
  const CalmStreakScreen({
    super.key,
    this.onNext,
    this.streakDays = 7,
    this.longestStreak = 12,
    this.buttonLabel = 'Keep it going',
    this.animate = true,
  });

  final VoidCallback? onNext;
  final int streakDays;
  final int longestStreak;
  final String buttonLabel;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmStreakScreen> createState() => _CalmStreakScreenState();
}

class _CalmStreakScreenState extends State<CalmStreakScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  bool get _still =>
      !widget.animate || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _t.value = e.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _ticker.stop();
      _t.value = 99;
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

  static const LinearGradient _numGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFB340), Color(0xFFEF5A1E)],
    stops: [0, .92],
  );

  Widget _gradText(String s, double size) => ShaderMask(
        shaderCallback: (r) => _numGradient.createShader(r),
        blendMode: BlendMode.srcIn,
        child: Text(
          s,
          style: TextStyle(
            color: Colors.white,
            fontSize: size,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: -size * .02,
            fontFeatures: const [ui.FontFeature.tabularFigures()],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ValueListenableBuilder<double>(
        valueListenable: _t,
        builder: (context, t, _) {
          // count 1 -> streakDays (easeOutCubic, starts at .38 for .85 s)
          final double cp = _ease(t, .38, .85, Curves.easeOutCubic);
          final int count = 1 + ((widget.streakDays - 1) * cp).round();
          // thump at 1.25 s
          final double thumpU = ((t - 1.25) / .42).clamp(0.0, 1.0);
          final double thump = thumpU <= 0 || thumpU >= 1
              ? 1
              : 1 + .1 * math.sin(math.pi * _bouncy.transform(thumpU));
          final double flameIn = _ease(t, .15, .6, _bouncy);
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: _ease(t, 0, .6),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -.4),
                      radius: 1.15,
                      colors: [
                        Color(0xFFFFFAF0),
                        Color(0xFFFCF0D8),
                        Color(0xFFF8E6C0),
                      ],
                      stops: [0, .56, 1],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // confetti bursts behind the stack of content
                        if (!_still)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                  painter: _ConfettiPainter(t: t)),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.rotate(
                                angle: -8 * math.pi / 180 * (1 - flameIn),
                                child: Transform.scale(
                                  scale: flameIn,
                                  child: CustomPaint(
                                    size: const Size(118, 118),
                                    painter: _FlamePainter(
                                        t: _still ? 0 : t),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Opacity(
                                opacity: _ease(t, .3, .6),
                                child: Transform.scale(
                                  scale:
                                      (.5 + .5 * _ease(t, .3, .6, _bouncy)) *
                                          thump,
                                  child: _gradText('$count', 62),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Opacity(
                                opacity: _ease(t, .48, .5),
                                child: Transform.translate(
                                  offset: Offset(
                                      0, 10 * (1 - _ease(t, .48, .5))),
                                  child: const Text(
                                    'DAY STREAK',
                                    style: TextStyle(
                                      color: Color(0xBFA0641E),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _week(t),
                              const SizedBox(height: 10),
                              _stats(t),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 36),
                    child: Opacity(
                      opacity: _ease(t, 1.62, .5),
                      child: Transform.translate(
                        offset:
                            Offset(0, 10 * (1 - _ease(t, 1.62, .5))),
                        child: _PressScale(
                          onTap: widget.onNext,
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFFFDF8),
                                  Color(0xFFFFF3DF)
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  offset: Offset(0, 14),
                                  blurRadius: 28,
                                  spreadRadius: -14,
                                  color: Color(0x80DC6E1E),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.buttonLabel,
                              style: const TextStyle(
                                color: Color(0xFFD2621F),
                                fontSize: 15.7,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _week(double t) {
    final double e = _ease(t, .68, .55);
    return Opacity(
      opacity: _ease(t, .68, .25),
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - e)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xBDFFFFFF), Color(0x80FFFFFF)],
                ),
                border: Border.all(color: const Color(0x47FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 14),
                    blurRadius: 28,
                    spreadRadius: -20,
                    color: Color(0x8CBE6E14),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int i = 0; i < 7; i++) _day(t, i),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _day(double t, int i) {
    final bool today = i == 6;
    final double pe = _ease(t, .78 + i * .055, today ? .6 : .5,
        today ? Curves.easeOut : _bouncy);
    // today overshoots: [0, 1.3, 1]
    final double scale = today
        ? (pe < .5 ? 2.6 * pe : 1.3 - .6 * ((pe - .5) / .5))
        : pe;
    final double rippleU = ((t - 1.78) / .75).clamp(0.0, 1.0);
    return Column(
      children: [
        Text(
          'MTWTFSS'[i],
          style: TextStyle(
            color: today
                ? const Color(0xFFD2621F)
                : const Color(0xC77A4E1A),
            fontSize: 9.9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 26,
          height: 26,
          child: Transform.scale(
            scale: scale.clamp(0.0, 2.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFB340), Color(0xFFF4781F)],
                    ),
                    boxShadow: [
                      const BoxShadow(
                        offset: Offset(0, 4),
                        blurRadius: 9,
                        spreadRadius: -4,
                        color: Color(0x99E06414),
                      ),
                      if (today) ...const [
                        BoxShadow(color: Color(0xFAFFFDF7), spreadRadius: 2),
                        BoxShadow(color: Color(0x99EF5A1E), spreadRadius: 3.5),
                      ],
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white),
                ),
                if (today && !_still && rippleU > 0 && rippleU < 1)
                  Positioned(
                    left: -2 - 15 * rippleU,
                    top: -2 - 15 * rippleU,
                    right: -2 - 15 * rippleU,
                    bottom: -2 - 15 * rippleU,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEF5A1E).withValues(
                              alpha: .5 *
                                  (rippleU < .3
                                      ? rippleU / .3
                                      : 1 - (rippleU - .3) / .7)),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stats(double t) {
    final double e = _ease(t, 1.45, .55);
    return Opacity(
      opacity: _ease(t, 1.45, .25),
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - e)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 11, 0, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xA8FFFFFF), Color(0x6BFFFFFF)],
            ),
            border: Border.all(color: const Color(0x40FFFFFF)),
            boxShadow: const [
              BoxShadow(
                offset: Offset(0, 12),
                blurRadius: 26,
                spreadRadius: -20,
                color: Color(0x80BE6E14),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                    child: _stat('${widget.longestStreak}', 'LONGEST STREAK')),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: const Color(0x338A5A20),
                ),
                Expanded(
                    child: _stat(
                        '${widget.streakDays}/7', 'THIS WEEK')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String big, String cap) => Column(
        children: [
          _gradText(big, 21.6),
          const SizedBox(height: 3),
          Text(
            cap,
            style: const TextStyle(
              color: Color(0xB88A5A20),
              fontSize: 9.6,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      );
}

/// Confetti burst: rise (easeOut) then fall (easeIn), fading out — pure
/// function of the screen clock.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = Offset(size.width / 2, size.height * .36);
    for (final _Confetto c in _kConfetti) {
      final double u = (t - c.delay) / 1.7;
      if (u <= 0 || u >= 1) continue;
      double x, y, rot, op;
      if (u < .42) {
        final double p = Curves.easeOut.transform(u / .42);
        x = c.xMid * p;
        y = -c.rise * p;
        rot = c.rot * .6 * p;
        op = 1;
      } else {
        final double p = Curves.easeIn.transform((u - .42) / .58);
        x = c.xMid + (c.xEnd - c.xMid) * p;
        y = -c.rise + (c.fall + c.rise) * p;
        rot = c.rot * (.6 + .4 * p);
        op = 1 - p;
      }
      canvas.save();
      canvas.translate(origin.dx + x, origin.dy + y);
      canvas.rotate(rot * math.pi / 180);
      final Paint paint =
          Paint()..color = c.color.withValues(alpha: op.clamp(0.0, 1.0));
      if (c.strip) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: 4, height: 10),
                const Radius.circular(2)),
            paint);
      } else {
        canvas.drawCircle(Offset.zero, c.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// The layered flame: blurred core inside the shell, crisp core outside it
/// (the upstream mask), the translucent shell and a top light — swaying and
/// flickering on two different loops.
class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.t});
  final double t;

  static final Path _shell = _svgPath(_shellD);
  static final Path _core = _svgPath(_coreD);
  static final Path _coreMasked =
      Path.combine(PathOperation.difference, _core, _shell);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);

    // warm drop glow standing in for the CSS drop-shadows
    canvas.drawPath(
        _shell,
        Paint()
          ..color = const Color(0x73F06E1E)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6));

    final Paint corePaint = Paint()
      ..shader = ui.Gradient.linear(
          const Offset(12, 9), const Offset(12, 21), const [
        Color(0xFFFF9A3D),
        Color(0xFFE64A12),
      ]);

    // flicker (1.5 s loop) and sway (2.8 s alternate)
    final double f = t % 1.5 / 1.5;
    final double flickY =
        1 + .07 * math.sin(f * math.pi * 2) + .02 * math.sin(f * math.pi * 6);
    final double flickX = 2 - flickY; // opposite squash
    final double flickR =
        -.03 * math.sin(f * math.pi * 2 + .8); // radians, subtle
    final double sway = .5 - .5 * math.cos(2 * math.pi * t / 5.6);

    void withPivot(double px, double py, double sx, double sy, double rot,
        void Function() draw) {
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
      canvas.scale(sx, sy);
      canvas.translate(-px, -py);
      draw();
      canvas.restore();
    }

    // core: crisp outside the shell, blurred inside it
    withPivot(12, 20.1, flickX, flickY, flickR, () {
      canvas.drawPath(_coreMasked, corePaint);
      canvas.save();
      canvas.clipPath(_shell);
      canvas.drawPath(
          _core,
          Paint()
            ..shader = corePaint.shader
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      canvas.restore();
    });

    // shell + top light sway together
    withPivot(12, 21.2, 1, 1 + .025 * sway,
        (-1.1 + 2.2 * sway) * math.pi / 180, () {
      canvas.drawPath(
          _shell,
          Paint()
            ..shader = ui.Gradient.linear(
                const Offset(12, 1.17), const Offset(12, 22), const [
              Color(0xCCFFC86E),
              Color(0xD9FF9642),
            ]));
      canvas.drawPath(
          _shell,
          Paint()
            ..shader = ui.Gradient.linear(
                const Offset(12, 1.17), const Offset(12, 13.23), [
              Colors.white.withValues(alpha: .5),
              Colors.white.withValues(alpha: 0),
            ]));
    });
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.t != t;
}

// ── SVG path mini-parser (absolute + relative commands, arcs) ──────────────

Path _svgPath(String d) {
  final RegExp tok = RegExp(
      r'[MmLlHhVvCcSsQqTtAaZz]|-?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?');
  final List<String> ts = tok.allMatches(d).map((m) => m.group(0)!).toList();
  final Path path = Path();
  int i = 0;
  double x = 0, y = 0, sx = 0, sy = 0, cx = 0, cy = 0;
  String cmd = '';
  double n() => double.parse(ts[i++]);
  while (i < ts.length) {
    final String t = ts[i];
    if (RegExp(r'^[A-Za-z]$').hasMatch(t)) {
      cmd = t;
      i++;
    } else if (cmd == 'M') {
      cmd = 'L';
    } else if (cmd == 'm') {
      cmd = 'l';
    }
    switch (cmd) {
      case 'M':
        x = n();
        y = n();
        path.moveTo(x, y);
        sx = x;
        sy = y;
      case 'm':
        x += n();
        y += n();
        path.moveTo(x, y);
        sx = x;
        sy = y;
      case 'L':
        x = n();
        y = n();
        path.lineTo(x, y);
      case 'l':
        x += n();
        y += n();
        path.lineTo(x, y);
      case 'H':
        x = n();
        path.lineTo(x, y);
      case 'h':
        x += n();
        path.lineTo(x, y);
      case 'V':
        y = n();
        path.lineTo(x, y);
      case 'v':
        y += n();
        path.lineTo(x, y);
      case 'C':
        final double a = n(), b = n();
        cx = n();
        cy = n();
        x = n();
        y = n();
        path.cubicTo(a, b, cx, cy, x, y);
      case 'c':
        final double a = x + n(), b = y + n();
        cx = x + n();
        cy = y + n();
        final double ex = x + n(), ey = y + n();
        path.cubicTo(a, b, cx, cy, ex, ey);
        x = ex;
        y = ey;
      case 'S':
        final double a = 2 * x - cx, b = 2 * y - cy;
        cx = n();
        cy = n();
        x = n();
        y = n();
        path.cubicTo(a, b, cx, cy, x, y);
      case 's':
        final double a = 2 * x - cx, b = 2 * y - cy;
        cx = x + n();
        cy = y + n();
        final double ex = x + n(), ey = y + n();
        path.cubicTo(a, b, cx, cy, ex, ey);
        x = ex;
        y = ey;
      case 'A' || 'a':
        final double rx = n(), ry = n(), rot = n();
        final bool large = n() != 0, sweep = n() != 0;
        double ex = n(), ey = n();
        if (cmd == 'a') {
          ex += x;
          ey += y;
        }
        path.arcToPoint(Offset(ex, ey),
            radius: Radius.elliptical(rx, ry),
            rotation: rot,
            largeArc: large,
            clockwise: sweep);
        x = ex;
        y = ey;
      case 'Z' || 'z':
        path.close();
        x = sx;
        y = sy;
      default:
        i++;
    }
    if (cmd != 'C' && cmd != 'c' && cmd != 'S' && cmd != 's') {
      cx = x;
      cy = y;
    }
  }
  return path;
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

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
        scale: _down ? .97 : 1,
        duration: const Duration(milliseconds: 220),
        curve: const Cubic(.34, 1.56, .64, 1),
        child: widget.child,
      ),
    );
  }
}
