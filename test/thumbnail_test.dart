// Every registry thumbnail must render at gallery-tile size without layout
// exceptions (overflow) and without touching assets — the gallery grid builds
// them all while scrolling. Guards the static-thumbnail contract added when
// the tile previews were reworked.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/app/theme.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/registry.dart';

void main() {
  testWidgets('thumbnails render clean at tile sizes', (tester) async {
    // Two representative tile widths: small phone and the 900px-wide test
    // viewport used by the app tests (2-col grid → ~360 inner width).
    const List<Size> sizes = [Size(180, 230), Size(360, 460)];
    final List<String> failures = <String>[];
    for (final MapEntry<String, ComponentDemo> entry
        in componentRegistry.entries) {
      final WidgetBuilder? thumb = entry.value.thumbnailBuilder;
      if (thumb == null) continue;
      for (final Size size in sizes) {
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            // The app's real theme — font metrics differ from the Material
            // default and a hand-sized design can overflow only under it.
            theme: buildTheme(Brightness.dark),
            home: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: ClipRect(child: Builder(builder: thumb)),
              ),
            ),
          ),
        );
        await tester.pump();
        final Object? e = tester.takeException();
        if (e != null) {
          failures.add('${entry.key} @ $size: $e');
        }
      }
      // Unmount between components so tickers/one-shots die predictably.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final Object? e = tester.takeException();
      if (e != null) failures.add('${entry.key} (dispose): $e');
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
