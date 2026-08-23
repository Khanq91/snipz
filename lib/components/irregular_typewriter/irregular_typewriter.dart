/// IrregularTypewriter
/// Origin: reimplemented — port of the "irregular playback typewriter"
/// example from anime.js v4 (juliangarnier/anime,
/// examples/irregular-playback-typewriter): text types itself with the
/// uneven rhythm of real keystrokes (easings.irregular — bursts and
/// hesitations), a block cursor steps along and blinks.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Text that types itself like a human: per-character reveal moments come
/// from a seeded irregular rhythm (fast bursts, sudden hesitations) instead
/// of a metronome. A block cursor steps after the last glyph and blinks.
class IrregularTypewriter extends StatefulWidget {
  const IrregularTypewriter({
    super.key,
    required this.text,
    this.style = const TextStyle(
      fontFamily: 'monospace',
      fontSize: 22,
      color: Color(0xFFEDEAE4),
    ),
    this.cursorColor,
    this.charInterval = const Duration(milliseconds: 125),
    this.irregularity = 2.0,
    this.loop = true,
    this.holdDuration = const Duration(milliseconds: 2600),
    this.textAlign = TextAlign.left,
    this.seed = 5,
    this.animate = true,
    this.frozenAt,
  });

  final String text;
  final TextStyle style;

  /// Block cursor color; null uses the text color.
  final Color? cursorColor;

  /// Average time per character (the real rhythm jitters around it).
  final Duration charInterval;

  /// 0 = metronome, 2 = the upstream feel, higher = wilder hesitations.
  final double irregularity;

  /// True erases and retypes after [holdDuration]; false types once.
  final bool loop;

  /// How long the finished line stays before a looping retype.
  final Duration holdDuration;

  final TextAlign textAlign;

  /// PRNG seed — same seed, same rhythm.
  final int seed;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<IrregularTypewriter> createState() => _IrregularTypewriterState();
}

class _IrregularTypewriterState extends State<IrregularTypewriter>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  List<double> _revealAt = const [];
  TextPainter? _measure;
  TextPainter? _reveal;
  int _revealCount = -1;
  double _layoutWidth = -1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(
        (elapsed) => _t.value = elapsed.inMicroseconds / 1e6);
    _buildSchedule();
  }

  /// Seeded irregular reveal moments — the upstream
  /// `easings.irregular(steps, randomness)` as explicit timestamps: random
  /// weights around 1, cumulative, normalized to steps × interval.
  void _buildSchedule() {
    final int n = widget.text.characters.length;
    final List<double> w = <double>[];
    double sum = 0;
    for (int i = 0; i < n; i++) {
      final double r = _rand01(i);
      final double weight =
          math.max(.05, 1 + widget.irregularity * (r * 2 - 1));
      w.add(weight);
      sum += weight;
    }
    final double total =
        n * widget.charInterval.inMicroseconds / 1e6;
    final List<double> at = <double>[];
    double acc = 0;
    for (int i = 0; i < n; i++) {
      acc += w[i];
      at.add(sum == 0 ? 0 : total * acc / sum);
    }
    _revealAt = at;
  }

  double _rand01(int a) {
    int h = widget.seed ^ (a * 0x9E3779B1) ^ 0x68E31DA4;
    h = (h ^ (h >> 15)) * 0x2C1B3C6D & 0xFFFFFFFF;
    h = (h ^ (h >> 12)) * 0x297A2D39 & 0xFFFFFFFF;
    h ^= h >> 15;
    return h / 0x100000000;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(IrregularTypewriter old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text ||
        old.charInterval != widget.charInterval ||
        old.irregularity != widget.irregularity ||
        old.seed != widget.seed) {
      _buildSchedule();
      _revealCount = -1;
    }
    if (old.style != widget.style || old.textAlign != widget.textAlign) {
      _measure = null;
      _revealCount = -1;
    }
    _syncTicker();
  }

  void _syncTicker() {
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool run = widget.animate && widget.frozenAt == null && !reduced;
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    _measure?.dispose();
    _reveal?.dispose();
    super.dispose();
  }

  double get _typeDuration =>
      _revealAt.isEmpty ? 0 : _revealAt.last;

  int _countAt(double t) {
    // still + reduced-motion render settled full text
    final bool still = !widget.animate ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (still && widget.frozenAt == null) return _revealAt.length;
    double s = t;
    if (widget.loop) {
      final double cycle = _typeDuration +
          widget.holdDuration.inMicroseconds / 1e6;
      if (cycle > 0) s = t % cycle;
    }
    int c = 0;
    while (c < _revealAt.length && _revealAt[c] <= s) {
      c++;
    }
    return c;
  }

  void _layout(double maxWidth, int count) {
    final TextDirection dir = Directionality.maybeOf(context) ??
        TextDirection.ltr;
    if (_measure == null || _layoutWidth != maxWidth) {
      _measure?.dispose();
      _measure = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        textAlign: widget.textAlign,
        textDirection: dir,
      )..layout(maxWidth: maxWidth);
      _layoutWidth = maxWidth;
      _revealCount = -1;
    }
    if (_revealCount != count) {
      final String shown =
          widget.text.characters.take(count).toString();
      _reveal?.dispose();
      _reveal = TextPainter(
        text: TextSpan(children: <InlineSpan>[
          TextSpan(text: shown, style: widget.style),
          TextSpan(
            text: widget.text.substring(shown.length),
            // invisible tail keeps wrapping identical to the full text
            style: widget.style.copyWith(
                color: const Color(0x00000000)),
          ),
        ]),
        textAlign: widget.textAlign,
        textDirection: dir,
      )..layout(maxWidth: maxWidth);
      _revealCount = count;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 600;
        return ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, t, _) {
            final double now = widget.frozenAt ?? t;
            final int count = _countAt(now);
            _layout(maxWidth, count);
            // upstream blink: 750ms alternate, sharp in-in feel
            final double tri =
                (now / .75) % 2 < 1 ? (now / .75) % 1 : 1 - (now / .75) % 1;
            final double blink = widget.frozenAt == null &&
                    widget.animate
                ? 1 - tri * tri
                : 1;
            final String shown =
                widget.text.characters.take(count).toString();
            final Offset caret = _reveal!.getOffsetForCaret(
              TextPosition(offset: shown.length),
              Rect.zero,
            );
            return CustomPaint(
              size: Size(
                  _measure!.width + (widget.style.fontSize ?? 14) * .7,
                  _measure!.height),
              painter: _TypewriterPainter(
                reveal: _reveal!,
                caret: caret,
                caretSize: Size(
                  (widget.style.fontSize ?? 14) * .6,
                  _measure!.preferredLineHeight,
                ),
                caretColor: (widget.cursorColor ??
                        widget.style.color ??
                        const Color(0xFFFFFFFF))
                    .withValues(alpha: blink.clamp(0.0, 1.0)),
              ),
            );
          },
        );
      },
    );
  }
}

class _TypewriterPainter extends CustomPainter {
  const _TypewriterPainter({
    required this.reveal,
    required this.caret,
    required this.caretSize,
    required this.caretColor,
  });

  final TextPainter reveal;
  final Offset caret;
  final Size caretSize;
  final Color caretColor;

  @override
  void paint(Canvas canvas, Size size) {
    reveal.paint(canvas, Offset.zero);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            caret.dx + 1, caret.dy, caretSize.width, caretSize.height),
        const Radius.circular(1.5),
      ),
      Paint()..color = caretColor,
    );
  }

  @override
  bool shouldRepaint(_TypewriterPainter old) =>
      old.reveal != reveal ||
      old.caret != caret ||
      old.caretSize != caretSize ||
      old.caretColor != caretColor;
}
