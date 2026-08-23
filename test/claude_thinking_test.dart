// ClaudeThinking's one-way text-type effect (1.1.0): the verb reveals
// left-to-right as a pure function of elapsed time; still frames show the
// full verb.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/claude_thinking/claude_thinking.dart';

void main() {
  Widget host(Widget child) => Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      );

  testWidgets('animate:false shows the full verb — no typing', (tester) async {
    await tester.pumpWidget(host(const ClaudeThinking(animate: false)));
    expect(find.text('Thinking…'), findsOneWidget);
  });

  testWidgets('verb types itself left-to-right at 55ms/char', (tester) async {
    await tester.pumpWidget(host(const ClaudeThinking()));
    // first frame: elapsed 0 → nothing revealed yet
    expect(find.text(''), findsOneWidget);

    // 120ms → floor(120/55) = 2 chars
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Th'), findsOneWidget);

    // well past 9 × 55ms → the whole 'Thinking…' stands
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Thinking…'), findsOneWidget);
  });

  testWidgets('typeEffect:false swaps instantly like the CLI', (tester) async {
    await tester.pumpWidget(host(const ClaudeThinking(typeEffect: false)));
    expect(find.text('Thinking…'), findsOneWidget);
  });

  testWidgets('a single fixed verb types once at mount', (tester) async {
    await tester.pumpWidget(
      host(const ClaudeThinking(verbs: <String>['Loading'])),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Lo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Loading…'), findsOneWidget);
    // single-element verbs never re-cycle — 10s later it still stands whole
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Loading…'), findsOneWidget);
  });
}
