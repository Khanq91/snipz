// Demo and copy-ready usage reference for CoucouMochi.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'coucou_mochi.dart';

const Color _stageColor = Color(0xFF080A10);
const _emotions = [
  CoucouMochiEmote.suspicious,
  CoucouMochiEmote.confused,
  CoucouMochiEmote.chill,
  CoucouMochiEmote.music,
  CoucouMochiEmote.shy,
];

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
        frozenAt: t % 6,
        initialEmote: _emotions[(t / 6).floor().clamp(0, 4)],
        animate: false,
        interactive: false,
        soundEnabled: false,
      ),
    ),
  ),
  scrubDuration: 30,
  variants: [
    for (final emote in _emotions)
      DemoVariant(
        id: emote.name,
        label: emote.name,
        builder: (context) => _EmotionPreview(emote: emote),
        frozenBuilder: (context) => _EmotionPreview(emote: emote, frozen: true),
      ),
    for (final CoucouMochiState state in CoucouMochiState.values)
      DemoVariant(
        id: state.name,
        label: state.name,
        builder: (context) => _MochiVariant(state: state),
        frozenBuilder: (context) => _MochiVariant(state: state, frozen: true),
      ),
    for (final scene in CoucouMochiSceneType.values)
      DemoVariant(
        id: scene.name,
        label: scene == CoucouMochiSceneType.launch
            ? 'Launch greeting'
            : 'File upload',
        builder: (context) => _ScenePreview(type: scene),
        frozenBuilder: (context) => _ScenePreview(type: scene, frozen: true),
      ),
    DemoVariant(
      id: 'mini',
      label: 'Mini companions',
      builder: (context) => const _MiniMochis(),
      frozenBuilder: (context) => const _MiniMochis(frozen: true),
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
  CoucouMochiSceneType? _scene;
  int _sceneRevision = 0;
  bool _minis = false;
  CoucouMochiEmote? _selectedEmote;
  bool _loop = false;
  double _bpm = 100;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _stageColor,
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, bounds) => Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: _minis
                      ? const _MiniMochis()
                      : _scene != null
                      ? CoucouMochiScene(
                          key: ValueKey(_sceneRevision),
                          type: _scene!,
                          width: math.min(
                            constraints.maxWidth - 24,
                            constraints.maxHeight * 640 / 176,
                          ),
                          soundEnabled: _sound,
                        )
                      : CoucouMochi(
                          size: math.max(
                            1,
                            math.min(
                              270.0,
                              math.min(
                                constraints.maxWidth - 24,
                                constraints.maxHeight / 1.28,
                              ),
                            ),
                          ),
                          state: _state,
                          controller: _controller,
                          morph: _morph,
                          soundEnabled: _sound,
                        ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: bounds.maxHeight * .72),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          for (final CoucouMochiState state
                              in CoucouMochiState.values)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: ChoiceChip(
                                label: Text(state.name),
                                visualDensity: VisualDensity.compact,
                                selected: _state == state,
                                onSelected: (_) => setState(() {
                                  _selectedEmote = null;
                                  _state = state;
                                  _scene = null;
                                  _minis = false;
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 42,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            for (final emote in _emotions)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: ChoiceChip(
                                  label: Text(emote.name),
                                  selected: _selectedEmote == emote,
                                  onSelected: (_) => _emote(emote),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedEmote != null)
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          if (_selectedEmote == CoucouMochiEmote.chill ||
                              _selectedEmote == CoucouMochiEmote.music)
                            FilterChip(
                              label: const Text('Loop'),
                              selected: _loop,
                              onSelected: (value) {
                                setState(() => _loop = value);
                                _emote(_selectedEmote!);
                              },
                            ),
                          TextButton.icon(
                            onPressed: () {
                              _controller.stopEmote();
                              setState(() => _selectedEmote = null);
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop emote'),
                          ),
                        ],
                      ),
                    if (_selectedEmote == CoucouMochiEmote.music)
                      SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text('${_bpm.round()} BPM'),
                            ),
                            Expanded(
                              child: Slider(
                                value: _bpm,
                                min: 40,
                                max: 240,
                                divisions: 40,
                                label: '${_bpm.round()} BPM',
                                onChanged: (value) =>
                                    setState(() => _bpm = value),
                                onChangeEnd: (_) =>
                                    _emote(CoucouMochiEmote.music),
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
                        _action(
                          Icons.waving_hand_outlined,
                          'Greet',
                          () => _command(_controller.greet),
                        ),
                        _action(
                          Icons.auto_awesome,
                          'Launch greeting',
                          () => setState(() {
                            _scene = CoucouMochiSceneType.launch;
                            _sceneRevision++;
                            _minis = false;
                          }),
                        ),
                        _action(
                          Icons.upload_file,
                          'File upload: drag or tap to replay',
                          () => setState(() {
                            _scene = CoucouMochiSceneType.upload;
                            _sceneRevision++;
                            _minis = false;
                          }),
                        ),
                        _action(
                          Icons.apps,
                          'Mini companions',
                          () => setState(() {
                            _minis = !_minis;
                            _scene = null;
                          }),
                        ),
                        _action(
                          Icons.favorite_border,
                          'Love',
                          () => _emote(CoucouMochiEmote.love),
                        ),
                        _action(
                          Icons.sentiment_very_satisfied_outlined,
                          'Surprise',
                          () => _emote(CoucouMochiEmote.surprised),
                        ),
                        _action(
                          Icons.star_outline,
                          'Proud',
                          () => _emote(CoucouMochiEmote.proud),
                        ),
                        _action(
                          Icons.visibility_outlined,
                          'Wink',
                          () => _emote(CoucouMochiEmote.wink),
                        ),
                        _action(
                          Icons.nights_stay_outlined,
                          'Yawn',
                          () => _emote(CoucouMochiEmote.yawn),
                        ),
                        _action(
                          Icons.sentiment_satisfied_alt_outlined,
                          'Happy',
                          () => _emote(CoucouMochiEmote.happy),
                        ),
                        _action(
                          Icons.sentiment_dissatisfied_outlined,
                          'Annoyed',
                          () => _emote(CoucouMochiEmote.annoyed),
                        ),
                        _action(Icons.move_to_inbox_outlined, 'Gulp', () {
                          _command(_controller.gulp);
                          setState(() => _morph = 1);
                        }),
                        IconButton(
                          tooltip: _sound ? 'Mute sounds' : 'Enable sounds',
                          onPressed: () => setState(() => _sound = !_sound),
                          icon: Icon(
                            _sound ? Icons.volume_up : Icons.volume_off,
                          ),
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
                              onChanged: (value) => setState(() {
                                _morph = value;
                                _scene = null;
                                _minis = false;
                              }),
                            ),
                          ),
                          const Text('Mailbox'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _action(IconData icon, String label, VoidCallback onPressed) =>
      IconButton(tooltip: label, onPressed: onPressed, icon: Icon(icon));

  void _emote(CoucouMochiEmote emote) {
    _command(
      () => _controller.emote(
        emote,
        loop:
            _loop &&
            (emote == CoucouMochiEmote.music ||
                emote == CoucouMochiEmote.chill),
        bpm: _bpm,
      ),
    );
    setState(() => _selectedEmote = emote);
  }

  void _command(VoidCallback command) {
    setState(() {
      _selectedEmote = null;
      _scene = null;
      _minis = false;
    });
    command();
  }
}

class _EmotionPreview extends StatelessWidget {
  const _EmotionPreview({required this.emote, this.frozen = false});
  final CoucouMochiEmote emote;
  final bool frozen;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _stageColor,
    child: LayoutBuilder(
      builder: (context, constraints) => Center(
        child: CoucouMochi(
          key: ValueKey(emote),
          size: math.max(
            1,
            math.min(
              220,
              math.min(constraints.maxWidth, constraints.maxHeight / 1.28),
            ),
          ),
          initialEmote: emote,
          frozenAt: frozen ? 1.65 : null,
          soundEnabled: false,
        ),
      ),
    ),
  );
}

class _ScenePreview extends StatelessWidget {
  const _ScenePreview({required this.type, this.frozen = false});
  final CoucouMochiSceneType type;
  final bool frozen;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _stageColor,
    child: LayoutBuilder(
      builder: (context, constraints) => Center(
        child: CoucouMochiScene(
          type: type,
          width: math.max(
            1,
            math.min(constraints.maxWidth, constraints.maxHeight * 640 / 176),
          ),
          frozenAt: frozen
              ? (type == CoucouMochiSceneType.launch ? 1.9 : 1.05)
              : null,
          soundEnabled: false,
        ),
      ),
    ),
  );
}

class _MiniMochis extends StatelessWidget {
  const _MiniMochis({this.frozen = false});
  final bool frozen;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _stageColor,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = math.max(
          1.0,
          math.min(
            100.0,
            math.min(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2 / 1.28,
            ),
          ),
        );
        return Center(
          child: SizedBox(
            width: size * 2,
            height: size * 2 * 1.28,
            child: Wrap(
              children: [
                for (int i = 0; i < 4; i++)
                  CoucouMochi(
                    size: size,
                    isMini: true,
                    behaviorSeed: 41 + i * 97,
                    miniColor: const [
                      Color(0xFFE86A6A),
                      Color(0xFF3E86E0),
                      Color(0xFFEFAE5A),
                      Color(0xFF8C73F2),
                    ][i],
                    permanentEmote: const [
                      CoucouMochiEmote.happy,
                      CoucouMochiEmote.annoyed,
                      CoucouMochiEmote.wink,
                      CoucouMochiEmote.love,
                    ][i],
                    frozenAt: frozen ? 2 : null,
                    soundEnabled: false,
                    interactive: false,
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
