import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/main.dart';

void main() {
  testWidgets('app boots without exceptions', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
