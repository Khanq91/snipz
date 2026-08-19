/// PixelCard
/// Origin: adapted — port react-bits "PixelCard" (Canvas 2D particle loop →
/// CustomPainter + Ticker): card viền bo, khi chạm giữ thì lưới pixel màu
/// hiện dần từ tâm ra rồi shimmer; thả tay thì rã ra và ticker tự dừng.
/// Source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Components/PixelCard/PixelCard.tsx
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The 4 presets of the original `VARIANTS` map. An explicitly passed
/// [PixelCard.gap]/[PixelCard.speed]/[PixelCard.colors] overrides the variant
/// value, exactly like the original's `gap ?? variantCfg.gap` precedence.
enum PixelCardVariant {
  /// Original key `default` (Dart reserved word).
  defaultVariant(
    activeColor: null,
    gap: 5,
    speed: 35,
    colors: <Color>[Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
  ),
  blue(
    activeColor: Color(0xFFE0F2FE),
    gap: 10,
    speed: 25,
    colors: <Color>[Color(0xFFE0F2FE), Color(0xFF7DD3FC), Color(0xFF0EA5E9)],
  ),
  yellow(
    activeColor: Color(0xFFFEF08A),
    gap: 3,
    speed: 20,
    colors: <Color>[Color(0xFFFEF08A), Color(0xFFFDE047), Color(0xFFEAB308)],
  ),
  pink(
    activeColor: Color(0xFFFECDD3),
    gap: 6,
    speed: 80,
    colors: <Color>[Color(0xFFFECDD3), Color(0xFFFDA4AF), Color(0xFFE11D48)],
  );

  const PixelCardVariant({
    required this.activeColor,
    required this.gap,
    required this.speed,
    required this.colors,
  });

  /// Carried over from the original variant data. The ts-tailwind source
  /// defines it but never consumes it either — exposed so a host app can
  /// tint its own content (e.g. text color) to match the variant.
  final Color? activeColor;

  /// Grid step in logical px (original iterates `x += parseInt(gap)`).
  final int gap;

  /// 0–100, mapped through the original's `getEffectiveSpeed` throttle.
  final double speed;

  /// Pixel colors, picked at random per grid cell.
  final List<Color> colors;
}

/// Card that fills with an animated pixel grid while pressed (the original's
/// hover/focus), emptying again on release. [child] is centered on top and
/// still receives taps — the trigger is a passive [Listener].
///
/// Set [active] non-null to drive the effect from the app instead of touch
/// (`active: false` also acts as the external stop switch — the internal
/// ticker halts once every pixel has shrunk away).
class PixelCard extends StatefulWidget {
  const PixelCard({
    super.key,
    this.variant = PixelCardVariant.defaultVariant,
    this.gap,
    this.speed,
    this.colors,
    this.active,
    this.seed,
    this.borderColor = const Color(0xFF27272A),
    this.borderWidth = 1,
    this.borderRadius = 25,
    this.backgroundColor,
    this.child,
  })  : assert(gap == null || gap > 0, 'gap must be > 0'),
        assert(colors == null || colors.length > 0, 'colors must not be empty');

  /// Preset (gap/speed/colors). Individual params below override its fields.
  final PixelCardVariant variant;

  /// Grid step in logical px; null = variant value.
  final int? gap;

  /// Animation speed 0–100 (0 freezes appear growth); null = variant value.
  final double? speed;

  /// Pixel palette; null = variant value.
  final List<Color>? colors;

  /// Touch mapping replaces the web hover: pointer-down = appear,
  /// pointer-up/cancel = disappear. When [active] is non-null touch is
  /// ignored entirely and the app drives the state (true = appear).
  final bool? active;

  /// Optional RNG seed for a reproducible grid (sizes/colors/timing jitter).
  final int? seed;

  /// Card chrome, matching the original div (`border-[#27272a] rounded-[25px]`).
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  /// Original card is transparent; null paints nothing behind the pixels.
  final Color? backgroundColor;

  /// Centered content (original `children` with `grid place-items-center`).
  final Widget? child;

  @override
  State<PixelCard> createState() => _PixelCardState();
}

class _PixelCardState extends State<PixelCard>
    with SingleTickerProviderStateMixin {
  // Web default size (Tailwind h-[400px] w-[300px]) — used only when the
  // parent gives unbounded constraints; bounded constraints win.
  static const double _defaultWidth = 300;
  static const double _defaultHeight = 400;

  late final Ticker _ticker;
  late final math.Random _random;
  final List<_CardPixel> _pixels = <_CardPixel>[];
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  bool _appearing = false; // current mode: appear (true) / disappear (false)
  bool _needsRebuild = true;
  Size _gridSize = Size.zero;
  double _prevMs = 0; // 60fps throttle base, mirrors timePreviousRef

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _random = math.Random(widget.seed);
    _appearing = widget.active ?? false;
  }

  @override
  void didUpdateWidget(PixelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variant != oldWidget.variant ||
        widget.gap != oldWidget.gap ||
        widget.speed != oldWidget.speed ||
        !listEquals(widget.colors, oldWidget.colors) ||
        widget.seed != oldWidget.seed) {
      _needsRebuild = true; // grid re-inits in the next build
    }
    if (widget.active != oldWidget.active && widget.active != null) {
      _setMode(widget.active!);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // --- animation drive -----------------------------------------------------

  /// Original `handleAnimation(name)`: switch appear/disappear and (re)start
  /// the frame loop.
  void _setMode(bool appearing) {
    _appearing = appearing;
    _startTicker();
  }

  void _startTicker() {
    if (_ticker.isActive) {
      return;
    }
    _prevMs = 0;
    _ticker.start();
  }

  /// Original `doAnimate`: throttled to 60fps (also on 120Hz displays, like
  /// the web version), steps every pixel, stops itself once all are idle.
  void _onTick(Duration elapsed) {
    final double nowMs = elapsed.inMicroseconds / 1000.0;
    final double passed = nowMs - _prevMs;
    const double interval = 1000 / 60;
    if (passed < interval) {
      return;
    }
    _prevMs = nowMs - (passed % interval);

    bool allIdle = true;
    for (int i = 0; i < _pixels.length; i++) {
      final _CardPixel pixel = _pixels[i];
      if (_appearing) {
        pixel.appear();
      } else {
        pixel.disappear();
      }
      if (!pixel.isIdle) {
        allIdle = false;
      }
    }
    _repaint.value++;
    if (allIdle) {
      _ticker.stop();
    }
  }

  // --- touch (web hover/focus replacement) ---------------------------------

  void _onPointerDown(PointerDownEvent event) {
    if (widget.active == null) {
      _setMode(true); // mouseenter
    }
  }

  void _onPointerUpOrCancel(PointerEvent event) {
    if (widget.active == null) {
      _setMode(false); // mouseleave
    }
  }

  // --- grid ----------------------------------------------------------------

  /// Original `initPixels`, run on first layout, size change and param
  /// change. Pixels reset to size 0; a running mode carries on over the new
  /// grid, same as the web ResizeObserver re-init.
  void _rebuildGrid(Size size) {
    _gridSize = size;
    _needsRebuild = false;
    final math.Random random =
        widget.seed != null ? math.Random(widget.seed) : _random;
    final int width = size.width.floor();
    final int height = size.height.floor();
    final int gap = math.max(1, widget.gap ?? widget.variant.gap);
    final List<Color> colors = widget.colors ?? widget.variant.colors;
    final double speed = _effectiveSpeed(widget.speed ?? widget.variant.speed);

    _pixels.clear();
    for (int x = 0; x < width; x += gap) {
      for (int y = 0; y < height; y += gap) {
        final Color color = colors[random.nextInt(colors.length)];
        final double dx = x - width / 2;
        final double dy = y - height / 2;
        final double delay = math.sqrt(dx * dx + dy * dy);
        _pixels.add(_CardPixel(
          canvasWidth: width.toDouble(),
          canvasHeight: height.toDouble(),
          x: x.toDouble(),
          y: y.toDouble(),
          color: color,
          speed: speed,
          delay: delay,
          random: random,
        ));
      }
    }
    // Painter keeps the same list instance — poke the repaint listenable so
    // the canvas clears/redraws even when nothing else animates this frame.
    _repaint.value++;
  }

  /// Original `getEffectiveSpeed` (reduced-motion branch dropped, see README).
  static double _effectiveSpeed(double value) {
    const double min = 0;
    const double max = 100;
    const double throttle = 0.001;
    if (value <= min) {
      return min;
    } else if (value >= max) {
      return max * throttle;
    }
    return value * throttle;
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.hasBoundedWidth ? constraints.maxWidth : _defaultWidth;
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : _defaultHeight;
        final Size size = Size(width, height);
        if (_needsRebuild || size != _gridSize) {
          _rebuildGrid(size);
          if (_appearing) {
            _startTicker(); // e.g. active: true on first build
          }
        }
        return SizedBox(
          width: width,
          height: height,
          child: Listener(
            // Passive: raw pointer events don't join the gesture arena, so
            // taps/buttons inside [child] keep working.
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUpOrCancel,
            onPointerCancel: _onPointerUpOrCancel,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: widget.borderWidth > 0
                    ? Border.all(
                        color: widget.borderColor,
                        width: widget.borderWidth,
                      )
                    : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _PixelFieldPainter(
                        pixels: _pixels,
                        repaint: _repaint,
                      ),
                    ),
                  ),
                  if (widget.child != null) Center(child: widget.child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Faithful port of the original `Pixel` class. Drawing moved out to the
/// painter (state machine identical; a pixel with `size <= 0` paints
/// nothing, matching the web's skipped `fillRect`).
class _CardPixel {
  _CardPixel({
    required double canvasWidth,
    required double canvasHeight,
    required this.x,
    required this.y,
    required this.color,
    required double speed,
    required this.delay,
    required math.Random random,
  })  : speed = _randomRange(random, 0.1, 0.9) * speed,
        sizeStep = random.nextDouble() * 0.4,
        maxSize = _randomRange(random, minSize, maxSizeInteger),
        counterStep =
            random.nextDouble() * 4 + (canvasWidth + canvasHeight) * 0.01;

  static const double minSize = 0.5;
  static const double maxSizeInteger = 2;

  final double x;
  final double y;
  final Color color;
  final double speed; // shimmer step, pre-randomized like the original ctor
  final double sizeStep; // growth per step while appearing
  final double maxSize;
  final double delay; // counter budget before appearing (distance to center)
  final double counterStep;

  double size = 0;
  double counter = 0;
  bool isIdle = false;
  bool isReverse = false;
  bool isShimmer = false;

  void appear() {
    isIdle = false;
    if (counter <= delay) {
      counter += counterStep;
      return;
    }
    if (size >= maxSize) {
      isShimmer = true;
    }
    if (isShimmer) {
      _shimmer();
    } else {
      size += sizeStep;
    }
  }

  void disappear() {
    isShimmer = false;
    counter = 0;
    if (size <= 0) {
      isIdle = true;
      return;
    }
    size -= 0.1;
  }

  void _shimmer() {
    if (size >= maxSize) {
      isReverse = true;
    } else if (size <= minSize) {
      isReverse = false;
    }
    if (isReverse) {
      size -= speed;
    } else {
      size += speed;
    }
  }

  static double _randomRange(math.Random random, double min, double max) =>
      random.nextDouble() * (max - min) + min;
}

class _PixelFieldPainter extends CustomPainter {
  _PixelFieldPainter({required this.pixels, required Listenable repaint})
      : super(repaint: repaint);

  /// Persisted, mutated in place by the state's ticker — no per-frame lists.
  final List<_CardPixel> pixels;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pixels.length; i++) {
      final _CardPixel pixel = pixels[i];
      if (pixel.size <= 0) {
        continue;
      }
      // Original draw(): centerOffset = maxSizeInteger*0.5 - size*0.5 keeps
      // each square centered in its 2px design cell while it grows/shrinks.
      final double centerOffset =
          _CardPixel.maxSizeInteger * 0.5 - pixel.size * 0.5;
      _paint.color = pixel.color;
      canvas.drawRect(
        Rect.fromLTWH(
          pixel.x + centerOffset,
          pixel.y + centerOffset,
          pixel.size,
          pixel.size,
        ),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelFieldPainter oldDelegate) =>
      oldDelegate.pixels != pixels;
}
