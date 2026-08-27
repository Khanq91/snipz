// Pins the GSAP-ported math (ease_lab curves + inertia_throw solver):
// endpoint contracts, determinism, and the soft-bounds/snap behaviors the
// components rely on. Pure math — no widgets pumped.

import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/ease_lab/ease_lab.dart';
import 'package:snipz/components/inertia_throw/inertia_throw.dart';

void main() {
  group('CubicPathEase', () {
    test('css cubic-bezier hits both endpoints and stays monotonic', () {
      final CubicPathEase ease = CubicPathEase.bezier(0.25, 0.1, 0.25, 1);
      expect(ease.transform(0), 0);
      expect(ease.transform(1), 1);
      double prev = -1;
      for (int i = 0; i <= 100; i++) {
        final double y = ease.transform(i / 100);
        expect(y, greaterThanOrEqualTo(prev - 1e-6));
        prev = y;
      }
    });
  });

  group('WiggleEase', () {
    test('starts and ENDS at 0, peaks within ±1', () {
      for (final WiggleType type in WiggleType.values) {
        final WiggleEase ease = WiggleEase(wiggles: 8, type: type);
        expect(ease.transform(0), closeTo(0, 1e-3), reason: '$type start');
        expect(ease.transform(1), closeTo(0, 1e-3), reason: '$type end');
        double peak = 0;
        for (int i = 0; i <= 200; i++) {
          final double y = ease.transform(i / 200).abs();
          if (y > peak) peak = y;
        }
        expect(peak, greaterThan(0.3), reason: '$type actually wiggles');
        expect(peak, lessThanOrEqualTo(1.2), reason: '$type bounded');
      }
    });

    test('random type is deterministic per seed', () {
      final WiggleEase a = WiggleEase(type: WiggleType.random, seed: 5);
      final WiggleEase b = WiggleEase(type: WiggleType.random, seed: 5);
      final WiggleEase c = WiggleEase(type: WiggleType.random, seed: 6);
      expect(a.transform(0.37), b.transform(0.37));
      expect(a.transform(0.37) == c.transform(0.37), isFalse);
    });
  });

  group('BounceEase / SquashEase', () {
    test('bounce travels 0 → 1 with rebounds above the floor', () {
      final BounceEase ease = BounceEase(strength: 0.6, squash: 3);
      expect(ease.transform(0), 0);
      expect(ease.transform(1), closeTo(1, 1e-3));
      // After the first impact (~0.1 of normalized time) it re-launches:
      // some sample must sit clearly above the floor again.
      bool rebounded = false;
      for (double t = 0.15; t < 1; t += 0.01) {
        if (ease.transform(t) < 0.9) rebounded = true;
      }
      expect(rebounded, isTrue);
    });

    test('squash rests at 0 both ends, peaks 1, stretches negative', () {
      final SquashEase squash = SquashEase(strength: 0.6, squash: 3);
      expect(squash.transform(0), closeTo(0, 1e-3));
      expect(squash.transform(1), closeTo(0, 1e-3));
      double top = 0, bottom = 0;
      for (int i = 0; i <= 400; i++) {
        final double y = squash.transform(i / 400);
        if (y > top) top = y;
        if (y < bottom) bottom = y;
      }
      expect(top, closeTo(1, 0.05), reason: 'full squash at first impact');
      expect(bottom, lessThan(-0.2), reason: 'departure stretch');
    });
  });

  group('SlowMoEase', () {
    test('holds the eased value across the linear middle', () {
      const SlowMoEase ease = SlowMoEase(linearRatio: 0.7, power: 1);
      // power 1 freezes the middle entirely at 0.5.
      expect(ease.transform(0.2), closeTo(0.5, 1e-9));
      expect(ease.transform(0.8), closeTo(0.5, 1e-9));
      expect(ease.transform(0), 0);
      expect(ease.transform(1), 1);
    });

    test('yoyo mode pulses 0 → 1 → 0', () {
      const SlowMoEase yoyo = SlowMoEase(yoyoMode: true);
      expect(yoyo.transform(0), 0);
      expect(yoyo.transform(0.5), 1);
      expect(yoyo.transform(1), 0);
    });
  });

  group('RoughEase', () {
    test('deterministic per seed, clamped when asked', () {
      final RoughEase a = RoughEase(seed: 3, clamp: true);
      final RoughEase b = RoughEase(seed: 3, clamp: true);
      for (int i = 0; i <= 50; i++) {
        final double y = a.transform(i / 50);
        expect(y, b.transform(i / 50));
        expect(y, inInclusiveRange(0, 1));
      }
    });
  });

  group('ExpoScaleEase', () {
    test('remaps linear progress onto geometric interpolation', () {
      final ExpoScaleEase ease = ExpoScaleEase(1, 8);
      expect(ease.transform(0), 0);
      expect(ease.transform(1), closeTo(1, 1e-9));
      // Halfway must correspond to scale 8^0.5: (sqrt(8)-1)/7.
      expect(ease.transform(0.5), closeTo(0.26120, 1e-4));
    });
  });

  group('InertiaFlight', () {
    const Rect bounds = Rect.fromLTRB(0, 0, 500, 500);

    test('faster flicks travel farther, along power3.out', () {
      final InertiaFlight slow = InertiaFlight.solve(
        start: const Offset(250, 250),
        velocity: const Offset(200, 0),
        bounds: bounds,
      );
      final InertiaFlight fast = InertiaFlight.solve(
        start: const Offset(250, 250),
        velocity: const Offset(400, 0),
        bounds: bounds,
      );
      expect(fast.x.end, greaterThan(slow.x.end));
      expect(slow.positionAt(0).dx, 250);
      expect(slow.positionAt(99).dx, closeTo(slow.x.end, 1e-6));
    });

    test('snaps ONLY within the radius, judging the 2D pair', () {
      final InertiaFlight snapped = InertiaFlight.solve(
        start: const Offset(100, 100),
        velocity: const Offset(300, 300),
        bounds: bounds,
        snapPoints: const <Offset>[Offset(200, 200)],
        snapRadius: 200,
      );
      expect(snapped.x.end, 200);
      expect(snapped.y.end, 200);

      final InertiaFlight free = InertiaFlight.solve(
        start: const Offset(100, 100),
        velocity: const Offset(300, 300),
        bounds: bounds,
        snapPoints: const <Offset>[Offset(200, 200)],
        snapRadius: 5,
      );
      expect(free.x.end == 200 && free.y.end == 200, isFalse);
    });

    test('soft bounds: overshoots the wall mid-flight, lands exactly on it',
        () {
      final InertiaFlight flight = InertiaFlight.solve(
        start: const Offset(400, 250),
        velocity: const Offset(3000, 0),
        bounds: bounds,
      );
      expect(flight.x.end, closeTo(500, 1e-6));
      double maxX = 0;
      for (double t = 0; t <= flight.duration; t += flight.duration / 200) {
        maxX = flight.positionAt(t).dx > maxX ? flight.positionAt(t).dx : maxX;
      }
      expect(maxX, greaterThan(500), reason: 'visible push past the wall');
    });
  });
}
