/// CopyButton
/// Origin: reimplemented — kinetics "Copy Button" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';

/// Copy-to-clipboard pill that confirms with a crossfade: the copy glyph
/// shrinks out, a green check springs in, the label swaps to "Copied", and
/// everything reverts after [revertDelay]. Re-tapping restarts the timer.
class CopyButton extends StatefulWidget {
  const CopyButton({
    super.key,
    required this.value,
    this.label = 'Copy',
    this.copiedLabel = 'Copied',
    this.revertDelay = const Duration(milliseconds: 1400),
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.foregroundColor = const Color(0xFFEDE9E0),
    this.okColor = const Color(0xFF4CD08A),
    this.onCopied,
    this.animate = true,
  });

  /// Text written to the clipboard.
  final String value;
  final String label;
  final String copiedLabel;
  final Duration revertDelay;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final Color okColor;
  final VoidCallback? onCopied;

  /// False applies the copied/idle states immediately (the revert timer
  /// still runs).
  final bool animate;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton>
    with SingleTickerProviderStateMixin {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  late final AnimationController _revert = AnimationController(
    vsync: this,
    duration: widget.revertDelay,
  );
  bool _copied = false;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    _revert.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  void didUpdateWidget(CopyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _revert.duration = widget.revertDelay;
  }

  @override
  void dispose() {
    _revert.dispose();
    super.dispose();
  }

  void _copy() {
    // Clipboard may be unavailable (e.g. some emulators) — still show the
    // feedback, like the original.
    Clipboard.setData(
      ClipboardData(text: widget.value),
    ).catchError((Object _) {});
    setState(() => _copied = true);
    _revert.forward(from: 0);
    widget.onCopied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Duration fadeDuration = _motionEnabled
        ? const Duration(milliseconds: 200)
        : Duration.zero;
    final Duration springDuration = _motionEnabled
        ? const Duration(milliseconds: 300)
        : Duration.zero;
    // Text/icon color swaps instantly in the original (only border-color and
    // the icon opacity/transform are in a transition list).
    final Color content = _copied ? widget.okColor : widget.foregroundColor;

    return Semantics(
      button: true,
      label: _copied ? widget.copiedLabel : widget.label,
      onTap: _copy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _copy,
        child: AnimatedContainer(
          duration: fadeDuration,
          curve: Curves.ease,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(
              color: _copied
                  ? widget.okColor.withValues(alpha: 0.45)
                  : widget.borderColor,
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: 18,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _icon(
                      visible: !_copied,
                      fadeDuration: fadeDuration,
                      springDuration: springDuration,
                      child: CustomPaint(painter: _CopyGlyphPainter(content)),
                    ),
                    _icon(
                      visible: _copied,
                      fadeDuration: fadeDuration,
                      springDuration: springDuration,
                      child: CustomPaint(
                        painter: _CheckGlyphPainter(widget.okColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Text(
                _copied ? widget.copiedLabel : widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// opacity 0.2s ease + scale 0.3s spring between 0.5 and 1 — the original
  /// `.copy-icon svg` transition pair.
  Widget _icon({
    required bool visible,
    required Duration fadeDuration,
    required Duration springDuration,
    required Widget child,
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: fadeDuration,
      curve: Curves.ease,
      child: AnimatedScale(
        scale: visible ? 1 : 0.5,
        duration: springDuration,
        curve: _spring,
        child: child,
      ),
    );
  }
}

/// The 24-viewBox copy glyph (back sheet corner + front rounded square).
class _CopyGlyphPainter extends CustomPainter {
  const _CopyGlyphPainter(this.color);

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
    canvas.drawRRect(
      RRect.fromLTRBR(9, 9, 20, 20, const Radius.circular(2)),
      paint,
    );
    final Path sheet = Path()
      ..moveTo(5, 15)
      ..lineTo(5, 5)
      ..arcToPoint(const Offset(7, 3), radius: const Radius.circular(2))
      ..lineTo(17, 3);
    canvas.drawPath(sheet, paint);
  }

  @override
  bool shouldRepaint(_CopyGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The 24-viewBox check polyline (5,12.5 → 10,17.5 → 19,7).
class _CheckGlyphPainter extends CustomPainter {
  const _CheckGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final Path check = Path()
      ..moveTo(5, 12.5)
      ..lineTo(10, 17.5)
      ..lineTo(19, 7);
    canvas.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
