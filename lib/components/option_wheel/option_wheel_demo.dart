// Demo/usage example for OptionWheel. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snipz/core/component_demo.dart';

import 'option_wheel.dart';

final ComponentDemo optionWheelDemo = ComponentDemo(
  id: 'option_wheel',
  builder: (context) => const _OptionWheelShowcase(),
  // Real wheel frozen at rest (its ticker only runs while spinning) — no
  // status text, designed at a fixed 360x460 so nothing overlaps at tile size.
  thumbnailBuilder: (context) => ColoredBox(
    color: const Color(0xFF060010),
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 360,
        height: 460,
        child: OptionWheel(
          items: const <String>[
            'House',
            'Techno',
            'Jazz',
            'Lo-Fi',
            'Synthwave',
            'Trance',
            'Funk',
          ],
          initialIndex: 2,
          fontSize: 44,
          inset: 28,
          draggable: false,
        ),
      ),
    ),
  ),
);

/// The original genre picker: drag vertically (or tap an entry) to spin;
/// selection changes tick with haptics via [OptionWheel.onTick].
class _OptionWheelShowcase extends StatefulWidget {
  const _OptionWheelShowcase();

  @override
  State<_OptionWheelShowcase> createState() => _OptionWheelShowcaseState();
}

class _OptionWheelShowcaseState extends State<_OptionWheelShowcase> {
  static const List<String> _genres = <String>[
    'Ambient',
    'House',
    'Techno',
    'Jazz',
    'Lo-Fi',
    'Synthwave',
    'Trance',
    'Funk',
    'Disco',
    'Hip-Hop',
    'Chillwave',
    'Drum & Bass',
  ];

  String _selected = _genres[3];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: OptionWheel(
              items: _genres,
              initialIndex: 3,
              fontSize: 40,
              inset: 32,
              onTick: HapticFeedback.selectionClick,
              onChanged: (index, item) => setState(() => _selected = item),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Text(
              'now playing: $_selected',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
