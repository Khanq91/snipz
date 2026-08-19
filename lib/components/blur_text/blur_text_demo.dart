// Demo/usage example for BlurText. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'blur_text.dart';

final ComponentDemo blurTextDemo = ComponentDemo(
  id: 'blur_text',
  builder: (context) => const _BlurTextShowcase(),
  // Static mock: the reveal frozen mid-flight — early words crisp, later ones
  // still blurred/offset. One-shot ImageFiltered blurs, no controller.
  thumbnailBuilder: (context) => const _BlurTextThumbnail(),
);

/// Static thumbnail — designed at 360x460 and scaled down by [FittedBox].
/// Hand-poses the segment keyframes of [BlurText]: "Isn't this" settled,
/// "so" half sharp with the overshoot, "cool?!" still heavy blur + offset.
class _BlurTextThumbnail extends StatelessWidget {
  const _BlurTextThumbnail();

  /// One frozen segment: [blur] sigma, [opacity] and vertical [dy] offset.
  static Widget _segment(
    String text, {
    double blur = 0,
    double opacity = 1,
    double dy = 0,
  }) {
    Widget segment = Opacity(
      opacity: opacity,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (blur > 0) {
      segment = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: segment,
      );
    }
    return Transform.translate(offset: Offset(0, dy), child: segment);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: FittedBox(
        fit: BoxFit.contain,
        child: ClipRect(
          child: SizedBox(
            width: 360,
            height: 460,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // scaleDown per line: test fonts (Ahem) render far wider
                  // than real ones — never let a line overflow the 360 frame.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _segment("Isn't this"),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _segment('so ', blur: 4, opacity: 0.55, dy: -4),
                        _segment('cool?!', blur: 9, opacity: 0.3, dy: -18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
