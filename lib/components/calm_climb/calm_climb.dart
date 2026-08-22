/// Calm Climb
/// Origin: adapted — port of ClimbScreen.tsx from mortspace's FeralUI
/// calm-app screen set (React + motion). The three parallax Everest layers
/// are procedural paintings replacing the original webp photos (vault
/// forbids assets); the route, marker, fog and flurries are upstream.
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

const String _routeD =
    'M 35 844 C 60 800, 96 766, 102 742 C 108 720, 134 712, 146 698 C 158 684, 118 668, 126 654 C 134 640, 154 624, 164 610 C 174 596, 186 580, 181 566 C 176 552, 158 548, 164 537 C 172 522, 186 512, 196 500 C 220 478, 254 460, 278 443 C 268 430, 254 412, 245 400 C 238 390, 228 380, 222 375 L 208 356';

// deterministic snow flurries (upstream formula)
final List<(double, double, double, double, double, double, double)>
    _kFlurries = [
  for (int i = 0; i < 14; i++)
    (
      40 + ((i * 67) % 310).toDouble(),
      300 + ((i * 47) % 420).toDouble(),
      22 + ((i * 13) % 26).toDouble(),
      16 + ((i * 7) % 18).toDouble(),
      1 + ((i * 11) % 8) / 10,
      4.5 + ((i * 29) % 40) / 10,
      ((i * 37) % 60) / 10,
    ),
];

String _thousands(int n) {
  final String s = '$n';
  final StringBuffer b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '$b';
}

/// "Halfway up Everest": step progress drawn as a climbing route up a
/// procedural three-layer mountain with drifting fog, snow flurries and a
/// "You're here" marker. Fills whatever box it is given (designed 390x844).
class CalmClimbScreen extends StatefulWidget {
  const CalmClimbScreen({
    super.key,
    this.onNext,
    this.progress = .5,
    this.steps = 26500,
    this.goalSteps = 53000,
    this.headline = 'Halfway up Everest',
    this.caption = "That's the full height of Everest",
    this.animate = true,
  });

  final VoidCallback? onNext;

  /// How far along the route the marker sits, 0..1.
  final double progress;
  final int steps;
  final int goalSteps;
  final String headline;
  final String caption;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmClimbScreen> createState() => _CalmClimbScreenState();
}

class _CalmClimbScreenState extends State<CalmClimbScreen>
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

  Widget _blurEnter(double t, double t0, double dur, double dy,
      {required Widget child}) {
    final double e = _ease(t, t0, dur, _blurIn);
    if (e >= 1) return child;
    Widget w =
        Transform.translate(offset: Offset(0, dy * (1 - e)), child: child);
    if (e < .96) {
      w = ImageFiltered(
        imageFilter:
            ui.ImageFilter.blur(sigmaX: 5 * (1 - e), sigmaY: 5 * (1 - e)),
        child: w,
      );
    }
    return Opacity(opacity: e, child: w);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ValueListenableBuilder<double>(
        valueListenable: _t,
        builder: (context, t, _) {
          final double countE =
              _ease(t, 1.9, 1.5, Curves.easeOutCubic);
          final int steps = (widget.steps * countE).round();
          // very slow breathing zoom of the whole scene (36 s)
          final double zoom = _still
              ? 1
              : 1 + .05 * (.5 - .5 * math.cos(2 * math.pi * t / 36));
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: _ease(t, 0, .6),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1D4A86),
                        Color(0xFF2B5F9F),
                        Color(0xFF4A7CB8),
                        Color(0xFF7BA3CF),
                      ],
                      stops: [0, .34, .7, 1],
                    ),
                  ),
                ),
              ),
              // mountain + route scene
              Transform.scale(
                scale: zoom,
                alignment: Alignment.bottomCenter,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _layer(t, .7, 1.25, 30, 1.03,
                        const _MountainPainterSpec.back()),
                    _layer(t, .4, 1.15, 74, 1.045,
                        const _MountainPainterSpec.mid()),
                    _layer(t, .05, 1.0, 124, 1.06,
                        const _MountainPainterSpec.front()),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _RoutePainter(
                            t: t,
                            still: _still,
                            progress: widget.progress.clamp(0.0, 1.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // scrims
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 200,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x6B081834), Color(0x00081834)],
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 148,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x000A1932), Color(0x520A1932)],
                      ),
                    ),
                  ),
                ),
              ),
              // flurries
              if (!_still)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _FlurriesPainter(t: t)),
                  ),
                ),
              // header
              Positioned(
                top: 94,
                left: 32,
                right: 32,
                child: Column(
                  children: [
                    _blurEnter(
                      t,
                      .12,
                      .85,
                      12,
                      child: const Text(
                        'THIS WEEK',
                        style: TextStyle(
                          color: Color(0xB3F4F8FD),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _blurEnter(
                      t,
                      .26,
                      .9,
                      14,
                      child: Text(
                        widget.headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF4F8FD),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                          height: 1.16,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 14,
                              color: Color(0x66081834),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    _blurEnter(
                      t,
                      .4,
                      .85,
                      12,
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: _thousands(steps),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFC27D),
                            ),
                          ),
                          TextSpan(
                              text:
                                  ' of ${_thousands(widget.goalSteps)} steps'),
                        ]),
                        style: const TextStyle(
                          color: Color(0xEBF4F8FD),
                          fontSize: 14.4,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _blurEnter(
                      t,
                      .52,
                      .8,
                      10,
                      child: Text(
                        widget.caption,
                        style: const TextStyle(
                          color: Color(0x9EF4F8FD),
                          fontSize: 11.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
                          color: const Color(0x5710223C),
                          border: Border.all(color: const Color(0x1FFFFFFF)),
                        ),
                        child: const Icon(Icons.chevron_right_rounded,
                            size: 24, color: Color(0xFFF4F8FD)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _layer(double t, double delay, double dur, double dy,
      double scaleFrom, _MountainPainterSpec spec) {
    final double e = _ease(t, delay, dur, _blurIn);
    return Positioned.fill(
      child: Opacity(
        opacity: _ease(t, delay, dur * .45),
        child: Transform.translate(
          offset: Offset(0, dy * (1 - e)),
          child: Transform.scale(
            scale: scaleFrom + (1 - scaleFrom) * e,
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              painter: _MountainPainter(
                  spec: spec, t: _still ? 0 : t),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shape + shading recipe of one mountain layer.
class _MountainPainterSpec {
  const _MountainPainterSpec.back()
      : ridge = const [
          (0, 520), (40, 430), (90, 470), (140, 360), (185, 300),
          (215, 330), (250, 390), (300, 440), (345, 410), (390, 480),
        ],
        top = const Color(0xFFE8F0FA),
        bottom = const Color(0xFFAEC4E0),
        snow = const Color(0xF2FFFFFF),
        fogDrift = 26,
        fogY = .58,
        fogAlpha = .40;

  const _MountainPainterSpec.mid()
      : ridge = const [
          (0, 620), (50, 540), (105, 580), (160, 470), (205, 505),
          (260, 455), (310, 540), (355, 510), (390, 570),
        ],
        top = const Color(0xFF9DB8D8),
        bottom = const Color(0xFF6D8FBC),
        snow = const Color(0xE6F2F7FF),
        fogDrift = 44,
        fogY = .85,
        fogAlpha = .40;

  const _MountainPainterSpec.front()
      : ridge = const [
          (0, 760), (45, 680), (110, 720), (170, 620), (230, 660),
          (285, 600), (330, 680), (390, 640),
        ],
        top = const Color(0xFF4F74A8),
        bottom = const Color(0xFF2E5187),
        snow = const Color(0xCCE8F1FB),
        fogDrift = -38,
        fogY = .95,
        fogAlpha = .38;

  final List<(double, double)> ridge;
  final Color top, bottom, snow;
  final double fogDrift, fogY, fogAlpha;
}

class _MountainPainter extends CustomPainter {
  const _MountainPainter({required this.spec, required this.t});
  final _MountainPainterSpec spec;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 390, size.height / 844);

    final Path ridge = Path()
      ..moveTo(-6, spec.ridge.first.$2);
    for (final (double x, double y) in spec.ridge) {
      ridge.lineTo(x, y);
    }
    final Path fill = Path.from(ridge)
      ..lineTo(396, 850)
      ..lineTo(-6, 850)
      ..close();

    canvas.drawPath(
        fill,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 300),
            const Offset(0, 844),
            [spec.top, spec.bottom],
          ));

    // snow line hugging the ridge
    canvas.drawPath(
        ridge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = spec.snow.withValues(alpha: spec.snow.a * .45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawPath(
        ridge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = spec.snow);

    // drifting fog banks
    final double drift = spec.fogDrift *
        (.5 - .5 * math.cos(2 * math.pi * t / (spec.fogDrift.abs() + 4)));
    final Paint fog = Paint()
      ..color = const Color(0xFFEAF2FB).withValues(alpha: spec.fogAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    final double fy = 259 + 585 * spec.fogY;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(120 + drift, fy), width: 240, height: 30),
        fog);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(290 + drift * .7, fy + 16), width: 190, height: 24),
        fog..color = fog.color.withValues(alpha: spec.fogAlpha * .8));
  }

  @override
  bool shouldRepaint(_MountainPainter old) =>
      old.t != t || old.spec != spec;
}

/// The route, its dashed "ahead" segment, the marker and the label pill.
class _RoutePainter extends CustomPainter {
  _RoutePainter(
      {required this.t, required this.still, required this.progress});
  final double t;
  final bool still;
  final double progress;

  static final Path _route = _parseRoute();

  static Path _parseRoute() {
    final Path p = Path();
    final List<double> ns = RegExp(r'-?\d+(?:\.\d+)?')
        .allMatches(_routeD)
        .map((m) => double.parse(m.group(0)!))
        .toList();
    // M x y then 9 cubics (6 numbers each) then L x y — fixed structure
    p.moveTo(ns[0], ns[1]);
    int i = 2;
    while (i + 5 < ns.length - 2) {
      p.cubicTo(ns[i], ns[i + 1], ns[i + 2], ns[i + 3], ns[i + 4], ns[i + 5]);
      i += 6;
    }
    p.lineTo(ns[ns.length - 2], ns[ns.length - 1]);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 390, size.height / 844);
    final ui.PathMetric m = _route.computeMetrics().first;
    final double total = m.length;

    // walked part draws itself on
    final double drawE = still
        ? 1
        : const Cubic(.4, 0, .15, 1)
            .transform(((t - 1.9) / 1.5).clamp(0.0, 1.0));
    final double walked = total * progress * drawE;
    if (walked > 0) {
      final Path done = m.extractPath(0, walked);
      canvas.drawPath(
          done,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xF2FFFFFF));
      canvas.drawPath(
          done,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFFFF5F3D));
    }

    // dotted road ahead
    final double aheadE =
        _soft.transform(((t - (still ? 0 : 3.45)) / 1.4).clamp(0.0, 1.0));
    if (aheadE > 0) {
      double d = total * progress + 9;
      while (d < total) {
        final ui.Tangent? tan = m.getTangentForOffset(d);
        if (tan != null) {
          canvas.drawCircle(
              tan.position,
              2.3,
              Paint()
                ..color = Colors.white.withValues(alpha: .75 * aheadE));
          canvas.drawCircle(
              tan.position,
              1.4,
              Paint()
                ..color = const Color(0xFFFF5F3D)
                    .withValues(alpha: .55 * aheadE));
        }
        d += 9;
      }
    }

    // marker + pill
    final ui.Tangent? mark = m.getTangentForOffset(total * progress);
    if (mark == null) return;
    final Offset mp = mark.position;

    final double pulseU = ((t - 3.7) / .85).clamp(0.0, 1.0);
    if (!still && pulseU > 0 && pulseU < 1) {
      canvas.drawCircle(
          mp,
          8 + 16 * Curves.easeOut.transform(pulseU),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = const Color(0xFFFF5F3D).withValues(
                alpha: .5 *
                    (pulseU < .3 ? pulseU / .3 : 1 - (pulseU - .3) / .7)));
    }

    const Cubic popCurve = Cubic(.34, 1.45, .5, 1);
    final double dotE = still
        ? 1
        : popCurve.transform(((t - 3.4) / .45).clamp(0.0, 1.0));
    if (dotE > 0) {
      canvas.drawCircle(
          mp,
          8 * dotE,
          Paint()
            ..color = Colors.white
            ..maskFilter = null);
      canvas.drawCircle(mp, 4.8 * math.min(1, dotE),
          Paint()..color = const Color(0xFFFF5F3D));
    }

    final double pillE = still
        ? 1
        : const Cubic(.34, 1.4, .5, 1)
            .transform(((t - 3.75) / .45).clamp(0.0, 1.0));
    if (pillE > 0) {
      canvas.save();
      canvas.translate(mp.dx, mp.dy - 32 + 6 * (1 - pillE));
      canvas.scale(.92 + .08 * pillE);
      final RRect pill = RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, 0), width: 70, height: 24),
          const Radius.circular(12));
      canvas.drawRRect(
          pill.shift(const Offset(0, 1.5)),
          Paint()
            ..color = const Color(0x330A1C38)
                .withValues(alpha: .2 * pillE)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawRRect(
          pill,
          Paint()
            ..color = Colors.white.withValues(alpha: .96 * pillE));
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: "You're here",
          style: TextStyle(
            color: const Color(0xFF1C1C1E).withValues(alpha: pillE),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: -.1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.t != t || old.progress != progress;
}

class _FlurriesPainter extends CustomPainter {
  const _FlurriesPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 390, size.height / 844);
    for (final (double x, double y, double drift, double fall, double r,
            double dur, double delay)
        in _kFlurries) {
      final double u = ((t - delay) % dur) / dur;
      if (t < delay) continue;
      final double op = u < .35 ? u / .35 * .8 : .8 * (1 - (u - .35) / .65);
      canvas.drawCircle(
          Offset(x + drift * u, y + fall * u),
          r,
          Paint()
            ..color = Colors.white.withValues(alpha: op.clamp(0.0, 1.0)));
    }
  }

  @override
  bool shouldRepaint(_FlurriesPainter old) => old.t != t;
}
