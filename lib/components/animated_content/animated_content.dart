/// AnimatedContent
/// Origin: reimplemented — dựng lại "AnimatedContent" của react-bits
/// (GSAP + ScrollTrigger) bằng AnimationController thuần
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:async';

import 'package:flutter/material.dart';

/// Entrance animation that plays once when the widget is scrolled into view:
/// the child slides in from [distance], fades from [initialOpacity] and scales
/// from [scale] to identity. Optionally animates back out after
/// [disappearAfter].
///
/// Trigger: if there is a [Scrollable] ancestor, the animation starts when the
/// widget's leading edge crosses `(1 - threshold)` of the viewport (the
/// ScrollTrigger `start: top 90%` behavior). Without a Scrollable ancestor it
/// plays right away. [AnimatedContentState.play] / [AnimatedContentState.reset]
/// (via a `GlobalKey`) give manual control.
class AnimatedContent extends StatefulWidget {
  const AnimatedContent({
    super.key,
    required this.child,
    this.distance = 100,
    this.direction = Axis.vertical,
    this.reverse = false,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.initialOpacity = 0,
    this.animateOpacity = true,
    this.scale = 1,
    this.threshold = 0.1,
    this.delay = Duration.zero,
    this.disappearAfter,
    this.disappearDuration = const Duration(milliseconds: 500),
    this.disappearCurve = Curves.easeInCubic,
    this.autoTrigger = true,
    this.onComplete,
    this.onDisappearanceComplete,
  }) : assert(threshold >= 0 && threshold <= 1, 'threshold must be 0..1');

  final Widget child;

  /// Slide-in offset in logical px along [direction].
  final double distance;

  final Axis direction;

  /// Flip the slide-in side (bottom→top becomes top→bottom, etc.).
  final bool reverse;

  final Duration duration;
  final Curve curve;

  /// Opacity before the animation runs (only used when [animateOpacity]).
  final double initialOpacity;
  final bool animateOpacity;

  /// Starting scale (1 = no scale animation).
  final double scale;

  /// Fraction of the viewport the leading edge must cross before triggering.
  final double threshold;

  /// Extra wait after the trigger fires.
  final Duration delay;

  /// Non-null: after the entrance completes, wait this long and animate back
  /// out (to the opposite side, scale 0.8).
  final Duration? disappearAfter;

  final Duration disappearDuration;
  final Curve disappearCurve;

  /// False = never trigger from scroll/mount; call
  /// [AnimatedContentState.play] yourself.
  final bool autoTrigger;

  final VoidCallback? onComplete;
  final VoidCallback? onDisappearanceComplete;

  @override
  State<AnimatedContent> createState() => AnimatedContentState();
}

class AnimatedContentState extends State<AnimatedContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ScrollPosition? _position;
  Timer? _delayTimer;
  Timer? _disappearTimer;
  bool _triggered = false;
  bool _disappearing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    if (!mounted || !widget.autoTrigger) {
      return;
    }
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      _trigger();
      return;
    }
    _position = scrollable.position;
    _position!.addListener(_checkVisibility);
    _checkVisibility();
  }

  void _checkVisibility() {
    if (_triggered || !mounted) {
      return;
    }
    final RenderObject? render = context.findRenderObject();
    final ScrollPosition? position = _position;
    if (render is! RenderBox || !render.hasSize || position == null) {
      return;
    }
    final RenderObject? viewportRender =
        position.context.notificationContext?.findRenderObject();
    if (viewportRender is! RenderBox || !viewportRender.hasSize) {
      return;
    }
    final Offset topLeft =
        render.localToGlobal(Offset.zero, ancestor: viewportRender);
    final bool vertical = position.axis == Axis.vertical;
    final double leading = vertical ? topLeft.dy : topLeft.dx;
    final double extent =
        vertical ? viewportRender.size.height : viewportRender.size.width;
    if (leading <= extent * (1 - widget.threshold)) {
      _trigger();
    }
  }

  void _trigger() {
    if (_triggered) {
      return;
    }
    _triggered = true;
    _detach();
    if (widget.delay == Duration.zero) {
      _play();
    } else {
      _delayTimer = Timer(widget.delay, _play);
    }
  }

  void _play() {
    if (!mounted) {
      return;
    }
    _controller
      ..duration = widget.duration
      ..forward(from: 0).whenComplete(_onEntranceDone);
  }

  void _onEntranceDone() {
    if (!mounted || _disappearing) {
      return;
    }
    widget.onComplete?.call();
    final Duration? after = widget.disappearAfter;
    if (after != null) {
      _disappearTimer = Timer(after, _disappear);
    }
  }

  void _disappear() {
    if (!mounted) {
      return;
    }
    setState(() => _disappearing = true);
    _controller
      ..duration = widget.disappearDuration
      ..forward(from: 0).whenComplete(() {
        if (mounted) {
          widget.onDisappearanceComplete?.call();
        }
      });
  }

  /// Manual trigger (also usable with `autoTrigger: false`).
  void play() => _trigger();

  /// Back to the hidden pre-trigger state; the scroll trigger re-arms.
  void reset() {
    _delayTimer?.cancel();
    _disappearTimer?.cancel();
    _controller.stop();
    _controller.value = 0;
    setState(() {
      _triggered = false;
      _disappearing = false;
    });
    _detach();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _detach() {
    _position?.removeListener(_checkVisibility);
    _position = null;
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _disappearTimer?.cancel();
    _detach();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double dist = widget.reverse ? -widget.distance : widget.distance;
        double dx = 0;
        double dy = 0;
        double scale;
        double opacity;
        if (_disappearing) {
          // Identity -> pushed out the opposite side, scaled down, faded.
          final double t =
              widget.disappearCurve.transform(_controller.value);
          final double out = -dist * t;
          if (widget.direction == Axis.horizontal) {
            dx = out;
          } else {
            dy = out;
          }
          scale = 1 + (0.8 - 1) * t;
          opacity = widget.animateOpacity
              ? 1 + (widget.initialOpacity - 1) * t
              : 1 - t;
        } else {
          final double t = widget.curve.transform(_controller.value);
          final double offset = dist * (1 - t);
          if (widget.direction == Axis.horizontal) {
            dx = offset;
          } else {
            dy = offset;
          }
          scale = widget.scale + (1 - widget.scale) * t;
          opacity = widget.animateOpacity
              ? widget.initialOpacity + (1 - widget.initialOpacity) * t
              : 1;
        }
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
