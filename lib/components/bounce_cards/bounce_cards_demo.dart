// Demo/usage example for BounceCards. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'bounce_cards.dart';

final ComponentDemo bounceCardsDemo = ComponentDemo(
  id: 'bounce_cards',
  builder: (context) => const _BounceCardsShowcase(),
  // Static mock: the fan's settled end pose rebuilt with plain Transforms —
  // the pop-in already finished, so no controller runs in the grid.
  thumbnailBuilder: (context) => const _BounceCardsThumbnail(),
);

/// Static thumbnail — a 3-card slice of the fan at its resting pose
/// (rotation + offset, scale already 1), drawn with plain [Transform]s so
/// nothing animates. Designed at 360x460 and scaled down by [FittedBox].
class _BounceCardsThumbnail extends StatelessWidget {
  const _BounceCardsThumbnail();

  /// One settled card: gradient face, white border, rotated and offset like
  /// the component's default poses.
  static Widget _card(
    List<Color> palette,
    String number, {
    required double rotationDeg,
    required Offset offset,
  }) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotationDeg * math.pi / 180,
        child: Container(
          width: 160,
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 7),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: FittedBox(
        fit: BoxFit.contain,
        child: ClipRect(
          child: SizedBox(
            width: 360,
            height: 460,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                _card(
                  _BounceCardsShowcaseState._palettes[0],
                  '1',
                  rotationDeg: 10,
                  offset: const Offset(-72, 8),
                ),
                _card(
                  _BounceCardsShowcaseState._palettes[3],
                  '4',
                  rotationDeg: -3,
                  offset: Offset.zero,
                ),
                _card(
                  _BounceCardsShowcaseState._palettes[4],
                  '5',
                  rotationDeg: -10,
                  offset: const Offset(72, 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The original 5-card fan (gradients standing in for photos — no assets in
/// the vault) plus a replay button driving [BounceCardsState.play].
class _BounceCardsShowcase extends StatefulWidget {
  const _BounceCardsShowcase();

  @override
  State<_BounceCardsShowcase> createState() => _BounceCardsShowcaseState();
}

class _BounceCardsShowcaseState extends State<_BounceCardsShowcase> {
  final GlobalKey<BounceCardsState> _cardsKey = GlobalKey<BounceCardsState>();

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFF5227FF), Color(0xFF060010)],
    <Color>[Color(0xFFFF6D00), Color(0xFF3D1000)],
    <Color>[Color(0xFF00BFA5), Color(0xFF00251F)],
    <Color>[Color(0xFFD500F9), Color(0xFF29003A)],
    <Color>[Color(0xFF00B0FF), Color(0xFF001B33)],
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: BounceCards(
                key: _cardsKey,
                width: 600,
                height: 300,
                cards: <Widget>[
                  for (int i = 0; i < _palettes.length; i++)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _palettes[i],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _cardsKey.currentState?.play(),
              icon: const Icon(Icons.replay),
              label: const Text('Replay'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
