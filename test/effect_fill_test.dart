// Regression: full-bleed effect components must EXPAND under loose
// constraints. A childless CustomPaint has preferred size zero — grid_ripple
// and line_drawing shipped collapsed to 0x0 inside the viewer stage (black
// screen) before growing an expanding child.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/grid_ripple/grid_ripple.dart';
import 'package:snipz/components/line_drawing/line_drawing.dart';

void main() {
  Future<void> pumpLoose(WidgetTester tester, Widget child) {
    // Center = bounded but LOOSE constraints, like the viewer stage.
    return tester.pumpWidget(
      MaterialApp(home: Center(child: child)),
    );
  }

  testWidgets('GridRipple expands under loose constraints', (tester) async {
    await pumpLoose(tester, const GridRipple(frozenAt: 1.1));
    expect(tester.getSize(find.byType(GridRipple)), const Size(800, 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('LineDrawing expands under loose constraints', (tester) async {
    await pumpLoose(tester, const LineDrawing(frozenAt: 3.2));
    expect(tester.getSize(find.byType(LineDrawing)), const Size(800, 600));
    expect(tester.takeException(), isNull);
  });
}
