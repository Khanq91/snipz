// Demo/usage example for AnimatedContent. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'animated_content.dart';

final ComponentDemo animatedContentDemo = ComponentDemo(
  id: 'animated_content',
  builder: (context) => const _AnimatedContentShowcase(),
);

/// A scrolling feed: every card animates in once, the first time it enters
/// the viewport — scroll down to see later cards trigger.
class _AnimatedContentShowcase extends StatelessWidget {
  const _AnimatedContentShowcase();

  static const List<(String, IconData, Color)> _cards =
      <(String, IconData, Color)>[
    ('Slides up (default)', Icons.arrow_upward, Color(0xFF5227FF)),
    ('From the left', Icons.arrow_forward, Color(0xFF7C4DFF)),
    ('From the right', Icons.arrow_back, Color(0xFF00BFA5)),
    ('Scale + fade', Icons.zoom_out_map, Color(0xFFFF6D00)),
    ('Slow and delayed', Icons.hourglass_bottom, Color(0xFFD500F9)),
    ('Appears then leaves', Icons.logout, Color(0xFF00B0FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 24),
        itemCount: _cards.length,
        itemBuilder: (context, i) {
          final (String label, IconData icon, Color color) = _cards[i];
          final Widget card = _FeedCard(label: label, icon: icon, color: color);
          return Padding(
            padding: const EdgeInsets.only(bottom: 160),
            child: switch (i) {
              1 => AnimatedContent(
                  direction: Axis.horizontal,
                  reverse: true,
                  child: card,
                ),
              2 => AnimatedContent(direction: Axis.horizontal, child: card),
              3 => AnimatedContent(distance: 0, scale: 0.6, child: card),
              4 => AnimatedContent(
                  duration: const Duration(milliseconds: 1500),
                  delay: const Duration(milliseconds: 300),
                  distance: 160,
                  child: card,
                ),
              5 => AnimatedContent(
                  disappearAfter: const Duration(seconds: 2),
                  child: card,
                ),
              _ => AnimatedContent(child: card),
            },
          );
        },
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: <Color>[color.withValues(alpha: 0.35), const Color(0xFF14101E)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
