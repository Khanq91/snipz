/// ScrollExpand
/// Origin: reimplemented — dựng lại "ScrollExpand" của react-bits
/// (sticky stage + clip-path theo scroll) bằng ScrollController + ClipPath
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

double _smoothstep(double edge0, double edge1, double x) {
  final double t = ((x - edge0) / ((edge1 - edge0).abs() < 1e-6 ? 1e-6 : (edge1 - edge0)))
      .clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Scroll-driven hero: fills its parent with its own scroll surface; the
/// [media] starts as an inset rounded card ([startWidth]/[startHeight] % of
/// the stage) and expands to fullscreen over [scrollDistance] viewports of
/// scrolling, while [title] fades away and [overlay] fades in. The stage is
/// "sticky" — only the clip animates, nothing scrolls visually. Scrolling is
/// eased with an exponential [smoothing].
class ScrollExpand extends StatefulWidget {
  const ScrollExpand({
    super.key,
    required this.media,
    this.title = '',
    this.scrollHint = '',
    this.overlay,
    this.startWidth = 42,
    this.startHeight = 58,
    this.startRadius = 24,
    this.endRadius = 0,
    this.mediaZoom = 1.35,
    this.scrollDistance = 1.2,
    this.holdDistance = 0.35,
    this.smoothing = 0.1,
    this.overlayScrim = 0.45,
    this.enabled = true,
    this.titleStyle,
    this.hintStyle,
    this.onProgress,
  });

  /// Fullscreen content behind the clip (image, video player, anything).
  final Widget media;

  /// Big centered heading over the collapsed state; fades/lifts away as the
  /// media expands.
  final String title;

  /// Small hint at the bottom edge; gone after the first 12% of progress.
  final String scrollHint;

  /// Content revealed near the end of the expansion (fades/slides in over the
  /// last third).
  final Widget? overlay;

  /// Collapsed media size, in % of the stage (0–100).
  final double startWidth;
  final double startHeight;

  final double startRadius;
  final double endRadius;

  /// Media starts zoomed by this factor and relaxes to 1 when expanded.
  final double mediaZoom;

  /// Viewport-heights of scrolling that drive 0 → 1 progress.
  final double scrollDistance;

  /// Extra scrollable viewport-heights after full expansion.
  final double holdDistance;

  /// Time constant (seconds) of the scroll easing; 0 = follow raw scroll.
  final double smoothing;

  /// Peak opacity of the darkening gradient over the expanded media.
  final double overlayScrim;

  /// False pins the stage at full expansion.
  final bool enabled;

  final TextStyle? titleStyle;
  final TextStyle? hintStyle;

  /// Eased progress 0..1, every time it changes.
  final ValueChanged<double>? onProgress;

  @override
  State<ScrollExpand> createState() => _ScrollExpandState();
}

class _ScrollExpandState extends State<ScrollExpand>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _current = 0;
  double _target = 0;
  double _stageHeight = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _scrollController.addListener(_onScroll);
  }

  double _readProgress() {
    if (!widget.enabled) {
      return 1;
    }
    if (_stageHeight <= 0 || !_scrollController.hasClients) {
      return 0;
    }
    final double span = _stageHeight * math.max(0.01, widget.scrollDistance);
    return (_scrollController.offset / span).clamp(0.0, 1.0);
  }

  void _onScroll() {
    _target = _readProgress();
    if (widget.smoothing <= 0) {
      _apply(_target);
      return;
    }
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final double dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : math.min((elapsed - _lastElapsed).inMicroseconds / 1e6, 0.05);
    _lastElapsed = elapsed;
    final double k = 1 - math.exp(-dt / math.max(widget.smoothing, 1e-3));
    double next = _current + (_target - _current) * k;
    if ((_target - next).abs() < 0.0004) {
      next = _target;
      _ticker.stop();
      _lastElapsed = Duration.zero;
    }
    _apply(next);
  }

  void _apply(double p) {
    if (p == _current && _ticker.isActive) {
      return;
    }
    setState(() => _current = p);
    widget.onProgress?.call(p);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double h = constraints.maxHeight;
        final double w = constraints.maxWidth;
        _stageHeight = h;
        final double trackHeight = h *
            (1 +
                math.max(0.0, widget.scrollDistance) +
                math.max(0.0, widget.holdDistance));
        final double p = widget.enabled ? _current : 1;
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _buildStage(p, w, h),
            // Transparent scroll surface on top: it owns the drag gestures,
            // the stage below stays pinned.
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false, overscroll: false),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(height: trackHeight, width: w),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStage(double p, double w, double h) {
    final double e = _smoothstep(0, 1, p);
    final double widthPct = widget.startWidth + (100 - widget.startWidth) * e;
    final double heightPct =
        widget.startHeight + (100 - widget.startHeight) * e;
    final double ix = math.max(0, (100 - widthPct) / 2) / 100 * w;
    final double iy = math.max(0, (100 - heightPct) / 2) / 100 * h;
    final double radius =
        widget.startRadius + (widget.endRadius - widget.startRadius) * e;
    final double mediaScale = widget.mediaZoom + (1 - widget.mediaZoom) * e;

    final double titleOut = _smoothstep(0.4, 0.88, p);
    final double hintGone = _smoothstep(0, 0.12, p);
    final double overlayIn = _smoothstep(0.68, 1, p);
    final double titleSize = (w * 0.075).clamp(20.0, 84.0);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRRect(
          clipper: _InsetClipper(inset: Offset(ix, iy), radius: radius),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Transform.scale(scale: mediaScale, child: widget.media),
              IgnorePointer(
                child: Opacity(
                  opacity: (widget.overlayScrim * e).clamp(0.0, 1.0),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: <double>[0, 0.45, 1],
                        colors: <Color>[
                          Color(0xBF000000),
                          Color(0x1A000000),
                          Color(0x59000000),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.overlay != null)
                Opacity(
                  opacity: overlayIn,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - overlayIn)),
                    child: Padding(
                      padding: EdgeInsets.all(w * 0.06),
                      child: Center(child: widget.overlay),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.title.isNotEmpty)
          IgnorePointer(
            child: Opacity(
              opacity: (1 - titleOut).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -28 * titleOut),
                child: Transform.scale(
                  scale: 1 + 0.06 * titleOut,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Center(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: (widget.titleStyle ?? const TextStyle())
                            .copyWith(
                          fontSize: widget.titleStyle?.fontSize ?? titleSize,
                          fontWeight:
                              widget.titleStyle?.fontWeight ?? FontWeight.w700,
                          color: widget.titleStyle?.color ?? Colors.white,
                          height: 1,
                          letterSpacing: -0.03 * titleSize,
                          shadows: const <Shadow>[
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 24,
                              color: Color(0x73000000),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (widget.scrollHint.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: IgnorePointer(
              child: Opacity(
                opacity: (1 - hintGone).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 8 * hintGone),
                  child: Text(
                    widget.scrollHint,
                    textAlign: TextAlign.center,
                    style: widget.hintStyle ??
                        const TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.3,
                          color: Color(0x8CFFFFFF),
                        ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Rounded-rect clip inset from the widget bounds by a progress-driven
/// amount — the Flutter equivalent of the animated CSS `clip-path: inset()`.
class _InsetClipper extends CustomClipper<RRect> {
  const _InsetClipper({required this.inset, required this.radius});

  final Offset inset;
  final double radius;

  @override
  RRect getClip(Size size) {
    return RRect.fromRectAndRadius(
      Rect.fromLTRB(
        inset.dx,
        inset.dy,
        size.width - inset.dx,
        size.height - inset.dy,
      ),
      Radius.circular(radius),
    );
  }

  @override
  bool shouldReclip(_InsetClipper oldClipper) =>
      oldClipper.inset != inset || oldClipper.radius != radius;
}
