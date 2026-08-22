/// Calm Onboard
/// Origin: adapted — port of OnboardScreen.tsx from mortspace's FeralUI
/// calm-app screen set (React + motion): three swipeable pages scrub one
/// continuous day — the sun and moon ride a great circle, the sky crosses
/// from morning through golden hour into night, and an arc slider mirrors
/// the drag. The landscape is a procedural painting replacing land.webp.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Curve _soft = Cubic(.22, 1, .3, 1);

/// One page of copy.
class CalmOnboardPage {
  const CalmOnboardPage(this.title, this.body);
  final String title;
  final String body;
}

const List<CalmOnboardPage> kCalmOnboardPages = [
  CalmOnboardPage('Start with a check-in',
      'One gentle mood check-in a day. No streaks to guard, no pressure.'),
  CalmOnboardPage('Breathe it out',
      'Guided minutes of calm that fit inside any kind of day.'),
  CalmOnboardPage('Rest like you mean it',
      'Wind down into softer nights and brighter mornings.'),
];

/// Warm sunset palette (the upstream `--sc-*` custom properties).
class CalmOnboardPalette {
  const CalmOnboardPalette({
    this.bg = const Color(0xFFF7F1EA),
    this.g1 = const Color(0xFFF3DDC8),
    this.g2 = const Color(0xFFDFA17C),
    this.ink = const Color(0xFF6E3D28),
    this.deep = const Color(0xFFB3603F),
    this.accent = const Color(0xFFC67F68),
    this.btnInk = const Color(0xFFA85A44),
    this.shadow = const Color(0xFF783728),
  });

  final Color bg, g1, g2, ink, deep, accent, btnInk, shadow;
}

/// Piecewise-linear map with clamped ends (framer's useTransform ranges).
double _map(double v, List<double> xs, List<double> ys) {
  if (v <= xs.first) return ys.first;
  if (v >= xs.last) return ys.last;
  for (int i = 0; i < xs.length - 1; i++) {
    if (v <= xs[i + 1]) {
      final double u = (v - xs[i]) / (xs[i + 1] - xs[i]);
      return ys[i] + (ys[i + 1] - ys[i]) * u;
    }
  }
  return ys.last;
}

// deterministic star field (upstream formula), upper third of the sky
final List<(double, double, double, double)> _kStars = [
  for (int i = 0; i < 14; i++)
    (
      8 + ((i * 53) % 84).toDouble(),
      6 + ((i * 37) % 34).toDouble(),
      1.6 + ((i * 7) % 3) * .8,
      2.6 + ((i * 13) % 20) / 10,
    ),
];

/// Onboarding as one continuous day: swipe (or scrub the arc) through three
/// pages while the sun sets and the moon rises. Fills whatever box it is
/// given (designed at 390x844).
class CalmOnboardScreen extends StatefulWidget {
  const CalmOnboardScreen({
    super.key,
    this.onNext,
    this.onPhase,
    this.pages = kCalmOnboardPages,
    this.initialPage = 0,
    this.palette = const CalmOnboardPalette(),
    this.animate = true,
  });

  /// Called by Skip, and by the button on the final (night) page.
  final VoidCallback? onNext;

  /// Fires when the night page is entered/left.
  final ValueChanged<bool>? onPhase;

  final List<CalmOnboardPage> pages;
  final int initialPage;
  final CalmOnboardPalette palette;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmOnboardScreen> createState() => _CalmOnboardScreenState();
}

class _CalmOnboardScreenState extends State<CalmOnboardScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  double _last = 0;

  late double _p = widget.initialPage.clamp(0, 2).toDouble();
  double _pv = 0;
  late int _target = widget.initialPage.clamp(0, 2);
  late int _page = _target;
  bool _dragging = false;
  double _dragStartP = 0;
  double _dragDx = 0;
  bool _wasNight = false;

  bool get _still =>
      !widget.animate || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) {
      final double now = e.inMicroseconds / 1e6;
      final double dt = math.min(.04, now - _last);
      _last = now;
      if (!_dragging) {
        // page spring: slower and calmer when crossing into/out of night
        final bool nightSpring = _target == 2 || _p > 1.5;
        final double k = nightSpring ? 55 : 160;
        final double c = nightSpring ? 14 : 21;
        _pv += (-k * (_p - _target) - c * _pv) * dt;
        _p += _pv * dt;
        if ((_p - _target).abs() < .0006 && _pv.abs() < .004) {
          _p = _target.toDouble();
          _pv = 0;
        }
      }
      _t.value = now;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _ticker.stop();
      _p = _target.toDouble();
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

  void _setPage(int n) {
    final int clamped = n.clamp(0, 2);
    setState(() {
      _target = clamped;
      _page = clamped;
    });
    if (_still) _p = clamped.toDouble();
    final bool night = clamped == 2;
    if (night != _wasNight) {
      _wasNight = night;
      widget.onPhase?.call(night);
    }
  }

  void _liveTrackPage() {
    final int n = _p.round().clamp(0, 2);
    if (n != _page) setState(() => _page = n);
  }

  @override
  Widget build(BuildContext context) {
    final CalmOnboardPalette pal = widget.palette;
    return ClipRect(
      child: LayoutBuilder(builder: (context, box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        return ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, t, _) {
            final double p = _p.clamp(0.0, 2.2);
            final double dial = _map(p, const [0, 1, 2], const [-48, 0, 180]);
            final double phaseA = _map(p, const [0, 1], const [1, 0]);
            final double phaseB =
                _map(p, const [0, 1, 2], const [0, 1, 0]);
            final double phaseC = _map(p, const [1.05, 2], const [0, 1]);
            final double starsOp =
                _map(p, const [1.35, 1.95], const [0, 1]);
            final double cloudsOp = _map(p, const [0, .2, 1.4, 1.85],
                const [.85, .95, .9, 0]);
            final double birdsOp =
                _map(p, const [0, .55, .95], const [.85, .7, 0]);
            final double sunGlowOp = _map(p, const [0, .45, 1, 1.5, 1.85],
                const [.55, .36, .32, .55, 0]);
            final double moonGlowOp =
                _map(p, const [1.5, 2], const [0, .34]);
            final double horizonOp = _map(p, const [0, .3, 1, 1.5, 1.8, 2],
                const [.5, .22, .16, .55, .18, 0]);

            final double r = w * .48;
            final double cy = h * .615;
            final double rad = dial * math.pi / 180;
            final Offset sun =
                Offset(w / 2 + r * math.sin(rad), cy - r * math.cos(rad));
            final double mrad = (dial - 180) * math.pi / 180;
            final Offset moon =
                Offset(w / 2 + r * math.sin(mrad), cy - r * math.cos(mrad));

            final bool night = _page == 2;
            final Color copyInk =
                Color.lerp(pal.ink, const Color(0xFFEEF1FF), phaseC)!;

            return Stack(
              fit: StackFit.expand,
              children: [
                // three skies cross-fading
                _sky(
                  phaseC,
                  const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF070C20),
                      Color(0xFF10173A),
                      Color(0xFF3A4170)
                    ],
                    stops: [0, .48, 1],
                  ),
                ),
                _sky(
                  phaseB * (1 - phaseC),
                  LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(pal.g1, const Color(0xFFE9F1F5), .46)!,
                      Color.lerp(Colors.white, pal.g1, .78)!,
                      Color.lerp(Colors.white, pal.g2, .88)!,
                    ],
                    stops: const [0, .46, 1],
                  ),
                ),
                _sky(
                  phaseA,
                  LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(pal.bg, Colors.white, .48)!,
                      Color.lerp(Colors.white, pal.g1, .92)!,
                      Color.lerp(Colors.white, pal.g2, .64)!,
                    ],
                    stops: const [0, .52, 1],
                  ),
                ),
                // stars (night only)
                if (starsOp > .003)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _StarsPainter(
                            t: _still ? 0 : t, opacity: starsOp),
                      ),
                    ),
                  ),
                // clouds + birds
                if (cloudsOp > .003) ...[
                  _cloud(t, w * .09, h * .33, 66, 16, -3.5, 26, cloudsOp,
                      pal),
                  _cloud(t, w - w * .11 - 46, h * .41, 46, -20, 3, 34,
                      cloudsOp, pal),
                ],
                if (birdsOp > .003)
                  Positioned(
                    left: w * .27,
                    top: h * .40,
                    child: Opacity(
                      opacity: birdsOp,
                      child: CustomPaint(
                        size: const Size(56, 22),
                        painter: _BirdsPainter(
                            pal.ink.withValues(alpha: .55)),
                      ),
                    ),
                  ),
                // horizon glow
                Positioned(
                  left: -w * .12,
                  right: -w * .12,
                  bottom: h * .30,
                  height: h * .16,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: horizonOp.clamp(0.0, 1.0),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, .24),
                            radius: .9,
                            colors: [
                              Color(0x8CF9BB6A),
                              Color(0x33F9BB6A),
                              Color(0x00F9BB6A)
                            ],
                            stops: [0, .52, .76],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // sun + moon riding the great circle
                _glow(sun, 140, const Color(0x80F6BE6C), sunGlowOp),
                Positioned(
                  left: sun.dx - 28,
                  top: sun.dy - 28,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFFF2B25C)),
                  ),
                ),
                _glow(moon, 100, const Color(0x66D8E2FF), moonGlowOp),
                Positioned(
                  left: moon.dx - 23,
                  top: moon.dy - 23,
                  child: const CustomPaint(
                      size: Size(46, 46), painter: _CrescentPainter()),
                ),
                // procedural landscape (day + night cross-fade)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: w * .42,
                  child: IgnorePointer(
                    child: CustomPaint(
                        painter: _LandPainter(night: phaseC)),
                  ),
                ),
                // swipe layer (everything above the foot)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 140,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (d) {
                      _dragging = true;
                      _dragStartP = _p;
                      _dragDx = 0;
                    },
                    onHorizontalDragUpdate: (d) {
                      _dragDx += d.delta.dx;
                      _p = (_dragStartP - _dragDx / w).clamp(-.14, 2.14);
                      _liveTrackPage();
                      if (_still) _t.value += .0001; // repaint when frozen
                    },
                    onHorizontalDragEnd: (d) {
                      _dragging = false;
                      final double vPages =
                          -d.velocity.pixelsPerSecond.dx / w;
                      _pv = vPages;
                      final double projected = _p + vPages * .24;
                      _setPage(projected.round());
                    },
                    onHorizontalDragCancel: () {
                      _dragging = false;
                      _setPage(_p.round());
                    },
                  ),
                ),
                // skip
                Positioned(
                  top: 58,
                  right: 16,
                  child: Opacity(
                    opacity: _ease(t, .5, .45),
                    child: Transform.scale(
                      scale: .8 + .2 * _ease(t, .5, .45),
                      child: GestureDetector(
                        onTap: widget.onNext,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(
                                sigmaX: 3, sigmaY: 3),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    Colors.white.withValues(alpha: .42),
                              ),
                              child: Icon(Icons.chevron_right_rounded,
                                  size: 22, color: copyInk),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // copy + foot
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 0, 30, 18),
                        child: Opacity(
                          opacity: _ease(t, .24, .6),
                          child: Transform.translate(
                            offset:
                                Offset(0, 14 * (1 - _ease(t, .24, .6))),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: const Cubic(.16, 1, .3, 1),
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, a) =>
                                  FadeTransition(
                                opacity: a,
                                child: SlideTransition(
                                  position: Tween(
                                          begin: const Offset(0, .16),
                                          end: Offset.zero)
                                      .animate(a),
                                  child: child,
                                ),
                              ),
                              child: Column(
                                key: ValueKey<int>(_page),
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.pages[_page].title,
                                    style: TextStyle(
                                      color: copyInk,
                                      fontSize: 24.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.16,
                                      letterSpacing: -.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.pages[_page].body,
                                    style: TextStyle(
                                      color: copyInk.withValues(
                                          alpha: .8),
                                      fontSize: 13.4,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 36),
                        child: Opacity(
                          opacity: _ease(t, .4, .55),
                          child: Transform.translate(
                            offset:
                                Offset(0, 12 * (1 - _ease(t, .4, .55))),
                            child: Column(
                              children: [
                                _arcSlider(w, p, phaseC, pal),
                                const SizedBox(height: 10),
                                _PressScale(
                                  onTap: () => night
                                      ? widget.onNext?.call()
                                      : _setPage(_page + 1),
                                  child: Container(
                                    height: 52,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(26),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white,
                                          Color.lerp(Colors.white,
                                              pal.accent, .09)!,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          offset: const Offset(0, 14),
                                          blurRadius: 28,
                                          spreadRadius: -14,
                                          color: pal.shadow
                                              .withValues(alpha: .55),
                                        ),
                                      ],
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                          milliseconds: 240),
                                      switchInCurve: _soft,
                                      transitionBuilder: (child, a) =>
                                          FadeTransition(
                                        opacity: a,
                                        child: SlideTransition(
                                          position: Tween(
                                                  begin: const Offset(
                                                      0, .5),
                                                  end: Offset.zero)
                                              .animate(a),
                                          child: child,
                                        ),
                                      ),
                                      child: Text(
                                        night ? 'Get started' : 'Next',
                                        key: ValueKey<bool>(night),
                                        style: TextStyle(
                                          color: pal.btnInk,
                                          fontSize: 15.7,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _sky(double opacity, Gradient g) => Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: DecoratedBox(decoration: BoxDecoration(gradient: g)),
      );

  Widget _glow(Offset center, double size, Color color, double opacity) =>
      Positioned(
        left: center.dx - size / 2,
        top: center.dy - size / 2,
        child: IgnorePointer(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  color,
                  color.withValues(alpha: color.a * .32),
                  color.withValues(alpha: 0),
                ], stops: const [
                  0,
                  .52,
                  .72,
                ]),
              ),
            ),
          ),
        ),
      );

  Widget _cloud(double t, double left, double top, double width, double dx,
      double dy, double dur, double opacity, CalmOnboardPalette pal) {
    final double u =
        _still ? 0 : .5 - .5 * math.cos(2 * math.pi * t / dur);
    return Positioned(
      left: left + dx * u,
      top: top + dy * u,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: CustomPaint(
            size: Size(width, width * 24 / 36),
            painter:
                _CloudPainter(Color.lerp(pal.g2, Colors.white, .84)!),
          ),
        ),
      ),
    );
  }

  Widget _arcSlider(
      double w, double p, double phaseC, CalmOnboardPalette pal) {
    const double aw = 132; // rendered arc width (viewBox 120x44)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (d) {
        _dragging = true;
        _arcScrub(d.localPosition.dx, aw);
      },
      onHorizontalDragUpdate: (d) => _arcScrub(d.localPosition.dx, aw),
      onHorizontalDragEnd: (_) {
        _dragging = false;
        _setPage(_p.round());
      },
      onTapDown: (d) => _arcScrub(d.localPosition.dx, aw),
      onTapUp: (_) => _setPage(_p.round()),
      child: SizedBox(
        width: aw,
        height: aw * 44 / 120 + 6,
        child: CustomPaint(
          painter: _ArcPainter(
            p: p,
            fill: Color.lerp(pal.deep, const Color(0xFFB8C4FF), phaseC)!,
            track: Color.lerp(pal.ink, const Color(0xFFEEF1FF), phaseC)!
                .withValues(alpha: .35),
          ),
        ),
      ),
    );
  }

  void _arcScrub(double x, double aw) {
    final double u =
        ((x / aw * 120 - 8) / 104).clamp(0.0, 1.0);
    _p = u * 2;
    _pv = 0;
    _liveTrackPage();
    if (_still) _t.value += .0001;
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter({required this.t, required this.opacity});
  final double t;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (double xp, double yp, double s, double tw) in _kStars) {
      final double twinkle =
          .45 + .5 * (.5 - .5 * math.cos(2 * math.pi * t / tw));
      canvas.drawCircle(
          Offset(size.width * xp / 100, size.height * .54 * yp / 100),
          s / 2 + .4,
          Paint()
            ..color = const Color(0xFFDFE6FF)
                .withValues(alpha: (twinkle * opacity).clamp(0.0, 1.0))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .8));
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) =>
      old.t != t || old.opacity != opacity;
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 36);
    final Path cloud = Path()
      ..moveTo(28.5, 21)
      ..lineTo(8, 21)
      ..arcToPoint(const Offset(6.9, 9.1),
          radius: const Radius.circular(6), clockwise: true)
      ..arcToPoint(const Offset(24.2, 6.7),
          radius: const Radius.circular(9), clockwise: true)
      ..arcToPoint(const Offset(28.5, 21),
          radius: const Radius.circular(6.5), clockwise: true)
      ..close();
    canvas.drawPath(cloud, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.color != color;
}

class _BirdsPainter extends CustomPainter {
  const _BirdsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 60);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawPath(
        Path()
          ..moveTo(6, 12)
          ..quadraticBezierTo(11, 7, 16, 12)
          ..quadraticBezierTo(21, 7, 26, 12),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(34, 7)
          ..quadraticBezierTo(38, 3, 42, 7)
          ..quadraticBezierTo(46, 3, 50, 7),
        p);
  }

  @override
  bool shouldRepaint(_BirdsPainter old) => old.color != color;
}

/// The moon crescent: a disc with a bite punched out at 74%/24%.
class _CrescentPainter extends CustomPainter {
  const _CrescentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double d = size.width;
    final Path disc = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(d / 2, d / 2), radius: d / 2));
    final Path bite = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(d * .74, d * .24), radius: d * .545));
    canvas.drawPath(Path.combine(PathOperation.difference, disc, bite),
        Paint()..color = const Color(0xFFF6F3E2));
  }

  @override
  bool shouldRepaint(_CrescentPainter old) => false;
}

/// Procedural rolling landscape standing in for land.webp; a dark night
/// variant cross-fades on top as the last page arrives.
class _LandPainter extends CustomPainter {
  const _LandPainter({required this.night});
  final double night;

  void _hills(Canvas canvas, Size size, List<Color> back,
      List<Color> front, double opacity) {
    if (opacity <= 0) return;
    final double w = size.width;
    final double h = size.height;
    final Path b = Path()
      ..moveTo(-4, h * .42)
      ..quadraticBezierTo(w * .18, h * .16, w * .42, h * .34)
      ..quadraticBezierTo(w * .6, h * .47, w * .78, h * .3)
      ..quadraticBezierTo(w * .9, h * .2, w + 4, h * .32)
      ..lineTo(w + 4, h + 4)
      ..lineTo(-4, h + 4)
      ..close();
    canvas.drawPath(
        b,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(0, h * .1), Offset(0, h), [
            back[0].withValues(alpha: back[0].a * opacity),
            back[1].withValues(alpha: back[1].a * opacity),
          ]));
    final Path f = Path()
      ..moveTo(-4, h * .74)
      ..quadraticBezierTo(w * .16, h * .5, w * .38, h * .66)
      ..quadraticBezierTo(w * .55, h * .78, w * .72, h * .6)
      ..quadraticBezierTo(w * .88, h * .44, w + 4, h * .62)
      ..lineTo(w + 4, h + 4)
      ..lineTo(-4, h + 4)
      ..close();
    canvas.drawPath(
        f,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(0, h * .4), Offset(0, h), [
            front[0].withValues(alpha: front[0].a * opacity),
            front[1].withValues(alpha: front[1].a * opacity),
          ]));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // warm daylight version
    _hills(
        canvas,
        size,
        const [Color(0xFFE3BC8C), Color(0xFFC98F60)],
        const [Color(0xFFC1935F), Color(0xFF96653F)],
        1);
    // night wash
    _hills(
        canvas,
        size,
        const [Color(0xFF232A52), Color(0xFF161C3E)],
        const [Color(0xFF181E42), Color(0xFF0C1130)],
        night.clamp(0.0, 1.0));
  }

  @override
  bool shouldRepaint(_LandPainter old) => old.night != night;
}

/// The dotted time-of-day arc with its filled sweep and draggable dot.
class _ArcPainter extends CustomPainter {
  const _ArcPainter(
      {required this.p, required this.fill, required this.track});
  final double p;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 120;
    canvas.scale(s);
    final Path arc = Path()
      ..moveTo(8, 36)
      ..quadraticBezierTo(60, -10, 112, 36);
    final ui.PathMetric m = arc.computeMetrics().first;

    // dotted track
    double d = 0;
    while (d < m.length) {
      final ui.Tangent? tan = m.getTangentForOffset(d);
      if (tan != null) {
        canvas.drawCircle(tan.position, 1, Paint()..color = track);
      }
      d += 6;
    }

    // filled sweep
    final double u = (p / 2).clamp(0.0, 1.0);
    if (u > .001) {
      canvas.drawPath(
          m.extractPath(0, m.length * u),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round
            ..color = fill);
    }

    // dot (x mapped linearly like upstream, y on the sine hump)
    final double dx = 8 + 104 * u;
    final double dy = 36 - math.sin(u * math.pi) * 24;
    canvas.drawCircle(
        Offset(dx, dy),
        9,
        Paint()
          ..color = Colors.white.withValues(alpha: .45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .5));
    canvas.drawCircle(Offset(dx, dy), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(dx, dy), 5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = fill.withValues(alpha: .8));
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.p != p || old.fill != fill || old.track != track;
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
