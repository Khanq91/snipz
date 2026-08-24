/// HoldToConfirm
/// Origin: reimplemented — kinetics "Hold to Confirm" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Circular hold-to-confirm button. Press and hold: a ring fills linearly
/// over [holdDuration]; held to the end it fires [onConfirm] and flashes a
/// success state, released early the ring snaps back (0.2s ease-out).
class HoldToConfirm extends StatefulWidget {
  const HoldToConfirm({
    super.key,
    this.onConfirm,
    this.holdDuration = const Duration(milliseconds: 800),
    this.resetDelay = const Duration(milliseconds: 1400),
    this.size = 84,
    this.label = 'Hold',
    this.doneLabel = '✓',
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.labelColor = const Color(0xFFA8A6A0),
    this.trackColor = const Color(0xFF2A2A2E),
    this.progressColor = const Color(0xFFFF8A00),
    this.doneColor = const Color(0xFF4CD08A),
    this.doneForegroundColor = const Color(0xFF0E0E10),
    this.animate = true,
  });

  final VoidCallback? onConfirm;

  /// How long the button must be held. This is interaction semantics, not
  /// decoration — it stays in effect even when [animate] is false.
  final Duration holdDuration;

  /// How long the success state shows before returning to idle.
  final Duration resetDelay;
  final double size;
  final String label;
  final String doneLabel;
  final Color backgroundColor;
  final Color borderColor;
  final Color labelColor;
  final Color trackColor;
  final Color progressColor;
  final Color doneColor;
  final Color doneForegroundColor;

  /// False makes the decorative transitions (snap-back, color fades)
  /// immediate. The ring still tracks the hold — it is functional feedback.
  final bool animate;

  @override
  State<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<HoldToConfirm>
    with TickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  );
  late final AnimationController _reset = AnimationController(
    vsync: this,
    duration: widget.resetDelay,
  );
  bool _holding = false;
  bool _done = false;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    _hold.addStatusListener((status) {
      if (status == AnimationStatus.completed && _holding) _promote();
    });
    _reset.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _done = false);
        // .done removed: the ring empties with the base 0.2s ease-out.
        _hold.animateBack(
          0,
          duration: _motionEnabled
              ? const Duration(milliseconds: 200)
              : Duration.zero,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(HoldToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hold.duration = widget.holdDuration;
    _reset.duration = widget.resetDelay;
  }

  @override
  void dispose() {
    _hold.dispose();
    _reset.dispose();
    super.dispose();
  }

  void _start() {
    if (_done) return;
    setState(() => _holding = true);
    // Constant duration from the current fill, like the CSS transition
    // retarget (a re-press during the snap-back resumes mid-ring).
    _hold.animateTo(1, duration: widget.holdDuration);
  }

  void _cancel() {
    if (!_holding) return;
    setState(() => _holding = false);
    _hold.animateBack(
      0,
      duration: _motionEnabled
          ? const Duration(milliseconds: 200)
          : Duration.zero,
      curve: Curves.easeOut,
    );
  }

  void _promote() {
    setState(() {
      _holding = false;
      _done = true;
    });
    widget.onConfirm?.call();
    _reset.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final Duration colorDuration = _motionEnabled
        ? const Duration(milliseconds: 300)
        : Duration.zero;

    return Semantics(
      button: true,
      enabled: !_done,
      label: _done ? widget.doneLabel : widget.label,
      // Accessibility path: a long-press action confirms without the ring.
      onLongPress: _done ? null : _promote,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _cancel(),
        onPointerCancel: (_) => _cancel(),
        child: AnimatedContainer(
          duration: colorDuration,
          curve: Curves.ease,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _done ? widget.doneColor : widget.backgroundColor,
            border: Border.all(
              color: _done ? widget.doneColor : widget.borderColor,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: _hold,
                    trackColor: widget.trackColor,
                    progressColor: _done
                        ? widget.doneColor
                        : widget.progressColor,
                    done: _done,
                  ),
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: colorDuration,
                curve: Curves.ease,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _done ? widget.doneForegroundColor : widget.labelColor,
                ),
                child: Text(_done ? widget.doneLabel : widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Track + progress arc of the original 72-viewBox SVG ring (r 33, stroke 3,
/// round cap, starting at 12 o'clock), scaled to the button size.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.done,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color trackColor;
  final Color progressColor;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.shortestSide / 72;
    final Offset center = size.center(Offset.zero);
    final double radius = 33 * unit;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * unit
      ..strokeCap = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    final double t = done ? 1 : progress.value;
    if (t <= 0) return;
    paint.color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * t,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.done != done;
}
