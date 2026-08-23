/// Calm Mood
/// Origin: adapted — port of MoodScreen.tsx from mortspace's FeralUI
/// calm-app screen set (React + motion). The bloom silhouette (a superellipse
/// that wobbles when uneasy and grows six petals when pleasant) is the
/// upstream math verbatim; the slider spring integrator too.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Curve _soft = Cubic(.22, 1, .3, 1);
const Curve _pop = Cubic(.34, 1.2, .5, 1);

/// One stop of the 7-step mood palette ramp.
class CalmMoodStop {
  const CalmMoodStop(
      this.light, this.base, this.deep, this.pop, this.bg, this.ink);
  final Color light, base, deep, pop, bg, ink;

  static CalmMoodStop lerp(CalmMoodStop a, CalmMoodStop b, double t) =>
      CalmMoodStop(
        Color.lerp(a.light, b.light, t)!,
        Color.lerp(a.base, b.base, t)!,
        Color.lerp(a.deep, b.deep, t)!,
        Color.lerp(a.pop, b.pop, t)!,
        Color.lerp(a.bg, b.bg, t)!,
        Color.lerp(a.ink, b.ink, t)!,
      );
}

/// Upstream MOOD_STOPS: violet -> indigo -> blue -> teal -> green -> gold ->
/// orange, one per label.
const List<CalmMoodStop> kCalmMoodStops = [
  CalmMoodStop(Color(0xFFD9BAFF), Color(0xFFA873FF), Color(0xFF7C3AED),
      Color(0xFFC9A1FF), Color(0xFFECDCFF), Color(0xFF55258F)),
  CalmMoodStop(Color(0xFFB9C4FF), Color(0xFF8291FB), Color(0xFF5560EF),
      Color(0xFFA4B2FF), Color(0xFFDFE3FF), Color(0xFF3A3F99)),
  CalmMoodStop(Color(0xFFA8E0FF), Color(0xFF6CBCF5), Color(0xFF3A8DE0),
      Color(0xFF8FD0FF), Color(0xFFD9EDFC), Color(0xFF245A8C)),
  CalmMoodStop(Color(0xFFC8F0EC), Color(0xFF92D5CF), Color(0xFF5CB3AE),
      Color(0xFFAEE5DB), Color(0xFFE2F2F0), Color(0xFF35625E)),
  CalmMoodStop(Color(0xFFD8F58A), Color(0xFFA8E04E), Color(0xFF74C122),
      Color(0xFFC4EC70), Color(0xFFE6F2C6), Color(0xFF43641A)),
  CalmMoodStop(Color(0xFFFFE27A), Color(0xFFFFCB3D), Color(0xFFF5A814),
      Color(0xFFFFDA6B), Color(0xFFFDEDBD), Color(0xFF7A5605)),
  CalmMoodStop(Color(0xFFFFC48A), Color(0xFFFF9D4D), Color(0xFFF97316),
      Color(0xFFFFB877), Color(0xFFFFE3C2), Color(0xFF8C3F0A)),
];

const List<String> kCalmMoodLabels = [
  'Very Unpleasant',
  'Unpleasant',
  'Slightly Unpleasant',
  'Neutral',
  'Slightly Pleasant',
  'Pleasant',
  'Very Pleasant',
];

CalmMoodStop calmMoodColorAt(double t, [List<CalmMoodStop>? stops]) {
  final List<CalmMoodStop> s = stops ?? kCalmMoodStops;
  final double x = t.clamp(0.0, 1.0) * (s.length - 1);
  final int i = math.min(s.length - 2, x.floor());
  return CalmMoodStop.lerp(s[i], s[i + 1], x - i);
}

/// The bloom silhouette: pure superellipse-ish disc at neutral, lobed wobble
/// when uneasy, a six-petal flower when pleasant. Upstream math verbatim.
Path calmMoodBloomPath(double t, double radius) {
  final double pleasant = math.max(0.0, t * 2 - 1);
  final double uneasy = math.max(0.0, 1 - t * 2);
  const int n = 144;
  const double step = math.pi * 2 / 6;
  final double petalDist = .5 * math.pow(pleasant, .9).toDouble();
  final double petalR = 1 - petalDist;
  final double wobbleAmp = .095 * math.pow(uneasy, 1.1).toDouble();
  final List<Offset> pts = List.generate(n, (i) {
    final double a = (i / n) * math.pi * 2 - math.pi / 2;
    final double aa = a + math.pi / 2;
    final double squircle = .02 * math.cos(4 * aa);
    final double m = ((aa % step) + step) % step;
    final double phi = math.min(m, step - m);
    final double flower = petalDist * math.cos(phi) +
        math.sqrt(math.max(
            0,
            petalR * petalR -
                petalDist * petalDist * math.sin(phi) * math.sin(phi)));
    final double lobe = (math.cos(8 * aa) + 1) / 2;
    final double wobble =
        wobbleAmp * (math.pow(lobe, 1.15).toDouble() * 2 - 1);
    final double r = radius * (flower + wobble + squircle);
    return Offset(math.cos(a) * r, math.sin(a) * r);
  });
  final Path d = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (int i = 0; i < n; i++) {
    final Offset p0 = pts[(i + n - 1) % n];
    final Offset p1 = pts[i];
    final Offset p2 = pts[(i + 1) % n];
    final Offset p3 = pts[(i + 2) % n];
    d.cubicTo(
      p1.dx + (p2.dx - p0.dx) / 6,
      p1.dy + (p2.dy - p0.dy) / 6,
      p2.dx - (p3.dx - p1.dx) / 6,
      p2.dy - (p3.dy - p1.dy) / 6,
      p2.dx,
      p2.dy,
    );
  }
  return d..close();
}

/// "Choose how you're feeling" check-in: a glassy bloom morphs and re-tints
/// the whole screen as a springy slider sweeps seven moods. Fills whatever
/// box it is given (designed at 390x844).
class CalmMoodScreen extends StatefulWidget {
  const CalmMoodScreen({
    super.key,
    this.onNext,
    this.onChanged,
    this.initialValue = .5,
    this.title = "Choose how you're\nfeeling right now",
    this.animate = true,
  });

  final VoidCallback? onNext;

  /// Reports the snapped 0..1 value when a drag ends.
  final ValueChanged<double>? onChanged;

  /// Starting slider position, 0..1 (0.5 = Neutral).
  final double initialValue;
  final String title;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmMoodScreen> createState() => _CalmMoodScreenState();
}

class _CalmMoodScreenState extends State<CalmMoodScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  double _last = 0;

  late double _target = widget.initialValue.clamp(0.0, 1.0);
  late double _shown = _target;
  double _vel = 0;
  bool _dragging = false;

  bool get _still =>
      !widget.animate || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) {
      final double now = e.inMicroseconds / 1e6;
      final double dt = math.min(.04, now - _last);
      _last = now;
      // critically damped spring toward the target (upstream k = 190)
      const double k = 190;
      _vel += (k * (_target - _shown) - 2 * math.sqrt(k) * _vel) * dt;
      _shown += _vel * dt;
      if ((_target - _shown).abs() < .0005 && _vel.abs() < .005) {
        _shown = _target;
        _vel = 0;
      }
      _t.value = now;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _ticker.stop();
      _shown = _target;
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

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ValueListenableBuilder<double>(
        valueListenable: _t,
        builder: (context, t, _) {
          final CalmMoodStop c = calmMoodColorAt(_shown);
          final int labelIdx = (_target * 6).round().clamp(0, 6);
          final double lagDiff = _target - _shown;
          final double lag = .22 * (1 - math.exp(-lagDiff.abs() * 5));
          return Stack(
            fit: StackFit.expand,
            children: [
              // re-tinting backdrop
              Opacity(
                opacity: _ease(t, 0, .6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -.12),
                      radius: 1,
                      colors: [
                        Color.lerp(Colors.white, c.light, .46)!,
                        c.bg,
                      ],
                      stops: const [0, .74],
                    ),
                  ),
                ),
              ),
              // grabber pill
              Positioned(
                top: 46,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _ease(t, .3, .5),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: c.ink.withValues(alpha: .28),
                      ),
                    ),
                  ),
                ),
              ),
              // next
              Positioned(
                top: 58,
                right: 16,
                child: _NextButton(
                    t: _ease(t, .5, .45), color: c.deep, onTap: widget.onNext),
              ),
              Column(
                children: [
                  const SizedBox(height: 100),
                  Opacity(
                    opacity: _ease(t, .16, .55),
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - _ease(t, .16, .55))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: c.ink,
                            fontSize: 22.7,
                            fontWeight: FontWeight.w800,
                            height: 1.26,
                            letterSpacing: -.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _bloomStage(t, c),
                    ),
                  ),
                  _panel(t, c, labelIdx, lag, lagDiff),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bloomStage(double t, CalmMoodStop c) {
    final double bloomIn = _ease(t, .26, .9, _pop);
    final double breathe =
        _still ? 0 : .5 - .5 * math.cos(2 * math.pi * t / 5.2);
    final double spin = _still ? 0 : 2 * math.pi * (t / 110);
    final double pulse =
        _still ? 1 : .75 + .25 * (.5 - .5 * math.cos(2 * math.pi * t / 9.2));
    return Opacity(
      opacity: bloomIn.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: .62 + .38 * bloomIn,
        child: SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // halo
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.lerp(Colors.white, c.light, .55)!
                          .withValues(alpha: .9),
                      c.pop.withValues(alpha: .26),
                      c.pop.withValues(alpha: 0),
                    ],
                    stops: const [0, .46, .68],
                  ),
                ),
              ),
              // floating bokeh dots
              for (final (double bx, double by, double sz, double dur,
                      double ph, Color col)
                  in [
                (.16, .18, 16.0, 7.0, 0.0, c.light),
                (.74, .30, 11.0, 8.5, 2.6, c.pop),
                (.24, .78, 8.0, 6.0, 5.0, c.base),
              ])
                Positioned(
                  left: 280 * bx +
                      7 * (.5 - .5 * math.cos(2 * math.pi * (t + ph) / dur)),
                  top: 280 * by -
                      12 * (.5 - .5 * math.cos(2 * math.pi * (t + ph) / dur)),
                  child: Container(
                    width: sz,
                    height: sz,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        col.withValues(alpha: .45),
                        col.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                ),
              Transform.rotate(
                angle: spin,
                child: Transform.scale(
                  scale: 1 + .04 * breathe,
                  child: CustomPaint(
                    size: const Size(236, 236),
                    painter: _BloomPainter(
                        shown: _shown, colors: c, pulse: pulse),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(
      double t, CalmMoodStop c, int labelIdx, double lag, double lagDiff) {
    final double e = _ease(t, .4, .6);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - e)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 42,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  child: Text(
                    kCalmMoodLabels[labelIdx],
                    key: ValueKey<int>(labelIdx),
                    style: TextStyle(
                      color: c.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, box) {
                final double trackW = box.maxWidth;
                final double thumbX =
                    (_dragging ? _target : _shown) * math.max(0, trackW - 32);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (d) {
                    _dragging = true;
                    _setFromX(d.localPosition.dx, trackW);
                  },
                  onHorizontalDragUpdate: (d) =>
                      _setFromX(d.localPosition.dx, trackW),
                  onHorizontalDragEnd: (_) => _release(),
                  onTapDown: (d) {
                    _dragging = true;
                    _setFromX(d.localPosition.dx, trackW);
                  },
                  onTapUp: (_) => _release(),
                  child: SizedBox(
                    height: 32,
                    child: Stack(
                      children: [
                        // inset track
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: c.ink.withValues(alpha: .1),
                              border: Border.all(
                                  color: c.ink.withValues(alpha: .08)),
                            ),
                          ),
                        ),
                        // fill up to the thumb
                        Positioned(
                          left: 2,
                          top: 2,
                          bottom: 2,
                          width: math.max(0, thumbX + 28),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.lerp(c.base, c.light, .42)!,
                                  c.base,
                                  Color.lerp(c.base, c.deep, .45)!,
                                ],
                                stops: const [0, .52, 1],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                  color: c.deep.withValues(alpha: .15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // squashy thumb
                        Positioned(
                          left: 2 + thumbX,
                          top: 2,
                          width: 28,
                          height: 28,
                          child: Transform.scale(
                            scaleX: 1 + lag,
                            scaleY: 1 - lag * .45,
                            alignment: lag < .015
                                ? Alignment.center
                                : (lagDiff > 0
                                    ? const Alignment(.56, 0)
                                    : const Alignment(-.56, 0)),
                            child: AnimatedScale(
                              scale: _dragging ? 1.18 : 1,
                              duration: const Duration(milliseconds: 280),
                              curve: const Cubic(.34, 1.56, .64, 1),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    center: Alignment(-.24, -.4),
                                    colors: [
                                      Colors.white,
                                      Color(0xFFF7F7FA),
                                      Color(0xFFEBEBF1),
                                    ],
                                    stops: [0, .55, 1],
                                  ),
                                  boxShadow: [
                                    const BoxShadow(
                                      offset: Offset(0, 4),
                                      blurRadius: 10,
                                      color: Color(0x38141E1E),
                                    ),
                                    if (_dragging)
                                      BoxShadow(
                                        offset: const Offset(0, 5),
                                        blurRadius: 14,
                                        color:
                                            c.pop.withValues(alpha: .42),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 11),
              DefaultTextStyle(
                style: TextStyle(
                  color: c.ink.withValues(alpha: .78),
                  fontSize: 9.9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('VERY UNPLEASANT'),
                    Text('VERY PLEASANT'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setFromX(double x, double trackW) {
    const double inset = 16;
    setState(() =>
        _target = ((x - inset) / (trackW - inset * 2)).clamp(0.0, 1.0));
    if (_still) _shown = _target;
  }

  void _release() {
    setState(() {
      _dragging = false;
      _target = (_target * 6).roundToDouble() / 6;
    });
    if (_still) _shown = _target;
    widget.onChanged?.call(_target);
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.t, required this.color, this.onTap});
  final double t;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: .8 + .2 * t,
        child: GestureDetector(
          onTap: onTap,
          child: _CssShadow(
            radius: 18,
            shadowOffset: const Offset(0, 4),
            blur: 14,
            spread: -6,
            color: const Color(0x4D1E1E28),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .42),
                ),
                child:
                    Icon(Icons.chevron_right_rounded, size: 24, color: color),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

/// Paints the layered glass bloom in a 236x236 box (design space
/// -130..130 like the upstream viewBox).
class _BloomPainter extends CustomPainter {
  const _BloomPainter(
      {required this.shown, required this.colors, required this.pulse});
  final double shown;
  final CalmMoodStop colors;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 260;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);
    final CalmMoodStop c = colors;

    // pulsing glow blobs behind everything
    canvas.drawPath(
        calmMoodBloomPath(shown, 84),
        Paint()
          ..color = c.pop.withValues(alpha: .42 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.drawPath(
        calmMoodBloomPath(shown, 66),
        Paint()
          ..color = c.base.withValues(alpha: .5 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    void disc(double r, List<Color> cols, List<double> stops,
        double strokeOp, double strokeW) {
      final Path p = calmMoodBloomPath(shown, r);
      canvas.drawPath(
          p,
          Paint()
            ..shader = ui.Gradient.radial(
                Offset(-.16 * r, -.32 * r), r * 1.65, cols, stops));
      canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..color = Colors.white.withValues(alpha: strokeOp));
    }

    // translucent outer discs
    disc(
        100,
        [
          Colors.white.withValues(alpha: .6),
          Colors.white.withValues(alpha: .26),
          c.light.withValues(alpha: .2),
        ],
        [0, .7, 1],
        .85,
        1.1);
    disc(
        78,
        [
          Colors.white.withValues(alpha: .78),
          Colors.white.withValues(alpha: .42),
          c.light.withValues(alpha: .3),
        ],
        [0, .72, 1],
        .9,
        1);
    disc(
        56,
        [
          c.light.withValues(alpha: .95),
          c.base.withValues(alpha: .88),
          c.deep.withValues(alpha: .8),
        ],
        [0, .62, 1],
        .75,
        1);

    // core
    final Path core = calmMoodBloomPath(shown, 34);
    canvas.drawPath(
        core,
        Paint()
          ..shader = ui.Gradient.radial(const Offset(-6, -11), 58, [
            Colors.white.withValues(alpha: .96),
            c.light,
            c.base,
            c.deep,
          ], const [
            0,
            .38,
            .78,
            1,
          ]));
    // bottom shade + top sheen
    canvas.drawPath(
        core,
        Paint()
          ..shader = ui.Gradient.linear(
              const Offset(0, -12), const Offset(0, 34), [
            c.deep.withValues(alpha: 0),
            c.deep.withValues(alpha: .32),
          ]));
    canvas.drawPath(
        core,
        Paint()
          ..shader = ui.Gradient.linear(
              const Offset(0, -34), const Offset(9, 34), [
            Colors.white.withValues(alpha: .55),
            Colors.white.withValues(alpha: 0),
          ], const [
            0,
            .45,
          ]));
    // specular glints
    canvas.save();
    canvas.translate(-13, -17);
    canvas.rotate(-24 * math.pi / 180);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 32, height: 18),
        Paint()
          ..color = Colors.white.withValues(alpha: .5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.restore();
    canvas.drawCircle(
        const Offset(-9, -15),
        5,
        Paint()
          ..color = Colors.white.withValues(alpha: .75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    // rims
    canvas.drawPath(
        core,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..shader = ui.Gradient.linear(
              const Offset(0, -34), const Offset(14, 34), [
            Colors.white.withValues(alpha: .9),
            Colors.white.withValues(alpha: 0),
          ], const [
            0,
            .55,
          ]));
    canvas.drawPath(
        core,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..shader = ui.Gradient.linear(
              const Offset(0, 34), const Offset(0, -3), [
            Colors.white.withValues(alpha: .35),
            Colors.white.withValues(alpha: 0),
          ]));
    // centre dot
    canvas.drawPath(
        calmMoodBloomPath(shown, 6.5),
        Paint()
          ..shader = ui.Gradient.radial(const Offset(-1.5, -2.5), 11, [
            Colors.white,
            Colors.white.withValues(alpha: .98),
            c.light,
          ], const [
            0,
            .7,
            1,
          ]));
  }

  @override
  bool shouldRepaint(_BloomPainter old) =>
      old.shown != shown || old.colors != colors || old.pulse != pulse;
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
