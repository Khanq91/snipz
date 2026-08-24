/// UndoSnackbar
/// Origin: reimplemented — kinetics "Undo Snackbar" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Timed undo bar: slides up from below with a spring, an amber progress
/// line drains linearly over three seconds, then the bar slides back out.
/// Increment [requestId] after a destructive action; a retrigger while the
/// bar is visible only restarts the drain (like the original — the bar does
/// not replay its slide). Motion follows CSS-transition semantics: the bar
/// animates toward its current target with the same spring bezier both ways.
class UndoSnackbar extends StatefulWidget {
  const UndoSnackbar({
    super.key,
    this.requestId = 0,
    this.message = 'Item deleted',
    this.undoLabel = 'Undo',
    this.width = 240,
    this.undoDuration = const Duration(milliseconds: 3000),
    this.backgroundColor = const Color(0xFF141417),
    this.borderColor = const Color(0xFF2A2A2E),
    this.textColor = const Color(0xFFEDE9E0),
    this.accentColor = const Color(0xFFFF8A00),
    this.onUndo,
    this.onDismissed,
    this.animate = true,
  });

  /// Change this value to show/retrigger the snackbar.
  final int requestId;
  final String message;
  final String undoLabel;
  final double width;
  final Duration undoDuration;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;
  final VoidCallback? onUndo;
  final VoidCallback? onDismissed;

  /// False renders a requested snackbar as a stable, full-progress frame.
  final bool animate;

  @override
  State<UndoSnackbar> createState() => _UndoSnackbarState();
}

class _UndoSnackbarState extends State<UndoSnackbar>
    with SingleTickerProviderStateMixin {
  /// CSS: transform 0.4s var(--spring) = cubic-bezier(0.34, 1.56, 0.64, 1).
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  late final AnimationController _life;
  bool _shown = false;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    _life = AnimationController(vsync: this, duration: widget.undoDuration)
      ..addStatusListener(_onLifeStatus);
    if (widget.requestId != 0) {
      _shown = true;
      if (widget.animate) _life.forward();
    }
  }

  @override
  void didUpdateWidget(UndoSnackbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.undoDuration != widget.undoDuration) {
      _life.duration = widget.undoDuration;
    }
    if (oldWidget.requestId != widget.requestId) _show();
    if (oldWidget.animate && !widget.animate && _shown) _life.stop();
  }

  void _onLifeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _dismiss();
  }

  /// Like the original click handler: restart the drain from full; the bar
  /// only slides in when it is not already on screen.
  void _show() {
    if (!_shown) setState(() => _shown = true);
    if (widget.animate) {
      _life.forward(from: 0);
    } else {
      _life
        ..stop()
        ..value = 0;
    }
  }

  void _undo() {
    widget.onUndo?.call();
    _dismiss();
  }

  void _dismiss() {
    if (!_shown) return;
    _life.stop();
    setState(() => _shown = false);
    // Without motion there is no exit transition to wait for.
    if (!_motionEnabled) widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _life.removeStatusListener(_onLifeStatus);
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 44,
      child: ClipRect(
        // 140% of the bar's own height, exactly the CSS transform.
        child: AnimatedSlide(
          offset: _shown ? Offset.zero : const Offset(0, 1.4),
          duration: _motionEnabled
              ? const Duration(milliseconds: 400)
              : Duration.zero,
          curve: _spring,
          onEnd: () {
            if (!_shown) widget.onDismissed?.call();
          },
          child: Semantics(
            liveRegion: true,
            label: widget.message,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border.all(color: widget.borderColor),
                borderRadius: BorderRadius.circular(9),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.textColor,
                              fontSize: 13,
                              height: 1.55,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Semantics(
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _undo,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                widget.undoLabel,
                                style: TextStyle(
                                  color: widget.accentColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // undo-drain: full width → zero, linear over undoDuration.
                  AnimatedBuilder(
                    animation: _life,
                    builder: (context, _) => Positioned(
                      left: 0,
                      bottom: 0,
                      width: widget.width * (1 - _life.value),
                      height: 2,
                      child: ColoredBox(color: widget.accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
