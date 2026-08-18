/// GradientWaves
/// Origin: reimplemented — port GLSL raymarch gốc của react-bits
/// "Gradient Waves" qua FragmentProgram (file gradient_waves.frag đi kèm,
/// PHẢI khai báo trong pubspec `shaders:` — xem README).
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project, add the .frag to
/// pubspec `shaders:`, and import this file.
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Raymarch step count per quality tier. Capped at 64 (the shader's loop
/// bound) for mid-range Android GPUs — the WebGL original went to 110.
enum GradientWavesDetail {
  low(24),
  medium(40),
  high(64);

  const GradientWavesDetail(this.steps);
  final int steps;
}

/// Default pubspec asset key of the bundled shader. If the folder lives
/// elsewhere in the host project, pass the new key to [loadGradientWavesProgram]
/// and list the same path under pubspec `shaders:`.
const String gradientWavesShaderAsset =
    'lib/components/gradient_waves/gradient_waves.frag';

final Map<String, Future<ui.FragmentProgram>> _programCache =
    <String, Future<ui.FragmentProgram>>{};

/// Loads (and memoizes) the compiled shader program. One program serves any
/// number of shaders/widgets.
Future<ui.FragmentProgram> loadGradientWavesProgram({
  String assetKey = gradientWavesShaderAsset,
}) =>
    _programCache.putIfAbsent(
      assetKey,
      () => ui.FragmentProgram.fromAsset(assetKey),
    );

/// §2.3 shader contract: returns a real [ui.Shader] (a configured
/// [ui.FragmentShader]) — usable with `ShaderMask`/`Paint.shader` on any
/// carrier. The program must be loaded first via [loadGradientWavesProgram]
/// (async, once); after that this factory is synchronous and cheap.
///
/// [time] is in seconds — pass a growing value to animate, a constant for a
/// frozen frame. [scale] is detail density (§9.1): it multiplies [waveScale]
/// so small carriers keep visible wave periods. The caller owns the returned
/// shader (`dispose()` it when done).
ui.FragmentShader createGradientWavesShader(
  ui.FragmentProgram program,
  ui.Rect bounds, {
  double time = 0,
  double scale = 1.0,
  ui.Color horizonColor = const ui.Color(0xFF5227FF),
  ui.Color waveColor = const ui.Color(0xFFFF9FFC),
  ui.Color crestColor = const ui.Color(0xFFFFFFFF),
  double speed = 0.4,
  double amplitude = 2.5,
  double waveScale = 0.6,
  double waveRatio = 0.9,
  double swell = 35,
  double turbulence = 20,
  double tilt = 1.11,
  double zoom = 1.0,
  double height = 5.5,
  double fogDepth = 15,
  GradientWavesDetail detail = GradientWavesDetail.medium,
  double brightness = 1.0,
  double opacity = 1.0,
  ui.Offset pointer = const ui.Offset(0.5, 0.5),
  double parallaxStrength = 0.5,
  bool pointerParallax = false,
  bool grain = false,
  double grainIntensity = 0.05,
}) {
  final ui.FragmentShader shader = program.fragmentShader();
  configureGradientWavesShader(
    shader,
    bounds.size,
    grain: grain,
    grainIntensity: grainIntensity,
    time: time,
    scale: scale,
    horizonColor: horizonColor,
    waveColor: waveColor,
    crestColor: crestColor,
    speed: speed,
    amplitude: amplitude,
    waveScale: waveScale,
    waveRatio: waveRatio,
    swell: swell,
    turbulence: turbulence,
    tilt: tilt,
    zoom: zoom,
    height: height,
    fogDepth: fogDepth,
    detail: detail,
    brightness: brightness,
    opacity: opacity,
    pointer: pointer,
    parallaxStrength: parallaxStrength,
    pointerParallax: pointerParallax,
  );
  return shader;
}

/// Writes every uniform (declaration order of gradient_waves.frag). Reuse
/// one [ui.FragmentShader] across frames and call this per tick — cheaper
/// than creating a shader each frame.
void configureGradientWavesShader(
  ui.FragmentShader shader,
  ui.Size size, {
  double time = 0,
  double scale = 1.0,
  ui.Color horizonColor = const ui.Color(0xFF5227FF),
  ui.Color waveColor = const ui.Color(0xFFFF9FFC),
  ui.Color crestColor = const ui.Color(0xFFFFFFFF),
  double speed = 0.4,
  double amplitude = 2.5,
  double waveScale = 0.6,
  double waveRatio = 0.9,
  double swell = 35,
  double turbulence = 20,
  double tilt = 1.11,
  double zoom = 1.0,
  double height = 5.5,
  double fogDepth = 15,
  GradientWavesDetail detail = GradientWavesDetail.medium,
  double brightness = 1.0,
  double opacity = 1.0,
  ui.Offset pointer = const ui.Offset(0.5, 0.5),
  double parallaxStrength = 0.5,
  bool pointerParallax = false,
  bool grain = false,
  double grainIntensity = 0.05,
}) {
  int i = 0;
  void f(double v) => shader.setFloat(i++, v);
  f(size.width); // uResolution
  f(size.height);
  f(time); // uTime
  f(speed); // uSpeed
  f(amplitude); // uAmplitude
  f(waveScale * scale); // uWaveScale — §9.1 detail density
  f(waveRatio); // uWaveRatio
  f(swell); // uSwell
  f(turbulence); // uTurbulence
  f(tilt); // uTilt
  f(zoom); // uZoom
  f(height); // uHeight
  f(fogDepth); // uFogDepth
  f(detail.steps.toDouble()); // uSteps
  f(brightness); // uBrightness
  f(opacity); // uOpacity
  f(grain ? 1.0 : 0.0); // uGrain — factory defaults off (text stays clean)
  f(grainIntensity); // uGrainIntensity
  f(pointer.dx); // uMouse
  f(pointer.dy);
  f(parallaxStrength); // uParallax
  f(pointerParallax ? 1.0 : 0.0); // uEnableMouse
  f(horizonColor.r); // uHorizonColor
  f(horizonColor.g);
  f(horizonColor.b);
  f(waveColor.r); // uWaveColor
  f(waveColor.g);
  f(waveColor.b);
  f(crestColor.r); // uCrestColor
  f(crestColor.g);
  f(crestColor.b);
}

/// Fullscreen-style widget wrapper: loads the program, runs the clock,
/// smooths touch parallax (drag = the original's mouse hover), and fills its
/// bounds with the raymarched waves. Shows a flat [horizonColor] until the
/// program finishes loading (first frame only).
class GradientWaves extends StatefulWidget {
  const GradientWaves({
    super.key,
    this.scale = 1.0,
    this.horizonColor = const ui.Color(0xFF5227FF),
    this.waveColor = const ui.Color(0xFFFF9FFC),
    this.crestColor = const ui.Color(0xFFFFFFFF),
    this.speed = 0.4,
    this.amplitude = 2.5,
    this.waveScale = 0.6,
    this.waveRatio = 0.9,
    this.swell = 35,
    this.turbulence = 20,
    this.tilt = 1.11,
    this.zoom = 1.0,
    this.height = 5.5,
    this.fogDepth = 15,
    this.detail = GradientWavesDetail.medium,
    this.brightness = 1.0,
    this.opacity = 1.0,
    this.grain = true,
    this.grainIntensity = 0.05,
    this.touchParallax = true,
    this.parallaxStrength = 0.5,
    this.animate = true,
    this.program,
    this.assetKey = gradientWavesShaderAsset,
    this.child,
  });

  /// Detail density (§9.1): multiplies [waveScale] so a small carrier still
  /// shows several wave periods instead of one flat slope.
  final double scale;

  final ui.Color horizonColor;
  final ui.Color waveColor;
  final ui.Color crestColor;

  /// Animation tempo (original default 0.4).
  final double speed;

  /// Wave height in scene units.
  final double amplitude;

  /// Wave frequency (original default 0.6).
  final double waveScale;

  /// Y-frequency relative to X.
  final double waveRatio;

  /// Large curved bulge strength.
  final double swell;

  /// Chaotic perturbation strength.
  final double turbulence;

  /// Camera roll, radians.
  final double tilt;

  /// Field-of-view divisor (bigger = narrower view).
  final double zoom;

  /// Vertical camera offset in scene units.
  final double height;

  /// Fog distance — lower = mistier horizon.
  final double fogDepth;

  /// Raymarch quality tier (steps: 24/40/64) — see Caveats for cost.
  final GradientWavesDetail detail;

  final double brightness;

  /// Output alpha multiplier (fog-driven, like the original).
  final double opacity;

  /// Film-grain dither on the alpha channel.
  final bool grain;

  final double grainIntensity;

  /// Drag = the original's mouse-hover parallax (camera yaw/pitch).
  final bool touchParallax;

  final double parallaxStrength;

  /// External stop switch: `false` halts the ticker (no frames scheduled);
  /// resuming continues from the same phase.
  final bool animate;

  /// Pre-loaded program (skips the async load). Null = load [assetKey].
  final ui.FragmentProgram? program;

  /// Pubspec shader key to load when [program] is null.
  final String assetKey;

  /// Optional foreground content on top of the waves.
  final Widget? child;

  @override
  State<GradientWaves> createState() => _GradientWavesState();
}

class _GradientWavesState extends State<GradientWaves>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  final ValueNotifier<ui.Offset> _pointer =
      ValueNotifier<ui.Offset>(const ui.Offset(0.5, 0.5));
  ui.Offset _pointerTarget = const ui.Offset(0.5, 0.5);
  double _timeBase = 0;
  ui.FragmentShader? _shader;

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
    loadGradientWavesProgram(assetKey: widget.assetKey).then((program) {
      if (mounted) {
        setState(() => _shader = program.fragmentShader());
      }
    });
  }

  void _onTick(Duration elapsed) {
    _time.value = _timeBase + elapsed.inMicroseconds / 1e6;
    if (_pointer.value != _pointerTarget) {
      // Same easing rate as the original's per-frame lerp (0.05 @ 60fps).
      final ui.Offset next =
          ui.Offset.lerp(_pointer.value, _pointerTarget, 0.05)!;
      _pointer.value = (next - _pointerTarget).distanceSquared < 1e-6
          ? _pointerTarget
          : next;
    }
  }

  @override
  void didUpdateWidget(GradientWaves oldWidget) {
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

  void _onPointer(ui.Offset local, ui.Size size) {
    if (size.isEmpty) {
      return;
    }
    // Same mapping as the web original: x/w, 1 - y/h, resting at (0.5, 0.5).
    _pointerTarget = ui.Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (1 - local.dy / size.height).clamp(0.0, 1.0),
    );
    if (!_ticker.isActive) {
      _pointer.value = _pointerTarget;
    }
  }

  void _onPointerEnd() {
    _pointerTarget = const ui.Offset(0.5, 0.5);
    if (!_ticker.isActive) {
      _pointer.value = _pointerTarget;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _pointer.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui.FragmentShader? shader = _shader;
    if (shader == null) {
      return ColoredBox(
        color: widget.horizonColor,
        child: widget.child ?? const SizedBox.expand(),
      );
    }
    final Widget waves = CustomPaint(
      painter: _WavesShaderPainter(
        shader: shader,
        time: _time,
        pointer: _pointer,
        config: widget,
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
    if (!widget.touchParallax) {
      return waves;
    }
    return LayoutBuilder(
      builder: (context, constraints) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) =>
            _onPointer(event.localPosition, constraints.biggest),
        onPointerMove: (event) =>
            _onPointer(event.localPosition, constraints.biggest),
        onPointerUp: (_) => _onPointerEnd(),
        onPointerCancel: (_) => _onPointerEnd(),
        child: waves,
      ),
    );
  }
}

class _WavesShaderPainter extends CustomPainter {
  _WavesShaderPainter({
    required this.shader,
    required this.time,
    required this.pointer,
    required this.config,
  }) : super(repaint: Listenable.merge(<Listenable>[time, pointer]));

  final ui.FragmentShader shader;
  final ValueListenable<double> time;
  final ValueListenable<ui.Offset> pointer;
  final GradientWaves config;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (size.isEmpty) {
      return;
    }
    configureGradientWavesShader(
      shader,
      size,
      time: time.value,
      scale: config.scale,
      horizonColor: config.horizonColor,
      waveColor: config.waveColor,
      crestColor: config.crestColor,
      speed: config.speed,
      amplitude: config.amplitude,
      waveScale: config.waveScale,
      waveRatio: config.waveRatio,
      swell: config.swell,
      turbulence: config.turbulence,
      tilt: config.tilt,
      zoom: config.zoom,
      height: config.height,
      fogDepth: config.fogDepth,
      detail: config.detail,
      brightness: config.brightness,
      opacity: config.opacity,
      pointer: pointer.value,
      parallaxStrength: config.parallaxStrength,
      pointerParallax: config.touchParallax,
      grain: config.grain,
      grainIntensity: config.grainIntensity,
    );
    canvas.drawRect(ui.Offset.zero & size, ui.Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_WavesShaderPainter oldDelegate) =>
      oldDelegate.shader != shader || oldDelegate.config != config;
}
