// Demo/usage example for RevealList. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'reveal_list.dart';

final ComponentDemo revealListDemo = ComponentDemo(
  id: 'reveal_list',
  builder: (context) => const _RevealListShowcase(),
);

/// react-bits-style item chrome: dark rounded tiles on a near-black backdrop,
/// selection lightens the tile. The chrome lives in the host's itemBuilder —
/// RevealList itself only handles scroll/entrance/selection mechanics.
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
