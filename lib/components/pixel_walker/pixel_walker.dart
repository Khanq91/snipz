/// PixelWalker
/// Origin: reimplemented — dựng lại cảnh pull-to-refresh của app Claude Code
/// mobile (mascot pixel đi qua skyline thành phố dither) từ video demo;
/// scene `nightCity` + mascot mèo Miu là phần tự chế thêm.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Movement personality; custom sprites default to [clawd].
enum PixelGait { clawd, miu, capy, duck, crab, axolotl }

/// Deterministic pose: [bob]/[sway] in sprite cells, [lean] in radians.
/// Pixel frames change discretely; the body transform remains continuous.
@immutable
class PixelSpritePose {
  const PixelSpritePose({
    required this.frameIndex,
    this.lean = 0,
    this.bob = 0,
    this.sway = 0,
    this.scaleX = 1,
    this.scaleY = 1,
  });

  final int frameIndex;
  final double lean;
  final double bob;
  final double sway;
  final double scaleX;
  final double scaleY;
}

/// Sprite pixel-art dạng ma trận ký tự: mỗi frame là một list dòng, mỗi ký tự
/// tra màu trong [palette]; `.` (hoặc ký tự không có trong palette) là trong
/// suốt. Mọi dòng trong một frame phải dài bằng nhau, mọi frame cùng kích cỡ.
///
/// Frame 0 là pose đứng yên; các frame còn lại là chu kỳ bước đi. [gait]
/// quyết định nhịp bước và chuyển động thân liên tục giữa các frame pixel.
class PixelSprite {
  const PixelSprite({
    required this.frames,
    required this.palette,
    this.gait = PixelGait.clawd,
  }) : assert(frames.length > 0);

  /// Mascot mặc định: con bọ cam kiểu Clawd — thân vuông bo, 2 hốc mắt,
  /// 3 cặp chân chạy nhanh, 1 pose đứng và 6 frame bước có màu sáng/tối.
  factory PixelSprite.clawd({Color color = const Color(0xFFE8875C)}) {
    return PixelSprite(
      frames: _clawdFrames,
      palette: <String, Color>{
        'X': color,
        'H': Color.lerp(color, Colors.white, 0.23)!,
        'S': Color.lerp(color, const Color(0xFF663B2C), 0.30)!,
        'E': const Color(0xFF35251F),
      },
    );
  }

  /// Mascot mèo "Miu" (tự chế): nhìn nghiêng bước sang phải, tai nhọn, mắt
  /// khe dọc, sọc lưng + chóp đuôi màu [stripe]. Sáu frame bước nhẹ, đuôi
  /// đi sau nhịp chân; thêm màu tai, mũi và vùng lông sáng.
  factory PixelSprite.miu({
    Color body = const Color(0xFFEBD3A0),
    Color stripe = const Color(0xFFC9884A),
  }) {
    return PixelSprite(
      frames: _miuFrames,
      gait: PixelGait.miu,
      palette: <String, Color>{
        'X': body,
        'S': stripe,
        'H': Color.lerp(body, Colors.white, 0.40)!,
        'E': const Color(0xFF35291F),
        'N': const Color(0xFFB66E66),
      },
    );
  }

  /// Mascot capybara "Capy": cục gạch biết đi nhìn nghiêng, lưng ngang, mõm
  /// vuông mũi sẫm, tai tròn nhỏ, mắt 1 ô, chân ngắn chìm dưới thân — vibe
  /// mặt đơ, lừ đừ. [dark] tô tai/mũi/chân.
  factory PixelSprite.capy({
    Color body = const Color(0xFFC49A6A),
    Color dark = const Color(0xFF7E5B38),
    Color eye = const Color(0xFF241A12),
  }) {
    return PixelSprite(
      frames: _capyFrames,
      gait: PixelGait.capy,
      palette: <String, Color>{
        'X': body,
        'S': dark,
        'E': eye,
        'H': Color.lerp(body, const Color(0xFFF3DEB8), 0.35)!,
      },
    );
  }

  /// Mascot vịt "Quạc": đầu tròn nhô trước, mỏ bè 2 ô, thân bầu đuôi hất,
  /// chân mảnh bàn bè, cánh và đuôi theo nhịp chân, thân nghiêng liên tục
  /// thành dáng lạch bạch. [beak] tô mỏ + chân.
  factory PixelSprite.duck({
    Color body = const Color(0xFFF2DE96),
    Color beak = const Color(0xFFE8963F),
    Color eye = const Color(0xFF241A12),
  }) {
    return PixelSprite(
      frames: _duckFrames,
      gait: PixelGait.duck,
      palette: <String, Color>{
        'X': body,
        'B': beak,
        'E': eye,
        'H': Color.lerp(body, Colors.white, 0.42)!,
        'S': Color.lerp(body, beak, 0.35)!,
      },
    );
  }

  /// Mascot cua "Cáu": front-facing kiểu Clawd — thân bè nguyên khối, 2 mắt
  /// lồi 2×2 trên cuống ([eyeWhite] lòng trắng + [eye] đồng tử lé vào trong),
  /// 3 cặp chân, 2 càng lớn thay phiên giơ lên ở frame bước (cáu nhưng vô
  /// hại); chân gần như không nhấc, đúng chất meme.
  factory PixelSprite.crab({
    Color body = const Color(0xFFE0654B),
    Color eyeWhite = const Color(0xFFF2EAD8),
    Color eye = const Color(0xFF2A140E),
  }) {
    return PixelSprite(
      frames: _crabFrames,
      gait: PixelGait.crab,
      palette: <String, Color>{
        'X': body,
        'W': eyeWhite,
        'E': eye,
        'H': Color.lerp(body, const Color(0xFFFFD4A8), 0.35)!,
        'S': Color.lerp(body, const Color(0xFF762D36), 0.30)!,
      },
    );
  }

  /// Mascot axolotl "Axo": nhìn nghiêng, đầu to vuông bo với 3 nhánh mang
  /// [accent] xoè sau gáy, thân ngắn, đuôi dài lượn lên/xuống theo nhịp,
  /// mang rung 1 ô ở frame bước — mềm, hiền, hơi fantasy.
  factory PixelSprite.axolotl({
    Color body = const Color(0xFFF2BFC9),
    Color accent = const Color(0xFFD9758F),
    Color eye = const Color(0xFF3A2430),
  }) {
    return PixelSprite(
      frames: _axoFrames,
      gait: PixelGait.axolotl,
      palette: <String, Color>{
        'X': body,
        'S': accent,
        'E': eye,
        'H': Color.lerp(body, Colors.white, 0.45)!,
      },
    );
  }

  final List<List<String>> frames;
  final Map<String, Color> palette;
  final PixelGait gait;

  int get rowCount => frames.first.length;
  int get colCount => frames.first.first.length;

  /// Samples phase seconds (already speed-scaled), independently of a widget.
  /// [motion] scales gestures, not [time]. Readiness keeps the feet anchored.
  /// Celebration is one 0-to-1 gesture with neutral endpoints.
  PixelSpritePose samplePose(
    double time, {
    bool walking = true,
    double motion = 1,
    double readiness = 0,
    double celebration = 0,
  }) {
    final double amount = walking ? motion.clamp(0.0, 1.0) : 0;
    final double ready = readiness.clamp(0.0, 1.0);
    final double done = celebration.clamp(0.0, 1.0);
    final double cheer = done > 0 && done < 1 ? math.sin(done * math.pi) : 0;
    // A cycle contains two steps, with a character-specific cadence.
    final double hz = switch (gait) {
      PixelGait.clawd => 2.15,
      PixelGait.miu => 1.45,
      PixelGait.capy => 0.85,
      PixelGait.duck => 1.60,
      PixelGait.crab => 1.90,
      PixelGait.axolotl => 1.05,
    };
    final double cycle = time * hz;
    final double phase = (cycle % 1) * math.pi * 2;
    final double step = math.sin(phase);
    final double lift = (1 - math.cos(phase * 2)) / 2;
    final (
      double lean,
      double bob,
      double sway,
      double squash,
    ) = switch (gait) {
      PixelGait.clawd => (
        0.045 * step,
        -0.28 * lift,
        0.07 * step,
        0.025 * lift,
      ),
      PixelGait.miu => (0.026 * step, -0.24 * lift, 0.04 * step, 0.012 * lift),
      PixelGait.capy => (0.018 * step, -0.09 * lift, 0.05 * step, 0.035 * lift),
      PixelGait.duck => (0.080 * step, -0.23 * lift, 0.23 * step, 0.020 * lift),
      PixelGait.crab => (0.022 * step, -0.08 * lift, 0.34 * step, 0.012 * lift),
      PixelGait.axolotl => (
        0.030 * step,
        -0.16 * lift,
        0.11 * step,
        0.022 * lift,
      ),
    };
    final double prepareLean = switch (gait) {
      PixelGait.miu => -0.035,
      PixelGait.capy => -0.018,
      PixelGait.duck => 0.045,
      PixelGait.crab => 0,
      PixelGait.axolotl => -0.025,
      PixelGait.clawd => -0.020,
    };
    final double jump = switch (gait) {
      PixelGait.clawd => 0.75,
      PixelGait.miu => 0.90,
      PixelGait.capy => 0.28,
      PixelGait.duck => 0.70,
      PixelGait.crab => 0.42,
      PixelGait.axolotl => 0.55,
    };
    final double compressed = ready * (gait == PixelGait.capy ? 0.035 : 0.060);
    final double stretch = cheer * 0.045;
    final int walkFrames = frames.length - 1;
    return PixelSpritePose(
      frameIndex: amount > 0 && walkFrames > 0
          ? 1 + ((cycle % 1) * walkFrames).floor().clamp(0, walkFrames - 1)
          : 0,
      lean:
          lean * amount +
          prepareLean * ready +
          0.035 * cheer * math.sin(done * math.pi * 2),
      bob: bob * amount - jump * cheer * cheer,
      sway: sway * amount,
      scaleX: 1 + compressed + squash * amount - stretch * 0.5,
      scaleY: 1 - compressed - squash * amount + stretch,
    );
  }
}

// One rest pose followed by six hand-authored pixel walk poses per mascot.
const List<List<String>> _clawdFrames = <List<String>>[
  <String>[
    '..HHHHXXXX..',
    '.HXXXXXXXXX.',
    'XXXXXXXXXXXX',
    'XXXEEXXEEXXX',
    'XXXEEXXEEXXX',
    'XXXXXXXXXXXX',
    'SXXXXXXXXXXS',
    '.SSXXXXXXSS.',
    '..XX.SS.XX..',
    '..SS.SS.SS..',
  ],
  <String>[
    '..HHHHXXXX..',
    '.HXXXXXXXXX.',
    'XXXXXXXXXXXX',
    'XXXEEXXEEXXX',
    'XXXEEXXEEXXX',
    'XXXXXXXXXXXX',
    'SXXXXXXXXXXS',
    '.SSXXXXXXSS.',
    '.XX...SS.XX.',
    'SS....SS..SS',
  ],
  <String>[
    '..HHHHXXXX..',
    '.HXXXXXXXXX.',
    'XXXXXXXXXXXX',
    'XXXEEXXEEXXX',
    'XXXEEXXEEXXX',
    'XXXXXXXXXXXX',
    'SXXXXXXXXXXS',
    '.SSXXXXXXSS.',
    '..XX..SSXX..',
    '..SS..SS.SS.',
  ],
  <String>[
    '..HHHHXXXX..',
    '.HXXXXXXXXX.',
    'XXXXXXXXXXXX',
    'XXXEEXXEEXXX',
    'XXXEEXXEEXXX',
    'XXXXXXXXXXXX',
    'SXXXXXXXXXXS',
    '.SSXXXXXXSS.',
    '...XXSS..XX.',
    '...SS.SS..SS',
  ],
  <String>[
    '..HHHHXXXX..',
    '.HXXXXXXXXX.',
    'XXXXXXXXXXXX',
    'XXXEEXXEEXXX',
    'XXXEEXXEEXXX',
    'XXXXXXXXXXXX',
    'SXXXXXXXXXXS',
    '.SSXXXXXXSS.',
    '.XX.SS...XX.',
    'SS..SS....SS',
  ],
  <String>[
    '..HHHHXXXX..',
    '.HXXXXXXXXX.',
    'XXXXXXXXXXXX',
    'XXXEEXXEEXXX',
    'XXXEEXXEEXXX',
    'XXXXXXXXXXXX',
    'SXXXXXXXXXXS',
    '.SSXXXXXXSS.',
    '..XXSS..XX..',
    '..SS.SS.SS..',
  ],
  <String>[
    '..HHHHXXXX..',
    '.HXXXXXXXXX.',
    'XXXXXXXXXXXX',
    'XXXEEXXEEXXX',
    'XXXEEXXEEXXX',
    'XXXXXXXXXXXX',
    'SXXXXXXXXXXS',
    '.SSXXXXXXSS.',
    '.XX..SSXX...',
    'SS..SS.SS...',
  ],
];

const List<List<String>> _miuFrames = <List<String>>[
  <String>[
    '..........X....X',
    '..........XS..SX',
    '..S.......XXXXXX',
    '.X........XXEXXX',
    '.X........XXEXXN',
    '.XXXSSXSSXXXXHXX',
    '..XXXSXXSXXXXXX.',
    '..XXXXHXXXXX....',
    '..SXXXXXXSSX....',
    '...XX....XX.....',
    '...SS....SS.....',
  ],
  <String>[
    '..........X....X',
    '..........XS..SX',
    '.S........XXXXXX',
    'X.........XXEXXX',
    'X.........XXEXXN',
    '.X.XSSXSSXXXXHXX',
    '..XXXSXXSXXXXXX.',
    '..XXXXHXXXXX....',
    '..SXXXXXXSSX....',
    '..XX......XX....',
    '..SS......SS....',
  ],
  <String>[
    '..........X....X',
    '..........XS..SX',
    'S.........XXXXXX',
    'X.........XXEXXX',
    '.X........XXEXXN',
    '.X.XSSXSSXXXXHXX',
    '..XXXSXXSXXXXXX.',
    '..XXXXHXXXXX....',
    '..SXXXXXXSSX....',
    '...XX.....XX....',
    '...SS.....SS....',
  ],
  <String>[
    '..........X....X',
    '..........XS..SX',
    '..........XXXXXX',
    'SX........XXEXXX',
    '.X........XXEXXN',
    '.X.XSSXSSXXXXHXX',
    '..XXXSXXSXXXXXX.',
    '..XXXXHXXXXX....',
    '..SXXXXXXSSX....',
    '....XX...XX.....',
    '....SS...SS.....',
  ],
  <String>[
    '..........X....X',
    '..........XS..SX',
    '..........XXXXXX',
    '.S........XXEXXX',
    'X.........XXEXXN',
    '.X.XSSXSSXXXXHXX',
    '..XXXSXXSXXXXXX.',
    '..XXXXHXXXXX....',
    '..SXXXXXXSSX....',
    '....XX..XX......',
    '....SS..SS......',
  ],
  <String>[
    '..........X....X',
    '..........XS..SX',
    '..........XXXXXX',
    '..........XXEXXX',
    '.S........XXEXXN',
    'X..XSSXSSXXXXHXX',
    '.XXXXSXXSXXXXXX.',
    '..XXXXHXXXXX....',
    '..SXXXXXXSSX....',
    '...XX...XX......',
    '...SS...SS......',
  ],
  <String>[
    '..........X....X',
    '..........XS..SX',
    '..........XXXXXX',
    'S.........XXEXXX',
    'X.........XXEXXN',
    '.X.XSSXSSXXXXHXX',
    '..XXXSXXSXXXXXX.',
    '..XXXXHXXXXX....',
    '..SXXXXXXSSX....',
    '..XX.....XX.....',
    '..SS.....SS.....',
  ],
];

const List<List<String>> _capyFrames = <List<String>>[
  <String>[
    '............S..S..',
    '...........HXXXXX.',
    '...........XXXEXXX',
    '..HHHHXXXXXXXXXXXS',
    '.HXXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXHXXX.',
    '.SXXXXXXXXXXXXXX..',
    '..SSXXXXXXXXSSSS..',
    '...SS.......SS....',
    '...SS.......SS....',
  ],
  <String>[
    '............S..S..',
    '...........HXXXXX.',
    '...........XXXEXXX',
    '..HHHHXXXXXXXXXXXS',
    '.HXXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXHXXX.',
    '.SXXXXXXXXXXXXXX..',
    '..SSXXXXXXXXSSSS..',
    '..SS.........SS...',
    '..SS.........SS...',
  ],
  <String>[
    '............S..S..',
    '...........HXXXXX.',
    '...........XXXEXXX',
    '..HHHHXXXXXXXXXXXS',
    '.HXXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXHXXX.',
    '.SXXXXXXXXXXXXXX..',
    '..SSXXXXXXXXSSSS..',
    '...SS........SS...',
    '...SS........SS...',
  ],
  <String>[
    '............S..S..',
    '...........HXXXXX.',
    '...........XXXEXXX',
    '..HHHHXXXXXXXXXXXS',
    '.HXXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXHXXX.',
    '.SXXXXXXXXXXXXXX..',
    '..SSXXXXXXXXSSSS..',
    '....SS......SS....',
    '.....SS.....SS....',
  ],
  <String>[
    '............S..S..',
    '...........HXXXXX.',
    '...........XXXEXXX',
    '..HHHHXXXXXXXXXXXS',
    '.HXXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXHXXX.',
    '.SXXXXXXXXXXXXXX..',
    '..SSXXXXXXXXSSSS..',
    '....SS.....SS.....',
    '....SS.....SS.....',
  ],
  <String>[
    '............S..S..',
    '...........HXXXXX.',
    '...........XXXEXXX',
    '..HHHHXXXXXXXXXXXS',
    '.HXXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXHXXX.',
    '.SXXXXXXXXXXXXXX..',
    '..SSXXXXXXXXSSSS..',
    '...SS......SS.....',
    '...SS......SS.....',
  ],
  <String>[
    '............S..S..',
    '...........HXXXXX.',
    '...........XXXEXXX',
    '..HHHHXXXXXXXXXXXS',
    '.HXXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXHXXX.',
    '.SXXXXXXXXXXXXXX..',
    '..SSXXXXXXXXSSSS..',
    '..SS........SS....',
    '..SS.......SS.....',
  ],
];

const List<List<String>> _duckFrames = <List<String>>[
  <String>[
    '........HHXX..',
    '........XXEX..',
    '........XXXXBB',
    '........HXXX..',
    '.X......XXXX..',
    '.XXHHXXXXXXX..',
    '..XXXSSXXXXXX.',
    '..SSXXXXXXSS..',
    '....B....B....',
    '...BB...BB....',
  ],
  <String>[
    '........HHXX..',
    '........XXEX..',
    '........XXXXBB',
    '.X......HXXX..',
    '........XXXX..',
    '.XXHHSSXXXXX..',
    '..XXXSSXXXXXX.',
    '..SSXXXXXXSS..',
    '...B......B...',
    '..BB.....BB...',
  ],
  <String>[
    '........HHXX..',
    '........XXEX..',
    '........XXXXBB',
    '.X......HXXX..',
    '........XXXX..',
    '.XXHHXXXXXXX..',
    '..XXSSSXXXXXX.',
    '..SSXXXXXXSS..',
    '....B.....B...',
    '...BB....BB...',
  ],
  <String>[
    '........HHXX..',
    '........XXEX..',
    '........XXXXBB',
    '........HXXX..',
    '.X......XXXX..',
    '.XXHHXXXXXXX..',
    '..XXSSSXXXXXX.',
    '..SSXXXXXXSS..',
    '.....B...B....',
    '....BB..BB....',
  ],
  <String>[
    '........HHXX..',
    '........XXEX..',
    '........XXXXBB',
    '........HXXX..',
    '.X......XXXX..',
    '.XXHHXXXXXXX..',
    '..XXXXSSXXXXX.',
    '..SSXXXXXXSS..',
    '.....B..B.....',
    '....BB.BB.....',
  ],
  <String>[
    '........HHXX..',
    '........XXEX..',
    '........XXXXBB',
    '........HXXX..',
    '.X......XXXX..',
    '.XXHHXXXXXXX..',
    '..XXXXSSXXXXX.',
    '..SSXXXXXXSS..',
    '....B...B.....',
    '...BB..BB.....',
  ],
  <String>[
    '........HHXX..',
    '........XXEX..',
    '........XXXXBB',
    '.X......HXXX..',
    '........XXXX..',
    '.XXHHSSXXXXX..',
    '..XXXSSXXXXXX.',
    '..SSXXXXXXSS..',
    '...B.....B....',
    '..BB....BB....',
  ],
];

const List<List<String>> _crabFrames = <List<String>>[
  <String>[
    '.....WW..WW.....',
    '.....WE..EW.....',
    '......X..X......',
    '....XHHHHXXX....',
    'XX..XXXXXXXX..XX',
    '.XXXXXXXXXXXXXX.',
    'SS..XXXXXXXX..SS',
    '....SSXXXXSS....',
    '....XX.XX.XX....',
    '....SS.SS.SS....',
  ],
  <String>[
    'HX...WW..WW.....',
    '.X...WE..EW.....',
    'XSX...X..X......',
    '..XXXHHHHXXX....',
    '....XXXXXXXX..XH',
    '....XXXXXXXXXXX.',
    '....XXXXXXXX..SS',
    '....SSXXXXSS....',
    '....XX.XX.XX....',
    '...SS..SS..SS...',
  ],
  <String>[
    '.....WW..WW.....',
    '.....WE..EW.....',
    'HX....X..X......',
    '.X..XHHHHXXX....',
    'SXX.XXXXXXXX..XH',
    '..XXXXXXXXXXXXX.',
    '....XXXXXXXX..SS',
    '....SSXXXXSS....',
    '....XX.XX.XX....',
    '....SS.SS.SS....',
  ],
  <String>[
    '.....WW..WW.....',
    '.....WE..EW.....',
    '......X..X....XH',
    '....XHHHHXXX..X.',
    'HX..XXXXXXXX.XXS',
    '.XXXXXXXXXXXXX..',
    'SS..XXXXXXXX....',
    '....SSXXXXSS....',
    '....XX.XX.XX....',
    '.....SSSSSS.....',
  ],
  <String>[
    '.....WW..WW...XH',
    '.....WE..EW...X.',
    '......X..X...XSX',
    '....XHHHHXXXXX..',
    'HX..XXXXXXXX....',
    '.XXXXXXXXXXX....',
    'SS..XXXXXXXX....',
    '....SSXXXXSS....',
    '....XX.XX.XX....',
    '...SS.SS..SS....',
  ],
  <String>[
    '.....WW..WW.....',
    '.....WE..EW.....',
    '......X..X....XH',
    '....XHHHHXXX..X.',
    'HX..XXXXXXXX.XXS',
    '.XXXXXXXXXXXXX..',
    'SS..XXXXXXXX....',
    '....SSXXXXSS....',
    '....XX.XX.XX....',
    '....SS.SS.SS....',
  ],
  <String>[
    '.....WW..WW.....',
    '.....WE..EW.....',
    'HX....X..X......',
    '.X..XHHHHXXX....',
    'SXX.XXXXXXXX..XH',
    '..XXXXXXXXXXXXX.',
    '....XXXXXXXX..SS',
    '....SSXXXXSS....',
    '....XX.XX.XX....',
    '.....SS.SS.SS...',
  ],
];

const List<List<String>> _axoFrames = <List<String>>[
  <String>[
    '.........S.S......',
    '........SSHHHHXX..',
    '........SSXXXXEX..',
    '.........SXXXXXX..',
    '..........XHXXSX..',
    '....XXXXXXXXXXXX..',
    '.SXXXXXHHXXXXXXX..',
    'SS..SXXXXXXXXS....',
    '.....XX......XX...',
    '....SSS.....SSS...',
  ],
  <String>[
    '........S.S.......',
    '........SSHHHHXX..',
    '.........SXXXXEX..',
    '........SSXXXXXX..',
    '..........XHXXSX..',
    'S...XXXXXXXXXXXX..',
    '.SXXXXXHHXXXXXXX..',
    '....SXXXXXXXXS....',
    '....XX........XX..',
    '...SSS.......SSS..',
  ],
  <String>[
    '........S.S.......',
    '........SSHHHHXX..',
    '.........SXXXXEX..',
    '........SSXXXXXX..',
    'S.........XHXXSX..',
    'S...XXXXXXXXXXXX..',
    '.SXXXXXHHXXXXXXX..',
    '....SXXXXXXXXS....',
    '.....XX.......XX..',
    '....SSS......SSS..',
  ],
  <String>[
    '........S.........',
    '.........SHHHHXX..',
    '........SSXXXXEX..',
    '........S.XXXXXX..',
    '..........XHXXSX..',
    'SX..XXXXXXXXXXXX..',
    '..XXXXXHHXXXXXXX..',
    '....SXXXXXXXXS....',
    '......XX.....XX...',
    '.....SSS....SSS...',
  ],
  <String>[
    '........S.........',
    '.........SHHHHXX..',
    '........SSXXXXEX..',
    '........S.XXXXXX..',
    '..........XHXXSX..',
    '....XXXXXXXXXXXX..',
    '.SXXXXXHHXXXXXXX..',
    'S...SXXXXXXXXS....',
    '......XX....XX....',
    '.....SSS...SSS....',
  ],
  <String>[
    '.........S.S......',
    '........SSHHHHXX..',
    '........SSXXXXEX..',
    '.........SXXXXXX..',
    '..........XHXXSX..',
    '....XXXXXXXXXXXX..',
    '..XXXXXHHXXXXXXX..',
    'SS..SXXXXXXXXS....',
    '.....XX.....XX....',
    '....SSS....SSS....',
  ],
  <String>[
    '.........S.S......',
    '........SSHHHHXX..',
    '........SSXXXXEX..',
    '.........SXXXXXX..',
    '..........XHXXSX..',
    '....XXXXXXXXXXXX..',
    '.SXXXXXHHXXXXXXX..',
    '.S..SXXXXXXXXS....',
    '....XX.......XX...',
    '...SSS......SSS...',
  ],
];

/// Procedural skyline, or a night city with moon, stars and mountains.
enum PixelWalkerScene { city, nightCity }

/// Cảnh pixel-art neo đáy: mascot đứng giữa, skyline thành phố + mây vẽ bằng
/// dither procedural. [progress] 0→1 hiện dần cảnh (mascot trồi lên từ mép
/// dưới, dither dày dần); [walking] bật chu kỳ bước đi + skyline/mây trôi
/// ngang (parallax); [scene] chọn bố cục nền ([PixelWalkerScene.city] mặc
/// định, [PixelWalkerScene.nightCity] thêm núi + sao + trăng + cửa sổ đèn).
/// Sinh ra cho vùng header pull-to-refresh nhưng dùng được làm
/// empty-state/loading bất kỳ.
///
/// Không expose factory `Shader`: cảnh nhiều layer + sprite animation không
/// biểu diễn được bằng một `ui.Gradient`/`ImageShader` (xem README Caveats).
class PixelWalker extends StatefulWidget {
  const PixelWalker({
    super.key,
    this.progress = 1.0,
    this.walking = false,
    this.scene = PixelWalkerScene.city,
    this.scale = 1.0,
    this.sprite,
    this.mascotColor = const Color(0xFFE8875C),
    this.skylineColor = const Color(0xFFB9B4AE),
    this.windowColor = const Color(0xFFF2C069),
    this.starColor = const Color(0xFFC7D3E6),
    this.backgroundColor = Colors.transparent,
    this.speed = 1.0,
    this.motion = 1.0,
    this.readiness = 0.0,
    this.celebration = 0.0,
    this.frozenAt,
    this.seed = 7,
  });

  /// 0 = ẩn hoàn toàn, 1 = hiện đủ. Điều khiển từ ngoài (ví dụ theo độ kéo).
  final double progress;

  /// true = mascot bước tại chỗ, skyline + mây trôi ngang. false = đứng yên,
  /// không ticker nào chạy (an toàn để giữ trong cây widget lâu dài).
  final bool walking;

  /// Bố cục cảnh nền; mặc định [PixelWalkerScene.city] — đúng cảnh gốc.
  final PixelWalkerScene scene;

  /// Mật độ chi tiết: 1.0 → ô dither 3px, ô mascot 6px. Tăng khi render vùng
  /// lớn (fullscreen ~1.5–2.0) để pixel không quá mịn, giảm khi nhét vào ô
  /// nhỏ. Đây là kích thước ô lưới, không phải scale transform.
  final double scale;

  /// Sprite thay thế; null → [PixelSprite.clawd] tô bằng [mascotColor].
  final PixelSprite? sprite;

  /// Màu mascot mặc định (chỉ dùng khi [sprite] null).
  final Color mascotColor;

  /// Màu dither của skyline; mây dùng cùng màu ở opacity thấp hơn, núi của
  /// [PixelWalkerScene.nightCity] dùng cùng màu ở 60%.
  final Color skylineColor;

  /// Màu cửa sổ sáng đèn trên toà nhà (chỉ [PixelWalkerScene.nightCity]).
  final Color windowColor;

  /// Màu sao + trăng khuyết (chỉ [PixelWalkerScene.nightCity]).
  final Color starColor;

  /// Nền vẽ dưới cảnh; mặc định trong suốt để đặt lên nền app.
  final Color backgroundColor;

  /// Nhân tốc độ bước đi + trôi skyline.
  final double speed;

  /// 0-to-1 gait strength and travel rate. Useful when easing out a refresh.
  /// Changing this or [speed] preserves the accumulated animation phase.
  final double motion;

  /// 0-to-1 preparation pose, driven by pull distance. No clock is needed.
  final double readiness;

  /// One completion gesture: 0 and 1 are neutral, 0.5 is its peak.
  /// The caller advances this value; it does not start a ticker.
  final double celebration;

  /// Freeze elapsed seconds for previews/tests, including a walking pose.
  /// Multiplied by [speed] and [motion]; bypasses the live startup ramp and
  /// disables the ticker. Null resumes the accumulated live clock.
  final double? frozenAt;

  /// Đổi seed để được skyline/mây bố cục khác (deterministic).
  final int seed;

  @override
  State<PixelWalker> createState() => _PixelWalkerState();
}

class _PixelWalkerState extends State<PixelWalker>
    with SingleTickerProviderStateMixin {
  // Tạo trong initState (không lazy) — lazy thì lần đụng đầu tiên có thể là
  // dispose(), lúc đó createTicker tra cứu TickerMode trên cây đã deactivate.
  late final Ticker _ticker;
  final _RepaintTrigger _repaint = _RepaintTrigger();

  // Thời gian animation tích lũy qua các lần start/stop ticker.
  double _timeSec = 0;
  Duration? _lastTick;
  double _walkAge = 0;
  bool _tickerMode = true;
  bool _disableAnimations = false;
  late PixelSprite _defaultSprite;

  double get _motion {
    final double ramp = widget.frozenAt != null
        ? 1
        : (_walkAge / 0.18).clamp(0.0, 1.0);
    return widget.motion.clamp(0.0, 1.0) * ramp * ramp * (3 - 2 * ramp);
  }

  double get _phase => widget.frozenAt == null
      ? _timeSec
      : widget.frozenAt! * widget.speed * widget.motion.clamp(0.0, 1.0);

  // Bố cục skyline/mây/núi cho một chu kỳ, sinh từ seed (núi rỗng khi scene
  // không có núi).
  late Int16List _heights;
  late Int16List _antennae;
  late List<_CloudSpec> _clouds;
  int _period = 1;
  late Int16List _mountains;
  int _mountPeriod = 1;

  // Reused point buffers. Views and pose samples still allocate small objects.
  final _PointSink _skySink = _PointSink();
  final _PointSink _cloudSink = _PointSink();
  final _PointSink _spriteSink = _PointSink();
  // Sao/trăng/núi vẽ tuần tự nên dùng chung một sink; cửa sổ cần sink riêng
  // vì được gom trong cùng pass với _skySink.
  final _PointSink _fxSink = _PointSink();
  final _PointSink _windowSink = _PointSink();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _defaultSprite = PixelSprite.clawd(color: widget.mascotColor);
    _rebuildLayout();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerMode = TickerMode.valuesOf(context).enabled;
    _disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(PixelWalker old) {
    super.didUpdateWidget(old);
    if (widget.seed != old.seed || widget.scene != old.scene) _rebuildLayout();
    if (widget.mascotColor != old.mascotColor) {
      _defaultSprite = PixelSprite.clawd(color: widget.mascotColor);
    }
    if (widget.walking && !old.walking) _walkAge = 0;
    _syncTicker();
    _repaint.bump();
  }

  void _syncTicker() {
    final bool run =
        widget.walking &&
        widget.frozenAt == null &&
        _tickerMode &&
        !_disableAnimations &&
        widget.speed != 0 &&
        widget.motion > 0;
    if (run == _ticker.isActive) return;
    // Restart elapsed tracking on every pause. A muted/offscreen ticker must
    // not jump by the wall time that passed while the scene was hidden.
    _lastTick = null;
    if (run) {
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final Duration? last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    // Avoid a large visible jump after an app pause or a stalled frame.
    final double dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.064);
    _walkAge += dt;
    _timeSec += dt * widget.speed * _motion;
    _repaint.bump();
  }

  void _rebuildLayout() {
    final bool night = widget.scene == PixelWalkerScene.nightCity;
    int r = (widget.seed * 2654435761) & 0x7fffffff;
    int next(int lo, int hi) {
      r = (r * 1103515245 + 12345) & 0x7fffffff;
      return lo + r % (hi - lo + 1);
    }

    // Skyline: dựng cột chiều cao cho một chu kỳ ~96 ô. Scene đêm dùng tháp
    // cao & mảnh hơn (nhà cao tầng) với khoảng hở hẹp.
    final List<int> heights = <int>[];
    final List<int> antennae = <int>[];
    while (heights.length < 96) {
      final int gap = night ? next(3, 8) : next(3, 9);
      final int width = night ? next(5, 10) : next(6, 16);
      final int height = night ? next(8, 20) : next(4, 13);
      for (int i = 0; i < gap; i++) {
        heights.add(0);
        antennae.add(0);
      }
      final int antennaAt = next(1, width - 2);
      for (int i = 0; i < width; i++) {
        heights.add(height);
        antennae.add(i == antennaAt ? next(2, 4) : 0);
      }
    }
    _heights = Int16List.fromList(heights);
    _antennae = Int16List.fromList(antennae);
    _period = _heights.length;

    // Núi (chỉ scene đêm): ridge một chu kỳ 160 ô = max của 5 đỉnh tam giác,
    // khoảng cách tính wrap-around để trôi liền mạch.
    if (night) {
      const int mp = 160;
      final Int16List m = Int16List(mp);
      for (int k = 0; k < 5; k++) {
        final int px = next(0, mp - 1);
        final int ph = next(12, 24);
        final double slope = next(30, 65) / 100;
        for (int i = 0; i < mp; i++) {
          final int dx = (i - px).abs();
          final int h = (ph - math.min(dx, mp - dx) * slope).round();
          if (h > m[i]) m[i] = h;
        }
      }
      _mountains = m;
      _mountPeriod = mp;
    } else {
      _mountains = Int16List(0);
      _mountPeriod = 1;
    }

    // Mây: vài blob rải trên một chu kỳ dài hơn skyline (parallax chậm).
    _clouds = <_CloudSpec>[
      for (int i = 0; i < 4; i++)
        _CloudSpec(
          start: i * 40 + next(0, 24),
          width: next(10, 18),
          height: next(3, 5),
          lift: next(0, 5),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: _PixelWalkerPainter(this),
        size: Size.infinite,
      ),
    );
  }
}

class _RepaintTrigger extends ChangeNotifier {
  void bump() => notifyListeners();
}

class _CloudSpec {
  const _CloudSpec({
    required this.start,
    required this.width,
    required this.height,
    required this.lift,
  });

  final int start;
  final int width;
  final int height;
  final int lift;
}

/// Buffer Float32List tự giãn, tái dùng giữa các frame.
class _PointSink {
  Float32List _buf = Float32List(512);
  int _len = 0;

  void clear() => _len = 0;

  void add(double x, double y) {
    if (_len + 2 > _buf.length) {
      final Float32List grown = Float32List(_buf.length * 2);
      grown.setAll(0, _buf);
      _buf = grown;
    }
    _buf[_len++] = x;
    _buf[_len++] = y;
  }

  bool get isEmpty => _len == 0;
  bool get isNotEmpty => _len > 0;

  Float32List get view => Float32List.sublistView(_buf, 0, _len);
}

class _PixelWalkerPainter extends CustomPainter {
  _PixelWalkerPainter(this.state) : super(repaint: state._repaint);

  final _PixelWalkerState state;

  static final Paint _dotPaint = Paint()
    ..isAntiAlias = false
    ..strokeCap = StrokeCap.square
    ..style = PaintingStyle.stroke;
  static final Paint _fillPaint = Paint();

  // Hash 2D deterministic → [0, 1). Giữ trong 32 bit để an toàn mọi platform.
  static double _hash(int x, int y, int s) {
    int h = (x * 0x27d4eb2d) & 0xffffffff;
    h ^= (y * 0x165667b1) & 0xffffffff;
    h ^= (s * 0x9e3779b1) & 0xffffffff;
    h = (h ^ (h >> 15)) & 0xffffffff;
    h = (h * 0x85ebca6b) & 0xffffffff;
    h = (h ^ (h >> 13)) & 0xffffffff;
    return (h & 0xfffff) / 0x100000;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final PixelWalker w = state.widget;

    if (w.backgroundColor.a > 0) {
      _fillPaint.color = w.backgroundColor;
      canvas.drawRect(Offset.zero & size, _fillPaint);
    }

    final double reveal = w.progress.clamp(0.0, 1.0);
    if (reveal <= 0 || size.isEmpty) return;
    final double eased = Curves.easeOutCubic.transform(reveal);

    final double cell = (3.0 * w.scale).clamp(1.0, 100.0);
    final double spriteCell = cell * 2;
    final double t = state._phase;

    final PixelSprite sprite = w.sprite ?? state._defaultSprite;
    final double spriteH = sprite.rowCount * spriteCell;
    final double spriteW = sprite.colCount * spriteCell;

    final double feetY = size.height - cell;
    // Chân trời: đáy skyline ngang tầm đầu mascot (như bản gốc).
    final double skylineBaseY = feetY - spriteH * 0.9 + (1 - eased) * 3 * cell;
    // Reserve a strip of sky even in the 110px refresh header. Compress the
    // number of skyline rows, not the pixel grid, to keep square dither dots.
    final double skyScale =
        ((skylineBaseY - 8 * cell) /
                ((w.scene == PixelWalkerScene.nightCity ? 24 : 17) * cell))
            .clamp(0.12, 1.0);

    if (w.scene == PixelWalkerScene.nightCity) {
      // Đêm: sao/trăng tĩnh sau cùng, rồi núi (parallax chậm nhất), mây, và
      // toà nhà vẽ SAU mây để tháp cao che mây → có chiều sâu.
      _paintStars(canvas, size, w, cell, skylineBaseY, eased);
      _paintMoon(canvas, size, w, cell, skylineBaseY, eased);
      _paintMountains(canvas, size, w, cell, t, skylineBaseY, eased, skyScale);
      _paintClouds(
        canvas,
        size,
        w,
        cell,
        t,
        skylineBaseY,
        eased,
        bandCells: 26,
      );
      _paintSkyline(
        canvas,
        size,
        w,
        cell,
        t,
        skylineBaseY,
        eased,
        skyScale: skyScale,
        night: true,
      );
    } else {
      _paintSkyline(
        canvas,
        size,
        w,
        cell,
        t,
        skylineBaseY,
        eased,
        skyScale: skyScale,
      );
      _paintClouds(canvas, size, w, cell, t, skylineBaseY, eased);
    }
    // Độ trồi của mascot dùng reveal TUYẾN TÍNH (không ease): chân chỉ chạm
    // đất đúng lúc progress = 1 → tự nó là chỉ báo "đủ ngưỡng để refresh".
    _paintSprite(
      canvas,
      size,
      sprite,
      spriteCell,
      spriteW,
      spriteH,
      feetY,
      sprite.samplePose(
        t,
        walking: w.walking && (!state._disableAnimations || w.frozenAt != null),
        motion: state._motion,
        readiness: w.readiness,
        celebration: state._disableAnimations ? 0 : w.celebration,
      ),
      eased,
      reveal,
    );
  }

  void _paintSkyline(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double t,
    double baseY,
    double eased, {
    required double skyScale,
    bool night = false,
  }) {
    final _PointSink sink = state._skySink..clear();
    final _PointSink windows = state._windowSink..clear();
    final double scroll = t * 9.0;
    final int first = scroll.floor();
    final double frac = scroll - first;
    final int cols = (size.width / cell).ceil() + 1;

    for (int i = 0; i <= cols; i++) {
      final int wx = first + i;
      final double sx = (i - frac) * cell + cell / 2;
      final int pi = wx % state._period;
      final int h = (state._heights[pi] * skyScale).round();
      if (h == 0) continue;
      final int extra = (state._antennae[pi] * skyScale).round();
      for (int y = 0; y < h + extra; y++) {
        final double py = baseY - y * cell - cell / 2;
        if (py < 0) break;
        // Cửa sổ sáng đèn: chỉ scene đêm, trong thân toà (không dính mép
        // trên); nhân eased để đèn "bật dần" theo độ kéo.
        if (night && y < h - 1 && _hash(wx, y, w.seed ^ 0xa11) < 0.10 * eased) {
          windows.add(sx, py);
          continue;
        }
        // Đêm dày dither hơn cho silhouette đặc.
        final double density = y >= h
            ? (night ? 0.35 : 0.30)
            : y >= h - 2
            ? (night ? 0.50 : 0.38)
            : (night ? 0.78 : 0.62);
        if (_hash(wx, y, w.seed) < density * eased) sink.add(sx, py);
      }
    }
    if (sink.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.skylineColor.withValues(alpha: w.skylineColor.a * eased);
      canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
    }
    if (windows.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.windowColor.withValues(alpha: w.windowColor.a * eased);
      canvas.drawRawPoints(ui.PointMode.points, windows.view, _dotPaint);
    }
  }

  void _paintClouds(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double t,
    double baseY,
    double eased, {
    int bandCells = 19,
  }) {
    final _PointSink sink = state._cloudSink..clear();
    const int periodCells = 160;
    final double scroll = t * 3.0;
    // Mây bay trên đỉnh skyline: city đỉnh chạm 13 + antenna 4 ô → band 19;
    // nightCity tháp tới 20 + antenna → caller đẩy band lên 26.
    final double cloudBandY = math.max(7 * cell, baseY - bandCells * cell);

    for (final _CloudSpec c in state._clouds) {
      double pos = (c.start - scroll) % periodCells;
      if (pos < 0) pos += periodCells;
      // Vẽ cả bản wrap trước đó để mây đi vào từ mép phải liền mạch.
      for (
        double base = pos - periodCells;
        base * cell <= size.width;
        base += periodCells
      ) {
        final double leftPx = base * cell;
        if (leftPx > size.width || leftPx + c.width * cell < 0) continue;
        for (int dx = 0; dx < c.width; dx++) {
          for (int dy = 0; dy < c.height; dy++) {
            final double nx = c.width == 1 ? 0 : dx / (c.width - 1) * 2 - 1;
            final double ny = c.height == 1 ? 0 : dy / (c.height - 1) * 2 - 1;
            final double r2 = nx * nx + ny * ny;
            if (r2 > 1) continue;
            final double density = 0.55 * (1 - r2) + 0.08;
            if (_hash(c.start * 131 + dx, dy, w.seed ^ 0x5bd1) <
                density * eased) {
              sink.add(
                leftPx + dx * cell + cell / 2,
                cloudBandY - c.lift * cell + dy * cell + cell / 2,
              );
            }
          }
        }
      }
    }
    if (sink.isEmpty) return;
    _dotPaint
      ..strokeWidth = cell
      ..color = w.skylineColor.withValues(
        alpha: w.skylineColor.a * eased * 0.55,
      );
    canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
  }

  void _paintMountains(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double t,
    double baseY,
    double eased,
    double skyScale,
  ) {
    if (state._mountains.isEmpty) return;
    final _PointSink sink = state._fxSink..clear();
    // Trôi chậm nhất trong các layer động — núi ở xa nhất.
    final double scroll = t * 2.2;
    final int first = scroll.floor();
    final double frac = scroll - first;
    final int cols = (size.width / cell).ceil() + 1;

    for (int i = 0; i <= cols; i++) {
      final int wx = first + i;
      final double sx = (i - frac) * cell + cell / 2;
      final int h = (state._mountains[wx % state._mountPeriod] * skyScale)
          .round();
      for (int y = 0; y < h; y++) {
        final double py = baseY - y * cell - cell / 2;
        if (py < 0) break;
        // Mép ridge dày hơn hẳn để đường núi đọc được sau các toà nhà.
        final double density = y >= h - 2 ? 0.60 : 0.40;
        if (_hash(wx, y, w.seed ^ 0x3d17) < density * eased) sink.add(sx, py);
      }
    }
    if (sink.isEmpty) return;
    _dotPaint
      ..strokeWidth = cell
      ..color = w.skylineColor.withValues(
        alpha: w.skylineColor.a * eased * 0.60,
      );
    canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
  }

  void _paintStars(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double baseY,
    double eased,
  ) {
    // Sao neo theo màn hình (xa vô cực — không parallax), rải trên lưới ô
    // bằng hash: 2 tầng sáng/mờ vẽ thành 2 lượt vì khác alpha.
    final int cols = (size.width / cell).ceil();
    final int rows = (baseY / cell).floor();
    for (int tier = 0; tier < 2; tier++) {
      final _PointSink sink = state._fxSink..clear();
      final double lo = tier == 0 ? 0.008 : 0.0;
      final double hi = tier == 0 ? 0.024 : 0.008;
      for (int cy = 0; cy < rows; cy++) {
        for (int cx = 0; cx <= cols; cx++) {
          final double v = _hash(cx, cy, w.seed ^ 0x57a5);
          if (v >= lo && v < hi) {
            sink.add(cx * cell + cell / 2, cy * cell + cell / 2);
          }
        }
      }
      if (sink.isEmpty) continue;
      _dotPaint
        ..strokeWidth = cell
        ..color = w.starColor.withValues(
          alpha: w.starColor.a * eased * (tier == 0 ? 0.25 : 0.85),
        );
      canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
    }
  }

  void _paintMoon(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double baseY,
    double eased,
  ) {
    final _PointSink sink = state._fxSink..clear();
    // Trăng khuyết dither: đĩa bán kính 3.6 ô trừ đĩa "cắn" lệch trên-phải.
    // Neo theo baseY để trăng mọc cùng cảnh lúc reveal; snap vào lưới ô.
    final double cx = (size.width * 0.78 / cell).floor() * cell + cell / 2;
    final double cy =
        (math.max(5 * cell, baseY - 22 * cell) / cell).floor() * cell +
        cell / 2;
    for (int dy = -4; dy <= 4; dy++) {
      for (int dx = -4; dx <= 4; dx++) {
        if (dx * dx + dy * dy > 3.6 * 3.6) continue;
        final double bx = dx - 1.6, by = dy + 1.2;
        if (bx * bx + by * by < 3.1 * 3.1) continue;
        if (_hash(dx + 8, dy + 8, w.seed ^ 0x300d) < 0.9) {
          sink.add(cx + dx * cell, cy + dy * cell);
        }
      }
    }
    if (sink.isEmpty) return;
    _dotPaint
      ..strokeWidth = cell
      ..color = w.starColor.withValues(alpha: w.starColor.a * eased * 0.9);
    canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
  }

  void _paintSprite(
    Canvas canvas,
    Size size,
    PixelSprite sprite,
    double spriteCell,
    double spriteW,
    double spriteH,
    double feetY,
    PixelSpritePose pose,
    double eased,
    double reveal,
  ) {
    final List<String> frame = sprite.frames[pose.frameIndex];
    final double rise = (1 - reveal) * (spriteH + spriteCell);

    canvas.save();
    canvas.translate(
      size.width / 2 + pose.sway * spriteCell,
      feetY + rise + pose.bob * spriteCell,
    );
    if (pose.lean != 0) canvas.rotate(pose.lean);
    canvas.scale(pose.scaleX, pose.scaleY);

    for (final MapEntry<String, Color> entry in sprite.palette.entries) {
      final _PointSink sink = state._spriteSink..clear();
      for (int r = 0; r < frame.length; r++) {
        final String row = frame[r];
        for (int c = 0; c < row.length; c++) {
          if (row[c] != entry.key) continue;
          sink.add(
            c * spriteCell - spriteW / 2 + spriteCell / 2,
            (r - frame.length) * spriteCell + spriteCell / 2,
          );
        }
      }
      if (sink.isEmpty) continue;
      _dotPaint
        ..strokeWidth = spriteCell
        ..color = entry.value.withValues(alpha: entry.value.a * eased);
      canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PixelWalkerPainter oldDelegate) => true;
}
