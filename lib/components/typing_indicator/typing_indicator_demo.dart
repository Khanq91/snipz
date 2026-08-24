// Demo/usage example for TypingIndicator. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'typing_indicator.dart';

final ComponentDemo typingIndicatorDemo = ComponentDemo(
  id: 'typing_indicator',
  builder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: TypingIndicator()),
  ),
  // Frozen mid-bounce for the gallery grid — no ticker per tile.
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: TypingIndicator(frozenAt: 0.34)),
  ),
);
