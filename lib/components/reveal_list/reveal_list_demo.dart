// Demo/usage example for RevealList. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'reveal_list.dart';

final ComponentDemo revealListDemo = ComponentDemo(
  id: 'reveal_list',
  builder: (context) => const _RevealListShowcase(),
  // Thumbnail tĩnh: mock lại chrome item của demo — một tile selected, tile
  // cuối đóng băng giữa entrance (scale+fade dở) + edge fade dưới. Không
  // scroll, không ticker.
  thumbnailBuilder: (context) => const _RevealListThumbnail(),
);

/// react-bits-style item chrome: dark rounded tiles on a near-black backdrop,
/// selection lightens the tile. The chrome lives in the host's itemBuilder —
/// RevealList itself only handles scroll/entrance/selection mechanics.
/// Thumbnail cho gallery grid: dựng ở khổ cố định 360×460 rồi FittedBox thu
/// về ô tile — 4 tile giả (tile 2 selected, tile 4 mid-entrance) trên nền
/// backdrop của demo, gradient fade ôm mép dưới như RevealList thật.
class _RevealListThumbnail extends StatelessWidget {
  const _RevealListThumbnail();

  static const Color _backdrop = _RevealListShowcase._backdrop;

  Widget _tile(String label, {bool selected = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF271E37) : const Color(0xFF170D27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF5227FF) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _backdrop,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: 460,
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    _tile('Item 1'),
                    const SizedBox(height: 12),
                    _tile('Item 2', selected: true),
                    const SizedBox(height: 12),
                    _tile('Item 3'),
                    const SizedBox(height: 12),
                    _tile('Item 4'),
                    const SizedBox(height: 12),
                    // Tile đang "pop in" — đóng băng ở scale 0.85 / opacity 0.45.
                    Opacity(
                      opacity: 0.45,
                      child: Transform.scale(
                        scale: 0.85,
                        child: _tile('Item 5'),
                      ),
                    ),
                  ],
                ),
              ),
              // Edge fade dưới (tĩnh) — dấu hiệu "còn nội dung phía dưới".
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: <Color>[
                        _backdrop,
                        _backdrop.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevealListShowcase extends StatelessWidget {
  const _RevealListShowcase();

  static const Color _backdrop = Color(0xFF060010);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _backdrop,
      child: RevealList(
        itemCount: 15,
        // Backdrop is darker than the theme scaffold — pass it explicitly so
        // the edge fades blend into it.
        edgeFadeColor: _backdrop,
        onItemSelected: (index) => debugPrint('selected item $index'),
        itemBuilder: (context, index, selected) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF271E37) : const Color(0xFF170D27),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF5227FF) : Colors.transparent,
            ),
          ),
          child: Text(
            'Item ${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
