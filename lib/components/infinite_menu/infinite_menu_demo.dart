// Demo/usage example for InfiniteMenu. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).
//
// Real apps pass normal ImageProviders (NetworkImage, AssetImage, ...).
// The demo has no assets, so it paints its own disc images procedurally.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'infinite_menu.dart';

final ComponentDemo infiniteMenuDemo = ComponentDemo(
  id: 'infinite_menu',
  builder: (context) => const _InfiniteMenuShowcase(),
  // Frozen sphere for the gallery grid — no ticker, no overlay (§8.3).
  thumbnailBuilder: (context) => InfiniteMenu(
    items: _demoItems(context, interactive: false),
    animate: false,
    showOverlay: false,
  ),
);

/// Fullscreen sphere with the faithful overlay: drag to spin, release to
/// snap; the active item's title/description fade back in and the accent
/// button fires the item's [InfiniteMenuItem.onPressed].
class _InfiniteMenuShowcase extends StatelessWidget {
  const _InfiniteMenuShowcase();

  @override
  Widget build(BuildContext context) {
    return InfiniteMenu(
      items: _demoItems(context, interactive: true),
      scale: 1.0,
    );
  }
}

List<InfiniteMenuItem> _demoItems(BuildContext context,
    {required bool interactive}) {
  const List<(String, String, Color, Color)> specs = <(String, String, Color, Color)>[
    ('Aurora', 'Northern sky gradients', Color(0xFF5227FF), Color(0xFF00E5FF)),
    ('Ember', 'Warm analog glow', Color(0xFFFF4D00), Color(0xFFFFC800)),
    ('Reef', 'Shallow water light', Color(0xFF00B894), Color(0xFF0984E3)),
    ('Dusk', 'Violet hour palette', Color(0xFF6C5CE7), Color(0xFFFD79A8)),
    ('Moss', 'Forest floor tones', Color(0xFF2D6A4F), Color(0xFFB7E4C7)),
    ('Static', 'Broadcast off-air', Color(0xFF2D3436), Color(0xFFB2BEC3)),
    ('Solar', 'Flare photography', Color(0xFFE17055), Color(0xFFFFEAA7)),
    ('Void', 'Deep field survey', Color(0xFF0F0F1A), Color(0xFF5227FF)),
  ];
  return <InfiniteMenuItem>[
    for (int i = 0; i < specs.length; i++)
      InfiniteMenuItem(
        image: _DiscImage(i, specs[i].$3, specs[i].$4, specs[i].$1),
        title: specs[i].$1,
        description: specs[i].$2,
        onPressed: interactive
            ? () => ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar(
                    content: Text('Opened "${specs[i].$1}"'),
                    duration: const Duration(seconds: 1),
                  ),
                )
            : null,
      ),
  ];
}

/// Procedural 512×512 disc art: diagonal gradient, soft highlight, big index
/// glyph — stands in for the Unsplash photos of the original demo.
class _DiscImage extends ImageProvider<_DiscImage> {
  const _DiscImage(this.index, this.colorA, this.colorB, this.label);

  final int index;
  final Color colorA;
  final Color colorB;
  final String label;

  @override
  Future<_DiscImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_DiscImage>(this);

  @override
  ImageStreamCompleter loadImage(_DiscImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(_paint());

  Future<ImageInfo> _paint() async {
    const double side = 512;
    const Rect rect = Rect.fromLTWH(0, 0, side, side);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, rect);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          <Color>[colorA, colorB],
        ),
    );
    canvas.drawCircle(
      const Offset(side * 0.30, side * 0.28),
      side * 0.42,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: side * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        Offset(
            (side - tp.width) / 2, (side - tp.height) / 2 - side * 0.02));

    final ui.Image image =
        await recorder.endRecording().toImage(side.toInt(), side.toInt());
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(Object other) =>
      other is _DiscImage &&
      other.index == index &&
      other.colorA == colorA &&
      other.colorB == colorB;

  @override
  int get hashCode => Object.hash(index, colorA, colorB);
}
