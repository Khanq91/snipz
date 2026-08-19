/// FaultyTerminal
/// Origin: adapted — port GLSL gốc của react-bits "FaultyTerminal" (nền
/// terminal CRT glitch: grid ký tự giả lập sáng theo fbm noise, scanline,
/// displace/flicker, barrel curvature) qua FragmentProgram (file
/// faulty_terminal.frag đi kèm, PHẢI khai báo trong pubspec `shaders:` —
/// xem README).
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project, add the .frag to
/// pubspec `shaders:`, and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Default pubspec asset key of the bundled shader. If the folder lives
/// elsewhere in the host project, pass the new key to
/// [loadFaultyTerminalProgram] and list the same path under pubspec
/// `shaders:`.
const String faultyTerminalShaderAsset =
    'lib/components/faulty_terminal/faulty_terminal.frag';

final Map<String, Future<ui.FragmentProgram>> _programCache =
    <String, Future<ui.FragmentProgram>>{};

/// Loads (and memoizes) the compiled shader program. One program serves any
/// number of shaders/widgets.
Future<ui.FragmentProgram> loadFaultyTerminalProgram({
  String assetKey = faultyTerminalShaderAsset,
}) =>
    _programCache.putIfAbsent(
      assetKey,
      () => ui.FragmentProgram.fromAsset(assetKey),
    );

/// §2.3 shader contract: returns a real [ui.Shader] (a configured
/// [ui.FragmentShader]) — usable with `ShaderMask`/`Paint.shader` on any
/// carrier. The program must be loaded first via [loadFaultyTerminalProgram]
/// (async, once); after that this factory is synchronous and cheap.
///
/// [time] is in seconds — pass a growing value to animate. The shader clock
/// is `(time + timeOffset) * timeScale`, matching the original's
/// `(t + Math.random()*100) * timeScale`; pass a nonzero [timeOffset] to
/// desync multiple instances (0 keeps it deterministic).
/// [scale] is detail density (§9.1): it multiplies the UV (exactly the
/// original's uScale) so small carriers keep terminal detail. The caller
/// owns the returned shader.
ui.FragmentShader createFaultyTerminalShader(
  ui.FragmentProgram program,
  ui.Rect bounds, {
  double time = 0,
  double scale = 1.0,
  double timeScale = 0.3,
  double timeOffset = 0,
  ui.Offset gridMul = const ui.Offset(2, 1),
  double digitSize = 1.5,
  double scanlineIntensity = 0.3,
  double glitchAmount = 1,
  double flickerAmount = 1,
  double noiseAmp = 1,
  double chromaticAberration = 0,
  double dither = 0,
  double curvature = 0.2,
  ui.Color tint = const ui.Color(0xFFFFFFFF),
  double brightness = 1,
  double pageLoadProgress = 1.0,
}) {
  final ui.FragmentShader shader = program.fragmentShader();
  configureFaultyTerminalShader(
    shader,
    bounds.size,
    time: time,
    scale: scale,
    timeScale: timeScale,
    timeOffset: timeOffset,
    gridMul: gridMul,
    digitSize: digitSize,
    scanlineIntensity: scanlineIntensity,
    glitchAmount: glitchAmount,
    flickerAmount: flickerAmount,
    noiseAmp: noiseAmp,
    chromaticAberration: chromaticAberration,
    dither: dither,
    curvature: curvature,
    tint: tint,
    brightness: brightness,
    pageLoadProgress: pageLoadProgress,
  );
  return shader;
}

/// Writes every uniform (declaration order of faulty_terminal.frag). Reuse
/// one [ui.FragmentShader] across frames and call this per tick — cheaper
/// than creating a shader each frame.
void configureFaultyTerminalShader(
  ui.FragmentShader shader,
  ui.Size size, {
  double time = 0,
  double scale = 1.0,
  double timeScale = 0.3,
  double timeOffset = 0,
  ui.Offset gridMul = const ui.Offset(2, 1),
  double digitSize = 1.5,
  double scanlineIntensity = 0.3,
  double glitchAmount = 1,
  double flickerAmount = 1,
  double noiseAmp = 1,
  double chromaticAberration = 0,
  double dither = 0,
  double curvature = 0.2,
  ui.Color tint = const ui.Color(0xFFFFFFFF),
  double brightness = 1,
  double pageLoadProgress = 1.0,
}) {
  int i = 0;
  void f(double v) => shader.setFloat(i++, v);
  f(size.width); // uResolution
  f(size.height);
  f((time + timeOffset) * timeScale); // uTime — the original's iTime
  f(scale); // uScale — §9.1 detail density (= the original's UV multiplier)
  f(gridMul.dx); // uGridMul
  f(gridMul.dy);
  f(digitSize); // uDigitSize
  f(scanlineIntensity); // uScanlineIntensity
  f(glitchAmount); // uGlitchAmount
  f(flickerAmount); // uFlickerAmount
  f(noiseAmp); // uNoiseAmp
  f(chromaticAberration); // uChromaticAberration
  f(dither); // uDither
  f(curvature); // uCurvature
  f(tint.r); // uTint
  f(tint.g);
  f(tint.b);
  f(brightness); // uBrightness
  f(pageLoadProgress.clamp(0.0, 1.0)); // uPageLoadProgress (1.0 = off/done)
}

/// Widget wrapper: loads the program, runs the clock, and fills its bounds
/// with the glitchy CRT terminal. Opaque (the original composites over
/// black). Renders nothing until the program finishes loading (first frame
/// only). Pass [child] for foreground content.
class FaultyTerminal extends StatefulWidget {
  const FaultyTerminal({
    super.key,
    this.scale = 1.0,
    this.gridMul = const ui.Offset(2, 1),
    this.digitSize = 1.5,
    this.timeScale = 0.3,
    this.scanlineIntensity = 0.3,
    this.glitchAmount = 1,
    this.flickerAmount = 1,
    this.noiseAmp = 1,
    this.chromaticAberration = 0,
    this.dither = 0,
    this.curvature = 0.2,
    this.tint = const ui.Color(0xFFFFFFFF),
    this.brightness = 1,
    this.pageLoadAnimation = true,
    this.timeOffset,
    this.animate = true,
    this.program,
    this.assetKey = faultyTerminalShaderAsset,
    this.child,
  });

  /// Detail density (§9.1): multiplies the UV — the original's own `scale`
  /// uniform. A small carrier keeps digit detail with a higher value.
  final double scale;

  /// Digit-grid cell multiplier per axis (original `gridMul` [2, 1]).
  final ui.Offset gridMul;

  /// Size of the lit dot block inside each cell (original 1.5).
  final double digitSize;

  /// Global speed factor of the whole animation (original 0.3).
  final double timeScale;

  /// Strength of the moving scanline bar on the glow (original 0.3).
  final double scanlineIntensity;

  /// Multiplier on the horizontal line-displacement glitch; 1 = original
  /// amount, 0 ≈ none, >1 exaggerates (original 1).
  final double glitchAmount;

  /// Multiplier on the flicker gate of the glitch (original 1).
  final double flickerAmount;

  /// Amplitude of the fbm noise lighting the digits (original 1).
  final double noiseAmp;

  /// RGB split in physical px; 0 skips the 2 extra getColor passes
  /// (original 0).
  final double chromaticAberration;

  /// Output dither strength 0..1 against banding (original 0).
  final double dither;

  /// Barrel distortion of the CRT glass (original 0.2; 0 = flat).
  final double curvature;

  /// Multiplied onto the final color — classic phosphor look via green
  /// (original '#ffffff').
  final ui.Color tint;

  /// Final brightness multiplier (original 1).
  final double brightness;

  /// Cells pop in with random delays over ~2s after mount (original
  /// `pageLoadAnimation`, time-based). False = terminal fully lit at once.
  final bool pageLoadAnimation;

  /// Start phase in seconds, added to the clock before [timeScale]. Null
  /// (default) replicates the original's `Math.random() * 100` per mount;
  /// pass a fixed value for a deterministic pattern.
  final double? timeOffset;

  /// External stop switch (original `pause` inverted): `false` halts the
  /// ticker; resuming continues from the same phase. While stopped, the
  /// page-load fade shows as completed (the original also finishes it
  /// regardless of `pause`).
  final bool animate;

  /// Pre-loaded program (skips the async load). Null = load [assetKey].
  final ui.FragmentProgram? program;

  /// Pubspec shader key to load when [program] is null.
  final String assetKey;

  /// Optional foreground content on top of the pattern.
  final Widget? child;

  @override
  State<FaultyTerminal> createState() => _FaultyTerminalState();
}

class _FaultyTerminalState extends State<FaultyTerminal>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  double _timeBase = 0;
  ui.FragmentShader? _shader;

  /// Resolved once per mount, like the original's timeOffsetRef.
  late final double _timeOffset =
      widget.timeOffset ?? math.Random().nextDouble() * 100;

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
    loadFaultyTerminalProgram(assetKey: widget.assetKey).then((program) {
      if (mounted) {
        setState(() => _shader = program.fragmentShader());
      }
    });
  }

  void _onTick(Duration elapsed) {
    _time.value = _timeBase + elapsed.inMicroseconds / 1e6;
  }

  @override
  void didUpdateWidget(FaultyTerminal oldWidget) {
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

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui.FragmentShader? shader = _shader;
    if (shader == null) {
      return widget.child ?? const SizedBox.expand();
    }
    return CustomPaint(
      painter: _FaultyTerminalPainter(
        shader: shader,
        time: _time,
        timeOffset: _timeOffset,
        config: widget,
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
  }
}

class _FaultyTerminalPainter extends CustomPainter {
  _FaultyTerminalPainter({
    required this.shader,
    required this.time,
    required this.timeOffset,
    required this.config,
  }) : super(repaint: time);

  final ui.FragmentShader shader;
  final ValueListenable<double> time;
  final double timeOffset;
  final FaultyTerminal config;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (size.isEmpty) {
      return;
    }
    final double raw = time.value;
    // Original page-load animation: 2000ms from mount, driven by the rAF
    // clock, independent of `pause` (it completes regardless) — so a
    // stopped ticker shows the fully-loaded frame.
    final double pageLoadProgress = config.pageLoadAnimation && config.animate
        ? math.min(raw / 2.0, 1.0)
        : 1.0;
    configureFaultyTerminalShader(
      shader,
      size,
      time: raw,
      scale: config.scale,
      timeScale: config.timeScale,
      timeOffset: timeOffset,
      gridMul: config.gridMul,
      digitSize: config.digitSize,
      scanlineIntensity: config.scanlineIntensity,
      glitchAmount: config.glitchAmount,
      flickerAmount: config.flickerAmount,
      noiseAmp: config.noiseAmp,
      chromaticAberration: config.chromaticAberration,
      dither: config.dither,
      curvature: config.curvature,
      tint: config.tint,
      brightness: config.brightness,
      pageLoadProgress: pageLoadProgress,
    );
    canvas.drawRect(ui.Offset.zero & size, ui.Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_FaultyTerminalPainter oldDelegate) =>
      oldDelegate.shader != shader ||
      oldDelegate.timeOffset != timeOffset ||
      oldDelegate.config != config;
}
