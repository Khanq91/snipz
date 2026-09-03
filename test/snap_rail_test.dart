// SnapRail: the spring's overshoot must never carry the pill outside the
// rail. Past the end cells it squashes against the wall and rebounds.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/snap_rail/snap_rail.dart';

void main() {
  testWidgets('pill squashes against the rail ends instead of leaving', (
    tester,
  ) async {
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: StatefulBuilder(
            builder: (context, setState) => SnapRail(
              index: index,
              onChanged: (i) => setState(() => index = i),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final track = find.descendant(
      of: find.byType(SnapRail),
      matching: find.byType(Stack),
    );
    final pill = find.descendant(of: track, matching: find.byType(DecoratedBox));
    final trackRect = tester.getRect(track);
    final cellWidth = trackRect.width / 3;
    expect(cellWidth, closeTo((240 - 2 - 8) / 3, 0.01));

    Future<double> sweep(String label) async {
      await tester.tap(find.text(label));
      await tester.pump();
      var narrowest = double.infinity;
      for (var t = 0; t <= 450; t += 25) {
        final r = tester.getRect(pill);
        expect(r.left, greaterThanOrEqualTo(trackRect.left - 0.5), reason: '$label @${t}ms');
        expect(r.right, lessThanOrEqualTo(trackRect.right + 0.5), reason: '$label @${t}ms');
        if (r.width < narrowest) narrowest = r.width;
        await tester.pump(const Duration(milliseconds: 25));
      }
      await tester.pumpAndSettle();
      expect(tester.getSize(pill).width, closeTo(cellWidth, 0.5));
      expect(
        tester.getCenter(pill).dx,
        closeTo(tester.getCenter(find.text(label)).dx, 0.5),
      );
      return narrowest;
    }

    // Day → Month travels two cells and overshoots ~15px; the spring still
    // fires (the pill visibly compresses) but stays inside the rail.
    expect(await sweep('Month'), lessThan(cellWidth - 8));
    expect(await sweep('Day'), lessThan(cellWidth - 8));
    // A middle cell never touches a wall: full width the whole way.
    expect(await sweep('Week'), closeTo(cellWidth, 0.5));
  });

  testWidgets('animate: false jumps straight to the cell', (tester) async {
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: StatefulBuilder(
            builder: (context, setState) => SnapRail(
              index: index,
              animate: false,
              onChanged: (i) => setState(() => index = i),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pill = find.descendant(
      of: find.descendant(of: find.byType(SnapRail), matching: find.byType(Stack)),
      matching: find.byType(DecoratedBox),
    );

    await tester.tap(find.text('Month'));
    await tester.pump();
    expect(
      tester.getCenter(pill).dx,
      closeTo(tester.getCenter(find.text('Month')).dx, 0.5),
    );
  });
}
