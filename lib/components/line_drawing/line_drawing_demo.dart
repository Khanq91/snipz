// Demo/usage example for LineDrawing. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'line_drawing.dart';

final ComponentDemo lineDrawingDemo = ComponentDemo(
  id: 'line_drawing',
  builder: (context) => const LineDrawing(),
  thumbnailBuilder: (context) =>
      const LineDrawing(count: 14, frozenAt: 3.2),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'circles',
      label: 'circles',
      builder: (context) => const LineDrawing(),
      frozenBuilder: (context) => const LineDrawing(frozenAt: 3.2),
    ),
    DemoVariant(
      id: 'lines',
      label: 'lines',
      builder: (context) =>
          const LineDrawing(variant: LineDrawingVariant.lines),
      frozenBuilder: (context) => const LineDrawing(
          variant: LineDrawingVariant.lines, frozenAt: 3.2),
    ),
    DemoVariant(
      id: 'mono',
      label: 'mono ice',
      builder: (context) => const LineDrawing(
        colorFrom: Color(0xFF9FC3F5),
        colorTo: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF0B1220),
      ),
      frozenBuilder: (context) => const LineDrawing(
        colorFrom: Color(0xFF9FC3F5),
        colorTo: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF0B1220),
        frozenAt: 3.2,
      ),
    ),
  ],
);
