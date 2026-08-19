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
  // Grid thumbnails must not run the shader/ticker or decode images (§9.2):
  // static mock of the "Dusk" slide — gradient, caption chip, arrows, dots.
  thumbnailBuilder: (context) => const _MorphSliderThumb(),
);

/// Static stand-in for the gallery tile: recreates the resting look of the
/// slider (first "Dusk" scene + its chrome) with plain boxes — no shader, no
/// image decode, no ticker. Designed at a fixed 340x430 and scaled to fit.
class _MorphSliderThumb extends StatelessWidget {
  const _MorphSliderThumb();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 340,
            height: 430,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    // The "Dusk" scene gradient from _paintItems.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color(0xFF1A0533),
                            Color(0xFF5227FF),
                            Color(0xFFFF6D3A),
                          ],
                        ),
                      ),
                    ),
                    // Soft discs standing in for the scene's blurred features.
                    Positioned(
                      top: 50,
                      left: 30,
                      child: _softDisc(140, const Color(0x995227FF)),
                    ),
                    Positioned(
                      bottom: 110,
                      right: 20,
                      child: _softDisc(120, const Color(0x8CFF6D3A)),
                    ),
                    // Prev/next arrows, same chrome as _roundButton.
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            _arrow(Icons.chevron_left),
                            _arrow(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    // Caption chip ("Dusk"), as in _buildCaption.
                    Positioned(
                      left: 20,
                      bottom: 44,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x6B0A0A0C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Dusk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                    ),
                    // Indicator dots: first one active/elongated.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _dot(22, 0.95),
                          _dot(8, 0.35),
                          _dot(8, 0.35),
                          _dot(8, 0.35),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _softDisc(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  static Widget _arrow(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0x660C0C0E),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, size: 22, color: Colors.white),
    );
  }

  static Widget _dot(double width, double alpha) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

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
