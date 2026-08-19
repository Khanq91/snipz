// Demo/usage example for PixelWalker. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'pixel_walker.dart';

final ComponentDemo pixelWalkerDemo = ComponentDemo(
  id: 'pixel_walker',
  builder: (context) => const _PixelWalkerShowcase(),
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF0E0D0B),
    child: PixelWalker(), // tĩnh: progress 1, không ticker
  ),
);

/// Cảnh trong khung header 200px + điều khiển trực tiếp hai param chính:
/// kéo slider `progress` để thấy hiệu ứng hiện dần (mascot trồi lên, dither
/// dày dần), bật `walking` để mascot bước và skyline trôi parallax.
class _PixelWalkerShowcase extends StatefulWidget {
  const _PixelWalkerShowcase();

  @override
  State<_PixelWalkerShowcase> createState() => _PixelWalkerShowcaseState();
}

class _PixelWalkerShowcaseState extends State<_PixelWalkerShowcase> {
  double _progress = 1.0;
  double _scale = 1.0;
  bool _walking = true;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E0D0B),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 200,
            width: double.infinity,
            child: PixelWalker(
              progress: _progress,
              walking: _walking,
              scale: _scale,
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                SwitchListTile(
                  title: const Text(
                    'walking',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: _walking,
                  onChanged: (bool v) => setState(() => _walking = v),
                ),
                Text(
                  'progress ${_progress.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white54),
                ),
                Slider(
                  value: _progress,
                  onChanged: (double v) => setState(() => _progress = v),
                ),
                Text(
                  'scale ${_scale.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white54),
                ),
                Slider(
                  value: _scale,
                  min: 0.5,
                  max: 3,
                  onChanged: (double v) => setState(() => _scale = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
