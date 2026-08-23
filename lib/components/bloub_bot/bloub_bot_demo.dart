// Demo/usage example for BloubBot. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
  String _expression = kBotDefaultExpression;
  String _shape = kBotDefaultShape;
  String _color = kBotDefaultColor;

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
              ink: Color(botColorById[_color]!.argb),
              expression: _expression,
              shape: _shape,
            ),
          ),
        ),
        // Customizer rows: shape morphs, expression glides, color is
        // immediate — exactly the upstream Personnaliser's three knobs.
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final BotShape s in kBotShapes)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.id),
                    visualDensity: VisualDensity.compact,
                    selected: _shape == s.id,
                    onSelected: (_) => setState(() => _shape = s.id),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final BotExpression e in kBotExpressions)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(e.id),
                    visualDensity: VisualDensity.compact,
                    selected: _expression == e.id,
                    onSelected: (_) => setState(() => _expression = e.id),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final BotColor c in kBotColors)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _color = c.id),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor:
                          _color == c.id ? scheme.primary : Colors.transparent,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(c.argb),
                      ),
                    ),
                  ),
                ),
            ],
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
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
              // SVG exports: the still works for ANY state; the animated one
              // is the resting avatar (body still, eyes alive) — same
              // boundary the upstream app measured. Both are plain strings
              // from the pure engine; share_plus hands the file out.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Share SVG (${_state.name})',
                    icon: const Icon(Icons.file_download_outlined),
                    onPressed: () => _shareSvg(
                      'bloub_bot_${_state.name}.svg',
                      bloubBotSvg(
                        state: _state,
                        expression: _expression,
                        shape: _shape,
                        inkArgb: botColorById[_color]!.argb,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Share animated SVG (rest)',
                    icon: const Icon(Icons.animation),
                    onPressed: () => _shareSvg(
                      'bloub_bot_anime.svg',
                      bloubBotAnimatedSvg(
                        expression: _expression,
                        shape: _shape,
                        inkArgb: botColorById[_color]!.argb,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _shareSvg(String name, String markup) async {
    try {
      final File file = File('${Directory.systemTemp.path}/$name');
      await file.writeAsString(markup);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'image/svg+xml')]),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }
}
