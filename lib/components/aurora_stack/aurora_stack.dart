/// AuroraStack
/// Origin: original — written for the Snipz vault
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'package:flutter/widgets.dart';

import '_blob_painter.dart';

export '_blob_painter.dart' show auroraDefaultColors;
// AuroraNoiseOverlay is reachable from this entry only through the export
// below — the validate.dart import graph must follow `export` edges (§0.4a).
export '_noise_layer.dart';

/// Animated aurora background: soft radial blobs drifting on a dark field,
/// additively blended. Pair with [AuroraNoiseOverlay] (exported from this
/// entry) for a film-grain finish.
class AuroraStack extends StatefulWidget {
  const AuroraStack({
    super.key,
    this.scale = 1.0,
    this.animate = true,
    this.colors,
    this.background,
  });

  /// Detail density (§9.1). Blob radius scales with it — lower it (`0.3`) on
  /// small carriers so blobs stay readable instead of flooding the bounds.
  final double scale;

  /// Set false to freeze the drift (the internal ticker stops — required by
  /// §9.2 so the app can pause offscreen previews).
  final bool animate;

  /// Blob colors; defaults to [auroraDefaultColors].
  final List<Color>? colors;

  /// Field behind the blobs; defaults to near-black navy.
  final Color? background;

  @override
  State<AuroraStack> createState() => _AuroraStackState();
}

class _AuroraStackState extends State<AuroraStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AuroraStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: AuroraBlobPainter(
          t: _controller.value,
          scale: widget.scale,
          colors: widget.colors ?? auroraDefaultColors,
          background: widget.background ?? const Color(0xFF07080F),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
