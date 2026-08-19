// Demo/usage example for SplitFlapText. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'split_flap_text.dart';

final ComponentDemo splitFlapTextDemo = ComponentDemo(
  id: 'split_flap_text',
  builder: (context) => const _SplitFlapTextShowcase(),
  // Thumbnail tĩnh: board thật nhưng khóa vào MỘT phrase (`text:` non-null
  // → không cycle, ticker không bao giờ chạy) — hai board như demo, thu về
  // ô tile bằng FittedBox.
  thumbnailBuilder: (context) => ColoredBox(
    color: const Color(0xFF060010),
    child: Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              SplitFlapText(text: 'SNIPZ', padTo: 5, fontSize: 44),
              SizedBox(height: 18),
              SplitFlapText(
                text: '13:45',
                padTo: 5,
                fontSize: 30,
                tileColor: Color(0xFF1F1305),
                textColor: Color(0xFFFFB300),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

/// The departure board cycling its default phrases, plus a small numeric
/// board showing a custom charset.
class _SplitFlapTextShowcase extends StatelessWidget {
  const _SplitFlapTextShowcase();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: SplitFlapText(
                  words: const <String>[
                    'LAUNCH READY',
                    'SYNC ONLINE',
                    'SIGNAL LIVE',
                  ],
                ),
              ),
              const SizedBox(height: 40),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: SplitFlapText(
                  words: const <String>['13:45', '20:10', '23:55'],
                  charset: SplitFlapText.numeric,
                  padTo: 5,
                  fontSize: 36,
                  flipsPerChar: 5,
                  tileColor: const Color(0xFF1F1305),
                  textColor: const Color(0xFFFFB300),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
