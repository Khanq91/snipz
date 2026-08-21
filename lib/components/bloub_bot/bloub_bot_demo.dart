// Demo/usage example for BloubBot. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'bloub_bot.dart';

final ComponentDemo bloubBotDemo = ComponentDemo(
  id: 'bloub_bot',
  builder: (context) => const _BloubBotShowcase(),
  // Thumbnail: the engine is pure in time, so a frozen frame costs no ticker.
  thumbnailBuilder: (context) => Center(
    child: BloubBot(
      size: 120,
      frozenAt: botStatePoses[BloubBotState.idle]!,
      paper: Theme.of(context).colorScheme.surface,
    ),
  ),
  // One variant per catalog state. frozenBuilder samples each state at its
  // most readable instant (botStatePoses) — the state board renders these
  // with zero animation loops.
  variants: [
    for (final BloubBotState s in botSequence)
      DemoVariant(
        id: s.name,
        label: s.name,
        builder: (context) => Center(
          child: BloubBot(
            size: 220,
            state: s,
            paper: Theme.of(context).colorScheme.surface,
          ),
        ),
        frozenBuilder: (context) => Center(
          child: BloubBot(
            size: 220,
            state: s,
            frozenAt: botStatePoses[s]!,
            paper: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
  ],
);

class _BloubBotShowcase extends StatefulWidget {
  const _BloubBotShowcase();

  @override
  State<_BloubBotShowcase> createState() => _BloubBotShowcaseState();
}

class _BloubBotShowcaseState extends State<_BloubBotShowcase> {
  BloubBotState _state = BloubBotState.idle;
  bool _playing = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Plays the catalog sequence: each state held for its measured duration,
  /// like the reference video's montage.
  void _scheduleNext() {
    _timer?.cancel();
    if (!_playing) return;
    final double hold = botStates[_state]!.duration;
    _timer = Timer(Duration(milliseconds: (hold * 1000).round()), () {
      if (!mounted || !_playing) return;
      final int i = botSequence.indexOf(_state);
      setState(() => _state = botSequence[(i + 1) % botSequence.length]);
      _scheduleNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: BloubBot(
              size: 260,
              state: _state,
              // paper matches the stage background so the eye holes read as
              // truly pierced
              paper: scheme.surface,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 6,
            runSpacing: -8,
            alignment: WrapAlignment.center,
            children: [
              for (final BloubBotState s in botSequence)
                ChoiceChip(
                  label: Text(s.name),
                  selected: _state == s,
                  onSelected: (_) => setState(() {
                    _state = s;
                    _playing = false;
                    _timer?.cancel();
                  }),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Play sequence'),
              Switch(
                value: _playing,
                onChanged: (v) {
                  setState(() => _playing = v);
                  _scheduleNext();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
