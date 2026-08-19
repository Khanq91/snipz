// Demo/usage example for StarBorderGlow. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'star_border.dart';

final ComponentDemo starBorderDemo = ComponentDemo(
  id: 'star_border',
  builder: (context) => const _StarBorderShowcase(),
  // Thumbnail: same buttons with animate: false — a single mid-cycle frame,
  // no ticker running in the gallery grid.
  thumbnailBuilder: (context) => const _StarBorderThumbnail(),
);

/// The glow only reads on a dark background, so the demo paints one — exactly
/// how a host app would use it. StarBorderGlow itself is not a button: the
/// second example shows the intended tap pattern (wrap it yourself).
class _StarBorderShowcase extends StatelessWidget {
  const _StarBorderShowcase();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Defaults: white glow, 6s sweep.
            const StarBorderGlow(
              child: Text('Star Border'),
            ),
            const SizedBox(height: 28),
            // Tappable: the app wraps it — the component has no onTap.
            GestureDetector(
              onTap: () => ScaffoldMessenger.maybeOf(context)
                  ?.showSnackBar(const SnackBar(content: Text('Tapped'))),
              child: const StarBorderGlow(
                color: Color(0xFF00E5FF),
                speed: Duration(seconds: 3),
                child: Text('Cyan · 3s'),
              ),
            ),
            const SizedBox(height: 28),
            // Wider gap (thickness) and a warmer glow.
            const StarBorderGlow(
              color: Color(0xFFFFB74D),
              speed: Duration(seconds: 4),
              thickness: 3,
              child: Text('Amber · thickness 3'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid tile: fixed design size scaled down whole, all animation off —
/// `animate: false` parks the controller mid-cycle so the glow is visible.
class _StarBorderThumbnail extends StatelessWidget {
  const _StarBorderThumbnail();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 320,
          height: 300,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                StarBorderGlow(
                  animate: false,
                  child: Text('Star Border'),
                ),
                SizedBox(height: 24),
                StarBorderGlow(
                  animate: false,
                  color: Color(0xFF00E5FF),
                  child: Text('Star Border'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
