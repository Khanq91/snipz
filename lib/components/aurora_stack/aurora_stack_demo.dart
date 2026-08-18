// Demo/usage example for AuroraStack. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/widgets.dart';
import 'package:snipz/core/component_demo.dart';

import 'aurora_stack.dart';

final ComponentDemo auroraStackDemo = ComponentDemo(
  id: 'aurora_stack',
  // Typical composition: the aurora field plus the exported grain overlay.
  builder: (context) => const Stack(
    fit: StackFit.expand,
    children: [AuroraStack(), AuroraNoiseOverlay()],
  ),
  // Grid thumbnails must not tick 20 controllers at once (§9.2) — freeze it.
  thumbnailBuilder: (context) => const AuroraStack(animate: false),
);
