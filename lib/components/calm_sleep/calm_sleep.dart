/// Calm Sleep
/// Origin: adapted — port of SleepScreen.tsx from mortspace's FeralUI
/// calm-app screen set (React + motion). The moon-phase mask math is
/// upstream verbatim; the moon face and the night hills are procedural
/// replacements for the original webp photos (vault forbids assets).
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Curve _soft = Cubic(.22, 1, .3, 1);
const Curve _blurIn = Cubic(.16, 1, .3, 1);

// upstream SL_T timeline (seconds)
const double _tHills = .1;
const double _tHead = .45;
const double _tMoon = .95;
const double _tMetric = 1.1;
const double _tCount = 1.25;
const double _tCountDur = 1.5;
const double _tShoot = 2.8;
const double _tCard = 2.75;
const double _tLine = 2.95;
const double _tLineDur = 1.2;
const double _tCStars = 2.9;
const double _tFill = 3.9;
const double _tTimes = 4.05;

// deterministic starfield (upstream formula), centre cleared for the moon
final List<(double, double, double, double, double)> _kStars = [
  for (int i = 0; i < 26; i++)
    (
      6 + ((i * 53) % 88).toDouble(),
      4 + ((i * 37) % 48).toDouble(),
      1.6 + ((i * 7) % 3) * .7,
      .2 + ((i * 29) % 70) / 100,
      2.6 + ((i * 13) % 22) / 10,
    ),
]..removeWhere((s) => s.$1 > 26 && s.$1 < 74 && s.$2 > 22);

// sleep-stage "constellation": x, y, star size in a 330x96 plot
const List<(double, double, double)> _kConst = [
  (12, 44, 2.6),
  (57.7, 66, 3.2),
  (103.3, 78, 4),
  (149, 56, 2.6),
  (194.7, 72, 3.6),
  (240.3, 42, 2.6),
  (286, 16, 4.2),
];

/// "Last night" sleep summary: a starfield with one shooting star, the moon
/// lit exactly as far as the sleep goal was met, and a constellation chart
/// of the night. Fills whatever box it is given (designed at 390x844).
class CalmSleepScreen extends StatefulWidget {
  const CalmSleepScreen({
    super.key,
    this.onNext,
    this.sleptMinutes = 384,
    this.goalMinutes = 480,
    this.headline = 'Nearly a full moon',
    this.bedtime = '11:12 pm',
    this.wakeTime = '6:38 am',
    this.animate = true,
  });

  final VoidCallback? onNext;
  final int sleptMinutes;
  final int goalMinutes;
  final String headline;
  final String bedtime;
  final String wakeTime;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmSleepScreen> createState() => _CalmSleepScreenState();
}

class _CalmSleepScreenState extends State<CalmSleepScreen>
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

  Widget _blurEnter(
    double t,
    double t0,
    double dur,
    double dy, {
    required Widget child,
  }) {
    final double e = _ease(t, t0, dur, _blurIn);
    if (e >= 1) return child;
    Widget w = Transform.translate(
      offset: Offset(0, dy * (1 - e)),
      child: child,
    );
    if (e < .96) {
      w = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: 5 * (1 - e),
          sigmaY: 5 * (1 - e),
        ),
        child: w,
      );
    }
    return Opacity(opacity: e, child: w);
  }

  @override
  Widget build(BuildContext context) {
    final int goal = math.max(1, widget.goalMinutes);
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.maxWidth;
          final double h = box.maxHeight;
          // hills scale with width but never eat a short screen
          final double hillsH = math.min(w * .40, h * .26);
          return ValueListenableBuilder<double>(
            valueListenable: _t,
            builder: (context, t, _) {
              // count-up minutes (easeOutCubic like upstream)
              final double cp = _ease(
                t,
                _tCount,
                _tCountDur,
                Curves.easeOutCubic,
              );
              final int mins = (widget.sleptMinutes * cp).round();
              final double phase = mins / goal;
              final int pct = (widget.sleptMinutes / goal * 100).round();
              return Stack(
                fit: StackFit.expand,
                children: [
                  // night sky backdrop
                  Opacity(
                    opacity: _ease(t, 0, .6),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF050A1E),
                            Color(0xFF0A1132),
                            Color(0xFF0D1740),
                          ],
                          stops: [0, .55, 1],
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: _ease(t, 0, .6),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(.56, -.84),
                          radius: .7,
                          colors: [Color(0x2E7891FA), Color(0x007891FA)],
                        ),
                      ),
                    ),
                  ),
                  // stars + shooting star
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SkyPainter(t: t, still: _still),
                      ),
                    ),
                  ),
                  // skip
                  Positioned(
                    top: 54,
                    right: 16,
                    child: Opacity(
                      opacity: _ease(t, .5, .45),
                      child: Transform.scale(
                        scale: .8 + .2 * _ease(t, .5, .45),
                        child: GestureDetector(
                          onTap: widget.onNext,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x661E2850),
                              border: Border.all(
                                color: const Color(0x24FFFFFF),
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 24,
                              color: Color(0xFFEEF1FF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 94),
                      _blurEnter(
                        t,
                        _tHead,
                        .85,
                        12,
                        child: const Text(
                          'LAST NIGHT',
                          style: TextStyle(
                            color: Color(0xA8EEF1FF),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _blurEnter(
                        t,
                        _tHead + .15,
                        .9,
                        14,
                        child: Text(
                          widget.headline,
                          style: const TextStyle(
                            color: Color(0xFFEEF1FF),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.6,
                            height: 1.16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      _blurEnter(
                        t,
                        _tHead + .3,
                        .85,
                        12,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$pct%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB8C4FF),
                                ),
                              ),
                              TextSpan(text: ' of your ${goal ~/ 60}h goal'),
                            ],
                          ),
                          style: const TextStyle(
                            color: Color(0xE0EEF1FF),
                            fontSize: 14.7,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        // scale the moon block down instead of overflowing on
                        // short screens
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: _ease(t, _tMoon, .8),
                                child: Transform.scale(
                                  scale: .88 + .12 * _ease(t, _tMoon, .8),
                                  child: CustomPaint(
                                    size: const Size(152, 152),
                                    painter: _MoonPainter(phase: phase),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Opacity(
                                opacity: _ease(t, _tMetric, .6),
                                child: Transform.translate(
                                  offset: Offset(
                                    0,
                                    10 * (1 - _ease(t, _tMetric, .6)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'ASLEEP',
                                        style: TextStyle(
                                          color: Color(0x8CEEF1FF),
                                          fontSize: 10.9,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${mins ~/ 60}h ${(mins % 60).toString().padLeft(2, '0')}m',
                                        style: const TextStyle(
                                          color: Color(0xFFEEF1FF),
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -.85,
                                          height: 1,
                                          fontFeatures: [
                                            ui.FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // chart card overlapping the hills
                      SizedBox(
                        height: hillsH + 62,
                        width: w,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: hillsH,
                              child: Opacity(
                                opacity: _ease(t, _tHills, .5),
                                child: Transform.translate(
                                  offset: Offset(
                                    0,
                                    34 * (1 - _ease(t, _tHills, .9)),
                                  ),
                                  child: CustomPaint(
                                    painter: const _HillsPainter(),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              top: 0,
                              child: _card(t, h),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _card(double t, double h) {
    final double e = _ease(t, _tCard, .65);
    return Opacity(
      opacity: _ease(t, _tCard, .3),
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - e)),
        child: Transform.scale(
          scale: .98 + .02 * e,
          child: _CssShadow(
            radius: 20,
            shadowOffset: const Offset(0, 16),
            blur: 32,
            spread: -22,
            color: const Color(0xE6020618),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x1FFFFFFF), Color(0x0EFFFFFF)],
                  ),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: 330 / 96,
                      child: CustomPaint(painter: _ChartPainter(t: t)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 2, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _timeCol(
                            t,
                            _tTimes,
                            widget.bedtime,
                            'BEDTIME',
                            CrossAxisAlignment.start,
                          ),
                          _timeCol(
                            t,
                            _tTimes + .1,
                            widget.wakeTime,
                            'WAKE',
                            CrossAxisAlignment.end,
                          ),
                        ],
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
    );
  }

  Widget _timeCol(
    double t,
    double t0,
    String time,
    String cap,
    CrossAxisAlignment align,
  ) {
    final double e = _ease(t, t0, .5);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - e)),
        child: Column(
          crossAxisAlignment: align,
          children: [
            Text(
              time,
              style: const TextStyle(
                color: Color(0xEBEEF1FF),
                fontSize: 13.1,
                fontWeight: FontWeight.w700,
                letterSpacing: -.13,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 1),
            Text(
              cap,
              style: const TextStyle(
                color: Color(0x80EEF1FF),
                fontSize: 10.6,
                fontWeight: FontWeight.w600,
                letterSpacing: .6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Twinkling stars + the one shooting star, over the whole screen.
class _SkyPainter extends CustomPainter {
  const _SkyPainter({required this.t, required this.still});
  final double t;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (double xp, double yp, double s, double delay, double tw)
        in _kStars) {
      final double e = _soft.transform(((t - delay) / .6).clamp(0.0, 1.0));
      if (e <= 0) continue;
      final double twinkle = still
          ? .7
          : .55 + .3 * (.5 - .5 * math.cos(2 * math.pi * (t - delay) / tw));
      final Paint p = Paint()
        ..color = const Color(
          0xFFDFE6FF,
        ).withValues(alpha: (e * twinkle).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .6);
      canvas.drawCircle(
        Offset(size.width * xp / 100, size.height * .52 * yp / 100),
        s * e / 2 + s / 2,
        p,
      );
    }

    // shooting star (once, at t = 2.8)
    if (!still) {
      final double u = (t - _tShoot) / 2.2;
      if (u > 0 && u < 1) {
        final double op = u < .1 ? u / .1 : (u > .74 ? (1 - u) / .26 : 1);
        final double drift = Curves.easeOut.transform(u);
        final Offset head = Offset(
          size.width * .92 - 195 * drift,
          size.height * .13 + 65 * drift,
        );
        final double tail =
            96 * (u < .4 ? .2 + .8 * (u / .4) : 1 - .6 * ((u - .4) / .6));
        final double ang = 162 * math.pi / 180;
        final Offset back = head + Offset(math.cos(ang), -math.sin(ang)) * tail;
        canvas.drawLine(
          back,
          head,
          Paint()
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..shader = ui.Gradient.linear(
              back,
              head,
              [
                const Color(0x00D6E2FF),
                Color(0x99D6E2FF).withValues(alpha: .6 * op),
                Colors.white.withValues(alpha: op),
              ],
              const [0, .55, 1],
            ),
        );
        canvas.drawCircle(
          head,
          2.3,
          Paint()
            ..color = const Color(0xFFF4F8FF).withValues(alpha: op)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.t != t;
}

/// Procedural moon: shadowed disc + craters, lit up to the goal-phase
/// terminator (upstream mask math verbatim).
class _MoonPainter extends CustomPainter {
  const _MoonPainter({required this.phase});
  final double phase;

  static const List<(double, double, double)> _craters = [
    (72, 66, 13),
    (128, 84, 9),
    (96, 128, 15),
    (140, 132, 7),
    (64, 108, 7),
    (112, 52, 6),
    (86, 88, 5),
    (132, 108, 4),
  ];

  void _face(Canvas canvas, Color base, Color crater, Color rim) {
    final Paint p = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(84, 82),
        110,
        [rim, base],
        const [0, 1],
      );
    canvas.drawCircle(const Offset(100, 100), 78, p);
    for (final (double cx, double cy, double r) in _craters) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = crater.withValues(alpha: .5),
      );
      canvas.drawCircle(
        Offset(cx - r * .12, cy - r * .12),
        r * .82,
        Paint()..color = base.withValues(alpha: .35),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200);

    // glow tracks how full the moon is
    canvas.drawCircle(
      const Offset(100, 100),
      118,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(100, 100), 130, [
          const Color(0xFFB0C0FF).withValues(alpha: (.08 + phase * .2) * .5),
          const Color(0x00B0C0FF),
        ])
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // dark side
    _face(
      canvas,
      const Color(0xFF2A3050),
      const Color(0xFF202642),
      const Color(0xFF3A4066),
    );

    // lit side, clipped by the phase terminator
    final double termRx = math.cos(math.pi * phase).abs() * 80;
    final bool sweepRight = phase >= .5;
    final Path lit = Path()
      ..moveTo(100, 20)
      ..arcToPoint(
        const Offset(100, 180),
        radius: const Radius.circular(80),
        clockwise: true,
      )
      ..arcToPoint(
        const Offset(100, 20),
        radius: Radius.elliptical(math.max(.01, termRx), 80),
        clockwise: sweepRight,
      )
      ..close();
    canvas.save();
    canvas.clipPath(lit);
    _face(
      canvas,
      const Color(0xFFE9E4D2),
      const Color(0xFFD3CDB8),
      const Color(0xFFFBF8EC),
    );
    canvas.restore();
    // soften the terminator
    canvas.drawPath(
      Path()
        ..moveTo(100, 20)
        ..arcToPoint(
          const Offset(100, 180),
          radius: Radius.elliptical(math.max(.01, termRx), 80),
          clockwise: !sweepRight,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFFE9E4D2).withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    canvas.drawCircle(
      const Offset(100, 100),
      78.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x24FFFFFF),
    );
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.phase != phase;
}

/// Sleep-stage constellation chart in the upstream 330x96 plot space.
class _ChartPainter extends CustomPainter {
  const _ChartPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double sx = size.width / 330;
    canvas.scale(sx, size.height / 96);

    final Paint grid = Paint()
      ..strokeWidth = 1
      ..color = const Color(0x1FFFFFFF);
    canvas.drawLine(const Offset(12, 16), const Offset(286, 16), grid);
    canvas.drawLine(const Offset(12, 78), const Offset(286, 78), grid);

    void label(String s, double y) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: s,
          style: const TextStyle(
            color: Color(0x8CEEF1FF),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(326 - tp.width, y - tp.height / 2));
    }

    label('Awake', 16);
    label('Deep', 78);

    final Path line = Path()..moveTo(_kConst[0].$1, _kConst[0].$2);
    for (int i = 1; i < _kConst.length; i++) {
      line.lineTo(_kConst[i].$1, _kConst[i].$2);
    }

    // area fill fades in late
    final double fillE = _soft.transform(((t - _tFill) / 1).clamp(0.0, 1.0));
    if (fillE > 0) {
      final Path area = Path.from(line)
        ..lineTo(286, 88)
        ..lineTo(12, 88)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader =
              ui.Gradient.linear(const Offset(0, 0), const Offset(0, 96), [
                const Color(0xFF8B9AF0).withValues(alpha: .2 * fillE),
                const Color(0x008B9AF0),
              ]),
      );
    }

    // line draws itself on
    final double lineE = const Cubic(
      .4,
      0,
      .2,
      1,
    ).transform(((t - _tLine) / _tLineDur).clamp(0.0, 1.0));
    if (lineE > 0) {
      final ui.PathMetric m = line.computeMetrics().first;
      canvas.drawPath(
        m.extractPath(0, m.length * lineE),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(
            const Offset(12, 0),
            const Offset(286, 0),
            [
              const Color(0xE6A99AFF),
              const Color(0xCC9DB1FF),
              const Color(0xF2FFC27D),
            ],
            const [0, .55, 1],
          ),
      );
    }

    // star sparkles pop one by one
    const Cubic popCurve = Cubic(.34, 1.45, .5, 1);
    for (int i = 0; i < _kConst.length; i++) {
      final double e = popCurve.transform(
        ((t - (_tCStars + i * .17)) / .45).clamp(0.0, 1.0),
      );
      if (e <= 0) continue;
      final (double x, double y, double s0) = _kConst[i];
      final double s = s0 * e;
      final Path star = Path()
        ..moveTo(x, y - s)
        ..lineTo(x + s * .32, y - s * .32)
        ..lineTo(x + s, y)
        ..lineTo(x + s * .32, y + s * .32)
        ..lineTo(x, y + s)
        ..lineTo(x - s * .32, y + s * .32)
        ..lineTo(x - s, y)
        ..lineTo(x - s * .32, y - s * .32)
        ..close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFEEF2FF));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.t != t;
}

/// Procedural night hills replacing the upstream hills.webp: two layered
/// rolling silhouettes under a faint rim light.
class _HillsPainter extends CustomPainter {
  const _HillsPainter();

  Path _ridge(Size size, List<(double, double)> pts) {
    final Path p = Path()..moveTo(-4, size.height * pts.first.$2);
    for (int i = 0; i < pts.length - 1; i++) {
      final (double x1, double y1) = pts[i];
      final (double x2, double y2) = pts[i + 1];
      p.quadraticBezierTo(
        size.width * (x1 + x2) / 2,
        size.height * math.min(y1, y2) -
            size.height * .06 * (y1 - y2).abs().clamp(.2, 1),
        size.width * x2,
        size.height * y2,
      );
    }
    p
      ..lineTo(size.width + 4, size.height + 4)
      ..lineTo(-4, size.height + 4)
      ..close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path back = _ridge(size, const [
      (0, .52),
      (.22, .34),
      (.45, .52),
      (.68, .3),
      (.88, .5),
      (1, .42),
    ]);
    canvas.drawPath(
      back,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * .2),
          Offset(0, size.height),
          [const Color(0xFF141B3E), const Color(0xFF0C1230)],
        ),
    );
    canvas.drawPath(
      back,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0x2E9DB1FF),
    );

    final Path front = _ridge(size, const [
      (0, .78),
      (.18, .62),
      (.42, .8),
      (.62, .58),
      (.82, .76),
      (1, .66),
    ]);
    canvas.drawPath(
      front,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * .45),
          Offset(0, size.height),
          [const Color(0xFF0C1230), const Color(0xFF070C22)],
        ),
    );
    canvas.drawPath(
      front,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x24B8C4FF),
    );
  }

  @override
  bool shouldRepaint(_HillsPainter old) => false;
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
