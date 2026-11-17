// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';

import 'package:snipz/core/component_demo.dart';
import 'liquid_voice.dart';

/// Demo registration for LiquidVoiceWidget.
///
/// Usage example — copy into your project:
/// ```dart
/// import 'components/liquid_voice/liquid_voice.dart';
///
/// LiquidVoiceWidget(
///   theme: LiquidVoiceTheme.light,
///   onSend: (dur) => debugPrint('Recorded ${dur.inMilliseconds}ms'),
///   onCancel: () => debugPrint('Cancelled'),
/// )
/// ```
final liquidVoiceDemo = ComponentDemo(
  id: 'liquid_voice',
  builder: (context) => const _LiveDemo(),
  thumbnailBuilder: (context) => const _ThumbnailDemo(),
  variants: [
    DemoVariant(
      id: 'light',
      label: 'Light',
      builder: (context) => const _VariantDemo(theme: LiquidVoiceTheme.light),
      frozenBuilder: (context) => const _FrozenDemo(theme: LiquidVoiceTheme.light),
    ),
    DemoVariant(
      id: 'dark',
      label: 'Dark',
      builder: (context) => const _VariantDemo(theme: LiquidVoiceTheme.dark),
      frozenBuilder: (context) => const _FrozenDemo(theme: LiquidVoiceTheme.dark),
    ),
    DemoVariant(
      id: 'fill_light',
      label: 'Fill · Light',
      builder: (context) => const _FillDemo(theme: LiquidVoiceTheme.light),
    ),
    DemoVariant(
      id: 'fill_dark',
      label: 'Fill · Dark',
      builder: (context) => const _FillDemo(theme: LiquidVoiceTheme.dark),
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────

/// Full interactive demo with theme toggle and callback log.
class _LiveDemo extends StatefulWidget {
  const _LiveDemo();
  @override
  State<_LiveDemo> createState() => _LiveDemoState();
}

class _LiveDemoState extends State<_LiveDemo> {
  LiquidVoiceTheme _theme = LiquidVoiceTheme.light;
  String _log = 'Tap the mic ↓';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // theme toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Light', style: TextStyle(fontSize: 13)),
            Switch(
              value: _theme == LiquidVoiceTheme.dark,
              onChanged: (v) =>
                  setState(() => _theme = v ? LiquidVoiceTheme.dark : LiquidVoiceTheme.light),
            ),
            const Text('Dark', style: TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        // The component itself
        LiquidVoiceWidget(
          theme: _theme,
          onSend: (dur) => setState(() => _log = 'Sent — ${dur.inMilliseconds} ms recorded'),
          onCancel: () => setState(() => _log = 'Cancelled'),
        ),
        const SizedBox(height: 12),
        Text(_log, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _VariantDemo extends StatelessWidget {
  const _VariantDemo({required this.theme});
  final LiquidVoiceTheme theme;

  @override
  Widget build(BuildContext context) => Center(
        child: LiquidVoiceWidget(theme: theme),
      );
}

class _FillDemo extends StatelessWidget {
  const _FillDemo({required this.theme});
  final LiquidVoiceTheme theme;

  @override
  Widget build(BuildContext context) => LiquidVoiceWidget(theme: theme, fill: true);
}

/// Frozen still-frame — no ticker, deterministic. Used for state board / thumbnails.
class _FrozenDemo extends StatelessWidget {
  const _FrozenDemo({required this.theme});
  final LiquidVoiceTheme theme;

  @override
  Widget build(BuildContext context) => TickerMode(
        enabled: false,
        child: LiquidVoiceWidget(theme: theme, animate: false),
      );
}

class _ThumbnailDemo extends StatelessWidget {
  const _ThumbnailDemo();

  @override
  Widget build(BuildContext context) => TickerMode(
        enabled: false,
        child: LiquidVoiceWidget(animate: false),
      );
}
