// Demo/usage example for GradualBlur. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'gradual_blur.dart';

final ComponentDemo gradualBlurDemo = ComponentDemo(
  id: 'gradual_blur',
  builder: (context) => const _GradualBlurShowcase(),
  // Thumbnail: zero BackdropFilter layers (each one is a backdrop readback
  // per frame — too heavy for a gallery grid). The "gradual blur" is faked
  // with list bars whose boxShadow blur grows toward the bottom edge.
  thumbnailBuilder: (context) => const _GradualBlurThumbnail(),
);

/// The classic use: a scrollable list with a GradualBlur pinned over its
/// bottom edge (and a lighter one over the top). The overlay is a plain
/// sized widget — position it yourself with Align inside a Stack.
class _GradualBlurShowcase extends StatefulWidget {
  const _GradualBlurShowcase();

  @override
  State<_GradualBlurShowcase> createState() => _GradualBlurShowcaseState();
}

class _GradualBlurShowcaseState extends State<_GradualBlurShowcase> {
  double _strength = 2;
  bool _exponential = false;

  static const List<Color> _cardColors = <Color>[
    Color(0xFF5227FF),
    Color(0xFFFF6D3A),
    Color(0xFF00B894),
    Color(0xFFE84393),
    Color(0xFF0984E3),
    Color(0xFFF9CA24),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                // The content being blurred — any scrollable works.
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 96, 16, 132),
                  itemCount: 24,
                  itemBuilder: (context, i) {
                    final Color c = _cardColors[i % _cardColors.length];
                    return Container(
                      height: 72,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: <Color>[
                            c.withValues(alpha: 0.85),
                            c.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Scroll item ${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
                // Footer blur — strongest at the bottom edge.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: GradualBlur(
                    size: 120,
                    strength: _strength,
                    divCount: 6,
                    exponential: _exponential,
                  ),
                ),
                // Header blur via a ported preset, lighter.
                GradualBlur.preset(
                  GradualBlurPreset.header,
                  size: 72,
                  strength: 1.5,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: <Widget>[
                const Text('strength',
                    style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Slider(
                    value: _strength,
                    min: 0.5,
                    max: 4,
                    onChanged: (v) => setState(() => _strength = v),
                  ),
                ),
                const Text('exp', style: TextStyle(color: Colors.white70)),
                Switch(
                  value: _exponential,
                  onChanged: (v) => setState(() => _exponential = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Static mock for the grid: crisp list bars up top that get progressively
/// "blurrier" toward the bottom — each fake-blurred bar is just a
/// transparent box casting a boxShadow of its own color.
class _GradualBlurThumbnail extends StatelessWidget {
  const _GradualBlurThumbnail();

  static const List<Color> _colors = <Color>[
    Color(0xFF5227FF),
    Color(0xFFFF6D3A),
    Color(0xFF00B894),
    Color(0xFFE84393),
    Color(0xFF0984E3),
    Color(0xFFF9CA24),
    Color(0xFF5227FF),
  ];

  @override
  Widget build(BuildContext context) {
    // Designed at a fixed 360x460 and scaled to the tile.
    return ColoredBox(
      color: const Color(0xFF060010),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: 460,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      // Blur ramps up over the last 4 bars, like the strips.
                      child: _bar(_colors[i], (i - 2).clamp(0, 4) * 4.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(Color color, double blur) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: blur == 0 ? color.withValues(alpha: 0.8) : null,
        boxShadow: blur == 0
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.65),
                  blurRadius: blur,
                  spreadRadius: 1,
                ),
              ],
      ),
    );
  }
}
