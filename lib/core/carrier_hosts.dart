// Carrier hosts (spec §2.2, §8.5): render one paint onto one carrier shape.
//
// Two pipelines, picked by CarrierSwitcher:
//   ShaderCarrierStage — §2.3 shader-contract paints. Shape carriers are
//     painted directly (Paint.shader — no saveLayer); only text/icon go
//     through ShaderMask, the one place masking is actually needed (§9.2).
//   WidgetCarrierStage — non-shader paints embedded into shape carriers
//     (the same thing a target project would do by hand).

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'component_demo.dart';
import 'models.dart';

/// Stage key used by tests: `carrier-stage-<carrier wire name>`.
Key carrierStageKey(Carrier carrier) => ValueKey('carrier-stage-${carrier.wire}');

/// Hosts a §2.3 shader-contract paint on [carrier]. Owns the prepared
/// [CarrierShaderHandle] and (for animated specs) a single ticker.
class ShaderCarrierStage extends StatefulWidget {
  const ShaderCarrierStage({
    super.key,
    required this.spec,
    required this.carrier,
    required this.scale,
  });

  final CarrierShaderSpec spec;
  final Carrier carrier;

  /// Detail-density hint wired in by the switcher (§9.1).
  final double scale;

  @override
  State<ShaderCarrierStage> createState() => _ShaderCarrierStageState();
}

class _ShaderCarrierStageState extends State<ShaderCarrierStage>
    with SingleTickerProviderStateMixin {
  CarrierShaderHandle? _handle;
  Ticker? _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    widget.spec.prepare().then((handle) {
      if (!mounted) {
        handle.dispose?.call();
        return;
      }
      setState(() => _handle = handle);
      if (widget.spec.animated) {
        _ticker = createTicker(
          (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
        )..start();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _handle?.dispose?.call();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CarrierShaderHandle? handle = _handle;
    if (handle == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return KeyedSubtree(
      key: carrierStageKey(widget.carrier),
      child: switch (widget.carrier) {
        Carrier.fullscreen => _fill(handle),
        Carrier.card => _CardFrame(child: _fill(handle)),
        Carrier.button => _ButtonFrame(background: _fill(handle)),
        Carrier.text => Center(child: _masked(handle, _sampleText())),
        Carrier.border => Center(
          child: SizedBox(
            width: 220,
            height: 140,
            child: CustomPaint(
              painter: _ShaderShapePainter(
                handle: handle,
                time: _time,
                scale: widget.scale,
                strokeWidth: 4,
              ),
            ),
          ),
        ),
        Carrier.icon => Center(child: _masked(handle, _sampleIcons())),
        Carrier.divider => _DividerFrame(child: _fill(handle)),
      },
    );
  }

  Widget _fill(CarrierShaderHandle handle) => CustomPaint(
    painter: _ShaderShapePainter(
      handle: handle,
      time: _time,
      scale: widget.scale,
    ),
    child: const SizedBox.expand(),
  );

  /// ShaderMask + srcIn — the §2.2 mechanism that reaches text and icon.
  /// Rebuilt per tick via the time listenable so the mask animates too.
  Widget _masked(CarrierShaderHandle handle, Widget child) =>
      ValueListenableBuilder<double>(
        valueListenable: _time,
        builder: (context, time, _) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => handle.build(bounds, widget.scale, time),
          child: child,
        ),
      );

  Widget _sampleText() => const Text(
    'Snipz',
    style: TextStyle(
      // White base — srcIn replaces every opaque pixel with the paint.
      color: Colors.white,
      fontSize: 64,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
  );

  Widget _sampleIcons() => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.auto_awesome, size: 24, color: Colors.white),
      SizedBox(width: 16),
      Icon(Icons.auto_awesome, size: 32, color: Colors.white),
      SizedBox(width: 16),
      Icon(Icons.auto_awesome, size: 48, color: Colors.white),
    ],
  );
}

/// Hosts a non-shader paint by embedding its widget into the carrier shape.
/// Only shape carriers are possible this way; the switcher never routes
/// text/icon/border here (they need a Shader or an explicit carrierBuilder).
class WidgetCarrierStage extends StatelessWidget {
  const WidgetCarrierStage({
    super.key,
    required this.builder,
    required this.carrier,
  });

  final WidgetBuilder builder;
  final Carrier carrier;

  /// Carriers this pipeline can host.
  static const Set<Carrier> supported = {
    Carrier.fullscreen,
    Carrier.card,
    Carrier.button,
    Carrier.divider,
  };

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: carrierStageKey(carrier),
      child: switch (carrier) {
        Carrier.fullscreen => builder(context),
        Carrier.card => _CardFrame(child: builder(context)),
        Carrier.button => _ButtonFrame(background: builder(context)),
        Carrier.divider => _DividerFrame(child: builder(context)),
        _ => const SizedBox.shrink(), // unreachable: switcher filters first
      },
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ButtonFrame extends StatelessWidget {
  const _ButtonFrame({required this.background});

  final Widget background;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 52,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              background,
              const Center(
                child: Text(
                  'Button',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DividerFrame extends StatelessWidget {
  const _DividerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(height: 4, width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// Paints the shader into the full rect (fill) or as a rounded-rect stroke
/// (border carrier). Repaints off the shared time listenable — no per-frame
/// widget rebuilds for shape carriers.
class _ShaderShapePainter extends CustomPainter {
  _ShaderShapePainter({
    required this.handle,
    required this.time,
    required this.scale,
    this.strokeWidth,
  }) : super(repaint: time);

  final CarrierShaderHandle handle;
  final ValueNotifier<double> time;
  final double scale;
  final double? strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Rect rect = Offset.zero & size;
    final Paint paint = Paint()..shader = handle.build(rect, scale, time.value);
    final double? stroke = strokeWidth;
    if (stroke == null) {
      canvas.drawRect(rect, paint);
    } else {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(stroke / 2), const Radius.circular(16)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShaderShapePainter oldDelegate) =>
      oldDelegate.handle != handle ||
      oldDelegate.scale != scale ||
      oldDelegate.strokeWidth != strokeWidth;
}
