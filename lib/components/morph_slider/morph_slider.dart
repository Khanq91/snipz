/// MorphSlider
/// Origin: adapted — port shader OGL/GLSL của react-bits "MorphSlider"
/// (melt/ripple/shear/swirl) sang FragmentProgram
/// Deps: flutter only (+ morph_slider.frag, khai báo ở pubspec `shaders:`)
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// One slide: an image plus an optional caption.
class MorphSliderItem {
  const MorphSliderItem({required this.image, this.caption});

  final ImageProvider image;
  final String? caption;
}

/// How two slides blend into each other.
enum MorphTransition { melt, ripple, shear, swirl }

/// GPU image slider: slides cross-fade through a morphing shader (fbm melt,
/// touch-centered ripple, sliced shear or center swirl) with chromatic
/// aberration on the seam and an idle "drift" wobble. Swipe horizontally,
/// tap the arrows/dots, or enable [autoplay].
///
/// Requires `morph_slider.frag` declared under the pubspec `shaders:` key
/// (NOT `assets:` — `FragmentProgram.fromAsset` fails silently otherwise).
class MorphSlider extends StatefulWidget {
  const MorphSlider({
    super.key,
    required this.items,
    this.startIndex = 0,
    this.transition = MorphTransition.melt,
    this.duration = const Duration(milliseconds: 1100),
    this.curve = Curves.easeInOut,
    this.intensity = 0.55,
    this.noiseScale = 2.4,
    this.aberration = 0.35,
    this.drift = 0.4,
    this.autoplay = false,
    this.autoplayDelay = const Duration(seconds: 4),
    this.loop = true,
    this.radius = 16,
    this.overlayColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFF0C0C0E),
    this.showCaptions = true,
    this.showControls = true,
    this.showIndicators = true,
    this.paused = false,
    this.onIndexChanged,
  }) : assert(items.length > 0, 'items must not be empty');

  final List<MorphSliderItem> items;
  final int startIndex;
  final MorphTransition transition;

  /// Length of one programmatic transition.
  final Duration duration;
  final Curve curve;

  /// Strength of the UV displacement while morphing.
  final double intensity;

  /// Spatial frequency of the melt noise (the original's `scale`).
  final double noiseScale;

  /// Chromatic aberration amount on the seam.
  final double aberration;

  /// Idle wobble amount; 0 also stops the ticker between transitions.
  final double drift;

  final bool autoplay;
  final Duration autoplayDelay;

  /// Wrap from the last slide back to the first.
  final bool loop;

  final double radius;

  /// Vignette tint mixed into the edges.
  final Color overlayColor;

  /// Shown behind everything until textures decode.
  final Color backgroundColor;

  final bool showCaptions;
  final bool showControls;
  final bool showIndicators;

  /// True freezes the idle drift ticker (offscreen, battery). Transitions
  /// still run.
  final bool paused;

  final ValueChanged<int>? onIndexChanged;

  @override
  State<MorphSlider> createState() => MorphSliderState();
}

class MorphSliderState extends State<MorphSlider>
    with TickerProviderStateMixin {
  static Future<ui.FragmentProgram>? _programFuture;

  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  late final AnimationController _progress;
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  late List<ImageInfo?> _images;
  final List<ImageStream> _streams = <ImageStream>[];
  final List<ImageStreamListener> _listeners = <ImageStreamListener>[];

  late int _current = widget.startIndex.clamp(0, widget.items.length - 1);
  late int _shownIndex = _current;
  int _target = 0;
  int _dragDir = 0;
  bool _animating = false;
  bool _dragging = false;
  double _time = 0;
  Offset _pointer = const Offset(0.5, 0.5);
  double _dragStartX = 0;
  double _lastWidth = 1;
  Timer? _autoplayTimer;

  /// Index of the slide the UI currently announces.
  int get index => _shownIndex;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: widget.duration);
    _progress.addListener(() => _repaint.value++);
    _ticker = createTicker((elapsed) {
      _time = elapsed.inMicroseconds / 1e6;
      _repaint.value++;
    });
    _images = List<ImageInfo?>.filled(widget.items.length, null);
    _programFuture ??= ui.FragmentProgram.fromAsset(
      'lib/components/morph_slider/morph_slider.frag',
    );
    _programFuture!.then((program) {
      if (mounted) {
        setState(() => _shader = program.fragmentShader());
      }
    });
    _syncTicker();
    _scheduleAutoplay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImages();
  }

  @override
  void didUpdateWidget(MorphSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _progress.duration = widget.duration;
    if (!identical(oldWidget.items, widget.items)) {
      _disposeImages();
      _images = List<ImageInfo?>.filled(widget.items.length, null);
      _current = _current.clamp(0, widget.items.length - 1);
      _shownIndex = _current;
      _resolveImages();
    }
    _syncTicker();
    _scheduleAutoplay();
  }

  void _resolveImages() {
    _disposeStreams();
    final ImageConfiguration config = createLocalImageConfiguration(context);
    for (int i = 0; i < widget.items.length; i++) {
      final ImageStream stream = widget.items[i].image.resolve(config);
      final ImageStreamListener listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          if (!mounted) {
            info.dispose();
            return;
          }
          _images[i]?.dispose();
          _images[i] = info;
          _repaint.value++;
          setState(() {});
        },
        onError: (Object error, StackTrace? stack) {
          debugPrint('MorphSlider: failed to load image $i: $error');
        },
      );
      stream.addListener(listener);
      _streams.add(stream);
      _listeners.add(listener);
    }
  }

  void _syncTicker() {
    final bool wantTicker = !widget.paused && widget.drift > 0;
    if (wantTicker && !_ticker.isActive) {
      _ticker.start();
    } else if (!wantTicker && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _scheduleAutoplay() {
    _autoplayTimer?.cancel();
    if (!widget.autoplay) {
      return;
    }
    _autoplayTimer = Timer(widget.autoplayDelay, () {
      if (mounted && !_dragging && !_animating) {
        next();
      }
      _scheduleAutoplay();
    });
  }

  int _wrap(int i) {
    final int n = widget.items.length;
    return ((i % n) + n) % n;
  }

  bool get _reduced =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _announce(int i) {
    if (i == _shownIndex) {
      return;
    }
    setState(() => _shownIndex = i);
    widget.onIndexChanged?.call(i);
  }

  void _commit(int target) {
    _current = target;
    _progress.value = 0;
    _animating = false;
    _repaint.value++;
    _announce(target);
  }

  /// Animate one step in [dir] (+1 next / -1 previous).
  void goTo(int dir) {
    if (_animating || _dragging || widget.items.length < 2) {
      return;
    }
    if (!widget.loop) {
      final int raw = _current + dir;
      if (raw < 0 || raw > widget.items.length - 1) {
        return;
      }
    }
    final int target = _wrap(_current + dir);
    _target = target;
    _dragDir = dir;
    _animating = true;
    _announce(target);
    final Duration duration = _reduced
        ? Duration(milliseconds: math.min(widget.duration.inMilliseconds, 400))
        : widget.duration;
    _progress.duration = duration;
    _progress
        .animateTo(1, curve: widget.curve)
        .whenComplete(() => _commit(target));
  }

  void next() => goTo(1);

  void prev() => goTo(-1);

  void _onDragStart(DragStartDetails d) {
    if (_animating || widget.items.length < 2) {
      return;
    }
    _dragging = true;
    _dragDir = 0;
    _dragStartX = d.localPosition.dx;
    final Size? size = context.size;
    _lastWidth = math.max(size?.width ?? 1, 1);
    if (size != null && size.height > 0) {
      _pointer = Offset(
        (d.localPosition.dx / size.width).clamp(0.0, 1.0),
        (d.localPosition.dy / size.height).clamp(0.0, 1.0),
      );
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_dragging) {
      return;
    }
    final double ndx = (d.localPosition.dx - _dragStartX) / _lastWidth;
    final int dir = ndx < 0 ? 1 : -1;
    if (!widget.loop) {
      final int raw = _current + dir;
      if (raw < 0 || raw > widget.items.length - 1) {
        _progress.value = 0;
        return;
      }
    }
    if (dir != _dragDir) {
      _dragDir = dir;
      _target = _wrap(_current + dir);
    }
    _progress.value = math.min(ndx.abs(), 1);
    _announce(_progress.value > 0.5 ? _wrap(_current + dir) : _current);
  }

  void _onDragEnd() {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    if (_dragDir == 0) {
      return;
    }
    final int target = _wrap(_current + _dragDir);
    final Duration duration =
        Duration(milliseconds: _reduced ? 300 : 500);
    _animating = true;
    _progress.duration = duration;
    if (_progress.value > 0.4) {
      _announce(target);
      _progress
          .animateTo(1, curve: Curves.easeOut)
          .whenComplete(() => _commit(target));
    } else {
      _announce(_current);
      _progress.animateTo(0, curve: Curves.easeOut).whenComplete(() {
        _animating = false;
      });
    }
  }

  void _disposeStreams() {
    for (int i = 0; i < _streams.length; i++) {
      _streams[i].removeListener(_listeners[i]);
    }
    _streams.clear();
    _listeners.clear();
  }

  void _disposeImages() {
    _disposeStreams();
    for (final ImageInfo? info in _images) {
      info?.dispose();
    }
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _ticker.dispose();
    _progress.dispose();
    _disposeImages();
    _shader?.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui.Image? currentImage = _images[_current]?.image;
    final int targetIndex = _dragDir == 0 ? _current : _target;
    final ui.Image? nextImage = _images[targetIndex]?.image;
    final bool ready =
        _shader != null && currentImage != null && nextImage != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: ColoredBox(
        color: widget.backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: (_) => _onDragEnd(),
              onHorizontalDragCancel: _onDragEnd,
              child: ready
                  ? CustomPaint(
                      painter: _MorphPainter(
                        shader: _shader!,
                        repaint: _repaint,
                        current: currentImage,
                        next: nextImage,
                        progress: () => _progress.value,
                        time: () => _time,
                        mode: widget.transition.index.toDouble(),
                        dir: _dragDir == 0 ? 1 : _dragDir.toDouble(),
                        intensity: widget.intensity,
                        noiseScale: widget.noiseScale,
                        aberration: widget.aberration,
                        drift: widget.drift,
                        reduce: _reduced ? 1 : 0,
                        pointer: _pointer,
                        overlay: widget.overlayColor,
                      ),
                    )
                  : const SizedBox.expand(),
            ),
            if (widget.showCaptions) _buildCaption(),
            if (widget.showControls && widget.items.length > 1)
              _buildControls(),
            if (widget.showIndicators && widget.items.length > 1)
              _buildIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildCaption() {
    final Duration swap = Duration(
      milliseconds: (widget.duration.inMilliseconds * 0.66).round(),
    );
    return Positioned(
      left: 22,
      bottom: 22,
      right: 60,
      child: IgnorePointer(
        child: Stack(
          children: <Widget>[
            for (int i = 0; i < widget.items.length; i++)
              if (widget.items[i].caption != null)
                AnimatedOpacity(
                  opacity: i == _shownIndex ? 1 : 0,
                  duration: swap,
                  curve: Curves.easeOutCubic,
                  child: AnimatedSlide(
                    offset: i == _shownIndex
                        ? Offset.zero
                        : const Offset(0, 0.4),
                    duration: swap,
                    curve: Curves.easeOutCubic,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x6B0A0A0C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.items[i].caption!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _roundButton(Icons.chevron_left, prev),
              _roundButton(Icons.chevron_right, next),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0x660C0C0E),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < widget.items.length; i++)
            GestureDetector(
              onTap: () {
                if (i != _shownIndex) {
                  goTo(i > _shownIndex ? 1 : -1);
                }
              },
              child: AnimatedContainer(
                duration: Duration(
                  milliseconds:
                      (widget.duration.inMilliseconds * 0.45).round(),
                ),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _shownIndex ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: i == _shownIndex ? 0.95 : 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MorphPainter extends CustomPainter {
  _MorphPainter({
    required this.shader,
    required Listenable repaint,
    required this.current,
    required this.next,
    required this.progress,
    required this.time,
    required this.mode,
    required this.dir,
    required this.intensity,
    required this.noiseScale,
    required this.aberration,
    required this.drift,
    required this.reduce,
    required this.pointer,
    required this.overlay,
  }) : super(repaint: repaint);

  final ui.FragmentShader shader;
  final ui.Image current;
  final ui.Image next;
  final double Function() progress;
  final double Function() time;
  final double mode;
  final double dir;
  final double intensity;
  final double noiseScale;
  final double aberration;
  final double drift;
  final double reduce;
  final Offset pointer;
  final Color overlay;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, current.width.toDouble())
      ..setFloat(3, current.height.toDouble())
      ..setFloat(4, next.width.toDouble())
      ..setFloat(5, next.height.toDouble())
      ..setFloat(6, progress())
      ..setFloat(7, dir)
      ..setFloat(8, mode)
      ..setFloat(9, intensity)
      ..setFloat(10, noiseScale)
      ..setFloat(11, aberration)
      ..setFloat(12, drift)
      ..setFloat(13, time())
      ..setFloat(14, reduce)
      ..setFloat(15, pointer.dx)
      ..setFloat(16, pointer.dy)
      ..setFloat(17, overlay.r)
      ..setFloat(18, overlay.g)
      ..setFloat(19, overlay.b)
      ..setImageSampler(0, current)
      ..setImageSampler(1, next);
    _paint.shader = shader;
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(_MorphPainter oldDelegate) =>
      oldDelegate.current != current ||
      oldDelegate.next != next ||
      oldDelegate.mode != mode ||
      oldDelegate.dir != dir;
}
