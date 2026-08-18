// Demo/usage example for BlurText. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'blur_text.dart';

final ComponentDemo blurTextDemo = ComponentDemo(
  id: 'blur_text',
  builder: (context) => const _BlurTextShowcase(),
);

/// Word reveal + character reveal, replayable by tapping anywhere — the
/// `GlobalKey<BlurTextState>` pattern is how a host app re-triggers it.
class _BlurTextShowcase extends StatefulWidget {
  const _BlurTextShowcase();

  @override
  State<_BlurTextShowcase> createState() => _BlurTextShowcaseState();
}

class _BlurTextShowcaseState extends State<_BlurTextShowcase> {
  final GlobalKey<BlurTextState> _headline = GlobalKey<BlurTextState>();
  final GlobalKey<BlurTextState> _caption = GlobalKey<BlurTextState>();

  void _replay() {
    _headline.currentState?.replay();
    _caption.currentState?.replay();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _replay,
      child: ColoredBox(
        color: const Color(0xFF060010),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                BlurText(
                  'Isn\'t this so cool?!',
                  key: _headline,
                  alignment: WrapAlignment.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                BlurText(
                  'characters, from below',
                  key: _caption,
                  unit: BlurTextUnit.characters,
                  direction: BlurTextSlideDirection.bottom,
                  stagger: const Duration(milliseconds: 40),
                  style: const TextStyle(
                    color: Color(0xFFB19EEF),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'tap anywhere to replay',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
