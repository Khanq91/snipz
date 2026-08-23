// Demo/usage example for ClaudeThinking. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'claude_thinking.dart';

final ComponentDemo claudeThinkingDemo = ComponentDemo(
  id: 'claude_thinking',
  builder: (context) => const _ClaudeThinkingShowcase(),
  // Thumbnail: the real widget frozen via `animate: false` (glyph parked on ✳,
  // verb solid terracotta — deterministic, no ticker).
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF101010),
    child: Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: ClaudeThinking(animate: false, fontSize: 22),
        ),
      ),
    ),
  ),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'text',
      label: 'Text glyphs',
      builder: (context) => const _DemoStage(child: ClaudeThinking()),
      frozenBuilder: (context) =>
          const _DemoStage(child: ClaudeThinking(animate: false)),
    ),
    DemoVariant(
      id: 'painted',
      label: 'Painted glyphs',
      builder: (context) => const _DemoStage(
        child: ClaudeThinking(glyphStyle: ClaudeThinkingGlyphStyle.painted),
      ),
      frozenBuilder: (context) => const _DemoStage(
        child: ClaudeThinking(
          glyphStyle: ClaudeThinkingGlyphStyle.painted,
          animate: false,
        ),
      ),
    ),
  ],
);

/// Terminal-dark backdrop shared by the variant previews.
class _DemoStage extends StatelessWidget {
  const _DemoStage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF101010),
      child: Center(child: child),
    );
  }
}

/// Default run, painted-glyph fallback, and a custom-verbs/colors take —
/// the three main configs, on a terminal-dark background.
class _ClaudeThinkingShowcase extends StatelessWidget {
  const _ClaudeThinkingShowcase();

  static const TextStyle _caption = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    color: Color(0xFF565F89),
  );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF101010),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text('// default — Dingbat text glyphs', style: _caption),
            SizedBox(height: 8),
            ClaudeThinking(),
            SizedBox(height: 28),
            Text('// painted glyphs (no-tofu fallback)', style: _caption),
            SizedBox(height: 8),
            ClaudeThinking(glyphStyle: ClaudeThinkingGlyphStyle.painted),
            SizedBox(height: 28),
            Text('// custom verbs + colors', style: _caption),
            SizedBox(height: 8),
            ClaudeThinking(
              verbs: <String>['Compiling', 'Brewing', 'Untangling'],
              baseColor: Color(0xFF5FAFAF),
              highlightColor: Color(0xFF9FDFDF),
              fontSize: 15,
            ),
          ],
        ),
      ),
    );
  }
}
