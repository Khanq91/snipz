// D4: the share-as-PNG button on the preview stage. The capture pipeline
// (RepaintBoundary -> toImage -> PNG -> share sheet) runs for real up to the
// share_plus call, which has no test implementation — the caught failure
// surfaces as a SnackBar, which is exactly the production error path.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/features/detail/preview_stage.dart';

ComponentMeta _meta(String kind) => ComponentMeta.fromJson({
  'id': 'test_share',
  'title': 'Test Share',
  'kind': kind,
  'tags': <Object?>[],
  'paint_source': 'painter',
  'carriers_verified': <Object?>[],
  'carriers_failed': <String, Object?>{},
  'scale_aware': false,
  'portability': 'single_file',
  'entry': 'test_share.dart',
  'files': {'test_share.dart': 'entry'},
  'vendored_from': null,
  'assets_required': <Object?>[],
  'shaders_required': <Object?>[],
  'deps': <String, Object?>{},
  'origin': 'original',
  'source': null,
  'author': 'test',
  'license': null,
  'created': '2026-08-21',
  'created_flutter': '3.44.5',
  'created_dart': '3.12.2',
  'created_deps': <String, Object?>{},
  'platforms_initial': ['android'],
  'version': '1.0.0',
  'latest_known_good': null,
  'last_verified': null,
  'status': null,
  'preview': null,
  'test_history': <Object?>[],
});

ComponentDemo _demo() => ComponentDemo(
  id: 'test_share',
  builder: (context) => const ColoredBox(
    color: Color(0xFF336699),
    child: Center(child: Text('content')),
  ),
);

void main() {
  for (final String kind in ['composite', 'effect', 'paint']) {
    testWidgets('$kind stage shows the share-as-PNG button', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: PreviewStage(meta: _meta(kind), demo: _demo())),
      ));
      expect(find.byKey(const ValueKey('share-image')), findsOneWidget);
    });
  }

  testWidgets('capture runs and the failing share surfaces as a SnackBar',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PreviewStage(meta: _meta('composite'), demo: _demo()),
      ),
    ));
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('share-image')));
      // real async: toImage + PNG encode + temp-file write, then share_plus
      // throws MissingPluginException in the test env
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
