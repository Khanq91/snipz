// Demo/usage example for GridRipple. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'grid_ripple.dart';

final ComponentDemo gridRippleDemo = ComponentDemo(
  id: 'grid_ripple',
  builder: (context) => const GridRipple(),
  thumbnailBuilder: (context) => const GridRipple(rows: 7, frozenAt: 1.1),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'charcoal',
      label: 'charcoal',
      builder: (context) => const GridRipple(),
      frozenBuilder: (context) => const GridRipple(frozenAt: 1.1),
    ),
    DemoVariant(
      id: 'blueprint',
      label: 'blueprint',
      builder: (context) => const GridRipple(
        dotColor: Color(0xFF9FC3F5),
        cursorColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF0D1B33),
      ),
      frozenBuilder: (context) => const GridRipple(
        dotColor: Color(0xFF9FC3F5),
        cursorColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF0D1B33),
        frozenAt: 1.1,
      ),
    ),
    DemoVariant(
      id: 'dense',
      label: 'dense 15',
      builder: (context) => const GridRipple(rows: 15),
      frozenBuilder: (context) => const GridRipple(rows: 15, frozenAt: 1.1),
    ),
  ],
);
