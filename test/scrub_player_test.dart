// Scrubber v2 (GSDevTools-style transport): the sample(t) scrub player in
// PreviewStage — frame rendering at the scrubbed time, play/pause looping
// inside the in/out window, ±1-frame steps, speed presets via timeDilation
// (reset on dispose), and session-scoped per-component persistence.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/features/detail/preview_stage.dart';

ComponentMeta _meta(String id) => ComponentMeta.fromJson({
  'id': id,
  'title': 'Scrub Target',
  'kind': 'composite',
  'tags': <Object?>[],
  'paint_source': 'painter',
  'carriers_verified': <Object?>[],
  'carriers_failed': <String, Object?>{},
  'scale_aware': false,
  'portability': 'single_file',
  'entry': '$id.dart',
  'files': {'$id.dart': 'entry'},
  'vendored_from': null,
  'assets_required': <Object?>[],
  'shaders_required': <Object?>[],
  'deps': <String, Object?>{},
  'origin': 'original',
  'source': null,
  'author': 'test',
  'license': null,
  'created': '2026-08-27',
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

ComponentDemo _scrubDemo(String id) => ComponentDemo(
  id: id,
  builder: (context) => const Text('live'),
  scrubBuilder: (context, t) => Text('t=${t.toStringAsFixed(2)}'),
  scrubDuration: 2,
);

Widget _host(String id) => MaterialApp(
  home: Scaffold(
    body: PreviewStage(
      meta: _meta(id),
      demo: _scrubDemo(id),
      initialFrozen: true,
    ),
  ),
);

/// Advances the scrub ticker ~[seconds] via 16ms frames (the player clamps
/// per-tick deltas, so one long pump cannot fast-forward it).
Future<void> _run(WidgetTester tester, double seconds) async {
  final int frames = (seconds / 0.016).ceil();
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  tearDown(() => timeDilation = 1.0);

  testWidgets('freeze shows the transport and the t=0 frame', (tester) async {
    await tester.pumpWidget(_host('scrub_a'));
    expect(find.text('t=0.00'), findsOneWidget);
    expect(find.byKey(const ValueKey('scrub-play')), findsOneWidget);
    expect(find.byKey(const ValueKey('scrub-slider')), findsOneWidget);
    expect(find.byKey(const ValueKey('scrub-window')), findsOneWidget);
    expect(find.text('live'), findsNothing);
  });

  testWidgets('play advances the frame, pause holds it', (tester) async {
    await tester.pumpWidget(_host('scrub_b'));
    await tester.tap(find.byKey(const ValueKey('scrub-play')));
    await _run(tester, 0.5);
    expect(find.text('t=0.00'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('scrub-play'))); // pause
    await tester.pump();
    final Text frame = tester.widget<Text>(
      find.textContaining(RegExp(r'^t=')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.widget<Text>(find.textContaining(RegExp(r'^t='))).data,
      frame.data,
      reason: 'paused player must hold the frame',
    );
  });

  testWidgets('playback loops inside the window, never past out', (
    tester,
  ) async {
    await tester.pumpWidget(_host('scrub_c'));
    await tester.tap(find.byKey(const ValueKey('scrub-play')));
    // 2s window at 1× needs >2s of frames to wrap at least once.
    await _run(tester, 2.6);
    final String data = tester
        .widget<Text>(find.textContaining(RegExp(r'^t=')))
        .data!;
    final double t = double.parse(data.substring(2));
    expect(t, lessThan(2), reason: 'wrapped back inside the loop window');
  });

  testWidgets('frame step moves exactly 1/60s and pauses playback', (
    tester,
  ) async {
    await tester.pumpWidget(_host('scrub_d'));
    await tester.tap(find.byKey(const ValueKey('scrub-step-fwd')));
    await tester.pump();
    expect(find.text('t=0.02'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scrub-step-back')));
    await tester.pump();
    expect(find.text('t=0.00'), findsOneWidget);
  });

  testWidgets('speed presets set timeDilation and dispose resets it', (
    tester,
  ) async {
    await tester.pumpWidget(_host('scrub_e'));
    await tester.tap(find.byKey(const ValueKey('toggle-speed')));
    await tester.pump();
    expect(find.text('½×'), findsOneWidget);
    expect(timeDilation, 2.0); // 0.5× speed = 2× dilation

    await tester.pumpWidget(const SizedBox()); // dispose the stage
    expect(timeDilation, 1.0);
  });

  testWidgets('per-component speed persists across stage instances', (
    tester,
  ) async {
    await tester.pumpWidget(_host('scrub_f'));
    await tester.tap(find.byKey(const ValueKey('toggle-speed')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());

    await tester.pumpWidget(_host('scrub_f')); // same component id
    expect(find.text('½×'), findsOneWidget);
    expect(timeDilation, 2.0, reason: 'restored speed re-applies dilation');
  });
}
