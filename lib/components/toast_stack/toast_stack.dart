/// ToastStack
/// Origin: reimplemented — kinetics "Toast Stack" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// A bottom-anchored stack of transient status pills. Change [pushId] to add
/// a toast; at most [maxToasts] active items are kept and every live item
/// dismisses itself after [displayDuration].
class ToastStack extends StatefulWidget {
  const ToastStack({
    super.key,
    this.pushId = 0,
    this.messageBuilder,
    this.initialMessages = const <String>[],
    this.maxToasts = 3,
    this.width = 200,
    this.height = 130,
    this.gap = 6,
    this.displayDuration = const Duration(milliseconds: 2400),
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.textColor = const Color(0xFFEDE9E0),
    this.dotColor = const Color(0xFF4CD08A),
    this.onDismissed,
    this.animate = true,
  }) : assert(maxToasts >= 1);

  /// Change this value to push a toast. Zero is reserved for "no request".
  final int pushId;

  /// Defaults to `Saved #<pushId>`.
  final String Function(int pushId)? messageBuilder;

  /// Stable entries rendered on mount. Primarily useful for previews and
  /// state boards; when [animate] is false they remain indefinitely.
  final List<String> initialMessages;
  final int maxToasts;
  final double width;
  final double height;
  final double gap;
  final Duration displayDuration;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color dotColor;
  final ValueChanged<int>? onDismissed;

  /// False disables motion and auto-dismiss, producing a stable stack.
  final bool animate;

  @override
  State<ToastStack> createState() => _ToastStackState();
}

class _ToastStackState extends State<ToastStack> with TickerProviderStateMixin {
  static const Curve _spring = Cubic(0.18, 1.25, 0.4, 1);

  final List<_ToastEntry> _entries = <_ToastEntry>[];
  bool _handledInitialRequest = false;

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  bool get _motionEnabled => widget.animate && !_reducedMotion;

  @override
  void initState() {
    super.initState();
    int index = 0;
    for (final String message in widget.initialMessages.take(
      widget.maxToasts,
    )) {
      index++;
      _entries.add(_createEntry(-index, message, staticEntry: true));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_handledInitialRequest) {
      _handledInitialRequest = true;
      if (widget.pushId != 0) _push(widget.pushId);
    } else if (_reducedMotion) {
      for (final _ToastEntry entry in _entries.where(
        (entry) => !entry.exiting,
      )) {
        entry.enter.value = 1;
        entry.opacity.value = 1;
      }
    }
  }

  @override
  void didUpdateWidget(ToastStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pushId != widget.pushId && widget.pushId != 0) {
      _push(widget.pushId);
    }
    if (oldWidget.animate && !widget.animate) {
      for (final _ToastEntry entry in _entries) {
        entry.life.stop();
        entry.enter.value = 1;
        entry.opacity.value = 1;
        entry.exit.value = 0;
        entry.exiting = false;
      }
    }
    _enforceLimit();
  }

  _ToastEntry _createEntry(int id, String message, {bool staticEntry = false}) {
    final _ToastEntry entry = _ToastEntry(
      id: id,
      message: message,
      enter: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
      opacity: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
      exit: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
      life: AnimationController(vsync: this, duration: widget.displayDuration),
    );
    entry.life.addStatusListener((status) {
      if (status == AnimationStatus.completed) _beginExit(entry);
    });
    if (staticEntry) {
      entry.enter.value = 1;
      entry.opacity.value = 1;
    }
    return entry;
  }

  void _push(int pushId) {
    final String message =
        widget.messageBuilder?.call(pushId) ?? 'Saved #$pushId';
    final _ToastEntry entry = _createEntry(pushId, message);
    setState(() => _entries.add(entry));
    _enforceLimit();

    if (_motionEnabled) {
      entry.enter.forward(from: 0);
      entry.opacity.forward(from: 0);
    } else {
      entry.enter.value = 1;
      entry.opacity.value = 1;
    }
    if (widget.animate) entry.life.forward(from: 0);
  }

  void _enforceLimit() {
    final List<_ToastEntry> active = _entries
        .where((entry) => !entry.exiting)
        .toList();
    final int overflow = active.length - widget.maxToasts;
    for (int i = 0; i < overflow; i++) {
      _beginExit(active[i]);
    }
  }

  void _beginExit(_ToastEntry entry) {
    if (entry.exiting || !_entries.contains(entry)) return;
    entry.exiting = true;
    entry.life.stop();
    if (mounted) setState(() {});

    if (!_motionEnabled) {
      _remove(entry);
      return;
    }
    Future.wait<void>(<Future<void>>[
      entry.exit.forward(from: 0),
      entry.opacity.reverse(),
    ]).then((_) {
      if (mounted && _entries.contains(entry)) _remove(entry);
    });
  }

  void _remove(_ToastEntry entry) {
    if (!_entries.remove(entry)) return;
    final int id = entry.id;
    entry.dispose();
    if (mounted) setState(() {});
    widget.onDismissed?.call(id);
  }

  @override
  void dispose() {
    for (final _ToastEntry entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < _entries.length; i++) ...<Widget>[
                if (i > 0) SizedBox(height: widget.gap),
                _toast(_entries[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _toast(_ToastEntry entry) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        entry.enter,
        entry.opacity,
        entry.exit,
      ]),
      builder: (context, child) {
        final double entered = _spring.transform(entry.enter.value);
        final double exiting = _spring.transform(entry.exit.value);
        return Opacity(
          opacity: Curves.ease.transform(entry.opacity.value),
          child: Transform.translate(
            offset: Offset(0, 20 * exiting),
            child: FractionalTranslation(
              translation: Offset(0, 1 - entered),
              child: Transform.scale(
                scale: 0.9 + 0.1 * entered - 0.1 * exiting,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Semantics(
        liveRegion: true,
        label: entry.message,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: widget.borderColor),
            // --radius-sm of the original design system.
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.dotColor,
                ),
                child: const SizedBox.square(dimension: 7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToastEntry {
  _ToastEntry({
    required this.id,
    required this.message,
    required this.enter,
    required this.opacity,
    required this.exit,
    required this.life,
  });

  final int id;
  final String message;
  final AnimationController enter;
  final AnimationController opacity;
  final AnimationController exit;
  final AnimationController life;
  bool exiting = false;

  void dispose() {
    enter.dispose();
    opacity.dispose();
    exit.dispose();
    life.dispose();
  }
}
