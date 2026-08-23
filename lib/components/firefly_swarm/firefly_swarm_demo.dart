// Demo/usage example for FireflySwarm. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'firefly_swarm.dart';

final ComponentDemo fireflySwarmDemo = ComponentDemo(
  id: 'firefly_swarm',
  // Touch to gather the swarm, hold to scatter the ring wide.
  builder: (context) => const FireflySwarm(),
  thumbnailBuilder: (context) =>
      const FireflySwarm(count: 90, frozenAt: 5, interactive: false),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'ember',
      label: 'ember',
      builder: (context) => const FireflySwarm(),
      frozenBuilder: (context) =>
          const FireflySwarm(frozenAt: 5, interactive: false),
    ),
    DemoVariant(
      id: 'glowworm',
      label: 'glowworm',
      builder: (context) => const FireflySwarm(
        colors: <Color>[
          Color(0xFFB6FF6E),
          Color(0xFF6EFFC1),
          Color(0xFFEFFF8A),
        ],
        backgroundColor: Color(0xFF0A1208),
      ),
      frozenBuilder: (context) => const FireflySwarm(
        colors: <Color>[
          Color(0xFFB6FF6E),
          Color(0xFF6EFFC1),
          Color(0xFFEFFF8A),
        ],
        backgroundColor: Color(0xFF0A1208),
        frozenAt: 5,
        interactive: false,
      ),
    ),
    DemoVariant(
      id: 'ice',
      label: 'ice',
      builder: (context) => const FireflySwarm(
        colors: <Color>[
          Color(0xFF6EC8FF),
          Color(0xFFB0E5FF),
          Color(0xFF7A8CFF),
        ],
        backgroundColor: Color(0xFF080C14),
      ),
      frozenBuilder: (context) => const FireflySwarm(
        colors: <Color>[
          Color(0xFF6EC8FF),
          Color(0xFFB0E5FF),
          Color(0xFF7A8CFF),
        ],
        backgroundColor: Color(0xFF080C14),
        frozenAt: 5,
        interactive: false,
      ),
    ),
  ],
);
