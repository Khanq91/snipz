/// TrueFocus
/// Origin: adapted — port of react-bits "True Focus" (motion/react → pure
/// Flutter): every word blurred except the active one, with a glowing
/// corner-bracket focus frame gliding between words.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Sentence split into words laid out in a centered [Wrap] (16px gaps).
/// The active word is sharp, all others are blurred by [blurAmount]; blur
/// transitions animate over [animationDuration]. A focus frame — four glowing
/// corner brackets sitting 10px outside the word bounds — glides (position AND
/// size) from the previous active word to the new one.
///
/// Auto mode (default): a [Timer] advances the active word every
/// [animationDuration] + [pauseBetweenAnimations], wrapping around.
/// [manualMode] disables the timer; on touch devices the original
/// hover-to-focus becomes tap-to-focus. Set [animate] to `false` to stop the
/// timer from outside (e.g. when scrolled off-screen).
class TrueFocus extends StatefulWidget {
  const TrueFocus(
    this.text, {
    super.key,
    this.separator = ' ',
    this.manualMode = false,
    this.blurAmount = 5.0,
    this.borderColor = const Color(0xFF008000),
    this.glowColor = const Color(0x9900FF00),
    this.animationDuration = const Duration(milliseconds: 500),
    this.pauseBetweenAnimations = const Duration(seconds: 1),
    this.textStyle,
    this.animate = true,
  });

  /// The sentence; split by [separator] into focusable words.
  final String text;

  /// Word separator (original default: single space).
  final String separator;

  /// `true` disables the auto-cycle timer; words focus on tap instead
  /// (the original's hover-to-focus, mapped to touch).
  final bool manualMode;

  /// Blur sigma applied to every non-active word.
  final double blurAmount;

  /// Bracket stroke color (CSS default `green` = #008000).
  final Color borderColor;

  /// Bracket glow color (original default `rgba(0,255,0,0.6)`).
  final Color glowColor;

  /// Duration of the blur transition and of the frame glide.
  final Duration animationDuration;

  /// Extra hold on each word between glides (auto mode only).
  final Duration pauseBetweenAnimations;

  /// Merged over `DefaultTextStyle` + the built-in default
  /// (fontSize 48, w900 — the original's `text-[3rem] font-black`).
  /// Color falls through to `DefaultTextStyle` unless set here.
  final TextStyle? textStyle;

  /// External stop switch: `false` cancels the auto-cycle timer and freezes
  /// the current word. Ignored in [manualMode] (which has no timer).
  final bool animate;

  @override
  State<TrueFocus> createState() => _TrueFocusState();
}

class _TrueFocusState extends State<TrueFocus> {
  late List<String> _words;
  late List<GlobalKey> _wordKeys;
  final GlobalKey _stackKey = GlobalKey();
  Timer? _timer;
  int _currentIndex = 0;

  /// Active word bounds relative to the Stack; null until first measured.
  Rect? _focusRect;

  @override
  void initState() {
    super.initState();
    _splitWords();
    _restartTimer();
  }

  void _splitWords() {
    _words = widget.text.split(widget.separator);
    _wordKeys = List<GlobalKey>.generate(_words.length, (_) => GlobalKey());
    if (_currentIndex >= _words.length) {
      _currentIndex = 0;
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.manualMode || !widget.animate || _words.length < 2) return;
    // Original: setInterval every (animationDuration + pauseBetweenAnimations).
    _timer = Timer.periodic(
      widget.animationDuration + widget.pauseBetweenAnimations,
      (_) => setState(() => _currentIndex = (_currentIndex + 1) % _words.length),
    );
  }

  @override
  void didUpdateWidget(TrueFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool wordsChanged = widget.text != oldWidget.text ||
        widget.separator != oldWidget.separator;
    if (wordsChanged) {
      _splitWords();
    }
    if (wordsChanged ||
        widget.manualMode != oldWidget.manualMode ||
        widget.animate != oldWidget.animate ||
        widget.animationDuration != oldWidget.animationDuration ||
        widget.pauseBetweenAnimations != oldWidget.pauseBetweenAnimations) {
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Post-layout: read the active word's RenderBox relative to the Stack
  /// (the port of getBoundingClientRect deltas in the original).
  void _measureFocusRect() {
    if (!mounted || _currentIndex >= _wordKeys.length) return;
    final RenderObject? container = _stackKey.currentContext?.findRenderObject();
    final RenderObject? word =
        _wordKeys[_currentIndex].currentContext?.findRenderObject();
    if (container is! RenderBox || word is! RenderBox) return;
    if (!container.hasSize || !word.hasSize) return;
    final Offset topLeft = word.localToGlobal(Offset.zero, ancestor: container);
    final Rect rect = topLeft & word.size;
    if (rect != _focusRect) {
      setState(() => _focusRect = rect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = DefaultTextStyle.of(context)
        .style
        .merge(const TextStyle(fontSize: 48, fontWeight: FontWeight.w900))
        .merge(widget.textStyle);
    // LayoutBuilder so parent resizes re-run this builder → re-measure.
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureFocusRect());
        return Stack(
          key: _stackKey,
          clipBehavior: Clip.none, // brackets sit 10px outside word bounds
          children: <Widget>[
            Wrap(
              spacing: 16, // original: flex gap-4
              runSpacing: 16,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (int i = 0; i < _words.length; i++) _buildWord(i, style),
              ],
            ),
            if (_focusRect != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<Rect?>(
                    // First glide starts from Rect.zero — same as the
                    // original motion.div animating out of {0,0,0,0}.
                    tween: RectTween(begin: Rect.zero, end: _focusRect),
                    duration: widget.animationDuration,
                    curve: Curves.easeInOut,
                    builder: (context, rect, _) => CustomPaint(
                      painter: _FocusFramePainter(
                        rect: rect ?? Rect.zero,
                        borderColor: widget.borderColor,
                        glowColor: widget.glowColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWord(int index, TextStyle style) {
    final double targetSigma = index == _currentIndex ? 0.0 : widget.blurAmount;
    Widget word = TweenAnimationBuilder<double>(
      // begin == end → no animation on mount (inactive words start blurred,
      // like the CSS filter's initial paint); target changes then animate
      // from the current value.
      tween: Tween<double>(begin: targetSigma, end: targetSigma),
      duration: widget.animationDuration,
      curve: Curves.ease, // CSS `transition: filter ... ease`
      builder: (context, sigma, child) {
        if (sigma < 0.05) return child!; // drop the saveLayer when sharp
        return ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
        );
      },
      child: Text(_words[index], style: style),
    );
    if (widget.manualMode) {
      word = GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Original hover-to-focus → tap-to-focus on touch. No "mouse leave"
        // on touch, so the tapped word simply stays focused.
        onTap: () => setState(() => _currentIndex = index),
        child: word,
      );
    }
    return KeyedSubtree(key: _wordKeys[index], child: word);
  }
}

/// Four corner brackets around [rect] inflated by 10px: 16px arms, 3px
/// stroke, 3px corner radius, each drawn twice — a blurred glow pass in
/// [glowColor] under a crisp pass in [borderColor].
class _FocusFramePainter extends CustomPainter {
  const _FocusFramePainter({
    required this.rect,
    required this.borderColor,
    required this.glowColor,
  });

  final Rect rect;
  final Color borderColor;
  final Color glowColor;

  static const double _offset = 10; // frame inset outside the word bounds
  static const double _arm = 16; // bracket box side (w-4 h-4)
  static const double _stroke = 3; // border-[3px]
  static const double _radius = 3; // rounded-[3px]

  @override
  void paint(Canvas canvas, Size size) {
    if (rect.isEmpty) return;
    final Rect frame = rect.inflate(_offset);
    // One bracket in local coords: corner at the origin, arms along +x/+y,
    // stroke centerline half a stroke inside the 16px box (CSS inner border).
    const double inset = _stroke / 2;
    final Path bracket = Path()
      ..moveTo(_arm, inset)
      ..lineTo(inset + _radius, inset)
      ..quadraticBezierTo(inset, inset, inset, inset + _radius)
      ..lineTo(inset, _arm);
    final Paint glow = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      // drop-shadow(0 0 4px) ≈ gaussian sigma radius/2.
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
    final Paint line = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    void corner(double dx, double dy, double sx, double sy) {
      canvas.save();
      canvas.translate(dx, dy);
      canvas.scale(sx, sy); // mirror the one bracket into each corner
      canvas.drawPath(bracket, glow);
      canvas.drawPath(bracket, line);
      canvas.restore();
    }

    corner(frame.left, frame.top, 1, 1);
    corner(frame.right, frame.top, -1, 1);
    corner(frame.left, frame.bottom, 1, -1);
    corner(frame.right, frame.bottom, -1, -1);
  }

  @override
  bool shouldRepaint(_FocusFramePainter oldDelegate) =>
      rect != oldDelegate.rect ||
      borderColor != oldDelegate.borderColor ||
      glowColor != oldDelegate.glowColor;
}
