// Demo/usage example for ShapeMorph. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'shape_morph.dart';

final ComponentDemo shapeMorphDemo = ComponentDemo(
  id: 'shape_morph',
  builder: (context) => const _ShapeMorphShowcase(),
  // Thumbnail: one frozen frame mid-morph — no ticker in the gallery grid.
  thumbnailBuilder: (context) => const _ShapeMorphThumbnail(),
  // The five demo keyframes as variants: ShapeMorph is stateless (time comes
  // in via t), so live and frozen are the same still frame.
  variants: [
    for (final (int i, String label) in const [
      (0, 'circle'),
      (1, 'squircle'),
      (2, 'hexagon'),
      (3, 'star'),
      (4, 'blob'),
    ])
      DemoVariant(
        id: label,
        label: label,
        builder: (context) => ShapeMorph(
          shapes: _demoShapes,
          t: i.toDouble(),
          color: Theme.of(context).colorScheme.primary,
          fit: 0.8,
        ),
      ),
  ],
);

/// The five keyframes the demo cycles through. Built once — every factory
/// that ray-casts does its work at construction, never per frame.
final List<RadialShape> _demoShapes = [
  RadialShape.circle(),
  RadialShape.superellipse(4), // squircle
  RadialShape.regularPolygon(6, cornerRadius: 0.18, rotationDeg: -90),
  RadialShape.polygon(_star(spikes: 5, outer: 1.05, inner: 0.55)).normalized(),
  RadialShape.unionOfCircles([
    (x: 0.0, y: 0.25, r: 0.62),
    (x: -0.42, y: -0.05, r: 0.45),
    (x: 0.16, y: -0.28, r: 0.48),
    (x: 0.48, y: 0.1, r: 0.4),
  ]).normalized(),
];

List<Offset> _star({required int spikes, required double outer, required double inner}) {
  return List.generate(spikes * 2, (i) {
    final double r = i.isEven ? outer : inner;
    final double a = -math.pi / 2 + i * math.pi / spikes;
    return Offset(r * math.cos(a), r * math.sin(a));
  });
}

class _ShapeMorphShowcase extends StatefulWidget {
  const _ShapeMorphShowcase();

  @override
  State<_ShapeMorphShowcase> createState() => _ShapeMorphShowcaseState();
}

class _ShapeMorphShowcaseState extends State<_ShapeMorphShowcase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: 2 * _demoShapes.length),
  )..repeat();

  bool _auto = true;
  double _manualT = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double t = _auto
                  ? _controller.value * _demoShapes.length
                  : _manualT;
              final RadialShape current =
                  RadialShape.sequence(_demoShapes, t, loop: true);
              return Row(
                children: [
                  // Filled morphing blob.
                  Expanded(
                    child: ShapeMorph(
                      shapes: _demoShapes,
                      t: t,
                      loop: true,
                      color: scheme.primary,
                      fit: 0.82,
                    ),
                  ),
                  // Same shape clipping a gradient — clip any child.
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: ClipPath(
                          clipper: RadialShapeClipper(current, fit: 0.95),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFF8A65),
                                  Color(0xFF7C4DFF),
                                  Color(0xFF18FFFF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Switch(
                value: _auto,
                onChanged: (v) => setState(() {
                  _auto = v;
                  if (!v) {
                    _manualT = _controller.value * _demoShapes.length;
                    _controller.stop();
                  } else {
                    _controller.repeat();
                  }
                }),
              ),
              const SizedBox(width: 4),
              Text(_auto ? 'Auto' : 'Manual'),
              Expanded(
                child: Slider(
                  value: _auto
                      ? _controller.value * _demoShapes.length
                      : _manualT,
                  max: _demoShapes.length.toDouble(),
                  onChanged: _auto
                      ? null
                      : (v) => setState(() => _manualT = v),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One deterministic frame, halfway between squircle and hexagon.
class _ShapeMorphThumbnail extends StatelessWidget {
  const _ShapeMorphThumbnail();

  @override
  Widget build(BuildContext context) {
    return ShapeMorph(
      shapes: _demoShapes,
      t: 1.5,
      color: Theme.of(context).colorScheme.primary,
      fit: 0.8,
    );
  }
}
