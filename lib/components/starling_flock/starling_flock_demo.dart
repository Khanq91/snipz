// Demo/usage example for StarlingFlock. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'starling_flock.dart';

final ComponentDemo starlingFlockDemo = ComponentDemo(
  id: 'starling_flock',
  builder: (context) => const StarlingFlock(),
  // Deterministic mid-flight frame, and far fewer birds for the grid.
  thumbnailBuilder: (context) =>
      const StarlingFlock(count: 400, frozenAt: 6),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'paper',
      label: 'paper',
      builder: (context) => const StarlingFlock(),
      frozenBuilder: (context) => const StarlingFlock(frozenAt: 6),
    ),
    DemoVariant(
      id: 'dusk',
      label: 'dusk',
      builder: (context) => const StarlingFlock(
        backgroundColor: Color(0xFF10131C),
        colors: <Color>[
          Color(0xFFE8DFD2),
          Color(0xFFCBB9A2),
          Color(0xFF8E97AD),
        ],
      ),
      frozenBuilder: (context) => const StarlingFlock(
        backgroundColor: Color(0xFF10131C),
        colors: <Color>[
          Color(0xFFE8DFD2),
          Color(0xFFCBB9A2),
          Color(0xFF8E97AD),
        ],
        frozenAt: 6,
      ),
    ),
    DemoVariant(
      id: 'dense',
      label: 'dense 2500',
      builder: (context) => const StarlingFlock(count: 2500),
      frozenBuilder: (context) =>
          const StarlingFlock(count: 2500, frozenAt: 6),
    ),
  ],
);
