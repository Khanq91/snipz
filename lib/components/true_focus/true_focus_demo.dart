// Demo/usage example for TrueFocus. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'true_focus.dart';

final ComponentDemo trueFocusDemo = ComponentDemo(
  id: 'true_focus',
  builder: (context) => const _TrueFocusShowcase(),
  // Static: manualMode has no timer, Duration.zero snaps the frame to the
  // first word — one focused frame, nothing keeps animating in the grid.
  thumbnailBuilder: (context) => const _TrueFocusThumbnail(),
);

/// Static thumbnail — designed at 360x460 and scaled down by [FittedBox].
/// Real widget, frozen: no auto-cycle timer (manualMode) and zero-duration
/// transitions, so it renders exactly one focused frame.
class _TrueFocusThumbnail extends StatelessWidget {
  const _TrueFocusThumbnail();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: 460,
          child: Center(
            child: const TrueFocus(
              'True Focus',
              manualMode: true, // no timer
              animationDuration: Duration.zero, // frame snaps, no tween
              textStyle: TextStyle(color: Colors.white, fontSize: 40),
            ),
          ),
        ),
      ),
    );
  }
}

/// Auto-cycling headline plus a manual (tap-to-focus) line — the two modes
/// a host app picks between.
class _TrueFocusShowcase extends StatelessWidget {
  const _TrueFocusShowcase();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Auto mode: cycles every animationDuration + pause (0.5s + 1s).
              const TrueFocus(
                'True Focus',
                textStyle: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 56),
              // Manual mode: the web hover-to-focus, mapped to tap on touch.
              const TrueFocus(
                'tap each word',
                manualMode: true,
                borderColor: Color(0xFF00D8FF),
                glowColor: Color(0x9900D8FF),
                textStyle: TextStyle(color: Colors.white70, fontSize: 24),
              ),
              const SizedBox(height: 24),
              const Text(
                'manual mode: tap a word to focus it',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
