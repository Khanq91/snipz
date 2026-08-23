// Demo/usage example for DrumClock + DrumClockController. Exempt from
// portability rules (§3.1.9); also serves as the copy-paste usage
// reference (§6) — wiring the upstream playback buttons to the controller.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'drum_clock.dart';

final ComponentDemo drumClockDemo = ComponentDemo(
  id: 'drum_clock',
  builder: (context) => const _DrumClockShowcase(),
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF191817),
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: DrumClock(fontSize: 26, frozenAt: 10 * 3600 + 8 * 60 + 30),
        ),
      ),
    ),
  ),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'full',
      label: 'HH:MM:SS.cc',
      builder: (context) => const _Stage(child: DrumClock(fontSize: 30)),
      frozenBuilder: (context) => const _Stage(
        child: DrumClock(
            fontSize: 30, frozenAt: 10 * 3600 + 8 * 60 + 30.9),
      ),
    ),
    DemoVariant(
      id: 'plain',
      label: 'HH:MM:SS',
      builder: (context) => const _Stage(
        child: DrumClock(fontSize: 38, showCentis: false),
      ),
      frozenBuilder: (context) => const _Stage(
        child: DrumClock(
          fontSize: 38,
          showCentis: false,
          frozenAt: 23 * 3600 + 59 * 60 + 59.8, // midnight roll
        ),
      ),
    ),
  ],
);

class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF191817),
      child: Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }
}

/// The upstream control board: play / pause / reverse, speed ramps and a
/// glide-seek back to the real current time.
class _DrumClockShowcase extends StatefulWidget {
  const _DrumClockShowcase();

  @override
  State<_DrumClockShowcase> createState() => _DrumClockShowcaseState();
}

class _DrumClockShowcaseState extends State<_DrumClockShowcase> {
  late final DrumClockController _controller;

  static Duration _now() {
    final DateTime n = DateTime.now();
    return Duration(
      hours: n.hour,
      minutes: n.minute,
      seconds: n.second,
      milliseconds: n.millisecond,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = DrumClockController(initialTime: _now());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _btn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEDEAE4),
        side: const BorderSide(color: Color(0xFF3A3835)),
        visualDensity: VisualDensity.compact,
        textStyle:
            const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF191817),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DrumClock(controller: _controller, fontSize: 34),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => Text(
                'speed ${_controller.speed.toStringAsFixed(2)}×'
                '${_controller.playing ? '' : '  ·  paused'}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF8A867E),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            // Wrap, not Row — seven buttons never fit one phone-width line
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _btn('PLAY', _controller.play),
                _btn('PAUSE', _controller.pause),
                _btn('REVERSE', _controller.reverse),
                _btn('SLOW MO', () => _controller.setSpeed(.1)),
                _btn('1×', () => _controller.setSpeed(1)),
                _btn('5×', () => _controller.setSpeed(5)),
                _btn('SEEK NOW', () => _controller.seekTo(_now())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
