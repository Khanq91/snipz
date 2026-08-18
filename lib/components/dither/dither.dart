/// DitherWaves
/// Origin: adapted — port GLSL gốc của react-bits "Dither" (wave pass +
/// Bayer dither postprocess gộp thành một fragment) qua FragmentProgram
/// (file dither.frag đi kèm, PHẢI khai báo trong pubspec `shaders:` — xem
/// README).
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project, add the .frag to
/// pubspec `shaders:`, and import this file.
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Default pubspec asset key of the bundled shader. If the folder lives
/// elsewhere in the host project, pass the new key to [loadDitherProgram]
/// and list the same path under pubspec `shaders:`.
const String ditherShaderAsset = 'lib/components/dither/dither.frag';

final Map<String, Future<ui.FragmentProgram>> _programCache =
    <String, Future<ui.FragmentProgram>>{};

/// Loads (and memoizes) the compiled shader program. One program serves any
/// number of shaders/widgets.
Future<ui.FragmentProgram> loadDitherProgram({
  String assetKey = ditherShaderAsset,
}) =>
    _programCache.putIfAbsent(
      assetKey,
      () => ui.FragmentProgram.fromAsset(assetKey),
    );

/// §2.3 shader contract: returns a real [ui.Shader] (a configured
/// [ui.FragmentShader]) — usable with `ShaderMask`/`Paint.shader` on any
/// carrier. The program must be loaded first via [loadDitherProgram]
/// (async, once); after that this factory is synchronous and cheap.
///
/// [time] is in seconds — pass a growing value to animate the waves.
/// [scale] is detail density (§9.1): it multiplies the noise domain so small
/// carriers keep wave detail. The caller owns the returned shader.
ui.FragmentShader createDitherShader(
  ui.FragmentProgram program,
  ui.Rect bounds, {
  double time = 0,
  double scale = 1.0,
  double waveSpeed = 0.05,
  double waveFrequency = 3,
  double waveAmplitude = 0.3,
  ui.Color waveColor = const ui.Color(0xFF808080),
  double colorNum = 4,
  double pixelSize = 2,
}) {
  final ui.FragmentShader shader = program.fragmentShader();
  configureDitherShader(
    shader,
    bounds.size,
    time: time,
    scale: scale,
    waveSpeed: waveSpeed,
    waveFrequency: waveFrequency,
    waveAmplitude: waveAmplitude,
    waveColor: waveColor,
    colorNum: colorNum,
    pixelSize: pixelSize,
  );
  return shader;
}

/// Writes every uniform (declaration order of dither.frag). Reuse one
/// [ui.FragmentShader] across frames and call this per tick — cheaper than
/// creating a shader each frame.
void configureDitherShader(
  ui.FragmentShader shader,
  ui.Size size, {
  double time = 0,
  double scale = 1.0,
  double waveSpeed = 0.05,
  double waveFrequency = 3,
  double waveAmplitude = 0.3,
  ui.Color waveColor = const ui.Color(0xFF808080),
  double colorNum = 4,
  double pixelSize = 2,
}) {
  int i = 0;
  void f(double v) => shader.setFloat(i++, v);
  f(size.width); // uResolution
  f(size.height);
  f(time); // uTime
  f(waveSpeed); // uWaveSpeed
  f(waveFrequency); // uWaveFrequency
  f(waveAmplitude); // uWaveAmplitude
  f(scale); // uScale — §9.1 detail density
  f(colorNum < 2 ? 2 : colorNum); // uColorNum (< 2 divides by zero)
  f(pixelSize < 1 ? 1 : pixelSize); // uPixelSize
  f(waveColor.r); // uWaveColor
  f(waveColor.g);
  f(waveColor.b);
}

/// Widget wrapper: loads the program, runs the clock, and fills its bounds
/// with the dithered wave pattern. Opaque (the original composites over
/// black). Renders nothing until the program finishes loading (first frame
/// only). Pass [child] for foreground content.
class DitherWaves extends StatefulWidget {
  const DitherWaves({
    super.key,
    this.scale = 1.0,
    this.waveSpeed = 0.05,
    this.waveFrequency = 3,
    this.waveAmplitude = 0.3,
    this.waveColor = const ui.Color(0xFF808080),
    this.colorNum = 4,
    this.pixelSize = 2,
    this.animate = true,
    this.program,
    this.assetKey = ditherShaderAsset,
    this.child,
  });

  /// Detail density (§9.1): multiplies the noise domain so a small carrier
  /// keeps wave variation instead of one flat blob.
  final double scale;

  /// Time factor of the wave drift (original default 0.05).
  final double waveSpeed;

  /// FBM lacunarity — how much finer each noise octave gets (original 3).
  final double waveFrequency;

  /// FBM gain — how much each octave contributes (original 0.3).
  final double waveAmplitude;

  /// Peak color; the pattern mixes black -> this color before quantizing.
  final ui.Color waveColor;

  /// Quantization levels per channel (min 2, original 4).
  final double colorNum;

  /// Dither/pixelation cell size in logical px (original 2).
  final double pixelSize;

  /// External stop switch (original `disableAnimation` inverted): `false`
  /// halts the ticker; resuming continues from the same phase.
  final bool animate;

  /// Pre-loaded program (skips the async load). Null = load [assetKey].
  final ui.FragmentProgram? program;

  /// Pubspec shader key to load when [program] is null.
  final String assetKey;

  /// Optional foreground content on top of the pattern.
  final Widget? child;

  @override
  State<DitherWaves> createState() => _DitherWavesState();
}

class _DitherWavesState extends State<DitherWaves>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
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
    loadDitherProgram(assetKey: widget.assetKey).then((program) {
      if (mounted) {
        setState(() => _shader = program.fragmentShader());
      }
    });
  }

  void _onTick(Duration elapsed) {
    _time.value = _timeBase + elapsed.inMicroseconds / 1e6;
  }

  @override
  void didUpdateWidget(DitherWaves oldWidget) {
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
      painter: _DitherPainter(shader: shader, time: _time, config: widget),
      child: widget.child ?? const SizedBox.expand(),
    );
  }
}

class _DitherPainter extends CustomPainter {
  _DitherPainter({
    required this.shader,
    required this.time,
    required this.config,
  }) : super(repaint: time);

  final ui.FragmentShader shader;
  final ValueListenable<double> time;
  final DitherWaves config;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (size.isEmpty) {
      return;
    }
    configureDitherShader(
      shader,
      size,
      time: time.value,
      scale: config.scale,
      waveSpeed: config.waveSpeed,
      waveFrequency: config.waveFrequency,
      waveAmplitude: config.waveAmplitude,
      waveColor: config.waveColor,
      colorNum: config.colorNum,
      pixelSize: config.pixelSize,
    );
    canvas.drawRect(ui.Offset.zero & size, ui.Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_DitherPainter oldDelegate) =>
      oldDelegate.shader != shader || oldDelegate.config != config;
}
