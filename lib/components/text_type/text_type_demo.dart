// Demo/usage example for TextType. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'text_type.dart';

final ComponentDemo textTypeDemo = ComponentDemo(
  id: 'text_type',
  builder: (context) => const _TextTypeShowcase(),
  // Thumbnail tĩnh: mock hai dòng đã gõ xong + cursor đứng yên (không dùng
  // TextType thật vì cursor của nó luôn blink bằng AnimationController).
  thumbnailBuilder: (context) => const _TextTypeThumbnail(),
);

/// Thumbnail cho gallery grid: hai dòng của demo ở trạng thái "gõ xong" —
/// dòng trắng đậm với cursor `|`, dòng xanh với cursor `▍` — thu về ô tile
/// bằng FittedBox. Thuần Text, không timer/ticker.
class _TextTypeThumbnail extends StatelessWidget {
  const _TextTypeThumbnail();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF060010),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Text typing effect |',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'per-sentence colors ▍',
                  style: TextStyle(color: Color(0xFF40FFAA), fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The looping multi-sentence default plus a variable-speed, per-sentence
/// colored variant; restart from outside via `GlobalKey<TextTypeState>`.
class _TextTypeShowcase extends StatefulWidget {
  const _TextTypeShowcase();

  @override
  State<_TextTypeShowcase> createState() => _TextTypeShowcaseState();
}

class _TextTypeShowcaseState extends State<_TextTypeShowcase> {
  final GlobalKey<TextTypeState> _colored = GlobalKey<TextTypeState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _colored.currentState?.restart(),
      child: ColoredBox(
        color: const Color(0xFF060010),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const TextType(
                  <String>[
                    'Text typing effect',
                    'for your websites',
                    'Happy coding!',
                  ],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                TextType(
                  const <String>['variable speed…', 'per-sentence colors'],
                  key: _colored,
                  variableSpeedMin: const Duration(milliseconds: 30),
                  variableSpeedMax: const Duration(milliseconds: 140),
                  textColors: const <Color>[
                    Color(0xFF40FFAA),
                    Color(0xFFB19EEF),
                  ],
                  cursorText: '▍',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 40),
                const Text(
                  'tap anywhere to restart the second line',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
