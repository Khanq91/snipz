// Demo/usage example for JellyBlobMascot + JellyBlobSpeech. Exempt from
// portability rules (§3.1.9); also serves as the copy-paste usage reference
// (§6) — the form section is the upstream README's "reacting to a form"
// recipe: the blob reads along as you type and looks away on the password.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'jelly_blob.dart';

final ComponentDemo jellyBlobDemo = ComponentDemo(
  id: 'jelly_blob',
  builder: (context) => const _JellyBlobShowcase(),
  // The engine is pure in time — a frozen frame costs no ticker.
  thumbnailBuilder: (context) => Center(
    child: JellyBlobMascot(
      size: 150,
      frozenAt: jellyMoodPoses[JellyBlobMood.neutral],
    ),
  ),
  variants: [
    for (final JellyBlobMood m in JellyBlobMood.values)
      DemoVariant(
        id: m.name,
        label: m.name,
        builder: (context) =>
            Center(child: JellyBlobMascot(size: 250, mood: m)),
        frozenBuilder: (context) => Center(
          child: JellyBlobMascot(
            size: 250,
            mood: m,
            frozenAt: jellyMoodPoses[m],
          ),
        ),
      ),
  ],
);

const List<(String, JellyBlobPalette)> _palettes = [
  ('violet', JellyBlobPalette.violet),
  ('mint', JellyBlobPalette.mint),
  ('coral', JellyBlobPalette.coral),
  ('gold', JellyBlobPalette.gold),
];

class _JellyBlobShowcase extends StatefulWidget {
  const _JellyBlobShowcase();

  @override
  State<_JellyBlobShowcase> createState() => _JellyBlobShowcaseState();
}

class _JellyBlobShowcaseState extends State<_JellyBlobShowcase> {
  JellyBlobMood _mood = JellyBlobMood.neutral;
  JellyHappyEyes _happyEyes = JellyHappyEyes.star;
  int _palette = 0;
  bool _speech = true;

  // form-driven state (upstream "reacting to a form")
  final FocusNode _msgFocus = FocusNode();
  final FocusNode _pwFocus = FocusNode();
  JellyTalkMouth? _talk;
  bool _nod = false;
  Timer? _talkTimer;
  int _keystrokes = 0;

  // overpoke protest, spoken through the cloud for a moment
  String? _protest;
  Timer? _protestTimer;

  @override
  void initState() {
    super.initState();
    _msgFocus.addListener(_onFocus);
    _pwFocus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _talkTimer?.cancel();
    _protestTimer?.cancel();
    _msgFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  /// Effective mood: the password field wins, then the manual chips.
  JellyBlobMood get _effectiveMood =>
      _pwFocus.hasFocus ? JellyBlobMood.password : _mood;

  /// Watching the message field = glancing down-left toward it.
  Offset get _gaze => _msgFocus.hasFocus ? const Offset(14, 9) : Offset.zero;

  void _onTyped(String _) {
    _keystrokes++;
    setState(() {
      _nod = true;
      // flip the talking mouth per keystroke so it "reads along"
      _talk = _keystrokes.isOdd ? JellyTalkMouth.open : JellyTalkMouth.wide;
    });
    _talkTimer?.cancel();
    _talkTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _talk = null;
        _nod = false;
      });
    });
  }

  void _onOverpoke() {
    setState(() => _protest = 'Stop it!');
    _protestTimer?.cancel();
    _protestTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _protest = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final JellyBlobMood mood = _effectiveMood;
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_speech)
                JellyBlobSpeech(mood: mood, text: _protest),
              Flexible(
                child: JellyBlobMascot(
                  size: 230,
                  mood: mood,
                  palette: _palettes[_palette].$2,
                  happyEyes: _happyEyes,
                  gaze: _gaze,
                  mouth: _pwFocus.hasFocus ? null : _talk,
                  nod: _nod,
                  onOverpoke: _onOverpoke,
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
              for (final JellyBlobMood m in JellyBlobMood.values)
                ChoiceChip(
                  label: Text(m.name),
                  visualDensity: VisualDensity.compact,
                  selected: _mood == m,
                  onSelected: (_) => setState(() => _mood = m),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SegmentedButton<JellyHappyEyes>(
                style: const ButtonStyle(
                    visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(
                      value: JellyHappyEyes.star, label: Text('star')),
                  ButtonSegment(
                      value: JellyHappyEyes.smile, label: Text('^_^')),
                ],
                selected: {_happyEyes},
                onSelectionChanged: (s) =>
                    setState(() => _happyEyes = s.first),
              ),
              const SizedBox(width: 14),
              for (int i = 0; i < _palettes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _palette = i),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: i == _palette
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: _palettes[i].$2.bodyMid,
                      ),
                    ),
                  ),
                ),
              const Text('cloud'),
              Switch(
                value: _speech,
                onChanged: (v) => setState(() => _speech = v),
              ),
            ],
          ),
        ),
        // the form the blob reacts to: it nods/talks along in the message
        // field and shuts its eyes on the password field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  focusNode: _msgFocus,
                  onChanged: _onTyped,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    labelText: 'Say something',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  focusNode: _pwFocus,
                  obscureText: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
