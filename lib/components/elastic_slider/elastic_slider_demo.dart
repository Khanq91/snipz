// Demo/usage example for ElasticSlider. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'elastic_slider.dart';

final ComponentDemo elasticSliderDemo = ComponentDemo(
  id: 'elastic_slider',
  builder: (context) => const _ElasticSliderShowcase(),
  // Thumbnail: two real sliders at rest — their controllers only run while
  // touched, so nothing ticks in the grid. No live readout text.
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF060010),
    child: Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElasticSlider(initialValue: 62, fillColor: Color(0xFFB19EEF)),
            SizedBox(height: 28),
            ElasticSlider(
              initialValue: 30,
              showValueLabel: false,
              leftIcon:
                  Icon(Icons.volume_mute, size: 16, color: Colors.white70),
              rightIcon:
                  Icon(Icons.volume_up, size: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    ),
  ),
);

/// Two configurations: the plain default, and a stepped volume slider with
/// icons + a live readout via `onChanged` — the pattern a host app uses.
class _ElasticSliderShowcase extends StatefulWidget {
  const _ElasticSliderShowcase();

  @override
  State<_ElasticSliderShowcase> createState() => _ElasticSliderShowcaseState();
}

class _ElasticSliderShowcaseState extends State<_ElasticSliderShowcase> {
  double _volume = 40;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Original defaults: 0..100, starts at 50, "−"/"+" ends.
              const ElasticSlider(),
              const SizedBox(height: 56),
              ElasticSlider(
                initialValue: _volume,
                isStepped: true,
                stepSize: 10,
                showValueLabel: false,
                leftIcon:
                    const Icon(Icons.volume_mute, size: 20, color: Colors.white70),
                rightIcon:
                    const Icon(Icons.volume_up, size: 20, color: Colors.white70),
                fillColor: const Color(0xFFB19EEF),
                onChanged: (v) => setState(() => _volume = v),
              ),
              const SizedBox(height: 12),
              Text(
                'volume ${_volume.round()} (steps of 10)',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 32),
              const Text(
                'drag past the ends',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
