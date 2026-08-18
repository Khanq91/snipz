/// PixelBlast
/// Origin: reimplemented — port shader gốc của react-bits "Pixel Blast"
/// qua FragmentProgram (file pixel_blast.frag đi kèm, PHẢI khai báo trong
/// pubspec `shaders:` — xem README).
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project, add the .frag to
/// pubspec `shaders:`, and import this file.
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Pixel shape drawn in each dither cell.
enum PixelBlastVariant {
  square(0),
  circle(1),
  triangle(2),
  diamond(3);

  const PixelBlastVariant(this.shapeId);
  final int shapeId;
}

/// One tap ripple: [position] in the paint's local logical px, [time] in
/// shader-time seconds (the value the shader's `uTime` had at tap).
typedef PixelBlastRipple = ({ui.Offset position, double time});

/// The shader tracks at most this many simultaneous ripples (original
/// MAX_CLICKS); older ones are overwritten ring-buffer style.
const int pixelBlastMaxRipples = 10;

/// Default pubspec asset key of the bundled shader. If the folder lives
/// elsewhere in the host project, pass the new key to [loadPixelBlastProgram]
/// and list the same path under pubspec `shaders:`.
const String pixelBlastShaderAsset =
    'lib/components/pixel_blast/pixel_blast.frag';

final Map<String, Future<ui.FragmentProgram>> _programCache =
    <String, Future<ui.FragmentProgram>>{};

/// Loads (and memoizes) the compiled shader program. One program serves any
/// number of shaders/widgets.
Future<ui.FragmentProgram> loadPixelBlastProgram({
  String assetKey = pixelBlastShaderAsset,
}) =>
    _programCache.putIfAbsent(
      assetKey,
      () => ui.FragmentProgram.fromAsset(assetKey),
    );

/// §2.3 shader contract: returns a real [ui.Shader] (a configured
/// [ui.FragmentShader]) — usable with `ShaderMask`/`Paint.shader` on any
/// carrier. The program must be loaded first via [loadPixelBlastProgram]
/// (async, once); after that this factory is synchronous and cheap.
///
/// [time] is in seconds — pass a growing value to animate the pattern.
/// [scale] is detail density (§9.1): it multiplies [patternScale] so small
/// carriers keep pattern variation. The caller owns the returned shader.
ui.FragmentShader createPixelBlastShader(
  ui.FragmentProgram program,
  ui.Rect bounds, {
  double time = 0,
  double scale = 1.0,
  PixelBlastVariant variant = PixelBlastVariant.square,
  ui.Color color = const ui.Color(0xFFB497CF),
  double pixelSize = 3,
  double patternScale = 2,
  double patternDensity = 1,
  double pixelSizeJitter = 0,
  bool enableRipples = true,
  double rippleSpeed = 0.3,
  double rippleThickness = 0.1,
  double rippleIntensityScale = 1,
  double edgeFade = 0.5,
  double noiseAmount = 0,
  bool transparent = true,
  List<PixelBlastRipple> ripples = const <PixelBlastRipple>[],
}) {
  final ui.FragmentShader shader = program.fragmentShader();
  configurePixelBlastShader(
    shader,
    bounds.size,
    time: time,
    scale: scale,
    variant: variant,
    color: color,
    pixelSize: pixelSize,
    patternScale: patternScale,
    patternDensity: patternDensity,
    pixelSizeJitter: pixelSizeJitter,
    enableRipples: enableRipples,
    rippleSpeed: rippleSpeed,
    rippleThickness: rippleThickness,
    rippleIntensityScale: rippleIntensityScale,
    edgeFade: edgeFade,
    noiseAmount: noiseAmount,
    transparent: transparent,
    ripples: ripples,
  );
  return shader;
}

/// Writes every uniform (declaration order of pixel_blast.frag). Reuse one
/// [ui.FragmentShader] across frames and call this per tick — cheaper than
/// creating a shader each frame.
void configurePixelBlastShader(
  ui.FragmentShader shader,
  ui.Size size, {
  double time = 0,
  double scale = 1.0,
  PixelBlastVariant variant = PixelBlastVariant.square,
  ui.Color color = const ui.Color(0xFFB497CF),
  double pixelSize = 3,
  double patternScale = 2,
  double patternDensity = 1,
  double pixelSizeJitter = 0,
  bool enableRipples = true,
  double rippleSpeed = 0.3,
  double rippleThickness = 0.1,
  double rippleIntensityScale = 1,
  double edgeFade = 0.5,
  double noiseAmount = 0,
  bool transparent = true,
  List<PixelBlastRipple> ripples = const <PixelBlastRipple>[],
}) {
  int i = 0;
  void f(double v) => shader.setFloat(i++, v);
  f(size.width); // uResolution
  f(size.height);
  f(time); // uTime
  f(color.r); // uColor
  f(color.g);
  f(color.b);
  f(pixelSize); // uPixelSize
  f(patternScale * scale); // uScale — §9.1 detail density
  f(patternDensity); // uDensity
  f(pixelSizeJitter); // uPixelJitter
  f(enableRipples ? 1.0 : 0.0); // uEnableRipples
  f(rippleSpeed); // uRippleSpeed
  f(rippleThickness); // uRippleThickness
  f(rippleIntensityScale); // uRippleIntensity
  f(edgeFade); // uEdgeFade
  f(variant.shapeId.toDouble()); // uShapeType
  f(noiseAmount); // uNoiseAmount
  f(transparent ? 1.0 : 0.0); // uTransparent
  for (int slot = 0; slot < pixelBlastMaxRipples; slot++) {
    // uClick0..uClick9: xy = position px, z = tap time, x < 0 = empty.
    if (slot < ripples.length) {
      f(ripples[slot].position.dx);
      f(ripples[slot].position.dy);
      f(ripples[slot].time);
      f(0);
    } else {
      f(-1);
      f(-1);
      f(0);
      f(0);
    }
  }
}

/// Widget wrapper: loads the program, runs the clock, records tap ripples
/// (ring buffer of [pixelBlastMaxRipples]), and fills its bounds with the
/// dithered pattern. Transparent by default so it layers over any backdrop;
/// pass [child] for foreground content. Renders nothing until the program
/// finishes loading (first frame only).
class PixelBlast extends StatefulWidget {
  const PixelBlast({
    super.key,
    this.scale = 1.0,
    this.variant = PixelBlastVariant.square,
    this.color = const ui.Color(0xFFB497CF),
    this.pixelSize = 3,
    this.patternScale = 2,
    this.patternDensity = 1,
    this.pixelSizeJitter = 0,
    this.enableRipples = true,
    this.rippleSpeed = 0.3,
    this.rippleThickness = 0.1,
    this.rippleIntensityScale = 1,
    this.edgeFade = 0.5,
    this.noiseAmount = 0,
    this.transparent = true,
    this.speed = 0.5,
    this.timeOffset = 0,
    this.animate = true,
    this.program,
    this.assetKey = pixelBlastShaderAsset,
    this.child,
  });

  /// Detail density (§9.1): multiplies [patternScale] so a small carrier
  /// keeps pattern variation instead of one flat noise value.
  final double scale;

  /// Pixel shape: square, circle, triangle, diamond.
  final PixelBlastVariant variant;

  final ui.Color color;

  /// Dither pixel size in logical px.
  final double pixelSize;

  /// FBM feature scale (original default 2).
  final double patternScale;

  /// Pattern coverage bias (original default 1).
  final double patternDensity;

  /// 0..1: random per-pixel coverage jitter.
  final double pixelSizeJitter;

  /// Tap spawns an expanding ring that lights pixels up.
  final bool enableRipples;

  final double rippleSpeed;
  final double rippleThickness;
  final double rippleIntensityScale;

  /// 0 disables; otherwise fraction of the short edge that fades out.
  final double edgeFade;

  /// Film-noise overlay folded in from the original's post-process pass.
  final double noiseAmount;

  /// `true` = premultiplied-alpha output (layers over any backdrop);
  /// `false` = opaque over black like the original's non-transparent mode.
  final bool transparent;

  /// Animation tempo (original default 0.5).
  final double speed;

  /// Start phase in seconds — the original used a random offset so two
  /// instances don't play identical patterns; pass any constant here.
  final double timeOffset;

  /// External stop switch: `false` halts the ticker (no frames scheduled);
  /// resuming continues from the same phase. Taps still repaint once.
  final bool animate;

  /// Pre-loaded program (skips the async load). Null = load [assetKey].
  final ui.FragmentProgram? program;

  /// Pubspec shader key to load when [program] is null.
  final String assetKey;

  /// Optional foreground content on top of the pattern.
  final Widget? child;

  @override
  State<PixelBlast> createState() => _PixelBlastState();
}

class _PixelBlastState extends State<PixelBlast>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  final ValueNotifier<int> _rippleRevision = ValueNotifier<int>(0);
  final List<PixelBlastRipple> _ripples = <PixelBlastRipple>[];
  int _rippleCursor = 0;
  double _timeBase = 0;
  ui.FragmentShader? _shader;

  double get _shaderTime => widget.timeOffset + _time.value * widget.speed;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.animate) {
      _ticker.start();
    }
    _resolveProgram();
  }

  void _resolveProgram() {
    final ui.FragmentProgram? provided = widget.program;
    if (provided != null) {
      _shader = provided.fragmentShader();
      return;
    }
    loadPixelBlastProgram(assetKey: widget.assetKey).then((program) {
      if (mounted) {
        setState(() => _shader = program.fragmentShader());
      }
    });
  }

  void _onTick(Duration elapsed) {
    _time.value = _timeBase + elapsed.inMicroseconds / 1e6;
  }

  @override
  void didUpdateWidget(PixelBlast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.program != oldWidget.program ||
        widget.assetKey != oldWidget.assetKey) {
      _shader?.dispose();
      _shader = null;
      _resolveProgram();
    }
    if (widget.animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.animate && _ticker.isActive) {
      _timeBase = _time.value;
      _ticker.stop();
    }
  }

  void _onTap(ui.Offset local) {
    if (!widget.enableRipples) {
      return;
    }
    final PixelBlastRipple ripple = (position: local, time: _shaderTime);
    if (_ripples.length < pixelBlastMaxRipples) {
      _ripples.add(ripple);
    } else {
      _ripples[_rippleCursor] = ripple;
    }
    _rippleCursor = (_rippleCursor + 1) % pixelBlastMaxRipples;
    _rippleRevision.value++; // repaint even when the ticker is stopped
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _rippleRevision.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui.FragmentShader? shader = _shader;
    if (shader == null) {
      return widget.child ?? const SizedBox.expand();
    }
    final Widget blast = CustomPaint(
      painter: _PixelBlastPainter(
        shader: shader,
        time: _time,
        rippleRevision: _rippleRevision,
        ripples: _ripples,
        config: widget,
        shaderTimeOf: (raw) => widget.timeOffset + raw * widget.speed,
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
    if (!widget.enableRipples) {
      return blast;
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _onTap(event.localPosition),
      child: blast,
    );
  }
}

class _PixelBlastPainter extends CustomPainter {
  _PixelBlastPainter({
    required this.shader,
    required this.time,
    required this.rippleRevision,
    required this.ripples,
    required this.config,
    required this.shaderTimeOf,
  }) : super(
          repaint: Listenable.merge(<Listenable>[time, rippleRevision]),
        );

  final ui.FragmentShader shader;
  final ValueListenable<double> time;
  final ValueListenable<int> rippleRevision;
  final List<PixelBlastRipple> ripples;
  final PixelBlast config;
  final double Function(double rawSeconds) shaderTimeOf;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (size.isEmpty) {
      return;
    }
    configurePixelBlastShader(
      shader,
      size,
      time: shaderTimeOf(time.value),
      scale: config.scale,
      variant: config.variant,
      color: config.color,
      pixelSize: config.pixelSize,
      patternScale: config.patternScale,
      patternDensity: config.patternDensity,
      pixelSizeJitter: config.pixelSizeJitter,
      enableRipples: config.enableRipples,
      rippleSpeed: config.rippleSpeed,
      rippleThickness: config.rippleThickness,
      rippleIntensityScale: config.rippleIntensityScale,
      edgeFade: config.edgeFade,
      noiseAmount: config.noiseAmount,
      transparent: config.transparent,
      ripples: ripples,
    );
    canvas.drawRect(ui.Offset.zero & size, ui.Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_PixelBlastPainter oldDelegate) =>
      oldDelegate.shader != shader || oldDelegate.config != config;
}
