/// GradientWaves
/// Origin: reimplemented — dựng lại ý tưởng "Gradient Waves" của react-bits
/// (bản gốc là WebGL raymarching; bản này là stylized layered sine waves —
/// xem README/Caveats).
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Animated ocean-like gradient waves: stacked sine-wave layers filled with a
/// horizon→wave gradient, fog-faded toward the back, crest highlight on each
/// ridge. Pure `CustomPainter` — no shaders, no assets.
///
/// As a `kind: paint` it fills its bounds; pass [child] to use it as the
/// background of a card/button (clip outside with `ClipRRect`).
///
/// [scale] is detail density (§9.1): how many wave periods fit across the
/// width. Raise it on small carriers (button ≈ 3–4) so the waves stay waves
/// instead of one flat bump.
class GradientWaves extends StatefulWidget {
  const GradientWaves({
    super.key,
    this.scale = 1.0,
    this.horizonColor = const Color(0xFF5227FF),
    this.waveColor = const Color(0xFFFF9FFC),
    this.crestColor = const Color(0xFFFFFFFF),
    this.layers = 4,
    this.amplitude = 1.0,
    this.speed = 1.0,
    this.animate = true,
    this.child,
  });

  /// Detail density (§9.1): wave periods across the width ≈ `1.5 * scale`.
  final double scale;

  /// Sky/background color; far layers fog-blend toward it.
  final Color horizonColor;

  /// Body color of the front-most wave layer.
  final Color waveColor;

  /// Ridge highlight color (also tints the top of the sky).
  final Color crestColor;

  /// Number of stacked wave layers, clamped to 1..8.
  final int layers;

  /// Wave height multiplier (1.0 ≈ 5.5% of the paint height per layer).
  final double amplitude;

  /// Animation tempo multiplier. `0` freezes motion without stopping the
  /// ticker — prefer [animate] for that.
  final double speed;

  /// External stop switch: set `false` to halt the internal ticker (no
  /// frames are scheduled while stopped). Resuming continues from the same
  /// phase.
  final bool animate;

  /// Optional foreground content painted on top of the waves.
  final Widget? child;

  @override
  State<GradientWaves> createState() => _GradientWavesState();
}

class _GradientWavesState extends State<GradientWaves>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  double _timeBase = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.animate) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    _time.value = _timeBase + elapsed.inMicroseconds / 1e6;
  }

  @override
  void didUpdateWidget(GradientWaves oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavesPainter(
        time: _time,
        scale: widget.scale,
        horizonColor: widget.horizonColor,
        waveColor: widget.waveColor,
        crestColor: widget.crestColor,
        layers: widget.layers,
        amplitude: widget.amplitude,
        speed: widget.speed,
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
  }
}

class _WavesPainter extends CustomPainter {
  _WavesPainter({
    required this.time,
    required this.scale,
    required this.horizonColor,
    required this.waveColor,
    required this.crestColor,
    required this.layers,
    required this.amplitude,
    required this.speed,
  }) : super(repaint: time);

  final ValueListenable<double> time;
  final double scale;
  final Color horizonColor;
  final Color waveColor;
  final Color crestColor;
  final int layers;
  final double amplitude;
  final double speed;

  static const int _segments = 48;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final double t = time.value * speed;
    final Rect rect = Offset.zero & size;

    // Sky: crest-tinted at the top, fading through the horizon color.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          <Color>[
            Color.lerp(horizonColor, crestColor, 0.22)!,
            horizonColor,
            Color.lerp(horizonColor, const Color(0xFF000000), 0.40)!,
          ],
          <double>[0.0, 0.45, 1.0],
        ),
    );

    final double periods = math.max(0.5, 1.5 * scale);
    final int n = layers.clamp(1, 8);
    final Path ridge = Path();
    for (int i = 0; i < n; i++) {
      final double depth = (i + 1) / n; // 0 = horizon, 1 = front
      final double baseY = size.height * ui.lerpDouble(0.40, 0.78, depth)!;
      final double amp =
          size.height * 0.055 * amplitude * (0.35 + 0.65 * depth);
      final double drift = t * (0.6 + 0.9 * depth) + i * 2.399;

      ridge.reset();
      for (int s = 0; s <= _segments; s++) {
        final double u = s / _segments;
        final double y = baseY +
            amp *
                (0.62 * math.sin(2 * math.pi * periods * u + drift) +
                    0.38 *
                        math.sin(
                          2 * math.pi * periods * 2.17 * u - drift * 0.6 + i,
                        ));
        if (s == 0) {
          ridge.moveTo(0, y);
        } else {
          ridge.lineTo(u * size.width, y);
        }
      }

      final Path fill = Path.from(ridge)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      // Fog: far layers are translucent and lean toward the horizon color.
      final double fog = 0.45 + 0.55 * depth;
      final Color top =
          Color.lerp(horizonColor, waveColor, 0.30 + 0.70 * depth)!;
      final Color bottom = Color.lerp(top, const Color(0xFF000000), 0.45)!;
      canvas.drawPath(
        fill,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, baseY - amp),
            Offset(0, size.height),
            <Color>[
              top.withValues(alpha: fog),
              bottom.withValues(alpha: fog),
            ],
          ),
      );
      canvas.drawPath(
        ridge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 + 1.5 * depth
          ..color = crestColor.withValues(alpha: 0.10 + 0.45 * depth),
      );
    }
  }

  @override
  bool shouldRepaint(_WavesPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.horizonColor != horizonColor ||
      oldDelegate.waveColor != waveColor ||
      oldDelegate.crestColor != crestColor ||
      oldDelegate.layers != layers ||
      oldDelegate.amplitude != amplitude ||
      oldDelegate.speed != speed;
}
