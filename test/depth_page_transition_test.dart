import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/depth_page_transition/depth_page_transition.dart';
import 'package:snipz/components/depth_page_transition/depth_page_transition_demo.dart';

void main() {
  testWidgets('gallery demo pushes and pops within its own navigator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: depthPageTransitionDemo.builder)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push page').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Page 1'), findsOneWidget);
    await tester.tap(find.text('Go back').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Depth navigation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('thumbnail fits small gallery tiles and scrub endpoints', (
    tester,
  ) async {
    for (final size in [const Size(180, 230), const Size(360, 460)]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Builder(
                builder: depthPageTransitionDemo.thumbnailBuilder!,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    for (final t in [0.0, .225, .45]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) =>
                depthPageTransitionDemo.scrubBuilder!(context, t),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
  for (final reduced in [false, true]) {
    testWidgets('page push/pop retains background; reduced=$reduced', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: ThemeData(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values)
                  platform: const DepthPageTransitionsBuilder(),
              },
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: const Scaffold(body: Center(child: Text('Root page'))),
        ),
      );
      final initial = tester.getCenter(find.text('Root page'));
      final pushed = navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Detail page'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      if (!reduced) {
        expect(
          tester.getCenter(find.text('Root page')).dx,
          lessThan(initial.dx),
        );
        expect(
          tester.getCenter(find.text('Detail page')).dx,
          greaterThan(initial.dx),
        );
      } else {
        expect(tester.getCenter(find.text('Detail page')).dx, initial.dx);
      }
      await tester.pumpAndSettle();
      expect(find.text('Detail page'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Root page'), findsOneWidget);
      expect(find.text('Detail page'), findsNothing);
      await pushed;
      expect(tester.getCenter(find.text('Root page')), initial);
    });
  }
}
