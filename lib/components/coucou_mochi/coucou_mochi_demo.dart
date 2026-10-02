// Demo and copy-ready usage reference for CoucouMochi.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'coucou_mochi.dart';

const Color _stageColor = Color(0xFF080A10);

final ComponentDemo coucouMochiDemo = ComponentDemo(
  id: 'coucou_mochi',
  builder: (context) => const _CoucouMochiShowcase(),
  thumbnailBuilder: (context) => const ColoredBox(
    color: _stageColor,
    child: Center(
      child: CoucouMochi(
        size: 132,
        frozenAt: 1.2,
        animate: false,
        interactive: false,
        soundEnabled: false,
      ),
    ),
  ),
  scrubBuilder: (context, t) => ColoredBox(
    color: _stageColor,
    child: Center(
      child: CoucouMochi(
        size: 220,
        frozenAt: t,
        animate: false,
        interactive: false,
        soundEnabled: false,
      ),
    ),
  ),
  scrubDuration: 26.4,
  variants: [
    for (final CoucouMochiState state in CoucouMochiState.values)
      DemoVariant(
        id: state.name,
        label: state.name,
        builder: (context) => _MochiVariant(state: state),
        frozenBuilder: (context) => _MochiVariant(state: state, frozen: true),
      ),
  ],
);

class _MochiVariant extends StatelessWidget {
  const _MochiVariant({required this.state, this.frozen = false});

  final CoucouMochiState state;
  final bool frozen;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _stageColor,
    child: Center(
      child: CoucouMochi(
        size: 220,
        state: state,
        frozenAt: frozen ? .55 : null,
        animate: !frozen,
        interactive: !frozen,
        soundEnabled: false,
      ),
    ),
  );
}

class _CoucouMochiShowcase extends StatefulWidget {
  const _CoucouMochiShowcase();

  @override
  State<_CoucouMochiShowcase> createState() => _CoucouMochiShowcaseState();
}

class _CoucouMochiShowcaseState extends State<_CoucouMochiShowcase> {
  final CoucouMochiController _controller = CoucouMochiController();
  CoucouMochiState _state = CoucouMochiState.idle;
  double _morph = 0;
  bool _sound = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _stageColor,
    child: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: CoucouMochi(
                  size: math.min(270.0, constraints.maxWidth - 24),
                  state: _state,
                  controller: _controller,
                  morph: _morph,
                  soundEnabled: _sound,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final CoucouMochiState state in CoucouMochiState.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text(state.name),
                      visualDensity: VisualDensity.compact,
                      selected: _state == state,
                      onSelected: (_) => setState(() => _state = state),
                    ),
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 4,
            runSpacing: 0,
            alignment: WrapAlignment.center,
            children: [
              _action(Icons.waving_hand_outlined, 'Greet', _controller.greet),
              _action(
                Icons.favorite_border,
                'Love',
                () => _controller.emote(CoucouMochiEmote.love),
              ),
              _action(
                Icons.sentiment_very_satisfied_outlined,
                'Surprise',
                () => _controller.emote(CoucouMochiEmote.surprised),
              ),
              _action(
                Icons.star_outline,
                'Proud',
                () => _controller.emote(CoucouMochiEmote.proud),
              ),
              _action(
                Icons.visibility_outlined,
                'Wink',
                () => _controller.emote(CoucouMochiEmote.wink),
              ),
              _action(
                Icons.nights_stay_outlined,
                'Yawn',
                () => _controller.emote(CoucouMochiEmote.yawn),
              ),
              _action(
                Icons.sentiment_satisfied_alt_outlined,
                'Happy',
                () => _controller.emote(CoucouMochiEmote.happy),
              ),
              _action(
                Icons.sentiment_dissatisfied_outlined,
                'Annoyed',
                () => _controller.emote(CoucouMochiEmote.annoyed),
              ),
              _action(Icons.move_to_inbox_outlined, 'Gulp', _controller.gulp),
              IconButton(
                tooltip: _sound ? 'Mute sounds' : 'Enable sounds',
                onPressed: () => setState(() => _sound = !_sound),
                icon: Icon(_sound ? Icons.volume_up : Icons.volume_off),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Row(
              children: [
                const Text('Mochi'),
                Expanded(
                  child: Slider(
                    value: _morph,
                    onChanged: (value) => setState(() => _morph = value),
                  ),
                ),
                const Text('Mailbox'),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _action(IconData icon, String label, VoidCallback onPressed) =>
      IconButton(tooltip: label, onPressed: onPressed, icon: Icon(icon));
}
