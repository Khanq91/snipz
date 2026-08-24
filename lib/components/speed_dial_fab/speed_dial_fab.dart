/// SpeedDialFab
/// Origin: reimplemented — kinetics "Speed-Dial FAB" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// One fanned-out action of a [SpeedDialFab].
class SpeedDialAction {
  const SpeedDialAction({required this.icon, this.onPressed, this.label});

  /// 18×18 glyph. [SpeedDialFab.defaultActions] shows the original three.
  final Widget icon;
  final VoidCallback? onPressed;

  /// Semantics label.
  final String? label;
}

/// FAB that fans out mini actions on a staggered spring when toggled: each
/// item springs from scale 0.4 at the FAB to its fanned position with a
/// per-item delay, while the + icon rotates 135° into a ×. Closing is
/// simultaneous (the original's transition-delay lives only on :checked).
class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({
    super.key,
    this.actions,
    this.fanOffsets = const <Offset>[
      Offset(-54, -58),
      Offset(0, -80),
      Offset(54, -58),
    ],
    this.initiallyOpen = false,
    this.mainSize = 54,
    this.itemSize = 40,
    this.mainColor = const Color(0xFFFF8A00),
    this.mainIconColor = const Color(0xFF0E0E10),
    this.itemColor = const Color(0xFF232326),
    this.itemBorderColor = const Color(0xFF2A2A2E),
    this.itemIconColor = const Color(0xFFEDE9E0),
    this.shadowColor = const Color(0xFFB36200),
    this.onOpenChanged,
    this.animate = true,
  });

  /// Defaults to the original share / edit / star trio.
  final List<SpeedDialAction>? actions;

  /// Where each item lands relative to the FAB center; extra actions beyond
  /// this list are ignored (the fan defines the effect).
  final List<Offset> fanOffsets;
  final bool initiallyOpen;
  final double mainSize;
  final double itemSize;
  final Color mainColor;
  final Color mainIconColor;
  final Color itemColor;
  final Color itemBorderColor;
  final Color itemIconColor;
  final Color shadowColor;
  final ValueChanged<bool>? onOpenChanged;

  /// False applies state changes immediately.
  final bool animate;

  static List<SpeedDialAction> get defaultActions => const <SpeedDialAction>[
    SpeedDialAction(icon: _GlyphIcon(_Glyph.share), label: 'Share'),
    SpeedDialAction(icon: _GlyphIcon(_Glyph.edit), label: 'Edit'),
    SpeedDialAction(icon: _GlyphIcon(_Glyph.star), label: 'Star'),
  ];

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab> {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);
  // Opening stagger of the three fan slots (transition-delay 0.02/0.07/0.12s).
  static const List<int> _delaysMs = <int>[20, 70, 120];

  late bool _open = widget.initiallyOpen;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  void _toggle() {
    setState(() => _open = !_open);
    widget.onOpenChanged?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    final List<SpeedDialAction> actions = (widget.actions ??
            SpeedDialFab.defaultActions)
        .take(widget.fanOffsets.length)
        .toList();

    return SizedBox(
      width: 150,
      height: 156,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int i = 0; i < actions.length; i++) _item(i, actions[i]),
          _mainButton(),
        ],
      ),
    );
  }

  /// The stagger is realized as an Interval prefix on the open transition
  /// only — closing runs plain, simultaneous, exactly like the CSS.
  Widget _item(int i, SpeedDialAction action) {
    final int delay = _delaysMs[i % _delaysMs.length];
    final Duration moveDuration = !_motionEnabled
        ? Duration.zero
        : Duration(milliseconds: _open ? 500 + delay : 500);
    final Duration fadeDuration = !_motionEnabled
        ? Duration.zero
        : Duration(milliseconds: _open ? 300 + delay : 300);
    final Curve moveCurve = _open
        ? Interval(delay / (500 + delay), 1, curve: _spring)
        : _spring;
    final Curve fadeCurve = _open
        ? Interval(delay / (300 + delay), 1, curve: Curves.ease)
        : Curves.ease;
    final Offset target = _open ? widget.fanOffsets[i] : Offset.zero;

    return Positioned(
      // Items rest 7px above the stage floor, stacked behind the FAB.
      bottom: 7,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(end: target),
        duration: moveDuration,
        curve: moveCurve,
        builder: (context, offset, child) =>
            Transform.translate(offset: offset, child: child),
        child: AnimatedScale(
          scale: _open ? 1 : 0.4,
          duration: moveDuration,
          curve: moveCurve,
          child: AnimatedOpacity(
            opacity: _open ? 1 : 0,
            duration: fadeDuration,
            curve: fadeCurve,
            child: Semantics(
              button: true,
              label: action.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _open ? action.onPressed : null,
                child: Container(
                  width: widget.itemSize,
                  height: widget.itemSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.itemColor,
                    border: Border.all(color: widget.itemBorderColor),
                  ),
                  child: SizedBox.square(
                    dimension: 18,
                    child: _tinted(action.icon, widget.itemIconColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mainButton() {
    return Semantics(
      button: true,
      expanded: _open,
      label: 'Toggle actions',
      onTap: _toggle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Container(
          width: widget.mainSize,
          height: widget.mainSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.mainColor,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.shadowColor,
                offset: const Offset(0, 8),
                blurRadius: 20,
                spreadRadius: -6,
              ),
            ],
          ),
          child: AnimatedRotation(
            turns: _open ? 135 / 360 : 0,
            duration: _motionEnabled
                ? const Duration(milliseconds: 450)
                : Duration.zero,
            curve: _spring,
            child: SizedBox.square(
              dimension: 24,
              child: CustomPaint(
                painter: _PlusPainter(widget.mainIconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tinted(Widget icon, Color color) {
    if (icon is _GlyphIcon) return _GlyphIcon(icon.glyph, color: color);
    return icon;
  }
}

enum _Glyph { share, edit, star }

/// The original card's three stroked 24-viewBox glyphs.
class _GlyphIcon extends StatelessWidget {
  const _GlyphIcon(this.glyph, {this.color = const Color(0xFFEDE9E0)});

  final _Glyph glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GlyphPainter(glyph, color));
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color);

  final _Glyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    switch (glyph) {
      case _Glyph.share:
        canvas.drawCircle(const Offset(18, 5), 3, paint);
        canvas.drawCircle(const Offset(6, 12), 3, paint);
        canvas.drawCircle(const Offset(18, 19), 3, paint);
        canvas.drawLine(const Offset(8.6, 13.5), const Offset(15.4, 17.5), paint);
        canvas.drawLine(const Offset(15.4, 6.5), const Offset(8.6, 10.5), paint);
      case _Glyph.edit:
        canvas.drawLine(const Offset(12, 20), const Offset(21, 20), paint);
        final Path pencil = Path()
          ..moveTo(16.5, 3.5)
          ..arcToPoint(const Offset(19.5, 6.5), radius: const Radius.circular(2.1))
          ..lineTo(7, 19)
          ..lineTo(3, 20)
          ..lineTo(4, 16)
          ..close();
        canvas.drawPath(pencil, paint);
      case _Glyph.star:
        final Path star = Path()
          ..moveTo(12, 2)
          ..lineTo(15, 9)
          ..lineTo(22, 9.3)
          ..lineTo(16.5, 14)
          ..lineTo(18.5, 21)
          ..lineTo(12, 17)
          ..lineTo(5.5, 21)
          ..lineTo(7.5, 14)
          ..lineTo(2, 9.3)
          ..lineTo(9, 9)
          ..close();
        canvas.drawPath(star, paint);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}

/// The + of the main button (stroke 2.4, rotates into a × when open).
class _PlusPainter extends CustomPainter {
  const _PlusPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawLine(const Offset(12, 5), const Offset(12, 19), paint);
    canvas.drawLine(const Offset(5, 12), const Offset(19, 12), paint);
  }

  @override
  bool shouldRepaint(_PlusPainter oldDelegate) => oldDelegate.color != color;
}
