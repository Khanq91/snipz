// Demo/usage example for SpectrumSweep. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:snipz/core/component_demo.dart';

import 'spectrum_sweep.dart';

final ComponentDemo spectrumSweepDemo = ComponentDemo(
  id: 'spectrum_sweep',
  builder: (context) => const _SpinningSweep(),
  // Static thumbnail: no ticker in the grid (§9.2).
  thumbnailBuilder: (context) => const SpectrumSweep(),
);

/// Usage example: the widget wrapper with an externally driven rotation.
/// For carriers, use the factory directly:
///
/// ```dart
/// ShaderMask(
///   blendMode: BlendMode.srcIn,
///   shaderCallback: (bounds) => createSpectrumSweepShader(bounds),
///   child: const Text('SPECTRUM'),
/// )
/// ```
class _SpinningSweep extends StatefulWidget {
  const _SpinningSweep();

  @override
  State<_SpinningSweep> createState() => _SpinningSweepState();
}

class _SpinningSweepState extends State<_SpinningSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          SpectrumSweep(rotation: _controller.value * 2 * math.pi),
    );
  }
}
