// Demo/usage example for SplitFlapText. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'split_flap_text.dart';

final ComponentDemo splitFlapTextDemo = ComponentDemo(
  id: 'split_flap_text',
  builder: (context) => const _SplitFlapTextShowcase(),
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
