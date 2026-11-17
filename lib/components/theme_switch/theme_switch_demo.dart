// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';

import 'package:snipz/core/component_demo.dart';
import 'theme_switch.dart';

/// Demo registration for ThemeSwitchWidget.
///
/// Usage example — copy into your project:
/// ```dart
/// import 'components/theme_switch/theme_switch.dart';
///
/// ThemeSwitchWidget(
///   theme: LiquidTheme.light,
///   onThemeChange: (t) => setState(() => _theme = t),
///   defaultEffect: SwitchEffect.droplet,
/// )
/// ```
final themeSwitchDemo = ComponentDemo(
  id: 'theme_switch',
  builder: (context) => const _LiveDemo(),
  thumbnailBuilder: (context) => TickerMode(
    enabled: false,
    child: ThemeSwitchWidget(animate: false),
  ),
  variants: [
    DemoVariant(
      id: 'droplet',
      label: 'Droplet',
      builder: (context) => const _EffectDemo(effect: SwitchEffect.droplet),
      frozenBuilder: (context) => TickerMode(
        enabled: false,
        child: ThemeSwitchWidget(
          defaultEffect: SwitchEffect.droplet,
          animate: false,
        ),
      ),
    ),
    DemoVariant(
      id: 'rain',
      label: 'Rain',
      builder: (context) => const _EffectDemo(effect: SwitchEffect.rain),
      frozenBuilder: (context) => TickerMode(
        enabled: false,
        child: ThemeSwitchWidget(
          defaultEffect: SwitchEffect.rain,
          animate: false,
        ),
      ),
    ),
    DemoVariant(
      id: 'diwali',
      label: 'Diwali 🎆',
      builder: (context) => const _EffectDemo(effect: SwitchEffect.diwali),
      frozenBuilder: (context) => TickerMode(
        enabled: false,
        child: ThemeSwitchWidget(
          defaultEffect: SwitchEffect.diwali,
          animate: false,
        ),
      ),
    ),
    DemoVariant(
      id: 'dark_start',
      label: 'Dark → Light',
      builder: (context) => const _EffectDemo(
        effect: SwitchEffect.droplet,
        startTheme: LiquidTheme.dark,
      ),
    ),
    DemoVariant(
      id: 'fill',
      label: 'Fill mode',
      builder: (context) => const _FillDemo(),
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────

/// Full interactive demo with effect selector and log.
class _LiveDemo extends StatefulWidget {
  const _LiveDemo();
  @override
  State<_LiveDemo> createState() => _LiveDemoState();
}

class _LiveDemoState extends State<_LiveDemo> {
  LiquidTheme _theme = LiquidTheme.light;
  SwitchEffect _effect = SwitchEffect.droplet;
  String _log = 'Press the button to switch theme';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ThemeSwitchWidget(
          theme: _theme,
          defaultEffect: _effect,
          onThemeChange: (t) => setState(() {
            _theme = t;
            _log = 'Theme → ${t.name}';
          }),
          onEffectChange: (e) => setState(() {
            _effect = e;
            _log = 'Effect → ${e.name}';
          }),
        ),
        const SizedBox(height: 16),
        Text(
          _log,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Single-effect demo, isolated.
class _EffectDemo extends StatefulWidget {
  const _EffectDemo({
    required this.effect,
    this.startTheme = LiquidTheme.light,
  });
  final SwitchEffect effect;
  final LiquidTheme startTheme;

  @override
  State<_EffectDemo> createState() => _EffectDemoState();
}

class _EffectDemoState extends State<_EffectDemo> {
  late LiquidTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.startTheme;
  }

  @override
  Widget build(BuildContext context) => Center(
        child: ThemeSwitchWidget(
          theme: _theme,
          defaultEffect: widget.effect,
          onThemeChange: (t) => setState(() => _theme = t),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// Fill-mode demo — component takes the whole screen.
class _FillDemo extends StatefulWidget {
  const _FillDemo();
  @override
  State<_FillDemo> createState() => _FillDemoState();
}

class _FillDemoState extends State<_FillDemo> {
  LiquidTheme _theme = LiquidTheme.light;
  SwitchEffect _effect = SwitchEffect.rain;

  @override
  Widget build(BuildContext context) => ThemeSwitchWidget(
        theme: _theme,
        defaultEffect: _effect,
        fill: true,
        onThemeChange: (t) => setState(() => _theme = t),
        onEffectChange: (e) => setState(() => _effect = e),
      );
}
