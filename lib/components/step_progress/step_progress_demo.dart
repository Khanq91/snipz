// Demo/usage example for StepProgress. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'step_progress.dart';

final ComponentDemo stepProgressDemo = ComponentDemo(
  id: 'step_progress',
  builder: (context) => const _StepProgressShowcase(),
  // State board: one entry per step. Implicit animations render their end
  // value on first build, so these are naturally frozen frames.
  variants: <DemoVariant>[
    for (int s = 1; s <= 4; s++)
      DemoVariant(
        id: 'step-$s',
        label: 'Step $s',
        builder: (context) => _Stage(
          child: SizedBox(width: 210, child: StepProgress(step: s)),
        ),
      ),
  ],
);

/// Kinetics card stage: dark backdrop, the indicator, and a Next pill that
/// advances and wraps back to step 1 — same behaviour as the original demo.
class _StepProgressShowcase extends StatefulWidget {
  const _StepProgressShowcase();

  @override
  State<_StepProgressShowcase> createState() => _StepProgressShowcaseState();
}

class _StepProgressShowcaseState extends State<_StepProgressShowcase> {
  static const int _count = 4;
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 210,
            child: StepProgress(step: _step, count: _count),
          ),
          const SizedBox(height: 22),
          _NextButton(
            onPressed: () => setState(() => _step = _step % _count + 1),
          ),
        ],
      ),
    );
  }
}

/// Dark stage matching the kinetics palette (graphite #0e0e10).
class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E0E10),
      child: Center(child: child),
    );
  }
}

/// Pill button styled like the original `.demo-steps-next` (hover border
/// dropped — no hover on Android; InkWell provides the pressed feedback).
class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF232326),
      shape: const StadiumBorder(
        side: BorderSide(color: Color(0xFF2A2A2E)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Next',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEDE9E0),
            ),
          ),
        ),
      ),
    );
  }
}
