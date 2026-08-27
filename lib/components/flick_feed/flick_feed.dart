/// FlickFeed
/// Origin: reimplemented — các luật "feel" scroll của GSAP ScrollTrigger +
///   InertiaPlugin + VelocityTracker (v3.15), https://github.com/greensock/GSAP
///   — snap theo đà có hướng (hằng số power3 0.18549), fastScrollEnd (2500
///   px/s), preventOverlaps, anticipate lookahead, tracker vận tốc 2 mẫu
///   (throttle 0.05s / zero 0.2s). Feed demo là original.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// GSAP inertia constants (same closed form as the inertia_throw component —
// duplicated here on purpose: vault components must be self-contained).
const double _checkPoint = 0.05;
const double _checkPointRatio = 0.18549375; // 1 - 0.95^4

/// power3.out — the ease GSAP solves its momentum against.
class _Power3Out extends Curve {
  const _Power3Out();

  @override
  double transformInternal(double t) {
    final double q = 1 - t;
    return 1 - q * q * q * q;
  }
}

/// GSAP's two-sample velocity tracker (utils/VelocityTracker.js): samples at
/// most every 0.05s, rotates a sample only when the value changed OR 0.2s
/// passed — fast to react, slow to zero, so sluggish event streams still
/// read real velocity while a genuine stop reads 0.
class _GsapVelocityTracker {
  double _v1 = 0, _t1 = 0, _v2 = 0, _t2 = 0;
  bool _seeded = false;

  void reset(double value, double now) {
    _v1 = _v2 = value;
    _t1 = _t2 = now;
    _seeded = true;
  }

  void update(double value, double now) {
    if (!_seeded) {
      reset(value, now);
      return;
    }
    if (now - _t1 < _checkPoint) return; // ~20 Hz — per-frame is too noisy
    if (value != _v1 || now - _t1 > 0.2) {
      _v2 = _v1;
      _t2 = _t1;
      _v1 = value;
      _t1 = now;
    }
  }

  /// px/s over the last ~50–200ms window.
  double velocity(double value, double now) {
    if (!_seeded || now - _t2 < 1e-6) return 0;
    return (value - _v2) / (now - _t2);
  }
}

/// One reveal (per section): plays on enter, resets when scrolled back out
/// below — so every rule can be felt repeatedly.
class _Reveal {
  double progress = 0;
  bool playing = false;
  double playStart = 0;
}

/// Marker set for the HUD: where the flick would land naturally vs where the
/// snap chose to go.
class _SnapMark {
  const _SnapMark(this.naturalPx, this.targetPx, this.at);

  final double naturalPx;
  final double targetPx;
  final double at;
}

/// A vertical story feed that demonstrates four GSAP scroll "feel" rules on
/// real content, with a **RULES ON/OFF** toggle so the difference is felt,
/// not read about:
///
/// 1. **Momentum-directional snap** — on release, the natural landing point
///    is solved in closed form from the flick velocity (GSAP inertia:
///    `duration = |v|/resistance`, `change = duration·0.05·v/0.18549`), the
///    nearest section top **in the direction of travel** is chosen, and a
///    `power3.out` tween whose duration is solved from the velocity takes
///    over. A hard flick skips sections; it never snaps backwards.
/// 2. **fastScrollEnd** — sections blown past faster than
///    [fastScrollThreshold] complete their reveal instantly instead of
///    animating behind your back.
/// 3. **preventOverlaps** — when a section starts revealing, still-running
///    reveals of trailing sections force-complete so animations never fight.
/// 4. **anticipate** — the floating chapter pill triggers at
///    `offset + velocity × anticipate` so listener-driven UI (which is
///    always one frame late in Flutter) appears on time during fast flings.
///
/// The bottom HUD plots live velocity, the predicted natural landing (hollow
/// marker) and the chosen snap target (filled marker) on a mini scroll map.
class FlickFeed extends StatefulWidget {
  const FlickFeed({
    super.key,
    this.sectionCount = 8,
    this.sectionExtent = 300,
    this.rulesOn = true,
    this.showHud = true,
    this.resistance = 400,
    this.snapDelay = 0.12,
    this.snapMinDuration = 0.1,
    this.snapMaxDuration = 2.0,
    this.fastScrollThreshold = 2500,
    this.anticipate = 0.12,
    this.revealDuration = 0.8,
    this.accent = const Color(0xFF8B7CFF),
    this.onSectionSnapped,
    this.animate = true,
    this.frozenAt,
  }) : assert(sectionCount > 1),
       assert(sectionExtent > 120),
       assert(resistance > 0),
       assert(snapDelay >= 0),
       assert(snapMinDuration > 0 && snapMaxDuration >= snapMinDuration),
       assert(fastScrollThreshold > 0),
       assert(anticipate >= 0),
       assert(revealDuration > 0);

  final int sectionCount;

  /// Fixed height of one section — snap targets are its multiples.
  final double sectionExtent;

  /// Initial state of the RULES toggle (still switchable in the UI).
  final bool rulesOn;

  /// Bottom mini-map with velocity + landing markers.
  final bool showHud;

  /// px/s of flick velocity traded for one second of natural travel
  /// (GSAP inertia `resistance`; mobile-tuned default).
  final double resistance;

  /// Seconds after release before the snap tween takes over
  /// (GSAP `snap.delay`).
  final double snapDelay;

  /// Snap tween duration clamp — GSAP `snap.duration: {min: 0.1, max: 2}`.
  final double snapMinDuration;
  final double snapMaxDuration;

  /// px/s above which passed sections jump straight to their revealed state
  /// (GSAP `fastScrollEnd` default 2500).
  final double fastScrollThreshold;

  /// Velocity lookahead (seconds) for the floating chapter pill
  /// (GSAP `anticipatePin`, reinterpreted for listener-driven state).
  final double anticipate;

  /// Seconds of one section reveal — deliberately slow so the rules are
  /// visible.
  final double revealDuration;

  final Color accent;

  /// Fired when a snap tween settles on a section.
  final ValueChanged<int>? onSectionSnapped;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the resting top-of-feed frame (visible reveals completed, no
  /// ticker). Gesture-driven component — the frozen frame is static.
  final double? frozenAt;

  @override
  State<FlickFeed> createState() => _FlickFeedState();
}

class _FlickFeedState extends State<FlickFeed>
    with SingleTickerProviderStateMixin {
  static const double _headerExtent = 108;
  static const Curve _power3Out = _Power3Out();

  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Duration? _lastTick;
  double _elapsedSeconds = 0;

  final ScrollController _scroll = ScrollController();
  final _GsapVelocityTracker _tracker = _GsapVelocityTracker();
  late List<_Reveal> _reveals;
  late bool _rulesOn = widget.rulesOn;

  bool _fingerDown = false;
  bool _snapping = false;
  double? _pendingSnapAt; // ticker time to fire the scheduled snap
  double _pendingSnapVelocity = 0;
  double _velocity = 0;
  _SnapMark? _mark;
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
    _reveals = List<_Reveal>.generate(widget.sectionCount, (_) => _Reveal());
  }

  void _handleTick(Duration elapsed) {
    final Duration previous = _lastTick ?? Duration.zero;
    _lastTick = elapsed;
    final double delta = ((elapsed - previous).inMicroseconds / 1000000)
        .clamp(0.0, 0.064)
        .toDouble();
    _elapsedSeconds += delta;
    final double t = _elapsedSeconds;

    if (_scroll.hasClients) {
      final double px = _scroll.position.pixels;
      _tracker.update(px, t);
      _velocity = _tracker.velocity(px, t);
      _updateReveals(px, t);
      _maybeFirePendingSnap(t);
    }
    _time.value = t;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(FlickFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionCount != widget.sectionCount) {
      _reveals = List<_Reveal>.generate(widget.sectionCount, (_) => _Reveal());
    }
    _syncTicker();
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
    _scroll.dispose();
    super.dispose();
  }

  // ---- geometry -----------------------------------------------------------

  double _sectionTopPx(int i) => _headerExtent + i * widget.sectionExtent;

  double get _maxScroll =>
      _scroll.hasClients ? _scroll.position.maxScrollExtent : 0;

  // ---- reveals: play-on-enter, reset-on-leave-back ------------------------

  void _updateReveals(double px, double t) {
    final double vh = _viewport.height;
    if (vh <= 0) return;
    final bool fast =
        _rulesOn && _velocity.abs() > widget.fastScrollThreshold;
    for (int i = 0; i < _reveals.length; i++) {
      final _Reveal r = _reveals[i];
      final double top = _sectionTopPx(i) - px; // viewport-relative

      if (r.playing) {
        r.progress = math.min(1, (t - r.playStart) / widget.revealDuration);
        if (r.progress >= 1) r.playing = false;
      }

      // fastScrollEnd: blown past above while moving fast → done, instantly.
      if (fast && top < -widget.sectionExtent * 0.2 && r.progress < 1) {
        r.progress = 1;
        r.playing = false;
      }

      // Enter: top edge crosses 82% of the viewport → play once.
      if (top < vh * 0.82 && r.progress == 0 && !r.playing) {
        r.playing = true;
        r.playStart = t;
        if (_rulesOn) _preventOverlaps(i);
      }

      // Leave back: fully below the viewport again → reset for a re-run.
      if (top > vh && (r.progress > 0 || r.playing)) {
        r.progress = 0;
        r.playing = false;
      }
    }
  }

  /// preventOverlaps: the freshly-starting section force-completes trailing
  /// reveals (behind it, relative to scroll direction).
  void _preventOverlaps(int starting) {
    final bool downward = _velocity >= 0;
    for (int i = 0; i < _reveals.length; i++) {
      final bool trailing = downward ? i < starting : i > starting;
      if (trailing && _reveals[i].playing) {
        _reveals[i].progress = 1;
        _reveals[i].playing = false;
      }
    }
  }

  // ---- momentum-directional snap ------------------------------------------

  bool _onScrollNotification(ScrollNotification n) {
    if (widget.frozenAt != null) return false;
    if (n is ScrollStartNotification) {
      if (n.dragDetails != null) {
        _fingerDown = true;
        _pendingSnapAt = null; // a new touch cancels any scheduled snap
        _snapping = false;
      }
    } else if (n is ScrollUpdateNotification) {
      if (_fingerDown && n.dragDetails == null) {
        // Finger just lifted — the ballistic phase begins. Schedule the
        // snap takeover (GSAP snap.delay).
        _fingerDown = false;
        _scheduleSnap();
      }
    } else if (n is ScrollEndNotification) {
      _fingerDown = false;
      if (_snapping) {
        _snapping = false;
        _notifySettled();
      } else if (_rulesOn && _pendingSnapAt == null) {
        // Drifted to a stop between sections (slow release) → quick settle.
        _pendingSnapVelocity = 0;
        _pendingSnapAt = _elapsedSeconds;
      }
    }
    return false;
  }

  void _scheduleSnap() {
    if (!_rulesOn) return;
    _pendingSnapVelocity = _velocity;
    _pendingSnapAt = _elapsedSeconds + widget.snapDelay;
  }

  void _maybeFirePendingSnap(double t) {
    final double? at = _pendingSnapAt;
    if (at == null || t < at || _fingerDown || !_rulesOn) return;
    _pendingSnapAt = null;
    _performSnap(_pendingSnapVelocity);
  }

  void _performSnap(double v) {
    if (!_scroll.hasClients) return;
    final double px = _scroll.position.pixels;

    // Natural landing, closed form (GSAP inertia).
    final double naturalDur = (v.abs() / widget.resistance).clamp(0.25, 2.0);
    final double naturalEnd =
        (px + naturalDur * _checkPoint * v / _checkPointRatio)
            .clamp(0.0, _maxScroll);

    // Candidate targets = section tops (+ the very top of the feed).
    final List<double> targets = <double>[
      0,
      for (int i = 0; i < widget.sectionCount; i++)
        math.min(_sectionTopPx(i), _maxScroll),
    ];

    // Directional: with real velocity, only consider targets ahead of the
    // CURRENT position in the direction of travel (GSAP `directional`).
    final bool hasDirection = v.abs() > 20;
    List<double> pool = targets;
    if (hasDirection) {
      pool = <double>[
        for (final double c in targets)
          if (v > 0 ? c >= px - 1 : c <= px + 1) c,
      ];
      if (pool.isEmpty) pool = targets;
    }
    double target = pool.first;
    for (final double c in pool) {
      if ((c - naturalEnd).abs() < (target - naturalEnd).abs()) target = c;
    }

    // Tween duration solved from velocity and distance
    // (GSAP _calculateDuration), with the "snapping should feel quick"
    // clamp when there is barely any speed.
    final double dist = (target - px).abs();
    if (dist < 1) {
      _notifySettled();
      return;
    }
    double dur;
    if (v.abs() < 40) {
      dur = widget.snapMinDuration +
          (widget.snapMaxDuration - widget.snapMinDuration) * 0.1;
    } else {
      dur = (dist * _checkPointRatio / v.abs() / _checkPoint)
          .clamp(widget.snapMinDuration, widget.snapMaxDuration);
    }

    _mark = _SnapMark(naturalEnd, target, _elapsedSeconds);
    _snapping = true;
    final bool reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion) {
      _scroll.jumpTo(target);
      _snapping = false;
      _notifySettled();
    } else {
      _scroll.animateTo(
        target,
        duration: Duration(milliseconds: (dur * 1000).round()),
        curve: _power3Out,
      );
    }
  }

  void _notifySettled() {
    final double px = _scroll.position.pixels;
    final int i = ((px - _headerExtent) / widget.sectionExtent).round();
    if (i >= 0 && i < widget.sectionCount &&
        (_sectionTopPx(i) - px).abs() < 2) {
      widget.onSectionSnapped?.call(i);
    }
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        final bool frozen = widget.frozenAt != null;
        return ColoredBox(
          color: const Color(0xFF0E0E10),
          child: ValueListenableBuilder<double>(
            valueListenable: _time,
            builder: (context, t, _) {
              final double px =
                  !frozen && _scroll.hasClients ? _scroll.position.pixels : 0;
              return IgnorePointer(
                ignoring: frozen,
                child: _stack(px, t, frozen),
              );
            },
          ),
        );
      },
    );
  }

  Widget _stack(double px, double t, bool frozen) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: SingleChildScrollView(
            controller: _scroll,
            physics: frozen
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                for (int i = 0; i < widget.sectionCount; i++)
                  _section(i, frozen),
                SizedBox(height: _viewport.height * 0.35),
              ],
            ),
          ),
        ),
        _chapterPill(px),
        if (widget.showHud && !frozen) _hud(px, t),
        _rulesToggle(),
      ],
    );
  }

  Widget _header() {
    // Right inset reserves room for the floating RULES toggle, but must
    // collapse gracefully at thumbnail widths.
    final double rightInset = math.min(120, _viewport.width * 0.3);
    return Container(
      height: _headerExtent,
      padding: EdgeInsets.fromLTRB(18, 18, rightInset, 0),
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'FLICK FEED',
              maxLines: 1,
              style: TextStyle(
                color: Color(0xFFF2F2F5),
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Flick hard, flick soft — toggle the rules.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFF2F2F5).withValues(alpha: 0.45),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Reveal channels: hero scales/fades in, headline bars slide from the
  /// left, the accent underline grows. All driven by one eased progress.
  Widget _section(int i, bool frozen) {
    final double raw;
    if (frozen) {
      // Static frame: whatever fits the initial viewport reads as revealed.
      raw = _sectionTopPx(i) < _viewport.height * 0.82 ? 1 : 0;
    } else {
      raw = _reveals[i].progress;
    }
    final double e = Curves.easeOutCubic.transform(raw);
    final Color tint = HSLColor.fromColor(widget.accent)
        .withHue(
          (HSLColor.fromColor(widget.accent).hue + i * 26) % 360,
        )
        .toColor();

    return SizedBox(
      height: widget.sectionExtent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Opacity(
                opacity: 0.25 + 0.75 * e,
                child: Transform.scale(
                  scale: 0.94 + 0.06 * e,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tint.withValues(alpha: 0.55),
                          tint.withValues(alpha: 0.18),
                        ],
                      ),
                      border: Border.all(color: tint.withValues(alpha: 0.5)),
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: tint,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Transform.translate(
              offset: Offset(-36 * (1 - e), 0),
              child: Opacity(
                opacity: e,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: 170, height: 15, color: const Color(0xFFE8E8EE)),
                    const SizedBox(height: 7),
                    _bar(
                      width: 110,
                      height: 11,
                      color: const Color(0xFFE8E8EE).withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
            _bar(width: 54 * e + 2, height: 4, color: tint),
          ],
        ),
      ),
    );
  }

  Widget _bar({
    required double width,
    required double height,
    required Color color,
  }) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );

  /// The anticipate demo: listener-driven state is one frame late by nature;
  /// with rules on the trigger reads `px + v·anticipate` so the pill (and
  /// its chapter number) keeps up with a fast fling.
  Widget _chapterPill(double px) {
    final double lookahead =
        _rulesOn ? px + _velocity * widget.anticipate : px;
    final double threshold = _headerExtent + widget.sectionExtent * 0.6;
    final bool shown = lookahead > threshold;
    final int chapter = ((lookahead - _headerExtent) / widget.sectionExtent)
            .floor()
            .clamp(0, widget.sectionCount - 1) +
        1;
    return Positioned(
      top: 12,
      left: 18,
      child: AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(0, -1.6),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A21).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: widget.accent.withValues(alpha: 0.6)),
            ),
            child: Text(
              'Section $chapter / ${widget.sectionCount}',
              style: const TextStyle(
                color: Color(0xFFEDEAFF),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rulesToggle() => Positioned(
    top: 12,
    right: 14,
    child: GestureDetector(
      onTap: () => setState(() => _rulesOn = !_rulesOn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: _rulesOn
              ? widget.accent.withValues(alpha: 0.24)
              : const Color(0xFF1A1A21),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _rulesOn ? widget.accent : const Color(0xFF3A3A44),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _rulesOn ? Icons.bolt : Icons.bolt_outlined,
              size: 15,
              color: _rulesOn ? const Color(0xFFEDEAFF) : const Color(0xFF9A9AA8),
            ),
            const SizedBox(width: 5),
            Text(
              _rulesOn ? 'RULES ON' : 'RULES OFF',
              style: TextStyle(
                color: _rulesOn
                    ? const Color(0xFFEDEAFF)
                    : const Color(0xFF9A9AA8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// Mini scroll map: ticks per section, playhead, hollow natural-landing
  /// marker + filled chosen-target marker (fading ~1.2s), live velocity.
  Widget _hud(double px, double t) => Positioned(
    left: 14,
    right: 14,
    bottom: 12,
    child: IgnorePointer(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF16161C).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A33)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'v ${_velocity.round()} px/s',
              style: TextStyle(
                color: _velocity.abs() > widget.fastScrollThreshold
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFF8C8C99),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 14,
              child: CustomPaint(
                painter: _HudPainter(
                  scroll: px,
                  maxScroll: math.max(1, _maxScroll),
                  sectionTops: <double>[
                    for (int i = 0; i < widget.sectionCount; i++)
                      _sectionTopPx(i),
                  ],
                  mark: _mark,
                  now: t,
                  accent: widget.accent,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HudPainter extends CustomPainter {
  const _HudPainter({
    required this.scroll,
    required this.maxScroll,
    required this.sectionTops,
    required this.mark,
    required this.now,
    required this.accent,
  });

  final double scroll;
  final double maxScroll;
  final List<double> sectionTops;
  final _SnapMark? mark;
  final double now;
  final Color accent;

  double _x(double px, Size size) =>
      (px / maxScroll).clamp(0.0, 1.0) * size.width;

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..color = const Color(0xFF2E2E38)
        ..strokeWidth = 2,
    );
    final Paint tick = Paint()..color = const Color(0xFF4A4A56);
    for (final double top in sectionTops) {
      final double x = _x(top, size);
      canvas.drawLine(Offset(x, midY - 4), Offset(x, midY + 4), tick..strokeWidth = 1.5);
    }
    // Snap markers linger 1.2s: hollow = natural landing, filled = chosen.
    final _SnapMark? m = mark;
    if (m != null && now - m.at < 1.2) {
      final double fade = 1 - (now - m.at) / 1.2;
      canvas.drawCircle(
        Offset(_x(m.naturalPx, size), midY),
        4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF8C8C99).withValues(alpha: fade),
      );
      canvas.drawCircle(
        Offset(_x(m.targetPx, size), midY),
        4,
        Paint()..color = accent.withValues(alpha: fade),
      );
    }
    // Playhead.
    canvas.drawCircle(
      Offset(_x(scroll, size), midY),
      3,
      Paint()..color = const Color(0xFFF2F2F5),
    );
  }

  @override
  bool shouldRepaint(_HudPainter oldDelegate) =>
      oldDelegate.scroll != scroll ||
      oldDelegate.now != now ||
      oldDelegate.mark != mark;
}
