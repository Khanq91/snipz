// Demo/usage example for InertiaThrow. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).
//
// InertiaFlight.solve() cũng dùng độc lập được cho bất kỳ vật ném nào:
//   final f = InertiaFlight.solve(start: p, velocity: v, bounds: r,
//       snapPoints: pegs);
//   ... mỗi frame: f.positionAt(elapsed)

import 'package:snipz/core/component_demo.dart';

import 'inertia_throw.dart';

final ComponentDemo inertiaThrowDemo = ComponentDemo(
  id: 'inertia_throw',
  builder: (context) => const InertiaThrow(),
  // Auto-demo script replayed to mid-flight of the first throw — no ticker.
  thumbnailBuilder: (context) => const InertiaThrow(frozenAt: 1.5),
  // sample(t): scrub through the deterministic auto-demo script.
  scrubBuilder: (context, t) => InertiaThrow(frozenAt: t),
  scrubDuration: 12, // first four scripted throws
  variants: [
    DemoVariant(
      id: 'free',
      label: 'No snap',
      builder: (context) => const InertiaThrow(snapRadius: 0, showGrid: false),
      frozenBuilder: (context) => const InertiaThrow(
        snapRadius: 0,
        showGrid: false,
        frozenAt: 1.5,
      ),
    ),
    DemoVariant(
      id: 'magnet',
      label: 'Strong snap',
      builder: (context) => const InertiaThrow(snapRadius: 999),
      frozenBuilder: (context) =>
          const InertiaThrow(snapRadius: 999, frozenAt: 1.5),
    ),
  ],
);
