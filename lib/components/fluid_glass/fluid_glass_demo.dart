// Demo/usage example for FluidGlass. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'fluid_glass.dart';

final ComponentDemo fluidGlassDemo = ComponentDemo(
  id: 'fluid_glass',
  builder: (context) => const _FluidGlassShowcase(),
);

/// Drag a finger anywhere: the glass glides after it and magnifies the
/// poster underneath. Switch to `bar` for the pinned glass navbar with its
/// own tappable items.
class _FluidGlassShowcase extends StatefulWidget {
  const _FluidGlassShowcase();

  @override
  State<_FluidGlassShowcase> createState() => _FluidGlassShowcaseState();
}

class _FluidGlassShowcaseState extends State<_FluidGlassShowcase> {
  FluidGlassMode _mode = FluidGlassMode.lens;
  String _nav = 'Home';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Column(
        children: <Widget>[
          Expanded(
            child: FluidGlass(
              mode: _mode,
              barChild: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final String label in const <String>[
                    'Home',
                    'About',
                    'Contact',
                  ])
                    TextButton(
                      onPressed: () => setState(() => _nav = label),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: _nav == label ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              child: const _Poster(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SegmentedButton<FluidGlassMode>(
              segments: <ButtonSegment<FluidGlassMode>>[
                for (final FluidGlassMode m in FluidGlassMode.values)
                  ButtonSegment<FluidGlassMode>(value: m, label: Text(m.name)),
              ],
              selected: <FluidGlassMode>{_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
        ],
      ),
    );
  }
}

/// Busy background with small type so the magnification is obvious.
class _Poster extends StatelessWidget {
  const _Poster();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1A0533), Color(0xFF5227FF)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < 4; i++)
            Align(
              alignment: Alignment(-0.8 + i * 0.55, -0.9 + (i % 2) * 1.5),
              child: Container(
                width: 120.0 + i * 30,
                height: 120.0 + i * 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6D3A)
                      .withValues(alpha: 0.12 + i * 0.05),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'React Bits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  List<String>.generate(
                    4,
                    (i) => 'drag the glass over this fine print',
                  ).join('\n'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
