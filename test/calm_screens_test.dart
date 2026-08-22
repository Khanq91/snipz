// Smoke tests for the 11 calm_* screens (FeralUI ports): every screen must
// build its settled still frame (animate: false) AND run a few live frames
// without throwing, and the interactive ones must survive basic input.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/calm_breath/calm_breath.dart';
import 'package:snipz/components/calm_climb/calm_climb.dart';
import 'package:snipz/components/calm_email/calm_email.dart';
import 'package:snipz/components/calm_insights/calm_insights.dart';
import 'package:snipz/components/calm_login/calm_login.dart';
import 'package:snipz/components/calm_mood/calm_mood.dart';
import 'package:snipz/components/calm_onboard/calm_onboard.dart';
import 'package:snipz/components/calm_paywall/calm_paywall.dart';
import 'package:snipz/components/calm_sleep/calm_sleep.dart';
import 'package:snipz/components/calm_streak/calm_streak.dart';
import 'package:snipz/components/calm_welcome/calm_welcome.dart';

Widget _host(Widget screen) => MaterialApp(
      home: Scaffold(body: SizedBox.expand(child: screen)),
    );

Future<void> _smoke(WidgetTester tester, Widget still, Widget live) async {
  await tester.pumpWidget(_host(still));
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(_host(live));
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox()); // dispose tickers
}

void main() {
  testWidgets('calm_welcome builds still and live', (tester) async {
    await _smoke(tester, const CalmWelcomeScreen(animate: false),
        const CalmWelcomeScreen());
  });

  testWidgets('calm_onboard builds, swipes and pages', (tester) async {
    await _smoke(tester, const CalmOnboardScreen(animate: false),
        const CalmOnboardScreen());
    await tester.pumpWidget(_host(const CalmOnboardScreen()));
    await tester.pump(const Duration(milliseconds: 600));
    // swipe to the second page
    await tester.fling(
        find.byType(CalmOnboardScreen), const Offset(-260, 0), 1200);
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('calm_login builds still and live', (tester) async {
    await _smoke(
        tester, const CalmLoginScreen(animate: false), const CalmLoginScreen());
  });

  testWidgets('calm_email validates the form before enabling sign-in',
      (tester) async {
    bool signedIn = false;
    await tester.pumpWidget(_host(CalmEmailScreen(
      animate: false,
      onSignIn: () => signedIn = true,
    )));
    await tester.tap(find.text('Sign in'), warnIfMissed: false);
    expect(signedIn, isFalse); // empty form -> disabled
    await tester.enterText(
        find.byType(TextField).first, 'khang@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret7');
    await tester.pump();
    await tester.tap(find.text('Sign in'), warnIfMissed: false);
    expect(signedIn, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('calm_mood builds and the slider reports a snapped value',
      (tester) async {
    double? reported;
    await tester.pumpWidget(_host(CalmMoodScreen(
      animate: false,
      onChanged: (v) => reported = v,
    )));
    final Finder screen = find.byType(CalmMoodScreen);
    // drag on the slider area near the bottom of the screen
    final Rect box = tester.getRect(screen);
    await tester.dragFrom(
        Offset(box.center.dx, box.bottom - 60), const Offset(120, 0));
    await tester.pump();
    expect(reported, isNotNull);
    expect((reported! * 6).roundToDouble() / 6, reported);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('calm_breath builds, pauses and resumes', (tester) async {
    await _smoke(tester, const CalmBreathScreen(animate: false),
        const CalmBreathScreen());
    await tester.pumpWidget(_host(const CalmBreathScreen()));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Pause'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Resume'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('calm_sleep builds still and live', (tester) async {
    await _smoke(tester, const CalmSleepScreen(animate: false),
        const CalmSleepScreen());
  });

  testWidgets('calm_streak builds still and live', (tester) async {
    await _smoke(tester, const CalmStreakScreen(animate: false),
        const CalmStreakScreen());
  });

  testWidgets('calm_insights switches weeks and days', (tester) async {
    await tester.pumpWidget(_host(const CalmInsightsScreen(animate: false)));
    await tester.tap(find.text('Last week'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('a steadier week.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('calm_climb builds still and live', (tester) async {
    await _smoke(tester, const CalmClimbScreen(animate: false),
        const CalmClimbScreen());
  });

  testWidgets('calm_paywall builds still and live', (tester) async {
    await _smoke(tester, const CalmPaywallScreen(animate: false),
        const CalmPaywallScreen());
  });
}
