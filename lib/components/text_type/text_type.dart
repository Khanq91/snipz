/// TextType
/// Origin: reimplemented — dựng lại "Text Type" của react-bits (setTimeout
/// chain + GSAP cursor blink → Timer + AnimationController thuần Flutter):
/// gõ từng ký tự, dừng, xoá, chuyển câu, lặp; cursor nhấp nháy.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Typewriter effect over one or more sentences: types [typingSpeed] per
/// character, holds [pauseDuration], deletes at [deletingSpeed], moves to
/// the next sentence, loops. Control externally via
/// `GlobalKey<TextTypeState>` (`start`/`stop`/`restart`).
class TextType extends StatefulWidget {
  const TextType(
    this.sentences, {
    super.key,
    this.typingSpeed = const Duration(milliseconds: 50),
    this.initialDelay = Duration.zero,
    this.pauseDuration = const Duration(milliseconds: 2000),
    this.deletingSpeed = const Duration(milliseconds: 30),
    this.loop = true,
    this.style,
    this.textColors = const <Color>[],
    this.showCursor = true,
    this.hideCursorWhileTyping = false,
    this.cursorText = '|',
    this.cursorStyle,
    this.cursorBlinkDuration = const Duration(milliseconds: 500),
    this.variableSpeedMin,
    this.variableSpeedMax,
    this.reverseMode = false,
    this.autoStart = true,
    this.onSentenceComplete,
  }) : assert(
         (variableSpeedMin == null) == (variableSpeedMax == null),
         'variableSpeedMin and variableSpeedMax come together',
       );

  /// Sentences typed in order (original `text: string | string[]`).
  final List<String> sentences;

  /// Per-character delay while typing.
  final Duration typingSpeed;

  /// Delay before the first character of each sentence.
  final Duration initialDelay;

  /// Hold after a sentence is fully typed, before deleting.
  final Duration pauseDuration;

  /// Per-character delay while deleting.
  final Duration deletingSpeed;

  /// `false` stops (fully typed) after the last sentence.
  final bool loop;

  /// Merged over the ambient [DefaultTextStyle].
  final TextStyle? style;

  /// Per-sentence colors, cycled (original `textColors`). Empty = inherit.
  final List<Color> textColors;

  final bool showCursor;

  /// Hide the cursor while actively typing/deleting, show it during holds.
  final bool hideCursorWhileTyping;

  /// Cursor glyph (original `cursorCharacter`).
  final String cursorText;

  final TextStyle? cursorStyle;

  /// One fade (out or in) of the blink; a full cycle is 2× (original 0.5s).
  final Duration cursorBlinkDuration;

  /// When both set, each character's typing delay is uniform-random in
  /// [variableSpeedMin], [variableSpeedMax] (original `variableSpeed`).
  final Duration? variableSpeedMin;
  final Duration? variableSpeedMax;

  /// Type each sentence backwards (original `reverseMode`).
  final bool reverseMode;

  /// Start typing on mount (replaces the web `startOnVisible`; wire it to
  /// your own visibility logic via `GlobalKey<TextTypeState>().start()`).
  final bool autoStart;

  /// Fired after a sentence is deleted, right before the next one starts.
  final void Function(String sentence, int index)? onSentenceComplete;

  @override
  State<TextType> createState() => TextTypeState();
}

/// Public so a host can drive the animation via a `GlobalKey`.
class TextTypeState extends State<TextType>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  late final Animation<double> _blinkOpacity;
  final math.Random _random = math.Random();

  Timer? _timer;
  int _sentenceIndex = 0;
  int _shownChars = 0;
  bool _deleting = false;
  bool _running = false;

  String get _processed {
    if (widget.sentences.isEmpty) {
      return '';
    }
    final String s = widget.sentences[_sentenceIndex];
    return widget.reverseMode ? String.fromCharCodes(s.runes.toList().reversed) : s;
  }

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: widget.cursorBlinkDuration,
    )..repeat(reverse: true);
    _blinkOpacity = Tween<double>(begin: 1, end: 0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_blink);
    if (widget.autoStart) {
      start();
    }
  }

  @override
  void didUpdateWidget(TextType oldWidget) {
    super.didUpdateWidget(oldWidget);
    _blink.duration = widget.cursorBlinkDuration;
    if (!listEquals(oldWidget.sentences, widget.sentences)) {
      restart();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blink.dispose();
    super.dispose();
  }

  /// Begin (or resume) the state machine. No-op while already running.
  void start() {
    if (_running || widget.sentences.isEmpty) {
      return;
    }
    _running = true;
    _schedule(_shownChars == 0 && !_deleting ? widget.initialDelay : _typeDelay());
  }

  /// Halt in place (cursor keeps blinking).
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Reset to the first sentence and start over.
  void restart() {
    stop();
    setState(() {
      _sentenceIndex = 0;
      _shownChars = 0;
      _deleting = false;
    });
    start();
  }

  Duration _typeDelay() {
    final Duration? min = widget.variableSpeedMin;
    final Duration? max = widget.variableSpeedMax;
    if (min == null || max == null) {
      return widget.typingSpeed;
    }
    final int span = max.inMicroseconds - min.inMicroseconds;
    return Duration(
      microseconds: min.inMicroseconds + (span <= 0 ? 0 : _random.nextInt(span)),
    );
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _step);
  }

  void _step() {
    if (!mounted || !_running) {
      return;
    }
    if (_deleting) {
      if (_shownChars > 0) {
        setState(() => _shownChars--);
        _schedule(widget.deletingSpeed);
      } else {
        _deleting = false;
        widget.onSentenceComplete
            ?.call(widget.sentences[_sentenceIndex], _sentenceIndex);
        setState(() {
          _sentenceIndex = (_sentenceIndex + 1) % widget.sentences.length;
        });
        _schedule(widget.initialDelay);
      }
      return;
    }
    if (_shownChars < _processed.length) {
      setState(() => _shownChars++);
      _schedule(_typeDelay());
    } else if (widget.loop || _sentenceIndex < widget.sentences.length - 1) {
      // _deleting flips only AFTER the hold, so the cursor stays visible
      // during the pause under hideCursorWhileTyping (matches the original).
      _timer?.cancel();
      _timer = Timer(widget.pauseDuration, () {
        if (!mounted || !_running) {
          return;
        }
        _deleting = true;
        _step();
      });
    } else {
      _running = false; // done: last sentence stays, no loop
    }
  }

  @override
  Widget build(BuildContext context) {
    final String processed = _processed;
    final String shown = processed.substring(
      0,
      _shownChars.clamp(0, processed.length),
    );
    final Color? color = widget.textColors.isEmpty
        ? null
        : widget.textColors[_sentenceIndex % widget.textColors.length];
    final bool cursorHidden = widget.hideCursorWhileTyping &&
        (_shownChars < processed.length || _deleting);

    return Text.rich(
      TextSpan(
        style: widget.style,
        children: <InlineSpan>[
          TextSpan(
            text: shown,
            style: color == null ? null : TextStyle(color: color),
          ),
          if (widget.showCursor && !cursorHidden)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: FadeTransition(
                  opacity: _blinkOpacity,
                  child: Text(
                    widget.cursorText,
                    style: widget.style?.merge(widget.cursorStyle) ??
                        widget.cursorStyle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
