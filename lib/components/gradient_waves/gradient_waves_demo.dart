// Demo/usage example for GradientWaves. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';

import 'gradient_waves.dart';

final ComponentDemo gradientWavesDemo = ComponentDemo(
  id: 'gradient_waves',
  builder: (context) => const GradientWaves(),
  // Grid thumbnails must not run tickers (§9.2) — freeze it.
  thumbnailBuilder: (context) => const GradientWaves(animate: false),
  // Painter paint (no Shader factory) → hand-built carriers (§2.3 fallback).
  carrierBuilders: <Carrier, WidgetBuilder>{
    Carrier.card: (context) => Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 320,
          height: 180,
          // Small carrier → raise scale so the waves keep their detail (§9.1).
          child: GradientWaves(
            scale: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Gradient Waves',
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
        child: SizedBox(
          width: 220,
          height: 56,
          child: GradientWaves(
            scale: 3.5,
            amplitude: 1.4,
            speed: 1.4,
            child: const Center(
              child: Text(
                'Get started',
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
