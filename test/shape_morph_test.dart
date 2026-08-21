// Unit tests for the shape_morph component's math core (no widgets pumped —
// RadialShape is pure data + Path building).

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/shape_morph/shape_morph.dart';

void main() {
  test('lerp returns the endpoints at t=0 and t=1', () {
    final a = RadialShape.circle(1);
    final b = RadialShape.superellipse(4);
    expect(RadialShape.lerp(a, b, 0).radii, a.radii);
    expect(RadialShape.lerp(a, b, 1).radii, b.radii);
  });

  test('rotation interpolates along the shortest arc', () {
    final a = RadialShape.circle().copyWith(rot: 170 * math.pi / 180);
    final b = RadialShape.circle().copyWith(rot: -170 * math.pi / 180);
    final mid = RadialShape.lerp(a, b, 0.5);
    // Halfway from +170° to −170° through the short way is ±180°, never 0°.
    expect(mid.rot.abs(), closeTo(math.pi, 1e-9));
  });

  test('sequence hits keyframes exactly and wraps when looping', () {
    final shapes = [
      RadialShape.circle(0.5),
      RadialShape.circle(1.0),
      RadialShape.circle(1.5),
    ];
    expect(RadialShape.sequence(shapes, 1).radii.first, 1.0);
    // Non-loop clamps at the last shape.
    expect(RadialShape.sequence(shapes, 99).radii.first, 1.5);
    // Loop: segment [2, 3] blends back toward the first shape.
    expect(RadialShape.sequence(shapes, 2.5, loop: true).radii.first,
        closeTo(1.0, 1e-9));
  });

  test('regular polygon profile stays within its inscribing radius', () {
    final hex = RadialShape.regularPolygon(6, cornerRadius: 0.18);
    expect(hex.radii.reduce(math.max), lessThanOrEqualTo(1.0 + 1e-6));
    expect(hex.radii.reduce(math.min), greaterThan(0.5));
  });

  test('union of circles is exact along a ray through a disc center', () {
    // One disc centered at (0.5, 0) with r 0.3: along +x the profile must
    // reach 0.8.
    final blob = RadialShape.unionOfCircles([(x: 0.5, y: 0.0, r: 0.3)]);
    expect(blob.radii.first, closeTo(0.8, 1e-9));
  });

  test('radiusAt interpolates between samples', () {
    final egg = RadialShape.superellipse(4, sx: 1, sy: 0.8);
    final r0 = egg.radiusAt(0);
    expect(r0, closeTo(egg.radii.first, 1e-9));
    // Any direction stays within the sampled min/max.
    final r = egg.radiusAt(0.123);
    expect(r, lessThanOrEqualTo(egg.radii.reduce(math.max) + 1e-9));
    expect(r, greaterThanOrEqualTo(egg.radii.reduce(math.min) - 1e-9));
  });

  test('toPath produces a closed, non-empty path with the right extent', () {
    final path = RadialShape.circle().toPath(radius: 100);
    final bounds = path.getBounds();
    // A unit circle at radius 100 spans ~200 px in both axes.
    expect(bounds.width, closeTo(200, 2));
    expect(bounds.height, closeTo(200, 2));
  });
}
