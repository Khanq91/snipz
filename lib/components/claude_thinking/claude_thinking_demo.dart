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

/// One (base, highlight) shimmer pair the showcase can dress a line in.
class _ThinkingTint {
  const _ThinkingTint(this.base, this.highlight);
  final Color base;
  final Color highlight;
}

const List<_ThinkingTint> _tints = <_ThinkingTint>[
  _ThinkingTint(Color(0xFFCD694A), Color(0xFFE79475)), // terracotta (default)
  _ThinkingTint(Color(0xFF5FAFAF), Color(0xFF9FDFDF)), // teal
  _ThinkingTint(Color(0xFF7CB65C), Color(0xFFB5E39A)), // green
  _ThinkingTint(Color(0xFF9A7ECC), Color(0xFFC9B3F0)), // violet
  _ThinkingTint(Color(0xFF5C8FD6), Color(0xFF9FC3F5)), // blue
  _ThinkingTint(Color(0xFFD6A23E), Color(0xFFF2CD86)), // gold
];

/// Default run, painted-glyph fallback, and a custom-verbs take — the three
/// main configs on a terminal-dark background, each with its own tint picker.
class _ClaudeThinkingShowcase extends StatefulWidget {
  const _ClaudeThinkingShowcase();

  @override
  State<_ClaudeThinkingShowcase> createState() =>
      _ClaudeThinkingShowcaseState();
}

class _ClaudeThinkingShowcaseState extends State<_ClaudeThinkingShowcase> {
  static const TextStyle _caption = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    color: Color(0xFF565F89),
  );

  // one tint index per showcase line — independent pickers
  final List<int> _tint = <int>[0, 0, 1];

  Widget _swatches(int line) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < _tints.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _tint[line] = i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _tints[i].base,
                  border: Border.all(
                    color: _tint[line] == i
                        ? Colors.white
                        : Colors.white24,
                    width: _tint[line] == i ? 2 : 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF101010),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('// default — Dingbat text glyphs', style: _caption),
            _swatches(0),
            ClaudeThinking(
              baseColor: _tints[_tint[0]].base,
              highlightColor: _tints[_tint[0]].highlight,
            ),
            const SizedBox(height: 24),
            const Text('// painted glyphs (no-tofu fallback)',
                style: _caption),
            _swatches(1),
            ClaudeThinking(
              glyphStyle: ClaudeThinkingGlyphStyle.painted,
              baseColor: _tints[_tint[1]].base,
              highlightColor: _tints[_tint[1]].highlight,
            ),
            const SizedBox(height: 24),
            const Text('// custom verbs', style: _caption),
            _swatches(2),
            ClaudeThinking(
              verbs: const <String>['Compiling', 'Brewing', 'Untangling'],
              baseColor: _tints[_tint[2]].base,
              highlightColor: _tints[_tint[2]].highlight,
              fontSize: 15,
            ),
          ],
        ),
      ),
    );
  }
}
