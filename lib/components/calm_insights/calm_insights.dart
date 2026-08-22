/// Calm Insights
/// Origin: adapted — port of InsightsScreen.tsx from mortspace's
/// FeralUI calm-app screen set (React + motion): the weekly mood curve with
/// a ghost of the other week, springy segmented/day pickers and takeaways.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Curve _soft = Cubic(.22, 1, .3, 1);

const List<String> _kMoodLabels = [
  'Very Unpleasant',
  'Unpleasant',
  'Slightly Unpleasant',
  'Neutral',
  'Slightly Pleasant',
  'Pleasant',
  'Very Pleasant',
];

const List<String> _kDayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const double _kCurveW = 272;
const double _kCurveH = 118;

const Color _ink = Color(0xFF79404E);
const Color _rose = Color(0xFFE5637F);
const Color _roseDeep = Color(0xFFC2405C);

List<Offset> _curvePoints(List<double> vals) => [
      for (int i = 0; i < 7; i++)
        Offset(10 + i * (_kCurveW - 20) / 6,
            _kCurveH - 14 - (vals[i] / 6) * (_kCurveH - 34)),
    ];

Path _curvePath(List<double> vals, {required bool area}) {
  final List<Offset> pts = _curvePoints(vals);
  final Path d = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (int i = 0; i < pts.length - 1; i++) {
    final Offset p0 = pts[i == 0 ? 0 : i - 1];
    final Offset p1 = pts[i];
    final Offset p2 = pts[i + 1];
    final Offset p3 = pts[i + 2 > 6 ? 6 : i + 2];
    d.cubicTo(
      p1.dx + (p2.dx - p0.dx) / 6,
      p1.dy + (p2.dy - p0.dy) / 6,
      p2.dx - (p3.dx - p1.dx) / 6,
      p2.dy - (p3.dy - p1.dy) / 6,
      p2.dx,
      p2.dy,
    );
  }
  if (area) {
    d
      ..lineTo(pts[6].dx, _kCurveH)
      ..lineTo(pts[0].dx, _kCurveH)
      ..close();
  }
  return d;
}

/// One selectable week of the insights screen.
class CalmInsightsWeek {
  const CalmInsightsWeek({
    required this.label,
    required this.headline,
    required this.moods,
    required this.takeaways,
  });

  final String label;
  final String headline;

  /// Seven mood indices 0..6 (Monday..Sunday).
  final List<int> moods;

  /// Two lines shown in the takeaway list.
  final List<String> takeaways;
}

const List<CalmInsightsWeek> kCalmInsightsDefaultWeeks = [
  CalmInsightsWeek(
    label: 'This week',
    headline: 'a brighter week.',
    moods: [3, 4, 2, 3, 5, 6, 5],
    takeaways: [
      'Your week lifted toward the weekend',
      'Saturday was your brightest day',
    ],
  ),
  CalmInsightsWeek(
    label: 'Last week',
    headline: 'a steadier week.',
    moods: [2, 3, 3, 4, 4, 5, 3],
    takeaways: [
      'A steady, gentle week overall',
      'Friday was your brightest day',
    ],
  ),
];

/// Weekly mood insights: the curve morphs between weeks, the other week
/// ghosts behind it, days are tappable and two takeaways slide in. Fills
/// whatever box it is given (designed at 390x844).
class CalmInsightsScreen extends StatefulWidget {
  const CalmInsightsScreen({
    super.key,
    this.onNext,
    this.weeks = kCalmInsightsDefaultWeeks,
    this.initialDay = 5,
    this.animate = true,
  });

  final VoidCallback? onNext;
  final List<CalmInsightsWeek> weeks;
  final int initialDay;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmInsightsScreen> createState() => _CalmInsightsScreenState();
}

class _CalmInsightsScreenState extends State<CalmInsightsScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  int _week = 0;
  late int _sel = widget.initialDay.clamp(0, 6);
  late List<double> _fromVals =
      widget.weeks[0].moods.map((m) => m.toDouble()).toList();
  double _tSwitch = -99;

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

  List<double> _shownVals(double t) {
    final List<double> target =
        widget.weeks[_week].moods.map((m) => m.toDouble()).toList();
    final double e = _ease(t, _tSwitch, .55);
    if (e >= 1) return target;
    return [
      for (int i = 0; i < 7; i++)
        _fromVals[i] + (target[i] - _fromVals[i]) * e,
    ];
  }

  void _switchWeek(int w) {
    if (w == _week) return;
    _fromVals = _shownVals(_t.value);
    _tSwitch = _t.value;
    setState(() => _week = w);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ValueListenableBuilder<double>(
        valueListenable: _t,
        builder: (context, t, _) {
          final CalmInsightsWeek wk = widget.weeks[_week];
          final int avg =
              (wk.moods.reduce((a, b) => a + b) / 7).round().clamp(0, 6);
          final List<double> vals = _shownVals(t);
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: _ease(t, 0, .6),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -.64),
                      radius: 1.25,
                      colors: [Color(0xFFFDF6F1), Color(0xFFF7E8E1)],
                      stops: [0, .72],
                    ),
                  ),
                ),
              ),
              const _BgBlob(
                  alignment: Alignment(-.9, -.86), color: Color(0x4DFF9AB2)),
              const _BgBlob(
                  alignment: Alignment(.92, -.4), color: Color(0x6BFFC7BE)),
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
                          filter:
                              ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: .42),
                            ),
                            child: const Icon(Icons.chevron_right_rounded,
                                size: 24, color: _roseDeep),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 96),
                  Opacity(
                    opacity: _ease(t, .16, .55),
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - _ease(t, .16, .55))),
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: _soft,
                            child: Text(
                              wk.headline,
                              key: ValueKey<int>(_week),
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 27.8,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                letterSpacing: -.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Opacity(
                            opacity: _ease(t, .26, .5),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                '${_kMoodLabels[avg]} on average',
                                key: ValueKey<int>(_week),
                                style: TextStyle(
                                  color: _ink.withValues(alpha: .68),
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    // clip quietly instead of overflowing on short screens
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                      child: Column(
                        children: [
                          _segmented(t),
                          const SizedBox(height: 12),
                          _card(t, vals),
                          const SizedBox(height: 12),
                          _takeaways(t, wk),
                        ],
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

  Widget _segmented(double t) {
    final double e = _ease(t, .24, .5);
    return Opacity(
      opacity: _ease(t, .24, .25),
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - e)),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: _ink.withValues(alpha: .09),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 2; i++)
                GestureDetector(
                  onTap: () => _switchWeek(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: _soft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: _week == i
                          ? Colors.white.withValues(alpha: .92)
                          : Colors.transparent,
                      boxShadow: _week == i
                          ? [
                              BoxShadow(
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                                color: _ink.withValues(alpha: .18),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      widget.weeks[i].label,
                      style: TextStyle(
                        color: _week == i
                            ? _ink
                            : _ink.withValues(alpha: .6),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
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

  Widget _card(double t, List<double> vals) {
    final double e = _ease(t, .32, .6);
    final List<int> moods = widget.weeks[_week].moods;
    return Opacity(
      opacity: _ease(t, .32, .3),
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - e)),
        child: Transform.scale(
          scale: .97 + .03 * e,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x8CFFFFFF), Color(0x4DFFFFFF)],
                  ),
                  border: Border.all(color: const Color(0x47FFFFFF)),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 16),
                      blurRadius: 32,
                      spreadRadius: -24,
                      color: _ink.withValues(alpha: .55),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 22,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: _soft,
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: _kDayNames[_sel],
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD14E6D),
                              ),
                            ),
                            TextSpan(
                                text:
                                    '  ·  ${_kMoodLabels[moods[_sel]]}'),
                          ]),
                          key: ValueKey<String>('$_week-$_sel'),
                          style: TextStyle(
                            color: _ink.withValues(alpha: .82),
                            fontSize: 12.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: _kCurveW / _kCurveH,
                      child: CustomPaint(
                        painter: _CurvePainter(
                          t: t,
                          vals: vals,
                          ghost: widget.weeks[1 - _week].moods
                              .map((m) => m.toDouble())
                              .toList(),
                          sel: _sel,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 0; i < 7; i++)
                          GestureDetector(
                            onTap: () => setState(() => _sel = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: _soft,
                              width: 28,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: _sel == i
                                    ? _rose.withValues(alpha: .15)
                                    : Colors.transparent,
                              ),
                              child: Text(
                                'MTWTFSS'[i],
                                style: TextStyle(
                                  color: _sel == i
                                      ? _roseDeep
                                      : _ink.withValues(alpha: .5),
                                  fontSize: 9.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _takeaways(double t, CalmInsightsWeek wk) {
    final double e = _ease(t, 1.05, .55);
    return Opacity(
      opacity: _ease(t, 1.05, .3),
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - e)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x7AFFFFFF), Color(0x42FFFFFF)],
            ),
            border: Border.all(color: const Color(0x40FFFFFF)),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 12),
                blurRadius: 26,
                spreadRadius: -22,
                color: _ink.withValues(alpha: .55),
              ),
            ],
          ),
          child: Column(
            children: [
              _row(Icons.trending_up_rounded,
                  const [Color(0xFFFF8AA4), Color(0xFFE5637F)], wk.takeaways[0], 0),
              _row(Icons.military_tech_rounded,
                  const [Color(0xFFFFCF67), Color(0xFFF5A814)], wk.takeaways[1], 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, List<Color> grad, String text, int i) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: grad,
              ),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 3),
                  blurRadius: 8,
                  spreadRadius: -3,
                  color: grad.last.withValues(alpha: .7),
                ),
              ],
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: _soft,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                          begin: const Offset(.04, 0), end: Offset.zero)
                      .animate(a),
                  child: child,
                ),
              ),
              child: Text(
                text,
                key: ValueKey<String>(text),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BgBlob extends StatelessWidget {
  const _BgBlob({required this.alignment, required this.color});
  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// The mood curve plot in the upstream 272x118 space: ghost week (dotted),
/// area fill, the animated main line and the seven day dots.
class _CurvePainter extends CustomPainter {
  const _CurvePainter({
    required this.t,
    required this.vals,
    required this.ghost,
    required this.sel,
  });

  final double t;
  final List<double> vals;
  final List<double> ghost;
  final int sel;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _kCurveW, size.height / _kCurveH);

    // ghost of the other week — dotted
    final double ghostE =
        _soft.transform(((t - .9) / .5).clamp(0.0, 1.0));
    if (ghostE > 0) {
      final Path gp = _curvePath(ghost, area: false);
      final Paint dp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF79404E)
            .withValues(alpha: .25 * ghostE);
      for (final ui.PathMetric m in gp.computeMetrics()) {
        double d = 0;
        while (d < m.length) {
          final ui.Tangent? tan = m.getTangentForOffset(d);
          if (tan != null) canvas.drawCircle(tan.position, 1, dp);
          d += 7;
        }
      }
    }

    // area fill
    final double areaE =
        _soft.transform(((t - .75) / .55).clamp(0.0, 1.0));
    if (areaE > 0) {
      canvas.drawPath(
          _curvePath(vals, area: true),
          Paint()
            ..shader = ui.Gradient.linear(
                const Offset(0, 0), const Offset(0, _kCurveH), [
              const Color(0xFFFF8AA4).withValues(alpha: .42 * areaE),
              const Color(0xFFFF8AA4).withValues(alpha: .03 * areaE),
            ]));
    }

    // main line draws itself on
    final double lineE = const Cubic(.6, 0, .2, 1)
        .transform(((t - .5) / .9).clamp(0.0, 1.0));
    if (lineE > 0) {
      final Path lp = _curvePath(vals, area: false);
      final ui.PathMetric m = lp.computeMetrics().first;
      canvas.drawPath(
          m.extractPath(0, m.length * lineE),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round
            ..color = _rose);
    }

    // day dots
    final List<Offset> pts = _curvePoints(vals);
    for (int i = 0; i < 7; i++) {
      final double dotE =
          ((t - (.75 + i * .05)) / .3).clamp(0.0, 1.0);
      if (dotE <= 0) continue;
      if (sel == i) {
        canvas.drawCircle(
            pts[i],
            5,
            Paint()
              ..color =
                  Colors.white.withValues(alpha: dotE));
        canvas.drawCircle(
            pts[i],
            5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = _rose.withValues(alpha: dotE));
      } else {
        canvas.drawCircle(pts[i], 3,
            Paint()..color = _rose.withValues(alpha: dotE));
      }
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.t != t || old.sel != sel || old.vals != vals;
}
