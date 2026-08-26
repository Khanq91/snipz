/// PagePeel
/// Origin: reimplemented — kinetics "Page Peel" (Surface & Motion),
///   https://github.com/ckissi/kinetics — observed motion rebuilt in Flutter
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy this whole folder into another project and import it.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Imperative commands for a [PagePeel].
///
/// The widget owns its page state. The controller only sends commands and is
/// never disposed by [PagePeel], so its owner remains responsible for calling
/// [dispose]. Tapping the stack calls the same [next] behavior internally.
class PagePeelController extends ChangeNotifier {
  _PagePeelCommand _command = _PagePeelCommand.next;

  _PagePeelCommand get _latestCommand => _command;

  /// Peels the topmost page that has not yet been peeled.
  ///
  /// Calling this once every page is already peeled resets the entire stack,
  /// matching the original three-tap cycle for a two-page stack.
  void next() {
    _command = _PagePeelCommand.next;
    notifyListeners();
  }

  /// Resets every page immediately as a command; the visual return still uses
  /// the configured motion unless [PagePeel.animate] is false.
  void reset() {
    _command = _PagePeelCommand.reset;
    notifyListeners();
  }
}

enum _PagePeelCommand { next, reset }

/// A back-to-front stack whose top page turns around its left edge and fades.
///
/// Supply [pages] in paint order: the first widget is at the back and the last
/// widget is the initial front page. A tap peels the topmost unpeeled page.
/// After every page has been peeled, the next tap resets the whole stack.
class PagePeel extends StatefulWidget {
  const PagePeel({
    super.key,
    required this.pages,
    this.controller,
    this.width = 150,
    this.height = 110,
    this.initialPeeledCount = 0,
    this.tapToAdvance = true,
    this.animate = true,
    this.semanticsLabel = 'Page stack',
    this.onPeeledCountChanged,
    this.onReset,
  }) : assert(pages.length > 0, 'PagePeel needs at least one page.'),
       assert(width > 0),
       assert(height > 0),
       assert(initialPeeledCount >= 0),
       assert(initialPeeledCount <= pages.length);

  /// Pages ordered back to front. The last widget peels first.
  final List<Widget> pages;

  /// Optional external next/reset commands.
  final PagePeelController? controller;

  /// Stack dimensions. The source demo is exactly 150 × 110 logical pixels.
  final double width;
  final double height;

  /// Number of top pages already peeled when the widget is first mounted.
  final int initialPeeledCount;

  /// Whether tapping anywhere on the stack advances the cycle.
  final bool tapToAdvance;

  /// False applies peel and reset targets immediately without animation.
  final bool animate;

  /// Accessible label announced for the interactive stack.
  final String semanticsLabel;

  /// Called immediately after a peel or reset with a value from 0 to
  /// [pages.length]. Zero means the stack has reset.
  final ValueChanged<int>? onPeeledCountChanged;

  /// Called when a completed cycle (or [PagePeelController.reset]) resets.
  final VoidCallback? onReset;

  @override
  State<PagePeel> createState() => _PagePeelState();
}

class _PagePeelState extends State<PagePeel> with TickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 600);
  static const Curve _turnCurve = Cubic(0.65, 0, 0.35, 1);
  static const Curve _opacityCurve = Curves.ease;
  static const double _perspective = -1 / 1000;
  static const double _endAngle = -130 * math.pi / 180;
  static const double _endTranslation = -20;

  final List<AnimationController> _turns = <AnimationController>[];
  late int _peeledCount;
  bool _reduceMotion = false;

  bool get _motionEnabled => widget.animate && !_reduceMotion;

  @override
  void initState() {
    super.initState();
    _peeledCount = widget.initialPeeledCount;
    _createTurns();
    widget.controller?.addListener(_handleControllerCommand);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (_reduceMotion) _snapToState();
  }

  @override
  void didUpdateWidget(PagePeel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerCommand);
      widget.controller?.addListener(_handleControllerCommand);
    }
    if (oldWidget.pages.length != widget.pages.length) {
      _peeledCount = _clampCount(_peeledCount);
      _replaceTurns();
    } else if (oldWidget.animate && !widget.animate) {
      _snapToState();
    }
  }

  int _clampCount(int value) {
    if (value < 0) return 0;
    if (value > widget.pages.length) return widget.pages.length;
    return value;
  }

  bool _isPeeled(int index) =>
      index >= widget.pages.length - _peeledCount;

  void _createTurns() {
    for (int index = 0; index < widget.pages.length; index++) {
      _turns.add(
        AnimationController(
          vsync: this,
          duration: _duration,
          value: _isPeeled(index) ? 1 : 0,
        ),
      );
    }
  }

  void _replaceTurns() {
    for (final AnimationController turn in _turns) {
      turn.dispose();
    }
    _turns.clear();
    _createTurns();
  }

  void _snapToState() {
    for (int index = 0; index < _turns.length; index++) {
      _turns[index].value = _isPeeled(index) ? 1 : 0;
    }
  }

  void _handleControllerCommand() {
    switch (widget.controller?._latestCommand) {
      case _PagePeelCommand.next:
        _advance();
        break;
      case _PagePeelCommand.reset:
        _reset();
        break;
      case null:
        break;
    }
  }

  void _drive(AnimationController turn, {required bool peeled}) {
    if (!_motionEnabled) {
      turn.value = peeled ? 1 : 0;
    } else if (peeled) {
      turn.forward();
    } else {
      turn.reverse();
    }
  }

  void _advance() {
    if (_peeledCount == widget.pages.length) {
      _reset();
      return;
    }

    final int pageIndex = widget.pages.length - 1 - _peeledCount;
    setState(() => _peeledCount++);
    _drive(_turns[pageIndex], peeled: true);
    widget.onPeeledCountChanged?.call(_peeledCount);
  }

  void _reset() {
    if (_peeledCount == 0) return;
    setState(() => _peeledCount = 0);
    for (final AnimationController turn in _turns) {
      _drive(turn, peeled: false);
    }
    widget.onPeeledCountChanged?.call(0);
    widget.onReset?.call();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerCommand);
    for (final AnimationController turn in _turns) {
      turn.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: widget.tapToAdvance,
      label: widget.semanticsLabel,
      value: '$_peeledCount of ${widget.pages.length} pages peeled',
      onTap: widget.tapToAdvance ? _advance : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.tapToAdvance ? _advance : null,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: <Widget>[
              for (int index = 0; index < widget.pages.length; index++)
                _buildPage(index, widget.pages[index]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index, Widget page) {
    return AnimatedBuilder(
      animation: _turns[index],
      child: page,
      builder: (BuildContext context, Widget? child) {
        final double raw = _turns[index].value;
        final double turn = _turnCurve.transform(raw);
        final double angle = _endAngle * turn;
        final bool frontFacing = math.cos(angle) > 0;
        final double opacity = frontFacing
            ? (1 - _opacityCurve.transform(raw)).clamp(0.0, 1.0)
            : 0;
        final Matrix4 transform = Matrix4.identity()
          ..setEntry(3, 2, _perspective)
          ..rotateY(angle)
          ..translateByDouble(_endTranslation * turn, 0, 0, 1);

        final bool leaving = _isPeeled(index) || raw > 0;
        return ExcludeSemantics(
          excluding: leaving,
          child: IgnorePointer(
            ignoring: leaving,
            child: Opacity(
              opacity: opacity,
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: transform,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
