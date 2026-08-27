/// ScrambleText
/// Origin: reimplemented — GSAP ScrambleTextPlugin (v3.15),
///   https://github.com/greensock/GSAP/blob/master/src/ScrambleTextPlugin.js —
///   thuật toán (charset pool 20×80, reveal split, length morph bậc 3,
///   revealDelay, rightToLeft) dựng lại bằng TextSpan, không copy code.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Built-in scramble alphabets (mirrors GSAP's `chars` presets).
enum ScrambleCharset {
  upperCase,
  lowerCase,
  upperAndLowerCase,

  /// Use [ScrambleText.customChars] as the alphabet.
  custom,
}

/// "Decoding" text: the target string resolves out of churning random
/// characters, left to right (or right to left).
///
/// Faithful to the GSAP plugin's model:
/// - noise comes from 20 pre-generated pooled strings (never per-frame
///   `Random()` in the paint path — pools are seeded, so a frame is a pure
///   function of elapsed time `t`);
/// - the pool in use hops every `0.05 / speed` seconds;
/// - the reveal boundary is `(ratio * length + 0.5).floor()`;
/// - when cycling between texts of different lengths the displayed length
///   morphs with a cubic (`1 - (1-ratio)^3`), GSAP's `tweenLength`;
/// - `revealDelay` scrambles without revealing for its duration.
class ScrambleText extends StatefulWidget {
  const ScrambleText({
    super.key,
    required this.texts,
    this.style,
    this.scrambleStyle,
    this.textAlign = TextAlign.start,
    this.duration = 1.8,
    this.hold = 1.4,
    this.revealDelay = 0,
    this.curve = Curves.linear,
    this.charset = ScrambleCharset.upperCase,
    this.customChars,
    this.speed = 1.0,
    this.tweenLength = true,
    this.rightToLeft = false,
    this.perWord = false,
    this.loop = true,
    this.seed = 421,
    this.animate = true,
    this.frozenAt,
  }) : assert(duration > 0),
       assert(hold >= 0),
       assert(revealDelay >= 0),
       assert(speed > 0),
       assert(
         charset != ScrambleCharset.custom ||
             (customChars != null && customChars != ''),
         'charset: custom requires customChars',
       );

  /// Texts revealed one per cycle. A single item just decodes and holds
  /// (forever when [loop], once otherwise).
  final List<String> texts;

  /// Style of revealed characters. Defaults to the ambient
  /// [DefaultTextStyle].
  final TextStyle? style;

  /// Style of the still-scrambled tail (GSAP `newClass`/`oldClass`).
  /// Defaults to [style] at 45% opacity.
  final TextStyle? scrambleStyle;

  final TextAlign textAlign;

  /// Seconds for one reveal sweep (after [revealDelay]).
  final double duration;

  /// Seconds the fully revealed text stays before the next cycle.
  final double hold;

  /// Seconds of pure scrambling before anything reveals.
  final double revealDelay;

  /// Ease applied to the reveal boundary's travel.
  final Curve curve;

  final ScrambleCharset charset;

  /// Alphabet used when [charset] is [ScrambleCharset.custom].
  final String? customChars;

  /// Noise churn rate: the pool hops every `0.05 / speed` seconds (GSAP
  /// `speed`).
  final double speed;

  /// Morph the displayed length between texts of different sizes (GSAP
  /// `tweenLength`). When false the scrambled tail always pads to the target
  /// length.
  final bool tweenLength;

  /// Reveal from the right end instead (GSAP `rightToLeft`).
  final bool rightToLeft;

  /// Reveal whole words at once (GSAP `delimiter: " "`); noise stays
  /// per-character.
  final bool perWord;

  /// Cycle through [texts] forever. When false, stops revealed on the last
  /// text.
  final bool loop;

  /// Seed of the noise pools — same seed, same frames.
  final int seed;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  @override
  State<ScrambleText> createState() => _ScrambleTextState();
}

class _ScrambleTextState extends State<ScrambleText>
    with SingleTickerProviderStateMixin {
  static const int _poolCount = 20; // GSAP CharSet: 20 strings...
  static const int _poolMinLength = 80; // ...of 80 chars each.
  static const int _hopCycle = 512; // pre-rolled pool-hop sequence length

  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Duration? _lastTick;
  double _elapsedSeconds = 0;

  late List<String> _pools;
  late List<int> _poolHops;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
    _buildPools();
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

  String get _alphabet => switch (widget.charset) {
    ScrambleCharset.upperCase => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    ScrambleCharset.lowerCase => 'abcdefghijklmnopqrstuvwxyz',
    ScrambleCharset.upperAndLowerCase =>
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
    ScrambleCharset.custom => widget.customChars!,
  };

  void _buildPools() {
    final String alphabet = _alphabet;
    int longest = 0;
    for (final String text in widget.texts) {
      longest = math.max(longest, text.characters.length);
    }
    final int poolLength = math.max(_poolMinLength, longest + 8);
    final math.Random rng = math.Random(widget.seed);
    _pools = List<String>.generate(_poolCount, (_) {
      final StringBuffer buffer = StringBuffer();
      for (int i = 0; i < poolLength; i++) {
        buffer.write(alphabet[rng.nextInt(alphabet.length)]);
      }
      return buffer.toString();
    });
    // GSAP hops by a random stride each interval; pre-roll the visited pool
    // sequence so a frame at time t needs no mutable cursor.
    _poolHops = List<int>.generate(
      _hopCycle,
      (_) => rng.nextInt(_poolCount),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(ScrambleText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed ||
        oldWidget.charset != widget.charset ||
        oldWidget.customChars != widget.customChars ||
        !_sameTexts(oldWidget.texts, widget.texts)) {
      _buildPools();
    }
    _syncTicker();
  }

  static bool _sameTexts(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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

  // ---- sample(t): pure frame math ----------------------------------------

  /// Reveal units of [text]: grapheme clusters, or words when [perWord].
  static List<String> _units(String text, bool perWord) =>
      perWord ? text.split(' ') : text.characters.toList();

  ({String revealed, String scrambled, bool revealedFirst}) _sample(double t) {
    final List<String> texts = widget.texts;
    final double cycleDur = widget.revealDelay + widget.duration + widget.hold;
    int cycle = (t / cycleDur).floor();
    final int lastCycle = texts.length - 1;
    if (!widget.loop && cycle > lastCycle) cycle = lastCycle;
    final double local = widget.loop || cycle < lastCycle
        ? t - cycle * cycleDur
        : math.min(t - cycle * cycleDur, cycleDur);

    final String text = texts[cycle % texts.length];
    final String prevText = cycle == 0 ? '' : texts[(cycle - 1) % texts.length];

    // Reveal ratio: 0 while inside revealDelay, then eased over duration.
    final double ratio;
    if (local <= widget.revealDelay) {
      ratio = 0;
    } else {
      final double raw = ((local - widget.revealDelay) / widget.duration)
          .clamp(0.0, 1.0);
      ratio = widget.curve.transform(raw).clamp(0.0, 1.0);
    }

    final List<String> units = _units(text, widget.perWord);
    final int unitCount = units.length;
    // GSAP: i = ~~(ratio * l + 0.5)
    final int revealedUnits = math.min(
      unitCount,
      (ratio * unitCount + 0.5).floor(),
    );

    final String revealed;
    if (widget.perWord) {
      revealed = widget.rightToLeft
          ? units.sublist(unitCount - revealedUnits).join(' ')
          : units.sublist(0, revealedUnits).join(' ');
    } else {
      revealed = widget.rightToLeft
          ? units.sublist(unitCount - revealedUnits).join()
          : units.sublist(0, revealedUnits).join();
    }
    final int revealedChars = revealed.characters.length;

    // Displayed total length morphs cubically old -> new (GSAP tweenLength).
    final int targetLen = text.characters.length;
    final int prevLen = prevText.characters.length;
    final double displayed;
    if (widget.tweenLength && prevLen != targetLen) {
      final double k = 1 - math.pow(1 - ratio, 3).toDouble();
      displayed = prevLen + (targetLen - prevLen) * k;
    } else {
      displayed = targetLen.toDouble();
    }
    final int fillerCount = math.max(0, (displayed + 0.5).floor() -
        revealedChars);

    // Noise: pool hops every 0.05/speed seconds; window slides with the
    // reveal boundary so the tail keeps churning in place (GSAP substr(i2)).
    final String scrambled;
    if (fillerCount == 0 || ratio >= 1) {
      scrambled = '';
    } else {
      final double interval = 0.05 / widget.speed;
      final int hop = (t / interval).floor();
      final String pool = _pools[_poolHops[hop % _hopCycle]];
      final int start = widget.rightToLeft
          ? 0
          : math.min(revealedChars, pool.length - fillerCount);
      scrambled = pool.substring(
        math.max(0, start),
        math.max(0, start) + math.min(fillerCount, pool.length),
      );
    }

    return (
      revealed: revealed,
      scrambled: scrambled,
      revealedFirst: !widget.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final TextStyle base =
        DefaultTextStyle.of(context).style.merge(widget.style);
    final TextStyle noise = widget.scrambleStyle ??
        base.copyWith(
          color: (base.color ?? const Color(0xFFFFFFFF)).withValues(
            alpha: ((base.color?.a ?? 1.0) * 0.45).clamp(0.0, 1.0),
          ),
        );

    if (reducedMotion && widget.frozenAt == null) {
      // Motion off: show the final text plainly.
      return Text(widget.texts.last, style: base, textAlign: widget.textAlign);
    }

    return ValueListenableBuilder<double>(
      valueListenable: _time,
      builder: (context, liveTime, _) {
        final frame = _sample(widget.frozenAt ?? liveTime);
        final TextSpan revealedSpan = TextSpan(
          text: frame.revealed,
          style: base,
        );
        final TextSpan scrambledSpan = TextSpan(
          text: frame.scrambled,
          style: noise,
        );
        return Text.rich(
          TextSpan(
            children: frame.revealedFirst
                ? <TextSpan>[revealedSpan, scrambledSpan]
                : <TextSpan>[scrambledSpan, revealedSpan],
          ),
          textAlign: widget.textAlign,
        );
      },
    );
  }
}
