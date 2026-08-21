// SVG export tests for bloub_bot — the serializer is pure string building
// over the pure engine, so everything here is deterministic.

import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/components/bloub_bot/bloub_bot.dart';

void main() {
  test('still SVG is deterministic and structurally sound', () {
    final String a = bloubBotSvg(state: BloubBotState.wink);
    final String b = bloubBotSvg(state: BloubBotState.wink);
    expect(a, b);
    expect(a, startsWith('<svg xmlns="http://www.w3.org/2000/svg"'));
    expect(a, endsWith('</svg>'));
    expect('</svg>'.allMatches(a).length, 1);
    // the mask with the body in white and two eye holes with matrices
    expect(a, contains('<mask id="bot-mask"'));
    expect(a, contains('fill="#fff"'));
    expect('transform="matrix('.allMatches(a).length, 2);
    // the paper backing and the masked ink rect
    expect(a, contains('fill="#f9f9f9"'));
    expect(a, contains('mask="url(#bot-mask)"'));
    expect(a, contains('fill="#0a0a0c"'));
  });

  test('faceless states export with no eye holes', () {
    final String svg = bloubBotSvg(state: BloubBotState.sleep);
    expect(svg, isNot(contains('transform="matrix(')));
    expect(svg, contains('<mask id="bot-mask"'));
  });

  test('any state at any instant exports', () {
    for (final BloubBotState state in botSequence) {
      final String svg = bloubBotSvg(state: state, at: 0.6);
      expect(svg, contains('</svg>'));
    }
  });

  test('animated SVG drives both eyes from CSS keyframes, alternate loop',
      () {
    final String svg = bloubBotAnimatedSvg();
    expect(svg, bloubBotAnimatedSvg(), reason: 'deterministic');
    // eyes carry classes instead of transforms in the mask
    expect(svg, contains('class="oeil0"'));
    expect(svg, contains('class="oeil1"'));
    expect(svg, isNot(contains('transform="matrix(')));
    // 90 keys per eye (30/s x 3s), interpolated by the browser
    expect(svg, contains('@keyframes oeil0{'));
    expect(svg, contains('@keyframes oeil1{'));
    expect('%{transform:matrix('.allMatches(svg).length, 180);
    // seamless loop: forward then backward
    expect(svg, contains('animation-direction:alternate'));
    expect(svg, contains('transform-box:view-box'));
    // a blink lands inside the 3 s window: some key must squash the eye
    // (the d coefficient collapses toward the 0.06 blink floor)
    expect(svg, contains('animation-duration:2.967s'));
  });

  test('tight export frame is the default for the animated avatar', () {
    // rest avatar exports in the profile-picture crop frame, stills of the
    // catalog keep the full screen frame (rings live there later)
    expect(bloubBotAnimatedSvg(), contains('viewBox="-108 -108 216 216"'));
    expect(bloubBotSvg(), contains('viewBox="-158 -158 316 316"'));
  });
}
