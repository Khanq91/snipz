/// RevealList
/// Origin: reimplemented — dựng lại "Animated List" của react-bits cho
/// mobile: entrance scale+fade khi item lọt viewport, chọn bằng tap thay vì
/// arrow keys, edge fade theo vị trí scroll.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Scrollable list whose items pop in (scale 0.7→1, fade 0→1) the first time
/// they become ≥[visibleFraction] visible, with gradient fades hugging the
/// top/bottom edges while there is more content that way. Tap selects an
/// item; the current selection is handed back to [itemBuilder] for styling.
///
/// Each item reveals exactly once per list lifetime — scrolling away and
/// back does not replay it.
class RevealList extends StatefulWidget {
  const RevealList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onItemSelected,
    this.initialSelectedIndex = -1,
    this.controller,
    this.padding = const EdgeInsets.all(16),
    this.itemSpacing = 12,
    this.physics,
    this.shrinkWrap = false,
    this.showEdgeFades = true,
    this.edgeFadeColor,
    this.edgeFadeHeight = 90,
    this.entranceDuration = const Duration(milliseconds: 260),
    this.entranceStagger = const Duration(milliseconds: 80),
    this.visibleFraction = 0.5,
  });

  final int itemCount;

  /// Builds one item; `selected` reflects the current tap selection.
  final Widget Function(BuildContext context, int index, bool selected)
      itemBuilder;

  /// Fired when the user taps an item (after the selection updates).
  final ValueChanged<int>? onItemSelected;

  /// -1 = nothing selected initially.
  final int initialSelectedIndex;

  /// Optional external scroll controller; an internal one is created (and
  /// disposed) when null.
  final ScrollController? controller;

  final EdgeInsetsGeometry padding;

  /// Vertical gap between items.
  final double itemSpacing;

  final ScrollPhysics? physics;
  final bool shrinkWrap;

  /// Show the top/bottom scroll-hint gradients.
  final bool showEdgeFades;

  /// Color the edge gradients fade from — match the backdrop behind the
  /// list. Defaults to `Theme.of(context).scaffoldBackgroundColor`.
  final Color? edgeFadeColor;

  final double edgeFadeHeight;

  /// Length of one item's entrance animation.
  final Duration entranceDuration;

  /// Extra delay per item for the batch visible on first layout.
  final Duration entranceStagger;

  /// How much of an item must be inside the viewport to trigger its
  /// entrance (0..1).
  final double visibleFraction;

  @override
  State<RevealList> createState() => _RevealListState();
}

class _RevealListState extends State<RevealList> {
  ScrollController? _internalController;
  ScrollController get _controller =>
      widget.controller ?? (_internalController ??= ScrollController());

  final Set<_RevealItemState> _items = <_RevealItemState>{};
  final Set<int> _revealed = <int>{};
  final ValueNotifier<double> _topFade = ValueNotifier<double>(0);
  final ValueNotifier<double> _bottomFade = ValueNotifier<double>(0);
  late int _selected = widget.initialSelectedIndex;
  bool _sweepScheduled = false;
  bool _initialSweepDone = false;

  @override
  void dispose() {
    _internalController?.dispose();
    _topFade.dispose();
    _bottomFade.dispose();
    super.dispose();
  }

  void _register(_RevealItemState item) {
    _items.add(item);
    _scheduleSweep();
  }

  void _unregister(_RevealItemState item) => _items.remove(item);

  bool _wasRevealed(int index) => _revealed.contains(index);

  void _scheduleSweep() {
    if (_sweepScheduled) {
      return;
    }
    _sweepScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sweepScheduled = false;
      if (mounted) {
        _sweep();
      }
    });
  }

  /// Reveal every registered item that is sufficiently inside the viewport.
  void _sweep() {
    if (!_controller.hasClients) {
      return;
    }
    final ScrollPosition position = _controller.position;
    _updateFades(position);
    final double vpTop = position.pixels;
    final double vpBottom = vpTop + position.viewportDimension;
    final List<_RevealItemState> due = <_RevealItemState>[];
    for (final _RevealItemState item in _items) {
      if (item._revealed) {
        continue;
      }
      final RenderObject? ro = item.context.findRenderObject();
      if (ro is! RenderBox || !ro.attached || !ro.hasSize) {
        continue;
      }
      final RenderAbstractViewport? viewport =
          RenderAbstractViewport.maybeOf(ro);
      if (viewport == null) {
        continue;
      }
      final double itemTop = viewport.getOffsetToReveal(ro, 0).offset;
      final double itemBottom = itemTop + ro.size.height;
      final double overlap = (itemBottom.clamp(vpTop, vpBottom)) -
          (itemTop.clamp(vpTop, vpBottom));
      if (ro.size.height <= 0 ||
          overlap / ro.size.height >= widget.visibleFraction) {
        due.add(item);
      }
    }
    // Stagger only the batch visible on first layout; later scroll-triggered
    // reveals play immediately (they already arrive one by one).
    due.sort((a, b) => a.widget.index.compareTo(b.widget.index));
    for (int i = 0; i < due.length; i++) {
      _revealed.add(due[i].widget.index);
      due[i].reveal(
        delay: _initialSweepDone
            ? Duration.zero
            : widget.entranceStagger * i,
      );
    }
    _initialSweepDone = true;
  }

  void _updateFades(ScrollPosition position) {
    if (!widget.showEdgeFades) {
      return;
    }
    final double fromTop = position.pixels - position.minScrollExtent;
    final double fromBottom = position.maxScrollExtent - position.pixels;
    _topFade.value = (fromTop / 50).clamp(0.0, 1.0);
    _bottomFade.value = (fromBottom / 50).clamp(0.0, 1.0);
  }

  void _select(int index) {
    setState(() => _selected = index);
    widget.onItemSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final Widget list = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _sweep();
        return false;
      },
      child: ListView.separated(
        controller: _controller,
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        itemCount: widget.itemCount,
        separatorBuilder: (_, _) => SizedBox(height: widget.itemSpacing),
        itemBuilder: (context, index) => _RevealItem(
          index: index,
          list: this,
          duration: widget.entranceDuration,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _select(index),
            child: widget.itemBuilder(context, index, index == _selected),
          ),
        ),
      ),
    );
    if (!widget.showEdgeFades) {
      return list;
    }
    final Color fade =
        widget.edgeFadeColor ?? Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      children: <Widget>[
        Positioned.fill(child: list),
        _EdgeFade(
          top: true,
          color: fade,
          height: widget.edgeFadeHeight,
          opacity: _topFade,
        ),
        _EdgeFade(
          top: false,
          color: fade,
          height: widget.edgeFadeHeight,
          opacity: _bottomFade,
        ),
      ],
    );
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade({
    required this.top,
    required this.color,
    required this.height,
    required this.opacity,
  });

  final bool top;
  final Color color;
  final double height;
  final ValueListenable<double> opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: ValueListenableBuilder<double>(
          valueListenable: opacity,
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                end: top ? Alignment.bottomCenter : Alignment.topCenter,
                colors: <Color>[color, color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealItem extends StatefulWidget {
  const _RevealItem({
    required this.index,
    required this.list,
    required this.duration,
    required this.child,
  });

  final int index;
  final _RevealListState list;
  final Duration duration;
  final Widget child;

  @override
  State<_RevealItem> createState() => _RevealItemState();
}

class _RevealItemState extends State<_RevealItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    // Items the list already revealed once stay visible when the ListView
    // recycles and rebuilds them.
    value: widget.list._wasRevealed(widget.index) ? 1 : 0,
  );
  late CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  late bool _revealed = widget.list._wasRevealed(widget.index);

  @override
  void initState() {
    super.initState();
    widget.list._register(this);
  }

  void reveal({Duration delay = Duration.zero}) {
    if (_revealed) {
      return;
    }
    _revealed = true;
    if (delay > Duration.zero) {
      // Fold the stagger delay into the controller's timeline instead of a
      // Timer, so no timers outlive the animation (host widget tests stay
      // clean).
      final Duration total = delay + widget.duration;
      _controller.duration = total;
      _curve.dispose();
      setState(() {
        _curve = CurvedAnimation(
          parent: _controller,
          curve: Interval(
            delay.inMicroseconds / total.inMicroseconds,
            1,
            curve: Curves.easeOutBack,
          ),
        );
      });
    }
    _controller.forward();
  }

  @override
  void dispose() {
    widget.list._unregister(this);
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.7, end: 1).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
