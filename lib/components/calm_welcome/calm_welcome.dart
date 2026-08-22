/// Calm Welcome
/// Origin: adapted — port of WelcomeScreen.tsx from mortspace's FeralUI
/// calm-app screen set (React + motion), rebuilt with Flutter widgets.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Curve _soft = Cubic(.22, 1, .3, 1);
const Curve _pop = Cubic(.34, 1.2, .5, 1);

/// Warm sunset palette of the welcome screen (the upstream `--sc-*` custom
/// properties, defaults verbatim).
class CalmWelcomePalette {
  const CalmWelcomePalette({
    this.bg = const Color(0xFFF7F1EA),
    this.g1 = const Color(0xFFF3DDC8),
    this.g2 = const Color(0xFFDFA17C),
    this.g3 = const Color(0xFFB8674C),
    this.orbA = const Color(0xFFFFF0E2),
    this.orbB = const Color(0xFFFBC9A8),
    this.orbC = const Color(0xFFF0A983),
    this.orbD = const Color(0xFFE0916C),
    this.orbShadow = const Color(0xFFD68060),
    this.orbInset = const Color(0xFFC66A4E),
    this.orbFace = const Color(0xFF7C4630),
    this.orbBlush = const Color(0x70F07E5F),
    this.orbHalo = const Color(0x80F6AC84),
    this.shadow = const Color(0xFF783728),
    this.accent = const Color(0xFFC67F68),
    this.btnInk = const Color(0xFFA85A44),
  });

  final Color bg, g1, g2, g3;
  final Color orbA, orbB, orbC, orbD, orbShadow, orbInset, orbFace, orbBlush,
      orbHalo;
  final Color shadow, accent, btnInk;
}

/// Welcome screen of a calm/mindfulness app: a warm gradient rises from the
/// bottom, a glowing orb mascot breathes at the top, and the copy + buttons
/// stagger in. Fills whatever box it is given (designed at 390x844).
class CalmWelcomeScreen extends StatefulWidget {
  const CalmWelcomeScreen({
    super.key,
    this.onNext,
    this.onLogin,
    this.palette = const CalmWelcomePalette(),
    this.title = 'Room to breathe,\none day at a time.',
    this.body =
        'A few quiet minutes each day to slow down, check in, and feel a little lighter.',
    this.buttonLabel = 'Get started',
    this.linkLabel = 'I already have an account',
    this.animate = true,
  });

  final VoidCallback? onNext;
  final VoidCallback? onLogin;
  final CalmWelcomePalette palette;
  final String title;
  final String body;
  final String buttonLabel;
  final String linkLabel;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmWelcomeScreen> createState() => _CalmWelcomeScreenState();
}

class _CalmWelcomeScreenState extends State<CalmWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  bool get _still =>
      !widget.animate || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(
        (e) => _t.value = e.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _ticker.stop();
      _t.value = 99; // settled: every entrance done, loops at a fixed phase
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

  @override
  Widget build(BuildContext context) {
    final CalmWelcomePalette p = widget.palette;
    return ClipRect(
      child: LayoutBuilder(builder: (context, box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        return ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, t, _) {
            final double gradIn = _ease(t, .42, 1.1);
            // orb breathe: 4.2 s sine loop (paused in still mode at phase 0)
            final double breathe = _still
                ? 0
                : .5 - .5 * math.cos(2 * math.pi * (t / 4.2));
            final double orbIn = _ease(t, .15, .9, _pop);
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: p.bg),
                // warm gradient rising from the bottom
                Transform.translate(
                  offset: Offset(0, h * (1 - gradIn)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          p.g1.withValues(alpha: 0),
                          p.g1,
                          p.g2,
                          p.g3,
                        ],
                        stops: const [0, .24, .54, 1],
                      ),
                    ),
                  ),
                ),
                // breathing orb mascot
                Positioned(
                  top: h * .14,
                  left: w / 2 - 75,
                  width: 150,
                  height: 150,
                  child: Opacity(
                    opacity: orbIn.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - orbIn)),
                      child: Transform.scale(
                        scale: .55 + .45 * orbIn,
                        child: _CalmOrb(palette: p, breathe: breathe),
                      ),
                    ),
                  ),
                ),
                // copy + actions
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(30, 0, 30, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _enter(
                          t,
                          1.05,
                          .6,
                          dy: 14,
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27.5,
                              fontWeight: FontWeight.w700,
                              height: 1.16,
                              letterSpacing: -.4,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 12,
                                  color: p.shadow.withValues(alpha: .25),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _enter(
                          t,
                          1.2,
                          .6,
                          dy: 12,
                          child: FractionallySizedBox(
                            widthFactor: .84,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.body,
                              style: const TextStyle(
                                color: Color(0xEBFFFFFF),
                                fontSize: 13.1,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _enter(
                          t,
                          1.35,
                          .55,
                          dy: 12,
                          child: _PressScale(
                            onTap: widget.onNext,
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Color.lerp(
                                        Colors.white, p.accent, .09)!,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(0, 14),
                                    blurRadius: 28,
                                    spreadRadius: -14,
                                    color: p.shadow.withValues(alpha: .55),
                                  ),
                                  BoxShadow(
                                    offset: const Offset(0, 2),
                                    blurRadius: 5,
                                    color: p.shadow.withValues(alpha: .18),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.buttonLabel,
                                style: TextStyle(
                                  color: p.btnInk,
                                  fontSize: 15.7,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -.15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _enter(
                          t,
                          1.5,
                          .5,
                          child: _PressScale(
                            onTap: widget.onLogin,
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  widget.linkLabel,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xEBFFFFFF),
                                    fontSize: 13.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
          },
        );
      }),
    );
  }

  Widget _enter(double t, double t0, double dur,
      {double dy = 0, required Widget child}) {
    final double e = _ease(t, t0, dur);
    if (e >= 1) return child;
    return Opacity(
      opacity: e,
      child: dy == 0
          ? child
          : Transform.translate(offset: Offset(0, dy * (1 - e)), child: child),
    );
  }
}

/// The breathing orb mascot with a sleepy smile — shared visual language of
/// the calm screens (also appears on the paywall screen).
class _CalmOrb extends StatelessWidget {
  const _CalmOrb({required this.palette, required this.breathe});
  final CalmWelcomePalette palette;
  final double breathe; // 0..1 breath phase

  @override
  Widget build(BuildContext context) {
    final CalmWelcomePalette p = palette;
    return Transform.translate(
      offset: Offset(0, -1.5 * breathe),
      child: Transform.scale(
        scale: 1 + .055 * breathe,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // halo
            Positioned.fill(
              left: -30,
              top: -30,
              right: -30,
              bottom: -30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [p.orbHalo, p.orbHalo.withValues(alpha: 0)],
                    stops: const [0, .62],
                  ),
                ),
              ),
            ),
            // body
            Positioned.fill(
              left: 12,
              top: 12,
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-.2, -.36),
                    radius: .95,
                    colors: [p.orbA, p.orbB, p.orbC, p.orbD],
                    stops: const [0, .46, .74, .96],
                  ),
                  border: Border.all(color: const Color(0x59FFFFFF)),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 24),
                      blurRadius: 52,
                      spreadRadius: -14,
                      color: p.orbShadow.withValues(alpha: .55),
                    ),
                    BoxShadow(
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                      spreadRadius: -3,
                      color: p.orbShadow.withValues(alpha: .3),
                    ),
                  ],
                ),
                // inner top light + bottom inset shade
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .5),
                        Colors.white.withValues(alpha: 0),
                        p.orbInset.withValues(alpha: 0),
                        p.orbInset.withValues(alpha: .26),
                      ],
                      stops: const [0, .3, .72, 1],
                    ),
                  ),
                ),
              ),
            ),
            // gloss
            Positioned(
              top: 150 * .13,
              left: 150 * .26,
              width: 150 * .3,
              height: 150 * .15,
              child: Transform.rotate(
                angle: -14 * math.pi / 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .92),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // blush
            for (final bool left in const [true, false])
              Positioned(
                top: 150 * .505,
                left: left ? 150 * .22 : null,
                right: left ? null : 150 * .22,
                width: 15,
                height: 7.2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: p.orbBlush.withValues(alpha: p.orbBlush.a * .55),
                    boxShadow: [
                      BoxShadow(color: p.orbBlush, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            // sleepy smiling eyes
            Positioned.fill(
              child: CustomPaint(painter: _OrbFacePainter(p.orbFace)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbFacePainter extends CustomPainter {
  const _OrbFacePainter(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 100;
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.6 * s
      ..strokeCap = StrokeCap.round
      ..color = ink;
    final Path l = Path()
      ..moveTo(31 * s, 46 * s)
      ..cubicTo(34.5 * s, 51.2 * s, 39.5 * s, 51.2 * s, 43 * s, 46 * s);
    final Path r = Path()
      ..moveTo(57 * s, 46 * s)
      ..cubicTo(60.5 * s, 51.2 * s, 65.5 * s, 51.2 * s, 69 * s, 46 * s);
    canvas.drawPath(l, p);
    canvas.drawPath(r, p);
  }

  @override
  bool shouldRepaint(_OrbFacePainter old) => old.ink != ink;
}

/// Springy press feedback (the CSS `scale 0.97` active state).
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
