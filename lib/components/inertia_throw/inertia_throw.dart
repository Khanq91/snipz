/// InertiaThrow
/// Origin: reimplemented — GSAP InertiaPlugin (v3.15),
///   https://github.com/greensock/GSAP/blob/master/src/InertiaPlugin.js —
///   mô hình momentum nghiệm đóng (duration = |v|/resistance, điểm đáp tự
///   nhiên qua hằng số power3 0.18549, soft-bounds bậc hai, linked 2D snap
///   trong bán kính) dựng lại; widget bảng ném là original.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// GSAP's inertia constants: power3.out has consumed ~18.549% of its travel
/// at 5% of its time — solving that against the release velocity gives the
/// natural landing point in closed form. No physics loop; every frame is
/// `start + c1·e(r) + c2·e(r)²`, so flights are scrubbable and reversible.
const double _checkPoint = 0.05;
const double _checkPointRatio = 0.18549375; // 1 - 0.95^4

double _easeOutPower3(double r) {
  final double q = 1 - r;
  return 1 - q * q * q * q;
}

/// One axis of a momentum flight (GSAP InertiaPlugin math).
class InertiaAxis {
  const InertiaAxis({
    required this.start,
    required this.c1,
    required this.c2,
  });

  final double start;

  /// Travel toward the (possibly snapped) end.
  final double c1;

  /// Soft-bounds correction: overshoots past the wall, quadratic term pulls
  /// back so ratio 1 lands exactly on it. 0 when unbounded.
  final double c2;

  double at(double ratio) {
    final double e = _easeOutPower3(ratio.clamp(0.0, 1.0));
    return start + c1 * e + c2 * e * e;
  }

  double get end => start + c1 + c2;
}

/// A solved 2D flight: duration + both axes. Built once on release.
class InertiaFlight {
  InertiaFlight._(this.duration, this.x, this.y, this.tilt);

  final double duration;
  final InertiaAxis x;
  final InertiaAxis y;

  /// Small launch tilt (rad) from the horizontal throw speed, decaying to 0.
  final double tilt;

  Offset positionAt(double elapsed) {
    final double r = duration <= 0 ? 1 : (elapsed / duration).clamp(0.0, 1.0);
    return Offset(x.at(r), y.at(r));
  }

  double tiltAt(double elapsed) {
    final double r = duration <= 0 ? 1 : (elapsed / duration).clamp(0.0, 1.0);
    return tilt * (1 - _easeOutPower3(r));
  }

  bool isDone(double elapsed) => elapsed >= duration;

  /// Solves a flight the way GSAP does:
  /// 1. `duration = clamp(|v| / resistance)` per axis, take the longer;
  /// 2. natural end = `start + duration · 0.05 · v / 0.18549`;
  /// 3. linked 2D snap: nearest of [snapPoints] to the natural END pair, but
  ///    only within [snapRadius] (off-grid landings stay off-grid);
  /// 4. walls: `c2 = (wall - start) - c1` gives the built-in soft bounce.
  factory InertiaFlight.solve({
    required Offset start,
    required Offset velocity,
    required Rect bounds,
    List<Offset> snapPoints = const <Offset>[],
    double snapRadius = 64,
    double resistance = 400,
    double minDuration = 0.3,
    double maxDuration = 2.5,
  }) {
    final double vx = velocity.dx.clamp(-4000.0, 4000.0);
    final double vy = velocity.dy.clamp(-4000.0, 4000.0);
    double duration = math.max(
      (vx.abs() / resistance).clamp(minDuration, maxDuration),
      (vy.abs() / resistance).clamp(minDuration, maxDuration),
    );

    final double nx = start.dx + duration * _checkPoint * vx / _checkPointRatio;
    final double ny = start.dy + duration * _checkPoint * vy / _checkPointRatio;

    // Linked-props snap: judge the PAIR so diagonals land on-grid.
    double ex = nx, ey = ny;
    if (snapPoints.isNotEmpty) {
      Offset best = snapPoints.first;
      double bestD = double.infinity;
      for (final Offset p in snapPoints) {
        final double d =
            (p.dx - nx) * (p.dx - nx) + (p.dy - ny) * (p.dy - ny);
        if (d < bestD) {
          bestD = d;
          best = p;
        }
      }
      if (math.sqrt(bestD) <= snapRadius) {
        ex = best.dx;
        ey = best.dy;
      }
    }

    // Barely moving toward a changed target: quick settle (GSAP's
    // "snapping should feel quick" clamp).
    final double speed = math.sqrt(vx * vx + vy * vy);
    if (speed < 45 && (ex != nx || ey != ny || _outside(nx, ny, bounds))) {
      duration = minDuration + (maxDuration - minDuration) * 0.1;
    }

    (double, double) axis(double s, double e, double lo, double hi) {
      if (e > hi) return (e - s, hi - e); // c1 keeps momentum, c2 pulls back
      if (e < lo) return (e - s, lo - e);
      return (e - s, 0);
    }

    final (double c1x, double c2x) = axis(start.dx, ex, bounds.left, bounds.right);
    final (double c1y, double c2y) = axis(start.dy, ey, bounds.top, bounds.bottom);
    if (c2x != 0 || c2y != 0) {
      duration = math.min(maxDuration, duration + 0.35); // room for the bounce
    }

    return InertiaFlight._(
      duration,
      InertiaAxis(start: start.dx, c1: c1x, c2: c2x),
      InertiaAxis(start: start.dy, c1: c1y, c2: c2y),
      (vx / 4000).clamp(-1.0, 1.0) * 0.14,
    );
  }

  static bool _outside(double x, double y, Rect b) =>
      x < b.left || x > b.right || y < b.top || y > b.bottom;
}

/// A pegboard of flickable cards. Throw one: it keeps your release velocity,
/// coasts along the GSAP inertia curve, snaps into the nearest peg **only**
/// when its natural landing falls within [snapRadius], and bounces softly
/// off the walls. Idle boards throw a card themselves every few seconds
/// ([autoDemo]) so the gallery preview shows the motion.
class InertiaThrow extends StatefulWidget {
  const InertiaThrow({
    super.key,
    this.cardColors = const <Color>[
      Color(0xFF8B7CFF),
      Color(0xFFFF8A65),
      Color(0xFF4DD0A6),
    ],
    this.cardSize = 64,
    this.cellExtent = 88,
    this.snapRadius = 64,
    this.resistance = 400,
    this.minDuration = 0.3,
    this.maxDuration = 2.5,
    this.showGrid = true,
    this.autoDemo = true,
    this.onLanded,
    this.animate = true,
    this.frozenAt,
  }) : assert(cardSize > 0),
       assert(cellExtent >= cardSize),
       assert(snapRadius >= 0),
       assert(resistance > 0),
       assert(minDuration > 0 && maxDuration >= minDuration);

  /// One card per color.
  final List<Color> cardColors;

  final double cardSize;

  /// Peg pitch — the board derives its snap grid from this.
  final double cellExtent;

  /// Max distance (px) between the natural landing and a peg for the flight
  /// to bend onto it. Off-grid throws stay off-grid, like GSAP `radius`.
  final double snapRadius;

  /// px/s of velocity per second of flight (GSAP `resistance`; default here
  /// is mobile-tuned — GSAP's web default is 100).
  final double resistance;

  final double minDuration;
  final double maxDuration;

  final bool showGrid;

  /// Scripted deterministic throws until the user first touches the board
  /// (keeps the gallery preview alive; hands off for good on interaction).
  final bool autoDemo;

  /// Fired when a card settles; [pegIndex] is -1 for off-grid landings.
  final void Function(int cardIndex, int pegIndex)? onLanded;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker (auto-demo script replayed up to t). Useful for thumbnails
  /// and golden tests.
  final double? frozenAt;

  @override
  State<InertiaThrow> createState() => _InertiaThrowState();
}

class _Card {
  _Card(this.rest);

  Offset rest;
  InertiaFlight? flight;
  double flightStart = 0;
  bool dragging = false;
}

class _InertiaThrowState extends State<InertiaThrow>
    with SingleTickerProviderStateMixin {
  // Deterministic auto-demo script: (interval-index → card round-robin,
  // velocity from this table). Speeds chosen to mix on-grid and wall shots.
  static const double _demoFirstAt = 1.1;
  static const double _demoEvery = 3.4;
  static const List<Offset> _demoVelocities = <Offset>[
    Offset(2300, -400),
    Offset(-1500, 1900),
    Offset(900, 2600),
    Offset(-2800, -700),
    Offset(1800, 1400),
  ];

  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Duration? _lastTick;
  double _elapsedSeconds = 0;

  Size _board = Size.zero;
  List<Offset> _pegs = const <Offset>[];
  Rect _bounds = Rect.zero;
  List<_Card> _cards = <_Card>[];
  int _demoFired = 0;
  bool _touched = false;
  int? _draggedIndex;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
  }

  void _handleTick(Duration elapsed) {
    final Duration previous = _lastTick ?? Duration.zero;
    _lastTick = elapsed;
    final double delta = ((elapsed - previous).inMicroseconds / 1000000)
        .clamp(0.0, 0.064)
        .toDouble();
    _elapsedSeconds += delta;
    _maybeAutoThrow(_elapsedSeconds);
    _settleFinished(_elapsedSeconds);
    _time.value = _elapsedSeconds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(InertiaThrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardColors.length != widget.cardColors.length ||
        oldWidget.cellExtent != widget.cellExtent ||
        oldWidget.cardSize != widget.cardSize) {
      _board = Size.zero; // force re-layout of pegs/cards
    }
    _syncTicker();
  }

  void _syncTicker() {
    final bool reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool shouldRun =
        widget.animate && widget.frozenAt == null && !reducedMotion;
    if (shouldRun && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
      _lastTick = null;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  // ---- board layout -------------------------------------------------------

  void _layout(Size size) {
    if (size == _board || size.isEmpty) return;
    _board = size;
    const double margin = 14;
    final double half = widget.cardSize / 2;
    _bounds = Rect.fromLTRB(
      margin + half,
      margin + half,
      size.width - margin - half,
      size.height - margin - half,
    );
    final int cols = math.max(2, (size.width - margin * 2) ~/ widget.cellExtent);
    final int rows = math.max(2, (size.height - margin * 2) ~/ widget.cellExtent);
    final double pitchX = (_bounds.width) / (cols - 1);
    final double pitchY = (_bounds.height) / (rows - 1);
    _pegs = <Offset>[
      for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++)
          Offset(_bounds.left + c * pitchX, _bounds.top + r * pitchY),
    ];
    // Cards start on the first row's pegs, spaced out.
    _cards = <_Card>[
      for (int i = 0; i < widget.cardColors.length; i++)
        _Card(_initialRest(i)),
    ];
    _demoFired = 0;
  }

  Offset _initialRest(int i) => _pegs[(i * 2) % _pegs.length];

  // ---- auto-demo + flights ------------------------------------------------

  InertiaFlight _solveThrow(Offset from, Offset velocity) =>
      InertiaFlight.solve(
        start: from,
        velocity: velocity,
        bounds: _bounds,
        snapPoints: _pegs,
        snapRadius: widget.snapRadius,
        resistance: widget.resistance,
        minDuration: widget.minDuration,
        maxDuration: widget.maxDuration,
      );

  void _maybeAutoThrow(double t) {
    if (!widget.autoDemo || _touched || _cards.isEmpty) return;
    while (t >= _demoFirstAt + _demoFired * _demoEvery) {
      final int k = _demoFired;
      final _Card card = _cards[k % _cards.length];
      if (!card.dragging) {
        card.rest = _cardPosition(card, t);
        card.flight = _solveThrow(
          card.rest,
          _demoVelocities[k % _demoVelocities.length],
        );
        card.flightStart = _demoFirstAt + k * _demoEvery;
      }
      _demoFired++;
    }
  }

  void _settleFinished(double t, {bool notify = true}) {
    for (int i = 0; i < _cards.length; i++) {
      final _Card card = _cards[i];
      final InertiaFlight? f = card.flight;
      if (f != null && f.isDone(t - card.flightStart)) {
        card.rest = Offset(f.x.end, f.y.end);
        card.flight = null;
        if (notify) {
          final int peg = _pegs.indexWhere(
            (p) => (p - card.rest).distance < 1,
          );
          widget.onLanded?.call(i, peg);
        }
      }
    }
  }

  Offset _cardPosition(_Card card, double t) {
    final InertiaFlight? f = card.flight;
    if (f == null) return card.rest;
    return f.positionAt(t - card.flightStart);
  }

  double _cardTilt(_Card card, double t) {
    final InertiaFlight? f = card.flight;
    if (f == null) return 0;
    return f.tiltAt(t - card.flightStart);
  }

  /// Frozen frames replay the deterministic auto-demo script up to [t] —
  /// idempotent: resets to the initial arrangement first, fires no
  /// callbacks.
  void _replayScriptTo(double t) {
    _demoFired = 0;
    for (int i = 0; i < _cards.length; i++) {
      _cards[i]
        ..flight = null
        ..rest = _initialRest(i);
    }
    if (!widget.autoDemo) return;
    while (t >= _demoFirstAt + _demoFired * _demoEvery) {
      final int k = _demoFired;
      final double at = _demoFirstAt + k * _demoEvery;
      final _Card card = _cards[k % _cards.length];
      card.rest = _cardPosition(card, at);
      card.flight = _solveThrow(
        card.rest,
        _demoVelocities[k % _demoVelocities.length],
      );
      card.flightStart = at;
      _settleFinished(
        math.min(t, at + card.flight!.duration + 0.001),
        notify: false,
      );
      _demoFired++;
    }
  }

  // ---- gestures -----------------------------------------------------------

  void _onPanStart(int index, DragStartDetails details) {
    _touched = true;
    _draggedIndex = index;
    final _Card card = _cards[index];
    card.rest = _cardPosition(card, _elapsedSeconds);
    card.flight = null;
    card.dragging = true;
    _time.value = _elapsedSeconds; // repaint even between ticks
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final int? i = _draggedIndex;
    if (i == null) return;
    final _Card card = _cards[i];
    final Offset next = card.rest + details.delta;
    card.rest = Offset(
      next.dx.clamp(_bounds.left, _bounds.right),
      next.dy.clamp(_bounds.top, _bounds.bottom),
    );
    _time.value = _elapsedSeconds;
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    final int? i = _draggedIndex;
    _draggedIndex = null;
    if (i == null) return;
    final _Card card = _cards[i];
    card.dragging = false;
    card.flight = _solveThrow(card.rest, details.velocity.pixelsPerSecond);
    card.flightStart = _elapsedSeconds;
    setState(() {});
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _layout(constraints.biggest);
        return ValueListenableBuilder<double>(
          valueListenable: _time,
          builder: (context, liveTime, _) {
            final double t;
            if (widget.frozenAt != null) {
              t = widget.frozenAt!;
              _replayScriptTo(t);
            } else {
              t = liveTime;
            }
            return ColoredBox(
              color: const Color(0xFF0E0E10),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (widget.showGrid)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PegboardPainter(pegs: _pegs),
                      ),
                    ),
                  for (int i = 0; i < _cards.length; i++)
                    _buildCard(i, t),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCard(int i, double t) {
    final _Card card = _cards[i];
    final Offset pos = _cardPosition(card, t);
    final double tilt = _cardTilt(card, t);
    final double s = widget.cardSize;
    final bool active = card.dragging || card.flight != null;
    return Positioned(
      left: pos.dx - s / 2,
      top: pos.dy - s / 2,
      child: GestureDetector(
        onPanStart: (d) => _onPanStart(i, d),
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Transform.rotate(
          angle: tilt,
          child: AnimatedScale(
            scale: card.dragging ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: widget.cardColors[i % widget.cardColors.length],
                borderRadius: BorderRadius.circular(s * 0.22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000)
                        .withValues(alpha: active ? 0.45 : 0.25),
                    blurRadius: active ? 18 : 8,
                    offset: Offset(0, active ? 8 : 3),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: s * 0.28,
                  height: s * 0.28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(s * 0.08),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PegboardPainter extends CustomPainter {
  const _PegboardPainter({required this.pegs});

  final List<Offset> pegs;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dot = Paint()..color = const Color(0xFF2E2E38);
    for (final Offset p in pegs) {
      canvas.drawCircle(p, 3, dot);
    }
  }

  @override
  bool shouldRepaint(_PegboardPainter oldDelegate) =>
      oldDelegate.pegs != pegs;
}
