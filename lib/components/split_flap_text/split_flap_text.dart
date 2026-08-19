/// SplitFlapText
/// Origin: reimplemented — dựng lại "SplitFlapText" của react-bits
/// (CSS 3D keyframes) bằng Transform + một Ticker
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Airport departure-board text: a row of dark tiles, one character each,
/// that mechanically flip through [flipsPerChar] random characters before
/// landing on the target. Cycles through [words] every [cycleDelay], flips
/// staggered left to right. Only tiles whose character actually changes flip.
///
/// Stop/resume from outside via `GlobalKey<SplitFlapTextState>`
/// ([SplitFlapTextState.stop] / [SplitFlapTextState.start]).
class SplitFlapText extends StatefulWidget {
  const SplitFlapText({
    super.key,
    this.words = const <String>['LAUNCH READY', 'SYNC ONLINE', 'SIGNAL LIVE'],
    this.text,
    this.flipDuration = const Duration(milliseconds: 120),
    this.stagger = const Duration(milliseconds: 60),
    this.cycleDelay = const Duration(milliseconds: 2400),
    this.charset = alphanumeric,
    this.flipsPerChar = 8,
    this.tileColor = const Color(0xFF111827),
    this.textColor = const Color(0xFFF8FAFC),
    this.tileRadius = 8,
    this.gap = 6,
    this.fontSize = 52,
    this.loop = true,
    this.padTo = 12,
    this.autoPlay = true,
    this.textStyle,
  });

  static const String alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String alphanumeric = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const String numeric = '0123456789';

  /// Phrases to cycle through (uppercase reads best on the board).
  final List<String> words;

  /// Non-null: show just this phrase, no cycling ([words] is ignored).
  final String? text;

  /// One flap turn (one character step).
  final Duration flipDuration;

  /// Extra start delay per tile index (left → right ripple).
  final Duration stagger;

  /// Hold time on a settled phrase before the next one starts.
  final Duration cycleDelay;

  /// Pool the random in-between characters are drawn from
  /// ([alpha] / [alphanumeric] / [numeric] or any custom string).
  final String charset;

  /// Random characters shown before the target lands.
  final int flipsPerChar;

  final Color tileColor;
  final Color textColor;
  final double tileRadius;

  /// Horizontal space between tiles.
  final double gap;

  final double fontSize;

  /// False: stop after the last phrase instead of wrapping around.
  final bool loop;

  /// Minimum tile count; phrases are space-padded/truncated to the board
  /// width (the longest phrase wins if it is longer).
  final int padTo;

  /// False = board shows the first phrase and waits for
  /// [SplitFlapTextState.start].
  final bool autoPlay;

  /// Base style; size/color/monospace defaults still apply on top.
  final TextStyle? textStyle;

  @override
  State<SplitFlapText> createState() => SplitFlapTextState();
}

class _TileState {
  _TileState(this.current)
      : next = current,
        flipping = false,
        fraction = 0;

  String current;
  String next;
  bool flipping;

  /// Progress 0..1 inside the current flap turn.
  double fraction;
}

class _FlipPlan {
  _FlipPlan({
    required this.index,
    required this.from,
    required this.sequence,
    required this.startMs,
  });

  final int index;
  final String from;

  /// Random in-betweens plus the target as the last entry.
  final List<String> sequence;
  final double startMs;
  int step = -1;
  bool done = false;
}

class SplitFlapTextState extends State<SplitFlapText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _random = math.Random();
  Timer? _cycleTimer;
  List<_TileState> _tiles = <_TileState>[];
  List<_FlipPlan> _plans = <_FlipPlan>[];
  int _phraseIndex = 0;
  bool _running = false;

  List<String> get _phrases {
    final String? text = widget.text;
    final List<String> source = text != null
        ? <String>[text]
        : (widget.words.isEmpty ? const <String>[' '] : widget.words);
    final int width = _boardWidth(source);
    return <String>[
      for (final String p in source) p.padRight(width).substring(0, width),
    ];
  }

  int _boardWidth(List<String> source) {
    int longest = 1;
    for (final String p in source) {
      longest = math.max(longest, p.length);
    }
    return math.max(longest, math.max(widget.padTo, 1));
  }

  double get _flipMs =>
      math.max(widget.flipDuration.inMilliseconds.toDouble(), 40);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onFrame);
    _resetBoard();
    if (widget.autoPlay) {
      start();
    }
  }

  @override
  void didUpdateWidget(SplitFlapText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.words != widget.words ||
        oldWidget.text != widget.text ||
        oldWidget.padTo != widget.padTo) {
      stop();
      _resetBoard();
      if (widget.autoPlay) {
        start();
      }
    }
  }

  void _resetBoard() {
    _phraseIndex = 0;
    _plans = <_FlipPlan>[];
    _tiles = <_TileState>[
      for (final String c in _phrases.first.split('')) _TileState(c),
    ];
  }

  /// Resume (or begin) cycling through the phrases.
  void start() {
    if (_running || _phrases.length <= 1) {
      return;
    }
    _running = true;
    _scheduleNext(widget.cycleDelay);
  }

  /// Halt cycling; tiles finish their current turn visually frozen.
  void stop() {
    _running = false;
    _cycleTimer?.cancel();
    _cycleTimer = null;
    if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _scheduleNext(Duration delay) {
    _cycleTimer?.cancel();
    _cycleTimer = Timer(delay, () {
      if (!mounted || !_running) {
        return;
      }
      final int next = _phraseIndex + 1;
      if (next >= _phrases.length && !widget.loop) {
        _running = false;
        return;
      }
      _phraseIndex = next % _phrases.length;
      final double animMs = _animateTo(_phrases[_phraseIndex]);
      _scheduleNext(
        widget.cycleDelay + Duration(milliseconds: animMs.ceil()),
      );
    });
  }

  String _sampleChar() {
    final String set = widget.charset.isEmpty
        ? SplitFlapText.alphanumeric
        : widget.charset;
    return set[_random.nextInt(set.length)];
  }

  /// Builds the flip plans toward [target]; returns the total duration in ms.
  double _animateTo(String target) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      setState(() {
        _tiles = <_TileState>[
          for (final String c in target.split('')) _TileState(c),
        ];
      });
      return 0;
    }
    final double staggerMs =
        math.max(widget.stagger.inMilliseconds, 0).toDouble();
    final int flips = math.max(widget.flipsPerChar, 0);
    _plans = <_FlipPlan>[];
    for (int i = 0; i < _tiles.length; i++) {
      final String from = _tiles[i].current;
      final String to = i < target.length ? target[i] : ' ';
      if (from == to) {
        continue;
      }
      _plans.add(
        _FlipPlan(
          index: i,
          from: from,
          sequence: <String>[
            for (int f = 0; f < flips; f++) _sampleChar(),
            to,
          ],
          startMs: i * staggerMs,
        ),
      );
    }
    if (_plans.isEmpty) {
      return 0;
    }
    double total = 0;
    for (final _FlipPlan plan in _plans) {
      total = math.max(total, plan.startMs + plan.sequence.length * _flipMs);
    }
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _ticker.start();
    return total;
  }

  void _onFrame(Duration elapsed) {
    final double ms = elapsed.inMicroseconds / 1000;
    bool active = false;
    for (final _FlipPlan plan in _plans) {
      if (plan.done) {
        continue;
      }
      final double local = ms - plan.startMs;
      if (local < 0) {
        active = true;
        continue;
      }
      final int step = local ~/ _flipMs;
      final _TileState tile = _tiles[plan.index];
      if (step < plan.sequence.length) {
        active = true;
        if (step != plan.step) {
          plan.step = step;
          tile
            ..current = step == 0 ? plan.from : plan.sequence[step - 1]
            ..next = plan.sequence[step]
            ..flipping = true;
        }
        tile.fraction = (local - step * _flipMs) / _flipMs;
      } else {
        plan.done = true;
        tile
          ..current = plan.sequence.last
          ..next = plan.sequence.last
          ..flipping = false
          ..fraction = 0;
      }
    }
    setState(() {});
    if (!active) {
      _ticker.stop();
      _plans = <_FlipPlan>[];
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < _tiles.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: widget.gap),
          _FlapTile(
            tile: _tiles[i],
            fontSize: widget.fontSize,
            tileColor: widget.tileColor,
            textColor: widget.textColor,
            radius: widget.tileRadius,
            textStyle: widget.textStyle,
          ),
        ],
      ],
    );
  }
}

class _FlapTile extends StatelessWidget {
  const _FlapTile({
    required this.tile,
    required this.fontSize,
    required this.tileColor,
    required this.textColor,
    required this.radius,
    required this.textStyle,
  });

  final _TileState tile;
  final double fontSize;
  final Color tileColor;
  final Color textColor;
  final double radius;
  final TextStyle? textStyle;

  double get _w => fontSize * 0.78;

  double get _h => fontSize * 1.08;

  Widget _char(String c) {
    final TextStyle base = textStyle ?? const TextStyle();
    return SizedBox(
      width: _w,
      height: _h,
      child: Center(
        child: Text(
          c,
          style: base.copyWith(
            fontSize: fontSize,
            height: 1,
            color: textColor,
            fontWeight: FontWeight.w800,
            fontFamily: base.fontFamily ?? 'monospace',
            fontFamilyFallback: base.fontFamily != null
                ? base.fontFamilyFallback
                : const <String>['Courier', 'Roboto Mono'],
            shadows: <Shadow>[
              Shadow(
                offset: Offset(0, fontSize * 0.025),
                color: const Color(0x29FFFFFF),
              ),
              Shadow(
                offset: Offset(0, fontSize * 0.09),
                blurRadius: fontSize * 0.16,
                color: const Color(0x6B000000),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top or bottom half-crop of a full-tile character, with the half-specific
  /// sheen the CSS gradients give.
  Widget _half(String c, {required bool top, double shade = 0}) {
    return ClipRect(
      child: Align(
        alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5,
        child: Stack(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                  end: top ? Alignment.bottomCenter : Alignment.topCenter,
                  stops: const <double>[0, 0.36],
                  colors: <Color>[
                    Color.alphaBlend(const Color(0x12FFFFFF), tileColor),
                    top
                        ? tileColor
                        : Color.alphaBlend(const Color(0x14000000), tileColor),
                  ],
                ),
              ),
              child: _char(c),
            ),
            if (shade > 0)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: shade.clamp(0.0, 1.0)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _flap(String c, {required bool top, required double angle,
      required double shade}) {
    final Matrix4 matrix = Matrix4.identity()
      ..setEntry(3, 2, -1 / (_h * 9))
      ..rotateX(angle);
    return Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      child: Transform(
        transform: matrix,
        alignment: top ? Alignment.bottomCenter : Alignment.topCenter,
        child: _half(c, top: top, shade: shade),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double f = tile.fraction.clamp(0.0, 1.0);
    // cubic-bezier(.23,1,.32,1) of the original — sharply decelerating.
    final double eFront = Curves.easeOutQuart.transform(f);
    // Back flap holds folded for 45% of the turn, then unfolds.
    final double eBack = f < 0.45
        ? 0
        : Curves.easeOutQuart.transform((f - 0.45) / 0.55);

    return Container(
      width: _w,
      height: _h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x14FFFFFF)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            offset: Offset(0, _h * 0.15),
            blurRadius: _h * 0.35,
            color: const Color(0x47000000),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.alphaBlend(const Color(0x24FFFFFF), tileColor),
            tileColor,
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: _half(tile.current, top: true),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _half(tile.flipping ? tile.next : tile.current, top: false),
          ),
          if (tile.flipping) ...<Widget>[
            // Front flap: the old character's top half folding away.
            _flap(
              tile.current,
              top: true,
              angle: eFront * math.pi / 2,
              shade: 0.48 * eFront,
            ),
            // Back flap: the new character's bottom half unfolding down.
            _flap(
              tile.next,
              top: false,
              angle: -(1 - eBack) * math.pi / 2,
              shade: 0.42 * (1 - eBack),
            ),
          ],
          // Center split hairline.
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Color(0x00000000),
                    Color(0x2EFFFFFF),
                    Color(0xA3000000),
                    Color(0x24FFFFFF),
                    Color(0x00000000),
                  ],
                  stops: <double>[0, 0.18, 0.5, 0.82, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
