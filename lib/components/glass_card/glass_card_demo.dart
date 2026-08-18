// Demo/usage example for GlassCard. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'glass_card.dart';

final ComponentDemo glassCardDemo = ComponentDemo(
  id: 'glass_card',
  builder: (context) => const _GlassCardShowcase(),
);

/// GlassCard only reads as glass over a busy backdrop, so the demo paints
/// colored circles behind it — exactly how a host app would use it.
class _GlassCardShowcase extends StatelessWidget {
  const _GlassCardShowcase();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(color: Color(0xFF10121C))),
        Positioned(
          top: -40,
          left: -30,
          child: _circle(const Color(0xFF7C4DFF), 220),
        ),
        Positioned(
          bottom: -60,
          right: -20,
          child: _circle(const Color(0xFF00E5FF), 260),
        ),
        Positioned(
          top: 120,
          right: 40,
          child: _circle(const Color(0xFFFF6E40), 140),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Glass Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Backdrop blur + translucent tint + hairline border. '
                    'Style it via constructor params.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _circle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
