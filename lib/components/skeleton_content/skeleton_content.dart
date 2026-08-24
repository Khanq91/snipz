/// SkeletonContent
/// Origin: reimplemented — kinetics "Skeleton to Content" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Skeleton loading card that resolves into real content: a shimmering
/// avatar + two text bars (1.4s ease-in-out gradient sweep) fade out when
/// [loaded] flips true, while the real avatar/name/meta fade in with a small
/// upward glide (0.4s `cubic-bezier(0.16, 1, 0.3, 1)`). Controlled: the
/// parent owns the `loaded` state; the shimmer ticker stops once loaded.
class SkeletonContent extends StatefulWidget {
  const SkeletonContent({
    super.key,
    required this.loaded,
    this.onTap,
    this.name = 'Ada Lovelace',
    this.meta = 'Analytical Engine',
    this.initial = 'K',
    this.width = 220,
    this.baseColor = const Color(0xFF232326),
    this.highlightColor = const Color(0xFF34343A),
    this.avatarColors = const <Color>[Color(0xFFFF8A00), Color(0xFFB36200)],
    this.nameColor = const Color(0xFFEDE9E0),
    this.metaColor = const Color(0xFF6E6C68),
    this.initialColor = const Color(0xFF0E0E10),
    this.animate = true,
    this.frozenAt,
  });

  /// False: shimmering skeleton. True: real content. Animate by flipping it.
  final bool loaded;

  /// Tap on the whole card (the original toggles `loaded` on click).
  final VoidCallback? onTap;

  final String name;
  final String meta;

  /// Letter inside the resolved avatar.
  final String initial;

  final double width;

  /// Skeleton gradient: base and moving highlight.
  final Color baseColor;
  final Color highlightColor;

  /// Resolved avatar 135° gradient (kinetics amber → deep amber).
  final List<Color> avatarColors;

  final Color nameColor;
  final Color metaColor;
  final Color initialColor;

  /// False freezes the shimmer ticker (viewer freeze / reduced motion).
  final bool animate;

  /// Non-null renders the shimmer at exactly t seconds — no ticker.
  final double? frozenAt;

  @override
  State<SkeletonContent> createState() => _SkeletonContentState();
}

class _SkeletonContentState extends State<SkeletonContent>
    with SingleTickerProviderStateMixin {
  static const double _period = 1.4;
  static const Curve _glide = Cubic(0.16, 1, 0.3, 1);

  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker =
        createTicker((elapsed) => _t.value = elapsed.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(SkeletonContent old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  void _syncTicker() {
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // Loaded skeleton is invisible — no reason to keep shimmering.
    final bool run = widget.animate &&
        widget.frozenAt == null &&
        !widget.loaded &&
        !reduced;
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget card = SizedBox(
      width: widget.width,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: <Widget>[
          // Skeleton row — fades out 0.3s ease on load.
          AnimatedOpacity(
            opacity: widget.loaded ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
            child: _skeletonRow(),
          ),
          // Real row — fades in + glides up 8px, 0.4s glide bezier.
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: widget.loaded ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              curve: _glide,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: widget.loaded ? 0 : 8),
                duration: const Duration(milliseconds: 400),
                curve: _glide,
                builder: (context, dy, child) =>
                    Transform.translate(offset: Offset(0, dy), child: child),
                child: IgnorePointer(child: _realRow()),
              ),
            ),
          ),
        ],
      ),
    );
    if (widget.onTap == null) return card;
    return GestureDetector(onTap: widget.onTap, child: card);
  }

  Widget _skeletonRow() {
    return ValueListenableBuilder<double>(
      valueListenable: _t,
      builder: (context, live, _) {
        final double t = widget.frozenAt ?? live;
        return Row(
          children: <Widget>[
            _shimmerBox(t, const Size(40, 40), circle: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _shimmerBox(t, const Size(double.infinity, 10)),
                  const SizedBox(height: 6),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: _shimmerBox(t, const Size(double.infinity, 10)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _shimmerBox(double t, Size size, {bool circle = false}) {
    return SizedBox(
      width: size.width.isFinite ? size.width : null,
      height: size.height,
      child: CustomPaint(
        painter: _ShimmerPainter(
          t: t,
          circle: circle,
          baseColor: widget.baseColor,
          highlightColor: widget.highlightColor,
          period: _period,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _realRow() {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.avatarColors,
            ),
          ),
          child: Text(
            widget.initial,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: widget.initialColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.nameColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: widget.metaColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kinetics `shimmer-sweep`: a 200%-wide gradient (base 25%, highlight 50%,
/// base 75%) whose background-position runs 200% → -200% eased in-out.
class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.t,
    required this.circle,
    required this.baseColor,
    required this.highlightColor,
    required this.period,
  });

  final double t;
  final bool circle;
  final Color baseColor;
  final Color highlightColor;
  final double period;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double frac =
        Curves.easeInOut.transform((t % period) / period);
    final double pos = 200 - 400 * frac; // percent
    final double gradW = 2 * w;
    final double x0 = (w - gradW) * pos / 100;
    final Paint paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(x0, 0),
        Offset(x0 + gradW, 0),
        <Color>[baseColor, highlightColor, baseColor],
        const <double>[0.25, 0.5, 0.75],
      );
    if (circle) {
      canvas.drawCircle(
          size.center(Offset.zero), size.shortestSide / 2, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Offset.zero & size, Radius.circular(size.height / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.t != t ||
      old.circle != circle ||
      old.baseColor != baseColor ||
      old.highlightColor != highlightColor ||
      old.period != period;
}
