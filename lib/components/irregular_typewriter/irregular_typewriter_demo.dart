// Demo/usage example for IrregularTypewriter. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'irregular_typewriter.dart';

final ComponentDemo irregularTypewriterDemo = ComponentDemo(
  id: 'irregular_typewriter',
  builder: (context) => const _TypewriterShowcase(),
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF191817),
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: IrregularTypewriter(
            text: 'Hello there.',
            frozenAt: 1.1,
          ),
        ),
      ),
    ),
  ),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'terminal',
      label: 'terminal',
      builder: (context) => const _Stage(
        child: IrregularTypewriter(
          text: 'The quick brown fox jumps over the lazy dog.',
        ),
      ),
      frozenBuilder: (context) => const _Stage(
        child: IrregularTypewriter(
          text: 'The quick brown fox jumps over the lazy dog.',
          frozenAt: 2.4,
        ),
      ),
    ),
    DemoVariant(
      id: 'calm',
      label: 'calm serif',
      builder: (context) => const _Stage(
        color: Color(0xFFFBF6EF),
        child: IrregularTypewriter(
          text: 'and breathe, slowly.',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 26,
            fontStyle: FontStyle.italic,
            color: Color(0xFF79404E),
          ),
          cursorColor: Color(0xFFE5637F),
          irregularity: 2.6,
        ),
      ),
      frozenBuilder: (context) => const _Stage(
        color: Color(0xFFFBF6EF),
        child: IrregularTypewriter(
          text: 'and breathe, slowly.',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 26,
            fontStyle: FontStyle.italic,
            color: Color(0xFF79404E),
          ),
          cursorColor: Color(0xFFE5637F),
          irregularity: 2.6,
          frozenAt: 1.4,
        ),
      ),
    ),
  ],
);

class _Stage extends StatelessWidget {
  const _Stage({required this.child, this.color = const Color(0xFF191817)});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }
}

/// Two rhythms side by side: default terminal feel and a wilder, slower one.
class _TypewriterShowcase extends StatelessWidget {
  const _TypewriterShowcase();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF191817),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IrregularTypewriter(
                text: 'anime.js — irregular playback.',
              ),
              SizedBox(height: 32),
              IrregularTypewriter(
                text: 'every rhythm is seeded, none is even.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  color: Color(0xFF8A867E),
                ),
                cursorColor: Color(0xFFFF4B4B),
                irregularity: 3,
                seed: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
