/// PixelTransition
/// Origin: reimplemented — dựng lại "Pixel Transition" của react-bits (GSAP
/// stagger trên DOM grid → CustomPainter + một AnimationController): lưới
/// pixel phủ lên theo thứ tự ngẫu nhiên, đổi nội dung ở giữa, rồi gỡ ra
/// theo thứ tự ngẫu nhiên khác.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Card swapping between [firstChild] and [secondChild] behind a pixel-grid
/// wipe. Tap toggles (the original's touch behavior); a host can also drive
/// it via `GlobalKey<PixelTransitionState>`.
class PixelTransition extends StatefulWidget {
  const PixelTransition({
    super.key,
    required this.firstChild,
    required this.secondChild,
    this.gridSize = 7,
    this.pixelColor = const Color(0xFFFFFFFF),
    this.stepDuration = const Duration(milliseconds: 300),
    this.once = false,
    this.interactive = true,
    this.aspectRatio = 1.0,
    this.backgroundColor = const Color(0xFF222222),
    this.borderRadius = 15,
    this.borderColor = const Color(0xFFFFFFFF),
    this.borderWidth = 2,
    this.onChanged,
  }) : assert(gridSize > 0, 'gridSize must be > 0');

  /// Resting content.
  final Widget firstChild;

  /// Content revealed behind the pixel wipe.
  final Widget secondChild;

  /// Pixels per side (total gridSize², original default 7).
  final int gridSize;

  /// Wipe cell color (original `currentColor`, effectively white).
  final Color pixelColor;

  /// Duration of ONE stagger sweep; a full transition is cover + uncover =
  /// 2× this (original `animationStepDuration` = 0.3s).
  final Duration stepDuration;

  /// `true`: once activated, stays on [secondChild] (original `once`).
  final bool once;

  /// Tap toggles. `false` = drive only via [PixelTransitionState].
  final bool interactive;

  /// Width / height (original `aspectRatio: '100%'` = 1.0). Null sizes from
  /// the parent instead.
  final double? aspectRatio;

  final Color backgroundColor;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;

  /// Fired when the shown content changes target (true = second).
  final ValueChanged<bool>? onChanged;

  @override
  State<PixelTransition> createState() => PixelTransitionState();
}

/// Public so a host can call [show]/[toggle] via a `GlobalKey`.
class PixelTransitionState extends State<PixelTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();

  // Rank fraction (0..1) per cell: the moment in each half-sweep when the
  // cell appears / disappears. Reshuffled independently every run, matching
  // the original's two `from: 'random'` staggers.
  List<double> _appearRanks = const <double>[];
  List<double> _disappearRanks = const <double>[];

  bool _active = false; // target content (true = second)
  bool _fromSecond = false; // content shown during the covering half

  /// Which content is currently the target.
  bool get active => _active;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.stepDuration * 2,
      value: 1, // idle with no pixels painted (uncover phase done)
    );
  }

  @override
  void didUpdateWidget(PixelTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.stepDuration * 2;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<double> _shuffledRanks() {
    final int total = widget.gridSize * widget.gridSize;
    final List<int> order = List<int>.generate(total, (i) => i)
      ..shuffle(_random);
    final List<double> ranks = List<double>.filled(total, 0);
    for (int i = 0; i < total; i++) {
      ranks[order[i]] = i / total;
    }
    return ranks;
  }

  bool get _displayedSecond => _controller.isAnimating
      ? (_controller.value < 0.5 ? _fromSecond : _active)
      : _active;

  /// Animate to [second] (no-op if already the target). Restarting mid-wipe
  /// re-randomizes and runs from the currently shown content, like the
  /// original's kill-and-restart.
  void show(bool second) {
    if (second == _active) {
      return;
    }
    _fromSecond = _displayedSecond;
    setState(() {
      _active = second;
      _appearRanks = _shuffledRanks();
      _disappearRanks = _shuffledRanks();
    });
    _controller.forward(from: 0);
    widget.onChanged?.call(second);
  }

  void toggle() => show(!_active);

  void _onTap() {
    if (!_active) {
      show(true);
    } else if (!widget.once) {
      show(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final bool second = _displayedSecond;
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Offstage(offstage: second, child: widget.firstChild),
                Offstage(offstage: !second, child: widget.secondChild),
              ],
            );
          },
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _PixelGridPainter(
              animation: _controller,
              gridSize: widget.gridSize,
              color: widget.pixelColor,
              appearRanks: _appearRanks,
              disappearRanks: _disappearRanks,
            ),
          ),
        ),
      ],
    );
    if (widget.aspectRatio != null) {
      content = AspectRatio(aspectRatio: widget.aspectRatio!, child: content);
    }
    content = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
      ),
      child: content,
    );
    if (!widget.interactive) {
      return content;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: content,
    );
  }
}

class _PixelGridPainter extends CustomPainter {
  _PixelGridPainter({
    required this.animation,
    required this.gridSize,
    required this.color,
    required this.appearRanks,
    required this.disappearRanks,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final int gridSize;
  final Color color;
  final List<double> appearRanks;
  final List<double> disappearRanks;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (appearRanks.isEmpty) {
      return;
    }
    final double v = animation.value;
    final double cover = (v * 2).clamp(0.0, 1.0); // first half sweep
    final double uncover = (v * 2 - 1).clamp(0.0, 1.0); // second half sweep
    if (cover == 0 || uncover == 1) {
      return; // fully clear at rest
    }
    _paint.color = color;
    final double cellW = size.width / gridSize;
    final double cellH = size.height / gridSize;
    for (int i = 0; i < appearRanks.length; i++) {
      final bool visible = cover > appearRanks[i] && uncover <= disappearRanks[i];
      if (!visible) {
        continue;
      }
      final int col = i % gridSize;
      final int row = i ~/ gridSize;
      // +1px overlap hides seams between cells at fractional sizes.
      canvas.drawRect(
        Rect.fromLTWH(col * cellW, row * cellH, cellW + 1, cellH + 1),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelGridPainter oldDelegate) =>
      oldDelegate.gridSize != gridSize ||
      oldDelegate.color != color ||
      oldDelegate.appearRanks != appearRanks ||
      oldDelegate.disappearRanks != disappearRanks;
}
