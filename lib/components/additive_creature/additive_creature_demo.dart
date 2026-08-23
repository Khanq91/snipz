// Demo/usage example for AdditiveCreature. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'additive_creature.dart';

final ComponentDemo additiveCreatureDemo = ComponentDemo(
  id: 'additive_creature',
  // Drag to lead the creature; leave it alone and it wanders by itself.
  builder: (context) => const AdditiveCreature(),
  // Deterministic frame mid-wander — no ticker in the gallery grid.
  thumbnailBuilder: (context) =>
      const AdditiveCreature(frozenAt: 8, interactive: false, dotRadius: 3),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'ember',
      label: 'ember',
      builder: (context) => const AdditiveCreature(),
      frozenBuilder: (context) =>
          const AdditiveCreature(frozenAt: 8, interactive: false),
    ),
    DemoVariant(
      id: 'plasma',
      label: 'plasma',
      builder: (context) => const AdditiveCreature(
        color: Color(0xFF2EB8E8),
        backgroundColor: Color(0xFF06131A),
      ),
      frozenBuilder: (context) => const AdditiveCreature(
        color: Color(0xFF2EB8E8),
        backgroundColor: Color(0xFF06131A),
        frozenAt: 8,
        interactive: false,
      ),
    ),
    DemoVariant(
      id: 'spirit',
      label: 'spirit',
      builder: (context) => const AdditiveCreature(
        color: Color(0xFFB44FE8),
        backgroundColor: Color(0xFF12081A),
      ),
      frozenBuilder: (context) => const AdditiveCreature(
        color: Color(0xFFB44FE8),
        backgroundColor: Color(0xFF12081A),
        frozenAt: 8,
        interactive: false,
      ),
    ),
  ],
);
