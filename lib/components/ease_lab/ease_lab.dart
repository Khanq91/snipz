/// EaseLab
/// Origin: reimplemented — GSAP eases (CustomEase engine, CustomWiggle,
///   CustomBounce + squash, SlowMo, RoughEase, ExpoScaleEase, v3.15),
///   https://github.com/greensock/GSAP — thuật toán dựng lại thành Flutter
///   Curve thuần, không copy code. Widget lab là original.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '_curves.dart';

export '_curves.dart';

/// Ease playground: pick one of the ported GSAP eases, watch its graph and a
/// purpose-built motion preview run on a shared clock. The curves themselves
/// ([WiggleEase], [BounceEase]/[SquashEase], [SlowMoEase], [RoughEase],
/// [ExpoScaleEase], [CubicPathEase]) are exported from this entry and usable
/// standalone with any AnimationController.
class EaseLab extends StatefulWidget {
  const EaseLab({
    super.key,
    this.initialEase = 'wiggle',
    this.period = 2.4,
    this.hold = 0.7,
    this.height = 420,
    this.accent = const Color(0xFF8B7CFF),
    this.onEaseSelected,
    this.animate = true,
    this.frozenAt,
  }) : assert(period > 0),
       assert(hold >= 0),
       assert(height > 200);

  /// One of: wiggle, anticipate, bounce, slowmo, rough, expo.
  final String initialEase;

  /// Seconds per demo run.
  final double period;

  /// Pause between runs.
  final double hold;

  /// Total height (chips + graph + preview).
  final double height;

  final Color accent;

  /// Fired when a chip is picked (also usable to mirror selection outside).
  final ValueChanged<String>? onEaseSelected;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  @override
  State<EaseLab> createState() => _EaseLabState();
}

class _EaseLabItem {
  _EaseLabItem({
    required this.id,
    required this.label,
    required this.curve,
    this.companion,
    this.yMin = 0,
    this.yMax = 1,
  });

  final String id;
  final String label;

  /// Graphed + drives the preview's primary channel.
  final Curve curve;

  /// Second synced channel (squash for bounce, yoyo fade for slow-mo).
  final Curve? companion;

  final double yMin;
  final double yMax;

  List<double>? _samples;

  /// 121 cached graph samples.
  List<double> get samples => _samples ??= List<double>.generate(
    121,
    (i) => curve.transform(i / 120),
  );
}

class _EaseLabState extends State<EaseLab>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Duration? _lastTick;
  double _elapsedSeconds = 0;

  late final List<_EaseLabItem> _items;
  late String _selected = widget.initialEase;
  double _selectedAt = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
    _items = <_EaseLabItem>[
      _EaseLabItem(
        id: 'wiggle',
        label: 'Wiggle',
        curve: WiggleEase(wiggles: 8),
        yMin: -1,
        yMax: 1,
      ),
      _EaseLabItem(
        id: 'anticipate',
        label: 'Anticipate',
        curve: WiggleEase(wiggles: 6, type: WiggleType.anticipate),
        yMin: -1,
        yMax: 1,
      ),
      _EaseLabItem(
        id: 'bounce',
        label: 'Bounce + Squash',
        curve: BounceEase(strength: 0.6, squash: 3),
        companion: SquashEase(strength: 0.6, squash: 3),
        yMin: 0,
        yMax: 1.05,
      ),
      _EaseLabItem(
        id: 'slowmo',
        label: 'Slow Mo',
        curve: const SlowMoEase(),
        companion: const SlowMoEase(yoyoMode: true),
      ),
      _EaseLabItem(
        id: 'rough',
        label: 'Rough',
        curve: RoughEase(points: 24, strength: 1, clamp: true, seed: 17),
      ),
      _EaseLabItem(
        id: 'expo',
        label: 'Expo Scale',
        curve: ExpoScaleEase(1, 8),
      ),
    ];
    if (!_items.any((i) => i.id == _selected)) _selected = _items.first.id;
  }

  void _handleTick(Duration elapsed) {
    final Duration previous = _lastTick ?? Duration.zero;
    _lastTick = elapsed;
    final double delta = ((elapsed - previous).inMicroseconds / 1000000)
        .clamp(0.0, 0.064)
        .toDouble();
    _elapsedSeconds += delta;
    _time.value = _elapsedSeconds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(EaseLab oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  _EaseLabItem get _item => _items.firstWhere((i) => i.id == _selected);

  /// Cycle progress at time [t] (0..1, holding at 1 between runs).
  double _progress(double t) {
    final double local = (t - _selectedAt) % (widget.period + widget.hold);
    return math.min(1, local / widget.period);
  }

  void _select(String id) {
    setState(() {
      _selected = id;
      _selectedAt = _elapsedSeconds; // restart the run for the new ease
    });
    widget.onEaseSelected?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Thumbnail-sized hosts (gallery tiles) get a scaled-down lab
        // instead of a RenderFlex overflow.
        if (constraints.hasBoundedHeight && constraints.maxHeight < 300) {
          return FittedBox(
            fit: BoxFit.contain,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(width: 360, height: widget.height, child: _lab()),
          );
        }
        return _lab();
      },
    );
  }

  Widget _lab() {
    const Color panel = Color(0xFF141419);
    const Color line = Color(0xFF2A2A33);
    const Color textDim = Color(0xFF8C8C99);
    return SizedBox(
      height: widget.height,
      child: ColoredBox(
        color: const Color(0xFF0E0E10),
        child: ValueListenableBuilder<double>(
          valueListenable: _time,
          builder: (context, liveTime, _) {
            final double t = widget.frozenAt ?? liveTime;
            final double p = widget.frozenAt != null
                ? math.min(1, (widget.frozenAt! % (widget.period + widget.hold)) / widget.period)
                : _progress(t);
            final _EaseLabItem item = _item;
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: line),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: _EasePreviewPainter(
                            id: item.id,
                            value: item.curve.transform(p),
                            companionValue:
                                item.companion?.transform(p) ?? 0,
                            accent: widget.accent,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 96,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: line),
                      ),
                      child: CustomPaint(
                        painter: _EaseGraphPainter(
                          samples: item.samples,
                          yMin: item.yMin,
                          yMax: item.yMax,
                          progress: p,
                          accent: widget.accent,
                          grid: line,
                          dim: textDim,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 56,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        for (final _EaseLabItem it in _items) ...[
                          _Chip(
                            label: it.label,
                            selected: it.id == _selected,
                            accent: widget.accent,
                            onTap: () => _select(it.id),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.22) : const Color(0xFF1A1A21),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : const Color(0xFF2A2A33),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFEDEAFF) : const Color(0xFF9A9AA8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Graph: the ease curve, a 0/1 frame, and the playhead dot.
class _EaseGraphPainter extends CustomPainter {
  const _EaseGraphPainter({
    required this.samples,
    required this.yMin,
    required this.yMax,
    required this.progress,
    required this.accent,
    required this.grid,
    required this.dim,
  });

  final List<double> samples;
  final double yMin;
  final double yMax;
  final double progress;
  final Color accent;
  final Color grid;
  final Color dim;

  @override
  void paint(Canvas canvas, Size size) {
    const double padX = 14;
    const double padY = 12;
    final Rect area = Rect.fromLTRB(
      padX,
      padY,
      size.width - padX,
      size.height - padY,
    );
    // Extend the value range a hair so overshoot stays visible.
    final double lo = yMin - 0.04 * (yMax - yMin);
    final double hi = yMax + 0.04 * (yMax - yMin);
    double mapY(double v) =>
        area.bottom - (v - lo) / (hi - lo) * area.height;
    double mapX(double x) => area.left + x * area.width;

    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    // Frame lines at value 0 and 1.
    for (final double v in <double>[0, 1]) {
      if (v < lo || v > hi) continue;
      canvas.drawLine(
        Offset(area.left, mapY(v)),
        Offset(area.right, mapY(v)),
        gridPaint,
      );
    }

    final Path path = Path();
    for (int i = 0; i < samples.length; i++) {
      final double x = mapX(i / (samples.length - 1));
      final double y = mapY(samples[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );

    // Playhead.
    final int idx =
        (progress * (samples.length - 1)).round().clamp(0, samples.length - 1);
    final Offset head = Offset(mapX(progress), mapY(samples[idx]));
    canvas.drawLine(
      Offset(head.dx, area.top),
      Offset(head.dx, area.bottom),
      Paint()
        ..color = dim.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(head, 4, Paint()..color = const Color(0xFFF2F2F5));
  }

  @override
  bool shouldRepaint(_EaseGraphPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent;
}

/// Per-ease motion vignette, all procedural.
class _EasePreviewPainter extends CustomPainter {
  const _EasePreviewPainter({
    required this.id,
    required this.value,
    required this.companionValue,
    required this.accent,
  });

  final String id;

  /// Primary curve output at the current progress.
  final double value;

  /// Companion curve output (squash / yoyo fade), 0 when absent.
  final double companionValue;

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    switch (id) {
      case 'wiggle':
      case 'anticipate':
        _paintWiggle(canvas, size);
      case 'bounce':
        _paintBounce(canvas, size);
      case 'slowmo':
        _paintSlowMo(canvas, size);
      case 'rough':
        _paintRough(canvas, size);
      case 'expo':
        _paintExpo(canvas, size);
    }
  }

  void _paintWiggle(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double angle = value * 30 * math.pi / 180; // peak ±30°
    canvas.save();
    canvas.translate(c.dx, c.dy - 6);
    canvas.rotate(angle);
    // A little bell: body + clapper.
    final Paint body = Paint()..color = accent;
    final Path bell = Path()
      ..moveTo(0, -34)
      ..quadraticBezierTo(22, -30, 24, 8)
      ..quadraticBezierTo(26, 20, 34, 26)
      ..lineTo(-34, 26)
      ..quadraticBezierTo(-26, 20, -24, 8)
      ..quadraticBezierTo(-22, -30, 0, -34)
      ..close();
    canvas.drawPath(bell, body);
    canvas.drawCircle(Offset(0, -36), 5, body);
    canvas.drawCircle(
      Offset(0, 34),
      7,
      Paint()..color = accent.withValues(alpha: 0.7),
    );
    canvas.restore();
  }

  void _paintBounce(Canvas canvas, Size size) {
    final double floorY = size.height * 0.78;
    final double topY = size.height * 0.16;
    const double r = 22;
    final double y = ui.lerpDouble(topY, floorY, value)!;
    // Squash: 1 at contact, negative = stretch on departure.
    final double s = companionValue;
    final double scaleX = 1 + 0.4 * s;
    final double scaleY = 1 - 0.4 * s;

    canvas.drawLine(
      Offset(size.width * 0.16, floorY + r),
      Offset(size.width * 0.84, floorY + r),
      Paint()
        ..color = const Color(0xFF2A2A33)
        ..strokeWidth = 2,
    );
    // Contact shadow grows as the ball nears the floor.
    final double near = value.clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, floorY + r + 4),
        width: 30 + 34 * near * scaleX,
        height: 8,
      ),
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.35 * near),
    );
    // Ball anchored to its bottom edge so squash flattens against the floor.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, y + r - r * scaleY),
        width: 2 * r * scaleX,
        height: 2 * r * scaleY,
      ),
      Paint()..color = accent,
    );
  }

  void _paintSlowMo(Canvas canvas, Size size) {
    final double x = ui.lerpDouble(
      size.width * 0.14,
      size.width * 0.86,
      value,
    )!;
    final double alpha = companionValue.clamp(0.0, 1.0);
    final Paint bar = Paint()..color = accent.withValues(alpha: alpha);
    final RRect pill = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, size.height / 2),
        width: size.width * 0.34,
        height: 44,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(pill, bar);
    final Paint lines = Paint()
      ..color = const Color(0xFF0E0E10).withValues(alpha: alpha)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final Rect box = pill.outerRect.deflate(12);
    canvas.drawLine(
      Offset(box.left, box.top + 4),
      Offset(box.right, box.top + 4),
      lines,
    );
    canvas.drawLine(
      Offset(box.left, box.bottom - 4),
      Offset(box.left + box.width * 0.6, box.bottom - 4),
      lines,
    );
  }

  void _paintRough(Canvas canvas, Size size) {
    final double alpha = value.clamp(0.0, 1.0);
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'OPEN',
        style: TextStyle(
          color: accent.withValues(alpha: 0.25 + 0.75 * alpha),
          fontSize: 46,
          fontWeight: FontWeight.w800,
          letterSpacing: 10,
          shadows: [
            Shadow(
              color: accent.withValues(alpha: 0.85 * alpha),
              blurRadius: 22,
            ),
            Shadow(
              color: accent.withValues(alpha: 0.5 * alpha),
              blurRadius: 46,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      size.center(Offset.zero) - Offset(tp.width / 2, tp.height / 2),
    );
  }

  void _paintExpo(Canvas canvas, Size size) {
    // Linear tween scale 1→8 remapped by ExpoScaleEase == geometric 8^p:
    // the zoom LOOKS constant-rate.
    final double scale = 1 + 7 * value;
    final Offset c = size.center(Offset.zero);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent;
    // Nested squares an octave apart: as one grows out, the next takes its
    // place — a seamless loop.
    for (int k = -1; k <= 3; k++) {
      final double side = 30 * scale / math.pow(8, k);
      if (side < 4 || side > size.longestSide * 2.4) continue;
      final double fade =
          (1 - (side / (size.shortestSide * 1.15))).clamp(0.0, 1.0);
      stroke.color = accent.withValues(alpha: 0.15 + 0.85 * fade);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: side, height: side),
          Radius.circular(side * 0.12),
        ),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_EasePreviewPainter oldDelegate) =>
      oldDelegate.id != id ||
      oldDelegate.value != value ||
      oldDelegate.companionValue != companionValue ||
      oldDelegate.accent != accent;
}
