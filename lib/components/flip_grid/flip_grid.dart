/// FlipGrid
/// Origin: reimplemented — kỹ thuật FLIP của GSAP Flip plugin (v3.15),
///   https://github.com/greensock/GSAP/blob/master/src/Flip.js — mô hình
///   capture → mutate → invert → play, onEnter/onLeave cho item vào/ra,
///   spin, stagger từ tâm hành động; dựng lại analytic, không copy code.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// FLIP grid: lọc / xáo / đưa lên đầu — mọi thay đổi layout đều là item
/// LƯỚT từ chỗ cũ sang chỗ mới thay vì nhảy. Item bị lọc mất thì fade-thu
/// tại chỗ (onLeave), item xuất hiện thì nở ra ở đích (onEnter), delay lan
/// từ nơi hành động ra xa kiểu stagger `from: center`. Idle tự chạy kịch
/// bản lọc/xáo cho gallery sống ([autoDemo], dừng hẳn khi user chạm).
class FlipGrid extends StatefulWidget {
  const FlipGrid({
    super.key,
    this.itemCount = 12,
    this.palette = const <Color>[
      Color(0xFF8B7CFF),
      Color(0xFF4DD0A6),
      Color(0xFFFF8A65),
      Color(0xFF64B5F6),
      Color(0xFFFFD54F),
      Color(0xFFF06292),
    ],
    this.moveDuration = 0.55,
    this.staggerAmount = 0.22,
    this.spinOnShuffle = true,
    this.autoDemo = true,
    this.seed = 99,
    this.onItemTap,
    this.animate = true,
    this.frozenAt,
  }) : assert(itemCount > 0),
       assert(moveDuration > 0),
       assert(staggerAmount >= 0);

  final int itemCount;

  /// Card colors; the category of item i is `i % 3` (Alpha/Beta/Gamma).
  final List<Color> palette;

  /// Seconds a card takes to glide to its new slot.
  final double moveDuration;

  /// Total extra delay spread across cards by distance from the action
  /// (GSAP stagger `from: center`-style).
  final double staggerAmount;

  /// Shuffle adds a full 360° to gliding cards (GSAP Flip `spin`).
  final bool spinOnShuffle;

  /// Scripted filter/shuffle cycle until the user first touches.
  final bool autoDemo;

  /// Seed of the deterministic shuffles.
  final int seed;

  final ValueChanged<int>? onItemTap;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the resting initial grid (no ticker). This component is
  /// interaction-driven, so the frozen frame is the static layout.
  final double? frozenAt;

  @override
  State<FlipGrid> createState() => _FlipGridState();
}

enum _FlipKind { move, enter, leave }

class _FlipItem {
  const _FlipItem({
    required this.id,
    required this.kind,
    required this.from,
    required this.to,
    required this.delay,
    required this.duration,
    required this.spin,
  });

  final int id;
  final _FlipKind kind;
  final Rect from;
  final Rect to;
  final double delay;
  final double duration;
  final bool spin;
}

class _FlipGridState extends State<FlipGrid>
    with SingleTickerProviderStateMixin {
  static const List<String> _filters = <String>['All', 'Alpha', 'Beta', 'Gamma'];
  static const double _demoFirstAt = 1.4;
  static const double _demoEvery = 2.9;

  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Duration? _lastTick;
  double _elapsedSeconds = 0;

  /// Master order of ALL item ids (mutated by shuffle/promote).
  late List<int> _master = List<int>.generate(widget.itemCount, (i) => i);
  int _filter = 0; // index into _filters; 0 = all
  int _shuffles = 0;
  int _demoFired = 0;
  bool _touched = false;

  /// Active transition (null when resting).
  List<_FlipItem>? _flips;
  double _flipStart = 0;
  double _flipTotal = 0;

  Size _area = Size.zero;
  int _cols = 3;
  double _cellW = 0;
  double _cellH = 0;
  static const double _pad = 16;
  static const double _gap = 10;
  static const double _chipsH = 52;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
  }

  void _handleTick(Duration elapsed) {
    final Duration previous = _lastTick ?? Duration.zero;
    _lastTick = elapsed;
    final double delta = ((elapsed - previous).inMicroseconds / 1000000)
        .clamp(0.0, 0.064)
        .toDouble();
    _elapsedSeconds += delta;
    _maybeAutoAct(_elapsedSeconds);
    if (_flips != null &&
        _elapsedSeconds - _flipStart > _flipTotal) {
      _flips = null; // transition finished — rest on the target layout
    }
    _time.value = _elapsedSeconds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(FlipGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _master = List<int>.generate(widget.itemCount, (i) => i);
      _flips = null;
      _filter = 0;
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
    super.dispose();
  }

  // ---- layout math --------------------------------------------------------

  int _categoryOf(int id) => id % 3;

  List<int> get _visible => _filter == 0
      ? List<int>.of(_master)
      : <int>[
          for (final int id in _master)
            if (_categoryOf(id) == _filter - 1) id,
        ];

  void _measure(Size size) {
    _area = size;
    _cols = math.max(3, ((size.width - _pad * 2) / 104).floor());
    _cellW = (size.width - _pad * 2 - (_cols - 1) * _gap) / _cols;
    _cellH = _cellW * 0.86;
  }

  Rect _slotRect(int index) {
    final int r = index ~/ _cols;
    final int c = index % _cols;
    return Rect.fromLTWH(
      _pad + c * (_cellW + _gap),
      _chipsH + _pad / 2 + r * (_cellH + _gap),
      _cellW,
      _cellH,
    );
  }

  /// Where every id sits RIGHT NOW (interpolated mid-transition) — the FLIP
  /// "getState" capture.
  Map<int, Rect> _captureRects(double t) {
    final Map<int, Rect> rects = <int, Rect>{};
    final List<int> visible = _visible;
    for (int i = 0; i < visible.length; i++) {
      rects[visible[i]] = _slotRect(i);
    }
    final List<_FlipItem>? flips = _flips;
    if (flips != null) {
      for (final _FlipItem f in flips) {
        rects[f.id] = _rectOfFlip(f, t);
      }
    }
    return rects;
  }

  Rect _rectOfFlip(_FlipItem f, double t) {
    final double p = _flipProgress(f, t);
    return Rect.lerp(f.from, f.to, Curves.easeInOutCubic.transform(p))!;
  }

  double _flipProgress(_FlipItem f, double t) {
    final double local = t - _flipStart - f.delay;
    if (local <= 0) return 0;
    return math.min(1, local / f.duration);
  }

  // ---- actions (the F-L-I-P sequence) -------------------------------------

  /// Capture old rects → mutate state via [mutate] → diff into move/enter/
  /// leave items with distance-staggered delays from [origin].
  void _flipTo(void Function() mutate, {Offset? origin, bool spin = false}) {
    final double t = _elapsedSeconds;
    final Map<int, Rect> before = _captureRects(t);
    final Set<int> wasVisible = _visible.toSet();
    mutate();
    final List<int> nowVisible = _visible;
    final Map<int, Rect> after = <int, Rect>{
      for (int i = 0; i < nowVisible.length; i++) nowVisible[i]: _slotRect(i),
    };

    final Offset from = origin ??
        Offset(_area.width / 2, (_chipsH + _area.height) / 2);
    double maxDist = 1;
    final Map<int, double> dists = <int, double>{};
    for (final MapEntry<int, Rect> e in after.entries) {
      final double d = (e.value.center - from).distance;
      dists[e.key] = d;
      maxDist = math.max(maxDist, d);
    }

    final List<_FlipItem> flips = <_FlipItem>[];
    double total = 0;
    for (final int id in nowVisible) {
      final Rect to = after[id]!;
      final double delay =
          widget.staggerAmount * ((dists[id] ?? 0) / maxDist);
      if (!wasVisible.contains(id) || !before.containsKey(id)) {
        // onEnter: pop in at the destination.
        final _FlipItem f = _FlipItem(
          id: id,
          kind: _FlipKind.enter,
          from: to,
          to: to,
          delay: 0.16 + delay,
          duration: 0.4,
          spin: false,
        );
        flips.add(f);
        total = math.max(total, f.delay + f.duration);
      } else if (before[id] != to) {
        final _FlipItem f = _FlipItem(
          id: id,
          kind: _FlipKind.move,
          from: before[id]!,
          to: to,
          delay: delay,
          duration: widget.moveDuration,
          spin: spin,
        );
        flips.add(f);
        total = math.max(total, f.delay + f.duration);
      }
    }
    for (final int id in wasVisible) {
      if (!after.containsKey(id)) {
        // onLeave: fade-shrink where it stood.
        final _FlipItem f = _FlipItem(
          id: id,
          kind: _FlipKind.leave,
          from: before[id]!,
          to: before[id]!,
          delay: 0,
          duration: 0.3,
          spin: false,
        );
        flips.add(f);
        total = math.max(total, f.duration);
      }
    }

    setState(() {
      _flips = flips;
      _flipStart = t;
      _flipTotal = total;
    });
  }

  void _setFilter(int f, {bool byUser = true}) {
    if (f == _filter) return;
    if (byUser) _touched = true;
    _flipTo(() => _filter = f);
  }

  void _shuffle({bool byUser = true}) {
    if (byUser) _touched = true;
    final math.Random rng = math.Random(widget.seed + _shuffles);
    _shuffles++;
    _flipTo(
      () => _master.shuffle(rng),
      spin: widget.spinOnShuffle,
    );
  }

  void _promote(int id, Offset origin) {
    _touched = true;
    widget.onItemTap?.call(id);
    _flipTo(
      () => _master
        ..remove(id)
        ..insert(0, id),
      origin: origin,
    );
  }

  void _maybeAutoAct(double t) {
    if (!widget.autoDemo || _touched) return;
    if (t < _demoFirstAt + _demoFired * _demoEvery) return;
    final int step = _demoFired % 4;
    _demoFired++;
    switch (step) {
      case 0:
        _setFilter(1 + (_demoFired ~/ 4) % 3, byUser: false);
      case 1:
        _setFilter(0, byUser: false);
      case 2:
        _shuffle(byUser: false);
      case 3:
        _setFilter(0, byUser: false); // no-op keeps rhythm honest
    }
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _measure(constraints.biggest);
        return ColoredBox(
          color: const Color(0xFF0E0E10),
          child: ValueListenableBuilder<double>(
            valueListenable: _time,
            builder: (context, liveTime, _) {
              final double t = widget.frozenAt != null ? -1 : liveTime;
              final List<Widget> cards = <Widget>[];
              final List<int> visible = _visible;
              final Set<int> inFlight = <int>{
                if (_flips != null && t >= 0)
                  for (final _FlipItem f in _flips!) f.id,
              };
              for (int i = 0; i < visible.length; i++) {
                final int id = visible[i];
                if (inFlight.contains(id)) continue;
                cards.add(_card(id, _slotRect(i), 1, 1, 0));
              }
              if (_flips != null && t >= 0) {
                for (final _FlipItem f in _flips!) {
                  final double p = _flipProgress(f, t);
                  switch (f.kind) {
                    case _FlipKind.move:
                      final Rect r = _rectOfFlip(f, t);
                      final double angle = f.spin
                          ? 2 *
                                math.pi *
                                Curves.easeInOutCubic.transform(p)
                          : 0;
                      cards.add(_card(f.id, r, 1, 1, angle));
                    case _FlipKind.enter:
                      final double e = Curves.easeOutBack.transform(p);
                      cards.add(
                        _card(f.id, f.to, 0.72 + 0.28 * e, p, 0),
                      );
                    case _FlipKind.leave:
                      final double e = Curves.easeIn.transform(p);
                      cards.add(
                        _card(f.id, f.from, 1 - 0.3 * e, 1 - e, 0),
                      );
                  }
                }
              }
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  ...cards,
                  _chipRow(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _chipRow() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: _chipsH,
      child: ColoredBox(
        color: const Color(0xFF0E0E10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              for (int f = 0; f < _filters.length; f++) ...[
                GestureDetector(
                  onTap: () => _setFilter(f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _filter == f
                          ? const Color(0xFF8B7CFF).withValues(alpha: 0.22)
                          : const Color(0xFF1A1A21),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _filter == f
                            ? const Color(0xFF8B7CFF)
                            : const Color(0xFF2A2A33),
                      ),
                    ),
                    child: Text(
                      _filters[f],
                      style: TextStyle(
                        color: _filter == f
                            ? const Color(0xFFEDEAFF)
                            : const Color(0xFF9A9AA8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: _shuffle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A21),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF2A2A33)),
                  ),
                  child: const Icon(
                    Icons.shuffle,
                    size: 16,
                    color: Color(0xFF9A9AA8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(int id, Rect rect, double scale, double opacity, double angle) {
    final Color color = widget.palette[id % widget.palette.length];
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTapUp: (d) => _promote(id, rect.center),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.7)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 10,
                      top: 8,
                      child: Text(
                        '${id + 1}',
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
