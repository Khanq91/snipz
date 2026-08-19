// Demo/usage example for FaultyTerminal. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'faulty_terminal.dart';

final ComponentDemo faultyTerminalDemo = ComponentDemo(
  id: 'faulty_terminal',
  builder: (context) => const _FaultyTerminalShowcase(),
  // Static frame for the gallery grid — no ticker per tile (§8.3).
  // timeOffset fixed so every gallery visit shows the same frame.
  thumbnailBuilder: (context) => const FaultyTerminal(
    animate: false,
    timeOffset: 42,
    tint: Color(0xFF86EFAC),
  ),
  // §2.3 shader contract: one FragmentShader reused, reconfigured per tick.
  shader: CarrierShaderSpec(
    prepare: () async {
      final program = await loadFaultyTerminalProgram();
      final shader = program.fragmentShader();
      return CarrierShaderHandle(
        build: (bounds, scale, time) {
          configureFaultyTerminalShader(
            shader,
            bounds.size,
            time: time,
            scale: scale,
          );
          return shader;
        },
        dispose: shader.dispose,
      );
    },
  ),
);

/// Fullscreen glitchy CRT terminal with foreground content — the standard
/// "hacker background" use. The widget is opaque (composites over black),
/// so it goes at the bottom of a Stack.
class _FaultyTerminalShowcase extends StatelessWidget {
  const _FaultyTerminalShowcase();

  @override
  Widget build(BuildContext context) {
    return FaultyTerminal(
      // Phosphor-green terminal; other params keep the original defaults
      // (curvature 0.2, scanlineIntensity 0.3, pageLoadAnimation on).
      tint: const Color(0xFF86EFAC),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Text(
              'Faulty Terminal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'CRT digits, scanlines, glitch displacement',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
