/// Calm Login
/// Origin: adapted — port of LoginScreen.tsx from mortspace's FeralUI
/// calm-app screen set (React + motion), rebuilt with Flutter widgets. The
/// Google / Apple marks are the upstream SVG paths, parsed procedurally.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Curve _soft = Cubic(.22, 1, .3, 1);
const Curve _pop = Cubic(.34, 1.4, .5, 1);

/// Warm sunset palette (the upstream `--sc-*` custom properties).
class CalmLoginPalette {
  const CalmLoginPalette({
    this.bg = const Color(0xFFF9F0E4),
    this.glowA = const Color(0xFFB25E3C),
    this.glowB = const Color(0xFFCB7852),
    this.glowB2 = const Color(0xFFDA8C64),
    this.glowC = const Color(0xFFE8A37C),
    this.glowC2 = const Color(0xFFFACDAC),
    this.deep = const Color(0xFFB3603F),
    this.copySub = const Color(0xFFFDF1E9),
    this.shadow = const Color(0xFF965032),
  });

  final Color bg, glowA, glowB, glowB2, glowC, glowC2, deep, copySub, shadow;
}

/// Sign-in screen: a deep sunset glow rises from the bottom, a small glass
/// brand mark smiles, and a frosted sheet offers Google / Apple / email.
/// Fills whatever box it is given (designed at 390x844).
class CalmLoginScreen extends StatefulWidget {
  const CalmLoginScreen({
    super.key,
    this.onGoogle,
    this.onApple,
    this.onEmail,
    this.palette = const CalmLoginPalette(),
    this.title = 'Take a breath.',
    this.body = 'Sign in and settle into your calm space.',
    this.terms = 'By continuing you agree to our Terms and Privacy Policy.',
    this.animate = true,
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onEmail;
  final CalmLoginPalette palette;
  final String title;
  final String body;
  final String terms;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmLoginScreen> createState() => _CalmLoginScreenState();
}

class _CalmLoginScreenState extends State<CalmLoginScreen>
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

  Widget _enter(double t, double t0, double dur,
      {double dy = 0, double scaleFrom = 1, required Widget child}) {
    final double e = _ease(t, t0, dur, scaleFrom != 1 ? _pop : _soft);
    if (e >= 1) return child;
    Widget w = child;
    if (dy != 0) {
      w = Transform.translate(offset: Offset(0, dy * (1 - e)), child: w);
    }
    if (scaleFrom != 1) {
      w = Transform.scale(scale: scaleFrom + (1 - scaleFrom) * e, child: w);
    }
    return Opacity(opacity: _ease(t, t0, dur * .3), child: w);
  }

  @override
  Widget build(BuildContext context) {
    final CalmLoginPalette p = widget.palette;
    return ClipRect(
      child: ValueListenableBuilder<double>(
        valueListenable: _t,
        builder: (context, t, _) {
          final double glowIn = _ease(t, .1, 1.1);
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: p.bg),
              // sunset glow rising from below
              Opacity(
                opacity: glowIn.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 90 * (1 - glowIn)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 1.25),
                        radius: 1.35,
                        colors: [
                          p.glowA,
                          p.glowA,
                          p.glowA.withValues(alpha: .94),
                          p.glowB.withValues(alpha: .86),
                          p.glowB2.withValues(alpha: .54),
                          p.glowC.withValues(alpha: .30),
                          p.glowC2.withValues(alpha: .12),
                          p.glowC2.withValues(alpha: 0),
                        ],
                        stops: const [0, .32, .48, .61, .72, .81, .89, .96],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const Spacer(),
                  // brand + copy
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _enter(
                          t,
                          .3,
                          .6,
                          dy: 12,
                          scaleFrom: .6,
                          child: _CssShadow(
                            radius: 17,
                            shadowOffset: const Offset(0, 12),
                            blur: 28,
                            spread: -16,
                            color: p.shadow.withValues(alpha: .4),
                            child: _Frost(
                            radius: 17,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(17),
                                color: Colors.white.withValues(alpha: .3),
                                border: Border.all(
                                    color: const Color(0x47FFFFFF)),
                              ),
                              child: CustomPaint(
                                  painter: _BrandFacePainter(p.deep)),
                            ),
                          ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _enter(
                          t,
                          .42,
                          .6,
                          dy: 14,
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 29.8,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              letterSpacing: -.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        _enter(
                          t,
                          .54,
                          .55,
                          dy: 12,
                          child: Text(
                            widget.body,
                            style: TextStyle(
                              color: p.copySub,
                              fontSize: 14.1,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // frosted action sheet
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    child: _enter(
                      t,
                      .62,
                      .6,
                      dy: 26,
                      child: _CssShadow(
                        radius: 28,
                        shadowOffset: const Offset(0, 24),
                        blur: 48,
                        spread: -34,
                        color: p.shadow.withValues(alpha: .45),
                        child: _Frost(
                        radius: 28,
                        child: Container(
                          padding:
                              const EdgeInsets.fromLTRB(14, 14, 14, 11),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x57FFFFFF), Color(0x2EFFFFFF)],
                            ),
                            border:
                                Border.all(color: const Color(0x47FFFFFF)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _enter(
                                t,
                                .72,
                                .45,
                                dy: 10,
                                child: _SheetButton(
                                  onTap: widget.onGoogle,
                                  background: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFFFFFFF),
                                      Color(0xFFF7F4F0)
                                    ],
                                  ),
                                  foreground: const Color(0xFF33302C),
                                  icon: const CustomPaint(
                                    size: Size(18, 18),
                                    painter: _GoogleLogoPainter(),
                                  ),
                                  label: 'Continue with Google',
                                ),
                              ),
                              const SizedBox(height: 10),
                              _enter(
                                t,
                                .8,
                                .45,
                                dy: 10,
                                child: _SheetButton(
                                  onTap: widget.onApple,
                                  background: const LinearGradient(
                                    colors: [
                                      Color(0xFF101012),
                                      Color(0xFF101012)
                                    ],
                                  ),
                                  foreground: Colors.white,
                                  icon: const CustomPaint(
                                    size: Size(18, 18),
                                    painter:
                                        _AppleLogoPainter(Colors.white),
                                  ),
                                  label: 'Continue with Apple',
                                ),
                              ),
                              const SizedBox(height: 10),
                              _enter(
                                t,
                                .88,
                                .4,
                                child: _PressScale(
                                  onTap: widget.onEmail,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11, horizontal: 12),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      color: Colors.white
                                          .withValues(alpha: .14),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: .45),
                                      ),
                                    ),
                                    child: const Text(
                                      'Continue with email',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _enter(
                                t,
                                .98,
                                .45,
                                child: Text(
                                  widget.terms,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xD9FFFFFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
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
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final Gradient background;
  final Color foreground;
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: background,
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 14),
              blurRadius: 28,
              spreadRadius: -18,
              color: Color(0x66301A10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The smiley brand mark: a stroked ring with the orb's sleepy eyes.
class _BrandFacePainter extends CustomPainter {
  const _BrandFacePainter(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    // the 100-unit face renders at 52px inside the 60px chip, centred
    final double s = size.width * (52 / 60) / 100;
    canvas.translate(
        (size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4 * s
      ..strokeCap = StrokeCap.round
      ..color = ink;
    canvas.drawCircle(Offset(50 * s, 50 * s), 31 * s, p);
    canvas.drawPath(
        Path()
          ..moveTo(36 * s, 46.5 * s)
          ..cubicTo(
              38.6 * s, 50.3 * s, 42.4 * s, 50.3 * s, 45 * s, 46.5 * s),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(55 * s, 46.5 * s)
          ..cubicTo(
              57.6 * s, 50.3 * s, 61.4 * s, 50.3 * s, 64 * s, 46.5 * s),
        p);
  }

  @override
  bool shouldRepaint(_BrandFacePainter old) => old.ink != ink;
}

// ── SVG path mini-parser (relative commands + arcs; enough for the marks) ──

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
        i++; // unknown command — skip defensively
    }
    if (cmd != 'C' && cmd != 'c' && cmd != 'S' && cmd != 's') {
      cx = x;
      cy = y;
    }
  }
  return path;
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static final List<(Path, Color)> _marks = [
    (
      _svgPath(
          'M23.49 12.27c0-.79-.07-1.54-.19-2.27H12v4.51h6.47c-.29 1.48-1.14 2.73-2.4 3.58v3h3.86c2.26-2.09 3.56-5.17 3.56-8.82z'),
      const Color(0xFF4285F4)
    ),
    (
      _svgPath(
          'M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.86-3c-1.08.72-2.45 1.16-4.07 1.16-3.13 0-5.78-2.11-6.73-4.96H1.29v3.09C3.26 21.3 7.31 24 12 24z'),
      const Color(0xFF34A853)
    ),
    (
      _svgPath(
          'M5.27 14.29c-.25-.72-.38-1.49-.38-2.29s.14-1.57.38-2.29V6.62H1.29C.47 8.24 0 10.06 0 12s.47 3.76 1.29 5.38l3.98-3.09z'),
      const Color(0xFFFBBC05)
    ),
    (
      _svgPath(
          'M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.31 0 3.26 2.7 1.29 6.62l3.98 3.09c.95-2.85 3.6-4.96 6.73-4.96z'),
      const Color(0xFFEA4335)
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    for (final (Path p, Color c) in _marks) {
      canvas.drawPath(p, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}

class _AppleLogoPainter extends CustomPainter {
  const _AppleLogoPainter(this.color);
  final Color color;

  static final Path _mark = _svgPath(
      'M16.365 12.79c-.024-2.44 1.995-3.61 2.086-3.668-1.136-1.662-2.905-1.89-3.534-1.916-1.505-.152-2.937.886-3.7.886-.76 0-1.94-.864-3.19-.84-1.641.024-3.153.953-3.997 2.42-1.704 2.955-.435 7.33 1.224 9.73.81 1.17 1.777 2.485 3.047 2.437 1.222-.05 1.685-.792 3.163-.792 1.477 0 1.894.792 3.19.767 1.318-.024 2.152-1.193 2.958-2.368.93-1.359 1.313-2.674 1.336-2.742-.03-.012-2.562-.983-2.583-3.914zM13.9 5.62c.674-.816 1.128-1.951 1.004-3.083-.97.04-2.144.646-2.84 1.462-.623.722-1.169 1.877-1.022 2.985 1.082.084 2.185-.55 2.858-1.364z');

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(_mark, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_AppleLogoPainter old) => old.color != color;
}

/// Frosted-glass backdrop (the upstream `.glass` fallback: blur 3).
class _Frost extends StatelessWidget {
  const _Frost({required this.radius, required this.child});
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: child,
      ),
    );
  }
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

/// CSS-style outer drop shadow. Flutter's BoxShadow also paints *under* the
/// box, which shows straight through the translucent glass fills here and
/// muddies them — CSS clips the border-box region out, so this painter does
/// the same: blurred rrect shifted/spread, with the box itself cut away.
class _CssShadow extends StatelessWidget {
  const _CssShadow({
    required this.radius,
    required this.shadowOffset,
    required this.blur,
    required this.spread,
    required this.color,
    required this.child,
  });

  final double radius;
  final Offset shadowOffset;
  final double blur;
  final double spread;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CssShadowPainter(
        radius: radius,
        offset: shadowOffset,
        blur: blur,
        spread: spread,
        color: color,
      ),
      child: child,
    );
  }
}

class _CssShadowPainter extends CustomPainter {
  const _CssShadowPainter({
    required this.radius,
    required this.offset,
    required this.blur,
    required this.spread,
    required this.color,
  });

  final double radius;
  final Offset offset;
  final double blur;
  final double spread;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = Offset.zero & size;
    final RRect rbox = RRect.fromRectAndRadius(box, Radius.circular(radius));
    // Keep everything inside the border box unpainted (the CSS behavior).
    final Path outside = Path()
      ..addRect(box.inflate(blur * 2 + offset.distance + spread.abs()))
      ..addRRect(rbox)
      ..fillType = PathFillType.evenOdd;
    canvas.save();
    canvas.clipPath(outside);
    final RRect shadow = RRect.fromRectAndRadius(
      box.shift(offset).inflate(spread),
      Radius.circular((radius + spread).clamp(0, double.infinity)),
    );
    canvas.drawRRect(
      shadow,
      Paint()
        ..color = color
        // CSS blur radius ≈ 2×sigma.
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CssShadowPainter old) =>
      old.radius != radius ||
      old.offset != offset ||
      old.blur != blur ||
      old.spread != spread ||
      old.color != color;
}
