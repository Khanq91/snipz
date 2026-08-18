// Demo/usage example for ParticleField. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';

import 'particle_field.dart';

final ComponentDemo particleFieldDemo = ComponentDemo(
  id: 'particle_field',
  // Drag anywhere: the field parallax-shifts toward the finger.
  builder: (context) => const ParticleField(
    backgroundColor: Color(0xFF0A0A14),
    colors: <Color>[Color(0xFFFFFFFF), Color(0xFFB19EEF), Color(0xFF5227FF)],
  ),
  // Grid thumbnails must not run tickers (§9.2) — freeze it.
  thumbnailBuilder: (context) => const ParticleField(
    backgroundColor: Color(0xFF0A0A14),
    colors: <Color>[Color(0xFFFFFFFF), Color(0xFFB19EEF)],
    animate: false,
    interactive: false,
  ),
  // Painter paint (no Shader factory) → hand-built carriers (§2.3 fallback).
  carrierBuilders: <Carrier, WidgetBuilder>{
    Carrier.card: (context) => Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 320,
          height: 180,
          // Density is per-area, so a card only needs a scale bump for a
          // denser starfield look (§9.1).
          child: ParticleField(
            scale: 2,
            backgroundColor: const Color(0xFF141024),
            colors: const <Color>[Color(0xFFFFFFFF), Color(0xFFB19EEF)],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Particle Field',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    Carrier.button: (context) => Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: const SizedBox(
          width: 220,
          height: 56,
          child: ParticleField(
            scale: 4,
            baseSize: 1.8,
            driftAmplitude: 8,
            backgroundColor: Color(0xFF1B1433),
            colors: <Color>[Color(0xFFFFFFFF), Color(0xFF8F7BFF)],
            child: Center(
              child: Text(
                'Launch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  },
);
