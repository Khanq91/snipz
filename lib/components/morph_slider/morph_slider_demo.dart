// Demo/usage example for MorphSlider. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'morph_slider.dart';

final ComponentDemo morphSliderDemo = ComponentDemo(
  id: 'morph_slider',
  builder: (context) => const _MorphSliderShowcase(),
);

/// Four procedurally painted "photos" (no assets/network in the vault) fed
/// to the slider as [MemoryImage]s. In a real app pass any [ImageProvider]
/// (NetworkImage, AssetImage, ...). Swipe, use the arrows, or the dots.
class _MorphSliderShowcase extends StatefulWidget {
  const _MorphSliderShowcase();

  @override
  State<_MorphSliderShowcase> createState() => _MorphSliderShowcaseState();
}

class _MorphSliderShowcaseState extends State<_MorphSliderShowcase> {
  late final Future<List<MorphSliderItem>> _items = _paintItems();
  MorphTransition _transition = MorphTransition.melt;

  static Future<List<MorphSliderItem>> _paintItems() async {
    const List<(String, List<Color>)> scenes = <(String, List<Color>)>[
      ('Dusk', <Color>[Color(0xFF1A0533), Color(0xFF5227FF), Color(0xFFFF6D3A)]),
      ('Reef', <Color>[Color(0xFF001B33), Color(0xFF00B0FF), Color(0xFF00BFA5)]),
      ('Ember', <Color>[Color(0xFF200000), Color(0xFFD32F2F), Color(0xFFFFB300)]),
      ('Orchid', <Color>[Color(0xFF29003A), Color(0xFFD500F9), Color(0xFFFF80AB)]),
    ];
    final List<MorphSliderItem> items = <MorphSliderItem>[];
    for (int s = 0; s < scenes.length; s++) {
      final (String caption, List<Color> colors) = scenes[s];
      items.add(
        MorphSliderItem(
          image: MemoryImage(await _paintScene(s, colors)),
          caption: caption,
        ),
      );
    }
    return items;
  }

  static Future<Uint8List> _paintScene(int seed, List<Color> colors) async {
    const Size size = Size(800, 600);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );
    // A few soft discs so each slide has recognizable features to morph.
    for (int i = 0; i < 5; i++) {
      final double t = (seed * 5 + i) * 2.399963; // golden-angle scatter
      canvas.drawCircle(
        Offset(
          size.width * (0.5 + 0.38 * ui.lerpDouble(-1, 1, t * 7 % 1)!),
          size.height * (0.5 + 0.38 * ui.lerpDouble(-1, 1, t * 13 % 1)!),
        ),
        40.0 + 40 * ((t * 3) % 1),
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    final ui.Image image = await recorder
        .endRecording()
        .toImage(size.width.toInt(), size.height.toInt());
    final ByteData bytes =
        (await image.toByteData(format: ui.ImageByteFormat.png))!;
    image.dispose();
    return bytes.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: FutureBuilder<List<MorphSliderItem>>(
        future: _items,
        builder: (context, snapshot) {
          final List<MorphSliderItem>? items = snapshot.data;
          if (items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MorphSlider(items: items, transition: _transition),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SegmentedButton<MorphTransition>(
                  segments: <ButtonSegment<MorphTransition>>[
                    for (final MorphTransition t in MorphTransition.values)
                      ButtonSegment<MorphTransition>(
                        value: t,
                        label: Text(t.name),
                      ),
                  ],
                  selected: <MorphTransition>{_transition},
                  onSelectionChanged: (selection) =>
                      setState(() => _transition = selection.first),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
