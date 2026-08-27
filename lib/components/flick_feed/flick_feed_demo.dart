// Demo/usage example for FlickFeed. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).
//
// Cách cảm nhận: flick MẠNH rồi flick NHẸ, xong tắt "RULES" và làm y hệt —
// khác biệt nằm ở chỗ dừng (snap theo đà, có hướng), ở các section vừa lướt
// qua (fastScrollEnd/preventOverlaps) và ở pill chương (anticipate).

import 'package:snipz/core/component_demo.dart';

import 'flick_feed.dart';

final ComponentDemo flickFeedDemo = ComponentDemo(
  id: 'flick_feed',
  builder: (context) => const FlickFeed(),
  // Top-of-feed resting frame — gesture-driven, static thumbnail.
  thumbnailBuilder: (context) => const FlickFeed(frozenAt: 0),
  variants: [
    DemoVariant(
      id: 'rules-off',
      label: 'Rules OFF',
      builder: (context) => const FlickFeed(rulesOn: false),
      frozenBuilder: (context) => const FlickFeed(rulesOn: false, frozenAt: 0),
    ),
    DemoVariant(
      id: 'no-hud',
      label: 'No HUD',
      builder: (context) => const FlickFeed(showHud: false),
      frozenBuilder: (context) => const FlickFeed(showHud: false, frozenAt: 0),
    ),
    DemoVariant(
      id: 'sticky',
      label: 'Magnet snap',
      builder: (context) => const FlickFeed(resistance: 800, snapDelay: 0.05),
      frozenBuilder: (context) => const FlickFeed(frozenAt: 0),
    ),
  ],
);
