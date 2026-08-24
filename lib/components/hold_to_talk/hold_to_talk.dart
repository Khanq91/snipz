/// HoldToTalk
/// Origin: reimplemented — kinetics "Hold to Talk" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/widgets.dart';

/// Visual phase of a [HoldToTalk] control.
enum HoldToTalkPhase { idle, live, sent }

/// Hold-to-talk control: idle bars sit almost flat; pressing springs them
/// into a staggered live waveform while a ring blooms around the button;
/// releasing collapses the bars with a spring, flashes SENT, then settles
/// back to rest. The waveform is the state — this is voice capture, not a
/// confirm-hold ring.
class HoldToTalk extends StatefulWidget {
  const HoldToTalk({
    super.key,
    this.label = 'hold to talk',
    this.sentLabel = 'SENT',
    this.sentHold = const Duration(milliseconds: 900),
    this.pinnedPhase,
    this.barColor = const Color(0xFFFF8A00),
    this.sentColor = const Color(0xFF4CD08A),
    this.buttonColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.textColor = const Color(0xFFEDE9E0),
    this.liveTextColor = const Color(0xFF0E0E10),
    this.onSent,
    this.animate = true,
  });

  final String label;
  final String sentLabel;

  /// How long the SENT flash shows before returning to rest.
  final Duration sentHold;

  /// Pins the visual phase (previews/state boards). Null = press-driven.
  /// A pinned live phase renders one deterministic waveform frame.
  final HoldToTalkPhase? pinnedPhase;
  final Color barColor;
  final Color sentColor;
  final Color buttonColor;
  final Color borderColor;
  final Color textColor;
  final Color liveTextColor;

  /// Fired when a hold is released (the capture "commits").
  final VoidCallback? onSent;

  /// False freezes the waveform loop and applies state changes immediately.
  final bool animate;

  @override
  State<HoldToTalk> createState() => _HoldToTalkState();
}

class _HoldToTalkState extends State<HoldToTalk>
    with TickerProviderStateMixin {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);
  static const int _barCount = 7;
  // animation-duration per bar: outer bars roll slowest, the center fastest.
  static const List<double> _periods = <double>[
    0.52, 0.34, 0.26, 0.20, 0.26, 0.34, 0.52,
  ];

  HoldToTalkPhase _phase = HoldToTalkPhase.idle;
  late final Ticker _ticker = createTicker((elapsed) {
    _liveT.value = elapsed.inMicroseconds / 1e6;
  });
  final ValueNotifier<double> _liveT = ValueNotifier<double>(0);

  /// Bar scales captured at the last phase change; the settle controller
  /// springs from them to the new resting value (the CSS 0.4s transition).
  List<double> _barsFrom = List<double>.filled(_barCount, 0.12);
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 1,
  );
  late final AnimationController _sentTimer = AnimationController(
    vsync: this,
    duration: widget.sentHold,
  );

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  HoldToTalkPhase get _shownPhase => widget.pinnedPhase ?? _phase;

  @override
  void initState() {
    super.initState();
    _sentTimer.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _changePhase(HoldToTalkPhase.idle);
      }
    });
  }

  @override
  void didUpdateWidget(HoldToTalk oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sentTimer.duration = widget.sentHold;
    if (oldWidget.animate && !widget.animate && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _liveT.dispose();
    _settle.dispose();
    _sentTimer.dispose();
    super.dispose();
  }

  /// Triangle-wave "alternate" cycle through ease-in-out, 0.18..1 — the
  /// original talk-bar keyframes.
  double _wave(int i, double t) {
    final double cycle = (t / _periods[i]) % 2;
    final double raw = cycle < 1 ? cycle : 2 - cycle;
    return 0.18 + 0.82 * Curves.easeInOut.transform(raw);
  }

  double _barScale(int i) {
    switch (_shownPhase) {
      case HoldToTalkPhase.live:
        if (widget.pinnedPhase == HoldToTalkPhase.live || !_motionEnabled) {
          return _wave(i, 0.25); // one deterministic frame
        }
        return _wave(i, _liveT.value);
      case HoldToTalkPhase.sent:
      case HoldToTalkPhase.idle:
        final double target = _shownPhase == HoldToTalkPhase.sent
            ? 0.18
            : 0.12;
        final double t = _spring.transform(_settle.value);
        return lerpDouble(_barsFrom[i], target, t)!;
    }
  }

  void _changePhase(HoldToTalkPhase next) {
    _barsFrom = List<double>.generate(_barCount, _barScale);
    setState(() => _phase = next);
    if (next == HoldToTalkPhase.live) {
      _liveT.value = 0;
      if (_motionEnabled) _ticker.start();
    } else {
      if (_ticker.isActive) _ticker.stop();
      if (_motionEnabled) {
        _settle.forward(from: 0);
      } else {
        _settle.value = 1;
      }
    }
  }

  void _start() {
    if (widget.pinnedPhase != null) return;
    _sentTimer.stop();
    _changePhase(HoldToTalkPhase.live);
  }

  void _commit() {
    if (widget.pinnedPhase != null || _phase != HoldToTalkPhase.live) return;
    _changePhase(HoldToTalkPhase.sent);
    _sentTimer.forward(from: 0);
    widget.onSent?.call();
  }

  @override
  Widget build(BuildContext context) {
    final HoldToTalkPhase phase = _shownPhase;
    final bool live = phase == HoldToTalkPhase.live;
    final bool sent = phase == HoldToTalkPhase.sent;
    final Duration colorDuration = _motionEnabled
        ? const Duration(milliseconds: 250)
        : Duration.zero;
    final Duration springDuration = _motionEnabled
        ? const Duration(milliseconds: 350)
        : Duration.zero;
    final Duration ringDuration = _motionEnabled
        ? const Duration(milliseconds: 450)
        : Duration.zero;

    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 42,
            width: (_barCount * 4) + (_barCount - 1) * 4,
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_liveT, _settle]),
              builder: (context, _) => CustomPaint(
                painter: _WavePainter(
                  scales: List<double>.generate(_barCount, _barScale),
                  color: sent ? widget.sentColor : widget.barColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: widget.label,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _start(),
              onPointerUp: (_) => _commit(),
              onPointerCancel: (_) => _commit(),
              child: AnimatedScale(
                scale: live ? 0.96 : 1,
                duration: springDuration,
                curve: _spring,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    // The bloom ring (inset -6, springs from 0.86).
                    Positioned.fill(
                      left: -6,
                      right: -6,
                      top: -6,
                      bottom: -6,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: live ? 1 : 0,
                          duration: springDuration,
                          curve: Curves.ease,
                          child: AnimatedScale(
                            scale: live ? 1 : 0.86,
                            duration: ringDuration,
                            curve: _spring,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: widget.barColor.withValues(
                                    alpha: 0.7,
                                  ),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: colorDuration,
                      curve: Curves.ease,
                      constraints: const BoxConstraints(
                        minWidth: 132,
                        minHeight: 40,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: live ? widget.barColor : widget.buttonColor,
                        border: Border.all(
                          color: live
                              ? widget.barColor
                              : sent
                              ? widget.sentColor.withValues(alpha: 0.55)
                              : widget.borderColor,
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: colorDuration,
                        curve: Curves.ease,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.24,
                          color: live
                              ? widget.liveTextColor
                              : sent
                              ? widget.sentColor
                              : widget.textColor,
                        ),
                        child: Text(widget.label),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 12,
            child: AnimatedSlide(
              offset: sent ? Offset.zero : const Offset(0, 4 / 12),
              duration: _motionEnabled
                  ? const Duration(milliseconds: 400)
                  : Duration.zero,
              curve: _spring,
              child: AnimatedOpacity(
                opacity: sent ? 1 : 0,
                duration: _motionEnabled
                    ? const Duration(milliseconds: 300)
                    : Duration.zero,
                curve: Curves.ease,
                child: Text(
                  widget.sentLabel,
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.26,
                    color: widget.sentColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4×36 rounded bars, gap 4, scaling from their vertical center.
class _WavePainter extends CustomPainter {
  const _WavePainter({required this.scales, required this.color});

  final List<double> scales;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double centerY = size.height / 2;
    for (int i = 0; i < scales.length; i++) {
      final double h = 36 * scales[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 8.0, centerY - h / 2, 4, h),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.scales != scales;
}
