/// BlurText
/// Origin: reimplemented — dựng lại "Blur Text" của react-bits
/// (per-segment blur+fade+slide reveal, animate by words or characters).
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Split unit for the reveal.
enum BlurTextUnit { words, characters }

/// Where segments slide in from.
enum BlurTextSlideDirection { top, bottom }

/// Text that reveals segment by segment: each word/character starts blurred,
/// transparent and offset, passes a half-sharp overshoot keyframe, then
/// settles crisp in place. One `AnimationController` drives every segment
/// through staggered intervals.
///
/// Replay/stop from outside via `GlobalKey<BlurTextState>`:
/// `key.currentState?.replay()` / `stop()`.
class BlurText extends StatefulWidget {
  const BlurText(
    this.text, {
    super.key,
    this.unit = BlurTextUnit.words,
    this.direction = BlurTextSlideDirection.top,
    this.stagger = const Duration(milliseconds: 120),
    this.stepDuration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOut,
    this.style,
    this.startBlur = 10.0,
    this.slideOffset = 40.0,
    this.alignment = WrapAlignment.start,
    this.autoPlay = true,
    this.onComplete,
  });

  final String text;

  /// Animate word-by-word or character-by-character.
  final BlurTextUnit unit;

  /// Slide in from above ([BlurTextSlideDirection.top]) or below.
  final BlurTextSlideDirection direction;

  /// Delay between one segment starting and the next.
  final Duration stagger;

  /// Duration of each of the two keyframe steps (segment total = 2×).
  final Duration stepDuration;

  /// Easing applied across a segment's full timeline.
  final Curve curve;

  /// Merged over `DefaultTextStyle` — style it like a `Text`.
  final TextStyle? style;

  /// Blur sigma at the start of the reveal.
  final double startBlur;

  /// Vertical slide distance in logical px.
  final double slideOffset;

  /// Horizontal alignment of the wrapped segments.
  final WrapAlignment alignment;

  /// Play once when mounted (and when [text] changes). Set `false` and drive
  /// it via [BlurTextState] instead.
  final bool autoPlay;

  /// Fires after the last segment settles.
  final VoidCallback? onComplete;

  @override
  BlurTextState createState() => BlurTextState();
}

/// Public state — the external play/stop handle (§ hard rule on controllers).
class BlurTextState extends State<BlurText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<String> _segments;

  @override
  void initState() {
    super.initState();
    _segments = _split(widget.text, widget.unit);
    _controller = AnimationController(vsync: this, duration: _totalDuration())
      ..addStatusListener(_onStatus);
    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  static List<String> _split(String text, BlurTextUnit unit) {
    if (unit == BlurTextUnit.characters) {
      return text.runes.map(String.fromCharCode).toList(growable: false);
    }
    // Keep the trailing space inside each word so the Wrap spacing is free.
    final List<String> words = text.split(' ');
    return <String>[
      for (int i = 0; i < words.length; i++)
        i == words.length - 1 ? words[i] : '${words[i]} ',
    ];
  }

  Duration _totalDuration() {
    final int n = _segments.length;
    return widget.stagger * (n <= 1 ? 0 : n - 1) + widget.stepDuration * 2;
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete?.call();
    }
  }

  /// Restart the reveal from the beginning.
  void replay() => _controller.forward(from: 0);

  /// Continue a stopped/unfinished reveal.
  void play() => _controller.forward();

  /// Freeze the reveal where it is.
  void stop() => _controller.stop();

  /// Jump straight to the settled end state without animating.
  void skipToEnd() => _controller.value = 1;

  @override
  void didUpdateWidget(BlurText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text ||
        widget.unit != oldWidget.unit ||
        widget.stagger != oldWidget.stagger ||
        widget.stepDuration != oldWidget.stepDuration) {
      _segments = _split(widget.text, widget.unit);
      _controller.duration = _totalDuration();
      if (widget.autoPlay) {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        DefaultTextStyle.of(context).style.merge(widget.style);
    final int n = _segments.length;
    final double totalMs =
        _totalDuration().inMilliseconds.toDouble().clamp(1, double.infinity);
    final double staggerMs = widget.stagger.inMilliseconds.toDouble();
    final double segmentMs = widget.stepDuration.inMilliseconds * 2.0;
    final double sign =
        widget.direction == BlurTextSlideDirection.top ? -1.0 : 1.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double nowMs = _controller.value * totalMs;
        return Wrap(
          alignment: widget.alignment,
          children: <Widget>[
            for (int i = 0; i < n; i++)
              _buildSegment(
                _segments[i],
                style,
                sign,
                ((nowMs - staggerMs * i) / segmentMs).clamp(0.0, 1.0),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSegment(String text, TextStyle style, double sign, double raw) {
    if (raw >= 1) {
      return Text(text, style: style);
    }
    final double t = widget.curve.transform(raw);
    final double blur;
    final double opacity;
    final double dy;
    if (t < 0.5) {
      // Keyframe A→B: heavy blur, transparent, far offset → half sharp with
      // a small overshoot past the resting line.
      final double f = t / 0.5;
      blur = ui.lerpDouble(widget.startBlur, widget.startBlur * 0.5, f)!;
      opacity = 0.5 * f;
      dy = ui.lerpDouble(
        sign * widget.slideOffset,
        -sign * widget.slideOffset * 0.12,
        f,
      )!;
    } else {
      // Keyframe B→C: settle crisp in place.
      final double f = (t - 0.5) / 0.5;
      blur = ui.lerpDouble(widget.startBlur * 0.5, 0, f)!;
      opacity = 0.5 + 0.5 * f;
      dy = ui.lerpDouble(-sign * widget.slideOffset * 0.12, 0, f)!;
    }
    Widget segment = Opacity(
      opacity: opacity,
      child: Text(text, style: style),
    );
    if (blur > 0.05) {
      segment = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: segment,
      );
    }
    return Transform.translate(offset: Offset(0, dy), child: segment);
  }
}
