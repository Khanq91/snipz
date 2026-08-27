// Demo/usage example for ScrambleText. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'scramble_text.dart';

final ComponentDemo scrambleTextDemo = ComponentDemo(
  id: 'scramble_text',
  builder: (context) => const _Stage(child: _Cycling()),
  // Mid-decode frame — no ticker in the gallery grid.
  thumbnailBuilder: (context) =>
      const _Stage(child: _Cycling(frozenAt: 0.9)),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => _Stage(child: _Cycling(frozenAt: t)),
  scrubDuration: 10.5, // 3 texts × (0.3 delay + 1.8 reveal + 1.4 hold)
  variants: [
    DemoVariant(
      id: 'hacker',
      label: 'Hacker',
      builder: (context) => const _Stage(child: _Hacker()),
      frozenBuilder: (context) => const _Stage(child: _Hacker(frozenAt: 1.1)),
    ),
    DemoVariant(
      id: 'rtl',
      label: 'Right → left',
      builder: (context) => const _Stage(child: _RightToLeft()),
      frozenBuilder: (context) =>
          const _Stage(child: _RightToLeft(frozenAt: 1.0)),
    ),
    DemoVariant(
      id: 'words',
      label: 'Per word',
      builder: (context) => const _Stage(child: _PerWord()),
      frozenBuilder: (context) => const _Stage(child: _PerWord(frozenAt: 1.3)),
    ),
  ],
);

class _Cycling extends StatelessWidget {
  const _Cycling({this.frozenAt});

  final double? frozenAt;

  @override
  Widget build(BuildContext context) {
    return ScrambleText(
      texts: const ['SNIPZ VAULT', 'SCRAMBLE TEXT', 'PORTED FROM GSAP'],
      style: const TextStyle(
        color: Color(0xFFF2F2F5),
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
      revealDelay: 0.3,
      frozenAt: frozenAt,
    );
  }
}

class _Hacker extends StatelessWidget {
  const _Hacker({this.frozenAt});

  final double? frozenAt;

  @override
  Widget build(BuildContext context) {
    return ScrambleText(
      texts: const ['ACCESS GRANTED', 'DECRYPTING 0x2F', 'TRACE COMPLETE'],
      charset: ScrambleCharset.custom,
      customChars: r'01<>/\|=+*#',
      speed: 1.6,
      style: const TextStyle(
        color: Color(0xFF53F27A),
        fontSize: 22,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      scrambleStyle: const TextStyle(
        color: Color(0xFF1F7A38),
        fontSize: 22,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      frozenAt: frozenAt,
    );
  }
}

class _RightToLeft extends StatelessWidget {
  const _RightToLeft({this.frozenAt});

  final double? frozenAt;

  @override
  Widget build(BuildContext context) {
    return ScrambleText(
      texts: const ['REVEALED FROM THE RIGHT'],
      rightToLeft: true,
      duration: 2.4,
      style: const TextStyle(
        color: Color(0xFFF2F2F5),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      frozenAt: frozenAt,
    );
  }
}

class _PerWord extends StatelessWidget {
  const _PerWord({this.frozenAt});

  final double? frozenAt;

  @override
  Widget build(BuildContext context) {
    return ScrambleText(
      texts: const ['WORDS LAND ONE BY ONE'],
      perWord: true,
      duration: 2.2,
      curve: Curves.easeOut,
      style: const TextStyle(
        color: Color(0xFFF2F2F5),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      frozenAt: frozenAt,
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E0E10),
      child: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }
}
