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

enum PixelSpriteVersion { v1, v2, v3, v4, v5, v6, v7 }

/// Independent art and motion editions. V1 keeps the original pixel artwork.

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

/// Các factory mặc định V1; truyền [PixelSpriteVersion.v2]..[PixelSpriteVersion.v7]
/// để chọn art 48×36 và chu kỳ 16 frame bước.

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
    this.version = PixelSpriteVersion.v1,
    this.pixelRatio = 1,
  }) : assert(frames.length > 0),
       assert(pixelRatio > 0);

  /// Mascot mặc định: con bọ cam kiểu Clawd — thân vuông bo, 2 hốc mắt,
  /// 3 cặp chân chạy nhanh, 1 pose đứng và 6 frame bước có màu sáng/tối.
  factory PixelSprite.clawd({
    Color? color,
    PixelSpriteVersion version = PixelSpriteVersion.v1,
  }) {
    if (version != PixelSpriteVersion.v1) {
      return _redesignedSprite(PixelGait.clawd, version, body: color);
    }
    color ??= const Color(0xFFE8875C);
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
    Color? body,
    Color? stripe,
    PixelSpriteVersion version = PixelSpriteVersion.v1,
  }) {
    if (version != PixelSpriteVersion.v1) {
      return _redesignedSprite(
        PixelGait.miu,
        version,
        body: body,
        detail: stripe,
      );
    }
    body ??= const Color(0xFFEBD3A0);
    stripe ??= const Color(0xFFC9884A);
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
    Color? body,
    Color? dark,
    Color? eye,
    PixelSpriteVersion version = PixelSpriteVersion.v1,
  }) {
    if (version != PixelSpriteVersion.v1) {
      return _redesignedSprite(
        PixelGait.capy,
        version,
        body: body,
        detail: dark,
        eye: eye,
      );
    }
    body ??= const Color(0xFFC49A6A);
    dark ??= const Color(0xFF7E5B38);
    eye ??= const Color(0xFF241A12);
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
    Color? body,
    Color? beak,
    Color? eye,
    PixelSpriteVersion version = PixelSpriteVersion.v1,
  }) {
    if (version != PixelSpriteVersion.v1) {
      return _redesignedSprite(
        PixelGait.duck,
        version,
        body: body,
        detail: beak,
        eye: eye,
      );
    }
    body ??= const Color(0xFFF2DE96);
    beak ??= const Color(0xFFE8963F);
    eye ??= const Color(0xFF241A12);
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
    Color? body,
    Color? eyeWhite,
    Color? eye,
    PixelSpriteVersion version = PixelSpriteVersion.v1,
  }) {
    if (version != PixelSpriteVersion.v1) {
      return _redesignedSprite(
        PixelGait.crab,
        version,
        body: body,
        eyeWhite: eyeWhite,
        eye: eye,
      );
    }
    body ??= const Color(0xFFE0654B);
    eyeWhite ??= const Color(0xFFF2EAD8);
    eye ??= const Color(0xFF2A140E);
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
    Color? body,
    Color? accent,
    Color? eye,
    PixelSpriteVersion version = PixelSpriteVersion.v1,
  }) {
    if (version != PixelSpriteVersion.v1) {
      return _redesignedSprite(
        PixelGait.axolotl,
        version,
        body: body,
        detail: accent,
        eye: eye,
      );
    }
    body ??= const Color(0xFFF2BFC9);
    accent ??= const Color(0xFFD9758F);
    eye ??= const Color(0xFF3A2430);
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

  final PixelSpriteVersion version;

  /// Number of art pixels per original sprite cell. Higher resolution artwork
  /// keeps its physical size instead of growing into the sky above the header.
  final double pixelRatio;

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
    if (version != PixelSpriteVersion.v1) {
      return _sampleRedesignPose(
        time,
        walking: walking,
        motion: motion,
        readiness: readiness,
        celebration: celebration,
      );
    }
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

  PixelSpritePose _sampleRedesignPose(
    double time, {
    required bool walking,
    required double motion,
    required double readiness,
    required double celebration,
  }) {
    final double amount = walking ? motion.clamp(0.0, 1.0) : 0;
    final double ready = readiness.clamp(0.0, 1.0);
    final double done = celebration.clamp(0.0, 1.0);
    final bool pocket = version == PixelSpriteVersion.v3;
    final double cycle = time * walkCyclesPerSecond;
    final double phase = (cycle % 1) * math.pi * 2;
    final double step = math.sin(phase);
    final double lift = (1 - math.cos(phase * 2)) / 2;
    final (double lean, double bob, double sway) = switch (gait) {
      PixelGait.clawd => (0.018, 0.60, 0.18),
      PixelGait.miu => (0.012, 0.65, 0.12),
      PixelGait.capy => (0.009, 0.28, 0.13),
      PixelGait.duck => (0.035, 0.70, 0.50),
      PixelGait.crab => (0.012, 0.24, 0.85),
      PixelGait.axolotl => (0.016, 0.40, 0.28),
    };
    final double cheer = done > 0 && done < 1 ? math.sin(done * math.pi) : 0;
    final double jump = switch (gait) {
      PixelGait.capy => 0.85,
      PixelGait.crab => 1.2,
      PixelGait.miu => 2.4,
      _ => 1.9,
    };

    if (version == PixelSpriteVersion.v2 || version == PixelSpriteVersion.v3) {
      final double jumpV2V3 = gait == PixelGait.miu ? 2.6 : jump;
      final double squash = lift * amount * (pocket ? 0.012 : 0.018);
      final double compressed =
          ready * (gait == PixelGait.capy ? 0.025 : 0.045);
      final double stretch = cheer * 0.035;
      final int walkFrames = frames.length - 1;
      return PixelSpritePose(
        frameIndex: amount > 0 && walkFrames > 0
            ? 1 + ((cycle % 1) * walkFrames).floor().clamp(0, walkFrames - 1)
            : 0,
        lean:
            lean * step * amount +
            0.015 * ready +
            (pocket ? 0.025 : 0.012) * cheer * math.sin(done * math.pi * 2),
        bob: -bob * lift * amount - jumpV2V3 * cheer * cheer,
        sway: sway * step * amount,
        scaleX: 1 + compressed + squash - stretch * 0.5,
        scaleY: 1 - compressed - squash + stretch,
      );
    }

    // V4..V7 specialized continuous body physics (strictly bounded within
    // lean < 0.4, bob < 2.5, scale in [0.7, 1.3], smooth across loop boundary):
    final (
      double verSquash,
      double verReadyCompress,
      double verReadyLean,
      double verBobFactor,
      double verLeanFactor,
    ) = switch (version) {
      PixelSpriteVersion.v4 => (0.030, 0.068, 0.012, 1.18, 0.92),
      PixelSpriteVersion.v5 => (0.009, 0.036, 0.032, 0.78, 1.30),
      PixelSpriteVersion.v6 => (0.015, 0.032, -0.038, 1.08, 1.65),
      PixelSpriteVersion.v7 => (0.020, 0.024, -0.016, 0.88, 0.85),
      _ => (0.018, 0.045, 0.015, 1.0, 1.0),
    };

    final double squash = lift * amount * verSquash;
    final double compressed =
        ready *
        (gait == PixelGait.capy ? verReadyCompress * 0.65 : verReadyCompress);
    final double stretch =
        cheer * (version == PixelSpriteVersion.v4 ? 0.050 : 0.036);
    // Small transforms preserve pixel clusters. Feet stay anchored during
    // anticipation; only the completion hop deliberately leaves the ground.
    final int walkFrames = frames.length - 1;
    final double hoverWave = version == PixelSpriteVersion.v7
        ? math.sin(phase) * 0.25 * amount
        : 0.0;

    return PixelSpritePose(
      frameIndex: amount > 0 && walkFrames > 0
          ? 1 + ((cycle % 1) * walkFrames).floor().clamp(0, walkFrames - 1)
          : 0,
      lean:
          lean * verLeanFactor * step * amount +
          verReadyLean * ready +
          0.024 * cheer * math.sin(done * math.pi * 2),
      bob:
          -bob * verBobFactor * lift * amount +
          hoverWave -
          jump * cheer * cheer,
      sway: sway * step * amount,
      scaleX: 1 + compressed + squash - stretch * 0.5,
      scaleY: 1 - compressed - squash + stretch,
    );
  }

  /// Two steps per cycle. Also useful for a seamless preview loop.
  double get walkCyclesPerSecond {
    if (version == PixelSpriteVersion.v1) {
      return switch (gait) {
        PixelGait.clawd => 2.15,
        PixelGait.miu => 1.45,
        PixelGait.capy => 0.85,
        PixelGait.duck => 1.60,
        PixelGait.crab => 1.90,
        PixelGait.axolotl => 1.05,
      };
    }
    final double base = switch (gait) {
      PixelGait.clawd => 1.05,
      PixelGait.miu => 0.95,
      PixelGait.capy => 0.68,
      PixelGait.duck => 1.10,
      PixelGait.crab => 1.05,
      PixelGait.axolotl => 0.82,
    };
    final double mult = switch (version) {
      PixelSpriteVersion.v1 => 1.0,
      PixelSpriteVersion.v2 => 1.0,
      PixelSpriteVersion.v3 => 1.08,
      PixelSpriteVersion.v4 => 0.94,
      PixelSpriteVersion.v5 => 1.16,
      PixelSpriteVersion.v6 => 1.12,
      PixelSpriteVersion.v7 => 0.88,
    };
    return base * mult;
  }
}

final Map<(PixelSpriteVersion, PixelGait), PixelSprite> _editionCache = {};

PixelSprite _redesignedSprite(
  PixelGait gait,
  PixelSpriteVersion version, {
  Color? body,
  Color? detail,
  Color? eye,
  Color? eyeWhite,
}) {
  final PixelSprite base = _editionCache.putIfAbsent(
    (version, gait),
    () => switch (version) {
      PixelSpriteVersion.v1 => PixelSprite.clawd(),
      PixelSpriteVersion.v2 => _mochiSprite(gait),
      PixelSpriteVersion.v3 => _pocketSprite(gait),
      PixelSpriteVersion.v4 => _slimeSprite(gait),
      PixelSpriteVersion.v5 => _mechaSprite(gait),
      PixelSpriteVersion.v6 => _windupSprite(gait),
      PixelSpriteVersion.v7 => _astralSprite(gait),
    },
  );
  if (body == null && detail == null && eye == null && eyeWhite == null) {
    return base;
  }
  final palette = <String, Color>{...base.palette};
  if (body != null) {
    palette['X'] = body;
    palette['H'] = Color.lerp(body, Colors.white, 0.42)!;
    palette['S'] = Color.lerp(body, const Color(0xFF79505C), 0.30)!;
    palette['O'] = Color.lerp(body, const Color(0xFF382D40), 0.62)!;
  }
  if (detail != null) {
    final keys = switch (gait) {
      PixelGait.miu => version == PixelSpriteVersion.v2 ? ['A'] : ['S', 'D'],
      PixelGait.capy => ['O', 'S'],
      PixelGait.duck => version == PixelSpriteVersion.v2 ? ['A'] : ['D'],
      _ => ['A'],
    };
    for (final key in keys) {
      palette[key] = detail;
    }
    if (gait == PixelGait.duck && version != PixelSpriteVersion.v2) {
      palette['C'] = Color.lerp(detail, Colors.white, 0.25)!;
    }
  }
  if (eye != null) palette['E'] = eye;
  if (eyeWhite != null) palette['W'] = eyeWhite;
  return PixelSprite(
    frames: base.frames,
    palette: Map.unmodifiable(palette),
    gait: gait,
    version: version,
    pixelRatio: base.pixelRatio,
  );
}

/// Small integer rasterizer used once to author/cache each edition's frames.
/// Rendering still uses the same portable character matrices as custom art.
class _SpriteCanvas {
  _SpriteCanvas(this.width, this.height)
    : _pixels = List.generate(height, (_) => List.filled(width, '.'));

  final int width;
  final int height;
  final List<List<String>> _pixels;

  void dot(int x, int y, String color) {
    if (x >= 0 && x < width && y >= 0 && y < height) _pixels[y][x] = color;
  }

  void rect(int x, int y, int width, int height, String color) {
    for (int row = y; row < y + height; row++) {
      for (int col = x; col < x + width; col++) {
        dot(col, row, color);
      }
    }
  }

  void ellipse(double cx, double cy, double rx, double ry, String color) {
    for (int y = (cy - ry).floor(); y <= (cy + ry).ceil(); y++) {
      for (int x = (cx - rx).floor(); x <= (cx + rx).ceil(); x++) {
        final double dx = (x - cx) / rx;
        final double dy = (y - cy) / ry;
        if (dx * dx + dy * dy <= 1) dot(x, y, color);
      }
    }
  }

  void line(int x0, int y0, int x1, int y1, String color, {int thickness = 1}) {
    final int dx = (x1 - x0).abs();
    final int dy = -(y1 - y0).abs();
    final int sx = x0 < x1 ? 1 : -1;
    final int sy = y0 < y1 ? 1 : -1;
    int error = dx + dy;
    while (true) {
      rect(
        x0 - thickness ~/ 2,
        y0 - thickness ~/ 2,
        thickness,
        thickness,
        color,
      );
      if (x0 == x1 && y0 == y1) break;
      final int twice = 2 * error;
      if (twice >= dy) {
        error += dy;
        x0 += sx;
      }
      if (twice <= dx) {
        error += dx;
        y0 += sy;
      }
    }
  }

  void polygon(List<math.Point<int>> points, String color) {
    if (points.length < 3) return;
    final int minX = points.map((p) => p.x).reduce(math.min);
    final int maxX = points.map((p) => p.x).reduce(math.max);
    final int minY = points.map((p) => p.y).reduce(math.min);
    final int maxY = points.map((p) => p.y).reduce(math.max);
    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        bool inside = false;
        for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
          final a = points[i];
          final b = points[j];
          if ((a.y > y) != (b.y > y) &&
              x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) {
            inside = !inside;
          }
        }
        if (inside) dot(x, y, color);
      }
    }
    for (int i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      line(a.x, a.y, b.x, b.y, color);
    }
  }

  List<String> finish() => List.unmodifiable(_pixels.map((row) => row.join()));
}

// V2 — Mochi buddies. Every pose is drawn once at sprite creation; the warm
// contour and stepped light clusters stay crisp as the continuous gait moves.
PixelSprite _mochiSprite(PixelGait gait) => PixelSprite(
  frames: List.unmodifiable(
    List<List<String>>.generate(17, (index) {
      final canvas = _SpriteCanvas(48, 36);
      final phase = index == 0 ? 0.0 : (index - 1) * math.pi / 8;
      _mochiDraw(canvas, gait, phase, index != 0);
      return canvas.finish();
    }, growable: false),
  ),
  palette: Map.unmodifiable(_mochiPalette(gait)),
  gait: gait,
  version: PixelSpriteVersion.v2,
  pixelRatio: 3,
);

Map<String, Color> _mochiPalette(PixelGait gait) {
  final colors = switch (gait) {
    PixelGait.clawd => <int>[
      0xFFAC675C,
      0xFFF1AE89,
      0xFFD88C77,
      0xFFFFD6AD,
      0xFF65463F,
      0xFFFFF7DE,
      0xFFE58C87,
      0xFFF7C39C,
    ],
    PixelGait.miu => <int>[
      0xFFAA806A,
      0xFFF2D9B2,
      0xFFD6AC80,
      0xFFFFF1D3,
      0xFF634A40,
      0xFFFFF9E7,
      0xFFDC9D91,
      0xFFBE8A61,
    ],
    PixelGait.capy => <int>[
      0xFF937361,
      0xFFD1B18D,
      0xFFB08D70,
      0xFFF2DABC,
      0xFF5E4B40,
      0xFFFFF2D9,
      0xFFC99786,
      0xFFE4C5A0,
    ],
    PixelGait.duck => <int>[
      0xFFC4A05E,
      0xFFF3DF9D,
      0xFFE5C77F,
      0xFFFFF4CE,
      0xFF6A5340,
      0xFFFFFCED,
      0xFFF0B49A,
      0xFFE8AD6D,
    ],
    PixelGait.crab => <int>[
      0xFFAE736F,
      0xFFEEB1A2,
      0xFFD68E86,
      0xFFFFDCD0,
      0xFF624944,
      0xFFFFF5DE,
      0xFFE18F8F,
      0xFFF5C7B7,
    ],
    PixelGait.axolotl => <int>[
      0xFFB88199,
      0xFFF2CFDB,
      0xFFDFAABE,
      0xFFFFEDF0,
      0xFF6B4D61,
      0xFFFFF9F4,
      0xFFE5A4B7,
      0xFFF3BACB,
    ],
  };
  return <String, Color>{
    for (var i = 0; i < colors.length; i++) 'OXSHEWNA'[i]: Color(colors[i]),
  };
}

void _mochiDraw(_SpriteCanvas c, PixelGait gait, double p, bool moving) {
  switch (gait) {
    case PixelGait.clawd:
      _mochiClawd(c, p, moving);
    case PixelGait.miu:
      _mochiMiu(c, p, moving);
    case PixelGait.capy:
      _mochiCapy(c, p, moving);
    case PixelGait.duck:
      _mochiDuck(c, p, moving);
    case PixelGait.crab:
      _mochiCrab(c, p, moving);
    case PixelGait.axolotl:
      _mochiAxo(c, p, moving);
  }
}

int _mochiSwing(double phase, bool moving, [double distance = 2]) =>
    moving ? (math.sin(phase) * distance).round() : 0;

int _mochiLift(double phase, bool moving, [double distance = 2]) =>
    moving ? (math.max(0.0, math.cos(phase)) * distance).round() : 0;

void _mochiPaw(
  _SpriteCanvas c,
  int x,
  double phase,
  bool moving, {
  int width = 3,
  String fill = 'X',
}) {
  final dx = _mochiSwing(phase, moving, 1.7);
  final lift = _mochiLift(phase, moving);
  c.ellipse(
    (x + dx).toDouble(),
    (32 - lift).toDouble(),
    width.toDouble(),
    3,
    'O',
  );
  c.ellipse((x + dx).toDouble(), (32 - lift).toDouble(), width - 1.0, 2, fill);
  c.rect(x + dx - 1, 33 - lift, 3, 1, 'H');
}

void _mochiEye(_SpriteCanvas c, int x, int y, {bool small = false}) {
  c.rect(x, y, 2, small ? 2 : 3, 'E');
  if (!small) c.dot(x, y, 'W');
}

void _mochiClawd(_SpriteCanvas c, double p, bool moving) {
  // Three pairs of little marshmallow feet follow a travelling gait.
  for (var i = 0; i < 3; i++) {
    _mochiPaw(c, 10 + i * 6, p + i * 1.1, moving, width: 2, fill: 'S');
    _mochiPaw(c, 27 + i * 5, p + math.pi + i * 1.1, moving, width: 2);
  }
  final arm = _mochiSwing(p - 0.7, moving, 1);
  c.ellipse(7, (24 + arm).toDouble(), 4, 5, 'O');
  c.ellipse(7, (23 + arm).toDouble(), 3, 4, 'X');
  c.ellipse(40, (24 - arm).toDouble(), 4, 5, 'O');
  c.ellipse(40, (23 - arm).toDouble(), 3, 4, 'X');
  // Rounded square silhouette keeps Clawd's characteristic compact shape.
  c.polygon(<math.Point<int>>[
    const math.Point(13, 8),
    const math.Point(33, 8),
    const math.Point(38, 12),
    const math.Point(40, 18),
    const math.Point(40, 27),
    const math.Point(36, 31),
    const math.Point(12, 31),
    const math.Point(8, 27),
    const math.Point(8, 17),
    const math.Point(10, 12),
  ], 'O');
  c.polygon(<math.Point<int>>[
    const math.Point(14, 9),
    const math.Point(32, 9),
    const math.Point(37, 13),
    const math.Point(39, 18),
    const math.Point(39, 26),
    const math.Point(35, 30),
    const math.Point(13, 30),
    const math.Point(9, 26),
    const math.Point(9, 18),
    const math.Point(11, 13),
  ], 'X');
  c.rect(15, 10, 16, 2, 'H');
  c.rect(12, 12, 6, 2, 'H');
  c.rect(11, 14, 3, 3, 'A');
  c.rect(36, 18, 3, 9, 'S');
  c.rect(14, 28, 21, 2, 'S');
  c.ellipse(24, 25, 10, 4, 'A');
  _mochiEye(c, 17, 18);
  _mochiEye(c, 29, 18);
  c.rect(12, 22, 4, 2, 'N');
  c.rect(32, 22, 4, 2, 'N');
  c.dot(22, 23, 'E');
  c.rect(23, 24, 3, 1, 'E');
  c.dot(26, 23, 'E');
}

void _mochiMiu(_SpriteCanvas c, double p, bool moving) {
  final tail = _mochiSwing(p - 0.85, moving, 1.6);
  // A generous curled tail: its transparent centre stays readable at 1x.
  c.ellipse(10, (19 + tail).toDouble(), 8, 10, 'O');
  c.ellipse(10, (18 + tail).toDouble(), 7, 8, 'A');
  c.ellipse(10, (17 + tail).toDouble(), 4, 5, 'O');
  c.ellipse(10, (16 + tail).toDouble(), 3, 4, '.');
  c.ellipse(12, (19 + tail).toDouble(), 3, 4, 'X');
  c.rect(5, 12 + tail, 5, 2, 'H');
  c.rect(4, 15 + tail, 2, 4, 'X');
  _mochiPaw(c, 16, p + math.pi, moving, fill: 'S');
  _mochiPaw(c, 29, p, moving, fill: 'S');
  c.ellipse(23, 25, 13, 8, 'O');
  c.ellipse(23, 24, 12, 7, 'X');
  c.ellipse(26, 27, 9, 4, 'H');
  c.rect(13, 24, 4, 4, 'S');
  final ear = _mochiSwing(p - 0.5, moving, 0.7);
  c.polygon(<math.Point<int>>[
    math.Point(22, 15),
    math.Point(23, 3 + ear),
    math.Point(27, 5 + ear),
    math.Point(31, 13),
  ], 'O');
  c.polygon(<math.Point<int>>[
    math.Point(24, 12),
    math.Point(24, 6 + ear),
    math.Point(28, 12),
  ], 'N');
  c.polygon(<math.Point<int>>[
    math.Point(33, 12),
    math.Point(38, 3 - ear),
    math.Point(41, 5 - ear),
    math.Point(41, 17),
  ], 'O');
  c.polygon(<math.Point<int>>[
    math.Point(36, 12),
    math.Point(39, 6 - ear),
    math.Point(40, 14),
  ], 'N');
  c.ellipse(31, 20, 12, 10, 'O');
  c.ellipse(31, 19, 11, 9, 'X');
  c.ellipse(34, 24, 8, 4, 'H');
  c.rect(24, 13, 5, 2, 'H');
  c.rect(28, 11, 2, 4, 'S');
  c.rect(32, 11, 2, 3, 'S');
  c.rect(36, 12, 2, 3, 'S');
  _mochiEye(c, 27, 19);
  _mochiEye(c, 37, 19);
  c.rect(24, 23, 3, 2, 'N');
  c.rect(39, 23, 3, 2, 'N');
  c.rect(32, 23, 2, 1, 'N');
  c.dot(33, 24, 'O');
  c.dot(32, 25, 'O');
  c.dot(34, 25, 'O');
  _mochiPaw(c, 21, p + 0.4, moving);
  _mochiPaw(c, 35, p + math.pi + 0.4, moving);
}

void _mochiCapy(_SpriteCanvas c, double p, bool moving) {
  _mochiPaw(c, 13, p + math.pi, moving, fill: 'S');
  _mochiPaw(c, 32, p, moving, fill: 'S');
  c.ellipse(22, 23, 16, 10, 'O');
  c.ellipse(22, 22, 15, 9, 'X');
  c.rect(13, 14, 17, 3, 'H');
  c.rect(9, 17, 6, 3, 'A');
  c.rect(10, 28, 17, 3, 'S');
  c.rect(13, 27, 8, 2, 'A');
  final ear = _mochiSwing(p - 0.65, moving, 0.6);
  c.ellipse(27, (11 + ear).toDouble(), 4, 5, 'O');
  c.ellipse(27, (11 + ear).toDouble(), 3, 4, 'X');
  c.ellipse(27, (12 + ear).toDouble(), 1, 2, 'S');
  c.ellipse(37, (12 - ear).toDouble(), 3, 4, 'O');
  c.ellipse(37, (12 - ear).toDouble(), 2, 3, 'X');
  // The long square muzzle, flat crown, and low eyes distinguish a capybara.
  c.polygon(<math.Point<int>>[
    const math.Point(26, 13),
    const math.Point(36, 13),
    const math.Point(41, 17),
    const math.Point(44, 23),
    const math.Point(44, 29),
    const math.Point(41, 31),
    const math.Point(29, 31),
    const math.Point(24, 27),
    const math.Point(23, 19),
  ], 'O');
  c.polygon(<math.Point<int>>[
    const math.Point(27, 14),
    const math.Point(36, 14),
    const math.Point(40, 18),
    const math.Point(43, 24),
    const math.Point(43, 28),
    const math.Point(40, 30),
    const math.Point(30, 30),
    const math.Point(25, 26),
    const math.Point(24, 19),
  ], 'X');
  c.rect(28, 15, 8, 2, 'A');
  c.ellipse(38, 26, 6, 4, 'H');
  // Calm, lightly curved eyelids rather than generic round eyes.
  c.rect(28, 21, 3, 1, 'E');
  c.dot(31, 20, 'E');
  c.rect(36, 21, 2, 1, 'E');
  c.rect(27, 24, 4, 2, 'N');
  c.rect(41, 24, 3, 2, 'E');
  c.rect(38, 28, 3, 1, 'O');
  c.dot(41, 27, 'O');
  _mochiPaw(c, 17, p + 0.35, moving);
  _mochiPaw(c, 34, p + math.pi + 0.35, moving);
}

void _mochiDuck(_SpriteCanvas c, double p, bool moving) {
  // Wide little slippers alternate a heel plant with a two-pixel toe lift.
  for (var i = 0; i < 2; i++) {
    final phase = p + i * math.pi;
    final dx = _mochiSwing(phase, moving, 2);
    final lift = _mochiLift(phase, moving, 2);
    final x = 20 + i * 12 + dx;
    c.rect(x, 29 - lift, 2, 5, 'O');
    c.ellipse((x + 2).toDouble(), (34 - lift).toDouble(), 4, 1, 'O');
    c.rect(x, 33 - lift, 5, 1, 'A');
  }
  final tail = _mochiSwing(p - 0.9, moving, 1);
  c.polygon(<math.Point<int>>[
    math.Point(16, 23),
    math.Point(6, 18 + tail),
    math.Point(7, 25 + tail),
    math.Point(13, 29),
  ], 'O');
  c.polygon(<math.Point<int>>[
    math.Point(15, 24),
    math.Point(8, 21 + tail),
    math.Point(9, 25 + tail),
    math.Point(14, 27),
  ], 'X');
  c.ellipse(23, 24, 14, 8, 'O');
  c.ellipse(23, 23, 13, 7, 'X');
  c.ellipse(27, 27, 8, 3, 'H');
  c.rect(15, 29, 10, 2, 'S');
  final wing = _mochiSwing(p - 0.4, moving, 1);
  c.ellipse(20, (23 + wing).toDouble(), 8, 5, 'S');
  c.ellipse(20, (22 + wing).toDouble(), 7, 4, 'H');
  c.rect(14, 23 + wing, 3, 2, 'X');
  c.dot(15, 26 + wing, 'S');
  c.dot(18, 27 + wing, 'S');
  c.ellipse(32, 15, 10, 10, 'O');
  c.ellipse(32, 14, 9, 9, 'X');
  c.ellipse(29, 10, 5, 3, 'H');
  c.line(28, 5, 28, 3, 'O', thickness: 2);
  c.line(28, 4, 31, 4, 'X', thickness: 2);
  c.line(31, 4, 33, 6, 'X', thickness: 2);
  c.ellipse(34, 20, 5, 3, 'H');
  c.ellipse(40, 19, 5, 3, 'O');
  c.ellipse(40, 18, 4, 2, 'A');
  c.rect(39, 20, 6, 1, 'S');
  _mochiEye(c, 35, 13);
  c.rect(32, 18, 3, 2, 'N');
}

void _mochiCrab(_SpriteCanvas c, double p, bool moving) {
  // Soft scalloped legs keep the shell broad and low during sideways steps.
  for (var i = 0; i < 3; i++) {
    final dx = _mochiSwing(p + i * 0.9, moving, 1.5);
    final lift = _mochiLift(p + i * 0.9, moving, 1);
    final y = 27 + i * 3;
    c.line(15, y - 2, 8 + i + dx, y - lift, 'O', thickness: 3);
    c.line(14, y - 2, 9 + i + dx, y - lift, 'X', thickness: 1);
    c.line(33, y - 2, 40 - i - dx, y - lift, 'O', thickness: 3);
    c.line(34, y - 2, 39 - i - dx, y - lift, 'X', thickness: 1);
  }
  final claw = _mochiSwing(p - 0.5, moving, 2);
  for (var side = 0; side < 2; side++) {
    final x = side == 0 ? 7 : 40;
    final lift = side == 0 ? claw : -claw;
    c.line(side == 0 ? 15 : 32, 23, x, 18 + lift, 'O', thickness: 4);
    c.line(side == 0 ? 15 : 32, 23, x, 18 + lift, 'S', thickness: 2);
    c.ellipse(x.toDouble(), (14 + lift).toDouble(), 5, 7, 'O');
    c.ellipse(x.toDouble(), (14 + lift).toDouble(), 4, 6, 'X');
    c.ellipse((x - 1).toDouble(), (12 + lift).toDouble(), 2, 3, 'H');
    c.rect(x, 7 + lift, 2, 5, '.');
    c.line(x - 1, 10 + lift, x + 1, 13 + lift, 'O');
    c.dot(x + 2, 11 + lift, 'O');
  }
  c.ellipse(24, 24, 14, 8, 'O');
  c.ellipse(24, 23, 13, 7, 'X');
  c.rect(15, 27, 18, 3, 'S');
  c.ellipse(24, 24, 10, 5, 'A');
  c.rect(18, 18, 12, 2, 'H');
  for (final x in <int>[18, 29]) {
    c.rect(x, 12, 3, 8, 'O');
    c.rect(x + 1, 12, 1, 7, 'X');
    c.ellipse((x + 1).toDouble(), 11, 4, 5, 'O');
    c.ellipse((x + 1).toDouble(), 10, 3, 4, 'W');
    _mochiEye(c, x + (x < 24 ? 1 : 0), 10);
  }
  c.rect(14, 22, 4, 2, 'N');
  c.rect(31, 22, 4, 2, 'N');
  c.dot(21, 23, 'E');
  c.rect(22, 24, 4, 1, 'E');
  c.dot(26, 23, 'E');
  c.dot(16, 27, 'H');
  c.dot(30, 27, 'H');
}

void _mochiAxo(_SpriteCanvas c, double p, bool moving) {
  final tail = _mochiSwing(p - 1.0, moving, 2);
  // A small translucent-looking fin curls around the body from behind.
  c.polygon(<math.Point<int>>[
    const math.Point(25, 31),
    const math.Point(36, 31),
    math.Point(42, 26 + tail),
    math.Point(44, 18 + tail),
    math.Point(40, 20 + tail),
    math.Point(36, 25 + tail),
    const math.Point(27, 25),
  ], 'O');
  c.polygon(<math.Point<int>>[
    const math.Point(27, 30),
    const math.Point(35, 30),
    math.Point(40, 26 + tail),
    math.Point(42, 21 + tail),
    math.Point(37, 26 + tail),
    const math.Point(28, 27),
  ], 'A');
  c.line(30, 29, 37, 28 + tail, 'H', thickness: 2);
  _mochiPaw(c, 20, p + math.pi, moving, width: 3, fill: 'S');
  _mochiPaw(c, 29, p, moving, width: 3, fill: 'S');
  c.ellipse(25, 27, 10, 7, 'O');
  c.ellipse(25, 26, 9, 6, 'X');
  c.ellipse(25, 28, 6, 4, 'H');
  final gill = _mochiSwing(p - 0.65, moving, 1);
  for (var side = 0; side < 2; side++) {
    final sign = side == 0 ? -1 : 1;
    final root = side == 0 ? 15 : 34;
    for (var petal = 0; petal < 3; petal++) {
      final tipX = root + sign * (petal == 1 ? 9 : 7);
      final tipY = 7 + petal * 7 + (side == 0 ? gill : -gill);
      c.line(root, 16, tipX, tipY, 'O', thickness: 5);
      c.line(root, 16, tipX, tipY, 'A', thickness: 3);
      c.dot(tipX, tipY - 1, 'H');
      c.line(root + sign * 3, 15, tipX - sign, tipY, 'N');
    }
  }
  // Wide smile and petal gills give Axo a different silhouette from Miu.
  c.ellipse(24, 18, 14, 11, 'O');
  c.ellipse(24, 17, 13, 10, 'X');
  c.ellipse(24, 23, 10, 4, 'H');
  c.rect(17, 9, 10, 2, 'H');
  c.rect(14, 11, 5, 2, 'H');
  c.rect(34, 16, 2, 7, 'S');
  _mochiEye(c, 17, 17);
  _mochiEye(c, 29, 17);
  c.rect(13, 21, 4, 2, 'N');
  c.rect(32, 21, 4, 2, 'N');
  c.dot(22, 22, 'E');
  c.rect(23, 23, 3, 1, 'E');
  c.dot(26, 22, 'E');
  _mochiPaw(c, 18, p + 0.4, moving, width: 3);
  _mochiPaw(c, 31, p + math.pi + 0.4, moving, width: 3);
}

/// Jewel-toned pocket companions with hand-placed pixel clusters. Each cycle
/// keeps a planted contact foot while the other foot takes a rounded arc;
/// tails, scarf ends, gills, and claws arrive slightly after the body.
PixelSprite _pocketSprite(PixelGait gait) {
  final Map<String, Color> palette = switch (gait) {
    PixelGait.clawd => const <String, Color>{
      'O': Color(0xFF603B40),
      'X': Color(0xFFF39872),
      'S': Color(0xFFD66E60),
      'H': Color(0xFFFFC69A),
      'E': Color(0xFF3E303C),
      'W': Color(0xFFFFF2DA),
      'N': Color(0xFFE86E78),
      'A': Color(0xFF43968E),
      'B': Color(0xFF87D6B6),
      'D': Color(0xFF327078),
    },
    PixelGait.miu => const <String, Color>{
      'O': Color(0xFF634249),
      'X': Color(0xFFF4B967),
      'S': Color(0xFFD48446),
      'H': Color(0xFFFFDF9E),
      'E': Color(0xFF44333F),
      'W': Color(0xFFFFF4DC),
      'N': Color(0xFFDC837E),
      'A': Color(0xFF609BAE),
      'B': Color(0xFFADE1DF),
      'D': Color(0xFFB86340),
    },
    PixelGait.capy => const <String, Color>{
      'O': Color(0xFF624740),
      'X': Color(0xFFCCA078),
      'S': Color(0xFFAC795B),
      'H': Color(0xFFE7BF8D),
      'E': Color(0xFF4E3B39),
      'W': Color(0xFFFFE3AE),
      'N': Color(0xFFD68C76),
      'A': Color(0xFFEB8B43),
      'B': Color(0xFFFFBC63),
      'D': Color(0xFF64885D),
    },
    PixelGait.duck => const <String, Color>{
      'O': Color(0xFF775743),
      'X': Color(0xFFF5D675),
      'S': Color(0xFFDBAC54),
      'H': Color(0xFFFFEAAA),
      'E': Color(0xFF4F3E3D),
      'W': Color(0xFFFFF6DA),
      'N': Color(0xFFE99A76),
      'A': Color(0xFF77A987),
      'B': Color(0xFFB7D6A3),
      'D': Color(0xFFDF8546),
      'C': Color(0xFFFAB369),
    },
    PixelGait.crab => const <String, Color>{
      'O': Color(0xFF70404C),
      'X': Color(0xFFE9817E),
      'S': Color(0xFFC85D69),
      'H': Color(0xFFFFB6A0),
      'E': Color(0xFF493344),
      'W': Color(0xFFFFEDD3),
      'N': Color(0xFFF0A18A),
      'A': Color(0xFFF7CB75),
      'B': Color(0xFFFFE8AB),
      'D': Color(0xFFAE5162),
    },
    PixelGait.axolotl => const <String, Color>{
      'O': Color(0xFF75506E),
      'X': Color(0xFFF1C2D1),
      'S': Color(0xFFD69CB8),
      'H': Color(0xFFFFDFDC),
      'E': Color(0xFF513952),
      'W': Color(0xFFFFF2E7),
      'N': Color(0xFFE28EAF),
      'A': Color(0xFFBB84B5),
      'B': Color(0xFFE3AFD4),
      'D': Color(0xFF9B75AE),
      'C': Color(0xFFD9D4EF),
    },
  };
  final frames = List<List<String>>.generate(17, (int frame) {
    final c = _SpriteCanvas(48, 36);
    final phase = frame == 0 ? 0.0 : (frame - 1) / 16 * math.pi * 2;
    final moving = frame != 0;
    switch (gait) {
      case PixelGait.clawd:
        _pocketClawd(c, phase, moving);
      case PixelGait.miu:
        _pocketMiu(c, phase, moving);
      case PixelGait.capy:
        _pocketCapy(c, phase, moving);
      case PixelGait.duck:
        _pocketDuck(c, phase, moving);
      case PixelGait.crab:
        _pocketCrab(c, phase, moving);
      case PixelGait.axolotl:
        _pocketAxo(c, phase, moving);
    }
    return c.finish();
  });
  return PixelSprite(
    frames: List.unmodifiable(frames),
    palette: Map.unmodifiable(palette),
    gait: gait,
    version: PixelSpriteVersion.v3,
    pixelRatio: 3,
  );
}

int _pocketSway(double phase, bool moving, [double amplitude = 1]) =>
    moving ? (math.sin(phase) * amplitude).round() : 0;

/// A soft rectangular contour, deliberately stepped instead of antialiased.
void _pocketBox(
  _SpriteCanvas c,
  int x,
  int y,
  int width,
  int height,
  String fill,
) {
  c.rect(x + 3, y, width - 6, height, 'O');
  c.rect(x + 1, y + 1, width - 2, height - 2, 'O');
  c.rect(x, y + 3, width, height - 6, 'O');
  c.rect(x + 3, y + 1, width - 6, height - 2, fill);
  c.rect(x + 2, y + 2, width - 4, height - 4, fill);
  c.rect(x + 1, y + 3, width - 2, height - 6, fill);
}

void _pocketOval(
  _SpriteCanvas c,
  double x,
  double y,
  double rx,
  double ry,
  String fill,
) {
  c.ellipse(x, y, rx, ry, 'O');
  c.ellipse(x, y - 0.2, rx - 1, ry - 1, fill);
}

void _pocketEye(_SpriteCanvas c, int x, int y, {bool small = false}) {
  if (small) {
    c.rect(x, y, 2, 3, 'E');
    c.dot(x, y, 'W');
  } else {
    c.rect(x, y + 1, 3, 3, 'E');
    c.rect(x + 1, y, 2, 5, 'E');
    c.dot(x + 1, y, 'W');
    c.dot(x + 2, y + 3, 'H');
  }
}

/// Contact feet travel left with the scenery; lifted feet recover right.
/// Keep the same lift timing for legs and their separately painted toe details.
(int, int) _pocketStep(
  double phase,
  bool moving, {
  int stride = 2,
  int clearance = 3,
}) {
  if (!moving) return (0, 0);
  return (
    -_pocketSway(phase, moving, stride.toDouble()),
    (math.max(0.0, -math.cos(phase)) * clearance).round(),
  );
}

/// A leg with a flat planted toe and a rounded, lifted swing foot.
void _pocketFoot(
  _SpriteCanvas c,
  int x,
  int y,
  double phase,
  bool moving, {
  String fill = 'X',
  int width = 5,
  int stride = 2,
}) {
  final (offset, lift) = _pocketStep(phase, moving, stride: stride);
  c.line(x, y, x + offset, 33 - lift, 'O', thickness: width - 1);
  c.line(x, y, x + offset, 33 - lift, fill, thickness: width - 3);
  c.rect(x + offset - width ~/ 2, 33 - lift, width, 3, 'O');
  c.rect(x + offset - width ~/ 2 + 1, 33 - lift, width - 2, 2, fill);
}

void _pocketClawd(_SpriteCanvas c, double p, bool moving) {
  final flutter = _pocketSway(p - 0.65, moving, 2);
  // Six articulated little legs retain Clawd's original bug silhouette.
  _pocketFoot(c, 15, 27, p + 0.2, moving, fill: 'S', width: 4);
  _pocketFoot(c, 33, 27, p + math.pi + 0.2, moving, fill: 'S', width: 4);
  for (final side in [-1, 1]) {
    final at = side < 0 ? 12 : 37;
    final dy = _pocketSway(p + (side < 0 ? 0 : math.pi), moving);
    c.line(at, 19, at + side * 4, 23 + dy, 'O', thickness: 4);
    c.line(at, 19, at + side * 4, 23 + dy, 'S', thickness: 2);
    c.line(at + side * 4, 23 + dy, at + side * 3, 27 + dy, 'O', thickness: 4);
    c.line(at + side * 4, 23 + dy, at + side * 3, 27 + dy, 'X', thickness: 2);
    c.dot(at + side * 4, 23 + dy, 'H');
  }
  _pocketFoot(c, 19, 28, p, moving);
  _pocketFoot(c, 30, 28, p + math.pi, moving);
  // Little scarf knot floats behind the body on the left.
  c.polygon([
    math.Point(14, 26),
    math.Point(5, 26 + flutter),
    math.Point(8, 29 + flutter),
    math.Point(6, 31 + flutter),
    math.Point(16, 29),
  ], 'O');
  c.polygon([
    math.Point(14, 27),
    math.Point(7, 27 + flutter),
    math.Point(10, 29 + flutter),
    math.Point(8, 30 + flutter),
    math.Point(15, 28),
  ], 'A');
  _pocketBox(c, 12, 9, 26, 22, 'X');
  c.rect(15, 10, 18, 2, 'H');
  c.rect(13, 13, 2, 8, 'H');
  c.rect(14, 27, 22, 2, 'S');
  c.rect(34, 15, 3, 11, 'S');
  // Three crisp head tufts give the smooth rectangle a playful contour.
  c.rect(17, 7, 5, 3, 'O');
  c.rect(18, 8, 3, 3, 'X');
  c.rect(24, 6, 4, 4, 'O');
  c.rect(25, 7, 2, 4, 'H');
  c.rect(29, 8, 4, 2, 'O');
  c.rect(30, 9, 2, 2, 'X');
  c.rect(18, 14, 3, 1, 'S');
  c.rect(29, 14, 3, 1, 'S');
  _pocketEye(c, 18, 16);
  _pocketEye(c, 29, 16);
  c.rect(15, 22, 4, 2, 'N');
  c.rect(32, 22, 3, 2, 'N');
  c.dot(23, 22, 'E');
  c.rect(24, 23, 3, 1, 'E');
  c.dot(27, 22, 'E');
  // Bandana wraps the belly with a folded, triangular front.
  c.rect(13, 26, 23, 2, 'D');
  c.rect(14, 26, 21, 1, 'B');
  c.polygon([math.Point(20, 27), math.Point(30, 27), math.Point(25, 32)], 'O');
  c.polygon([math.Point(21, 27), math.Point(29, 27), math.Point(25, 30)], 'A');
  c.line(22, 28, 25, 30, 'B');
  c.dot(25, 28, 'W');
}

void _pocketMiu(_SpriteCanvas c, double p, bool moving) {
  final tail = _pocketSway(p - 0.7, moving, 2);
  final scarf = _pocketSway(p - 0.9, moving);
  // Broad, curled tail. The inner opening remains transparent.
  c.line(16, 28, 9, 25, 'O', thickness: 7);
  c.line(9, 25, 6, 19 + tail, 'O', thickness: 7);
  c.line(6, 19 + tail, 7, 13 + tail, 'O', thickness: 7);
  c.line(7, 13 + tail, 12, 12 + tail, 'O', thickness: 7);
  c.line(12, 12 + tail, 14, 16 + tail, 'O', thickness: 6);
  c.line(16, 28, 9, 25, 'X', thickness: 5);
  c.line(9, 25, 6, 19 + tail, 'X', thickness: 5);
  c.line(6, 19 + tail, 7, 13 + tail, 'X', thickness: 5);
  c.line(7, 13 + tail, 12, 12 + tail, 'X', thickness: 5);
  c.line(12, 12 + tail, 14, 16 + tail, 'S', thickness: 4);
  c.line(6, 14 + tail, 7, 12 + tail, 'H', thickness: 2);
  c.line(7, 22 + tail, 10, 21 + tail, 'D', thickness: 2);
  _pocketFoot(c, 18, 27, p + math.pi, moving, fill: 'S', width: 4);
  _pocketFoot(c, 32, 27, p, moving, fill: 'S', width: 4);
  _pocketOval(c, 24, 25, 13, 7, 'X');
  c.ellipse(21, 22, 7, 3, 'H');
  c.rect(15, 21, 3, 4, 'S');
  c.rect(21, 20, 3, 4, 'S');
  _pocketFoot(c, 16, 28, p, moving, width: 6);
  _pocketFoot(c, 31, 28, p + math.pi, moving, width: 6);
  final (toeOffset, toeLift) = _pocketStep(p, moving);
  c.rect(14 + toeOffset, 34 - toeLift, 4, 1, 'W');
  // Folded scarf behind the neck, with a small swallowtail.
  c.polygon([
    math.Point(26, 24),
    math.Point(18, 26 + scarf),
    math.Point(20, 31 + scarf),
    math.Point(22, 29 + scarf),
    math.Point(25, 31 + scarf),
    math.Point(29, 25),
  ], 'O');
  c.polygon([
    math.Point(26, 25),
    math.Point(20, 27 + scarf),
    math.Point(21, 29 + scarf),
    math.Point(23, 28 + scarf),
    math.Point(24, 29 + scarf),
    math.Point(28, 25),
  ], 'A');
  // Uneven ear heights and a cheek ruff soften the cat's 3/4 view.
  c.polygon([
    math.Point(22, 14),
    math.Point(23, 4),
    math.Point(31, 10),
    math.Point(38, 5),
    math.Point(42, 17),
  ], 'O');
  c.polygon([
    math.Point(24, 13),
    math.Point(24, 7),
    math.Point(30, 12),
    math.Point(38, 8),
    math.Point(40, 16),
  ], 'X');
  c.polygon([math.Point(25, 11), math.Point(25, 8), math.Point(28, 11)], 'N');
  c.polygon([math.Point(35, 11), math.Point(38, 8), math.Point(39, 13)], 'N');
  _pocketBox(c, 22, 11, 21, 17, 'X');
  c.rect(24, 13, 4, 2, 'H');
  c.rect(30, 11, 2, 4, 'S');
  c.rect(34, 11, 2, 3, 'S');
  c.rect(22, 19, 2, 4, 'S');
  c.rect(40, 21, 2, 3, 'S');
  c.rect(23, 24, 3, 2, 'H');
  c.rect(38, 24, 3, 2, 'H');
  c.ellipse(34, 23, 6, 3, 'W');
  _pocketEye(c, 27, 16);
  _pocketEye(c, 37, 16, small: true);
  c.rect(24, 21, 3, 2, 'N');
  c.rect(40, 20, 2, 2, 'N');
  c.rect(33, 21, 2, 1, 'N');
  c.dot(34, 22, 'E');
  c.dot(32, 23, 'E');
  c.dot(35, 23, 'E');
  c.dot(25, 23, 'S');
  c.dot(41, 23, 'S');
  c.line(27, 27, 37, 27, 'O', thickness: 2);
  c.line(28, 27, 36, 27, 'A');
  c.rect(29, 27, 3, 1, 'B');
  c.rect(31, 28, 3, 2, 'O');
  c.dot(32, 28, 'B');
}

void _pocketCapy(_SpriteCanvas c, double p, bool moving) {
  final leaf = _pocketSway(p - 0.9, moving);
  _pocketFoot(c, 15, 28, p + math.pi, moving, fill: 'S', width: 5, stride: 1);
  _pocketFoot(c, 33, 28, p, moving, fill: 'S', width: 5, stride: 1);
  _pocketBox(c, 6, 15, 29, 17, 'X');
  c.rect(10, 16, 16, 2, 'H');
  c.rect(7, 19, 2, 7, 'H');
  c.rect(8, 28, 25, 2, 'S');
  c.rect(10, 25, 1, 2, 'H');
  c.rect(14, 27, 2, 1, 'H');
  c.rect(18, 25, 1, 2, 'S');
  _pocketFoot(c, 12, 28, p, moving, width: 6, stride: 1);
  _pocketFoot(c, 29, 28, p + math.pi, moving, width: 6, stride: 1);
  // Small velvet ears above the long, almost rectangular muzzle.
  _pocketOval(c, 25, 13, 3, 4, 'X');
  c.rect(24, 12, 2, 3, 'S');
  _pocketOval(c, 35, 12, 3, 4, 'X');
  c.rect(35, 11, 1, 3, 'S');
  _pocketBox(c, 23, 13, 21, 17, 'X');
  c.rect(27, 14, 11, 2, 'H');
  c.rect(24, 18, 2, 6, 'H');
  c.rect(26, 27, 15, 2, 'S');
  // Pale muzzle has the capybara's characteristic wide, flat front.
  _pocketBox(c, 34, 20, 11, 9, 'H');
  c.rect(35, 21, 8, 5, 'H');
  c.rect(42, 21, 2, 3, 'S');
  c.rect(41, 21, 2, 2, 'E');
  c.dot(42, 21, 'H');
  c.line(39, 26, 42, 26, 'O');
  // Calm half-lidded eye: relaxed, not expressionless.
  c.rect(28, 20, 4, 1, 'O');
  c.rect(29, 21, 2, 2, 'E');
  c.dot(29, 21, 'W');
  c.rect(27, 24, 4, 2, 'N');
  c.dot(36, 24, 'S');
  c.dot(38, 23, 'S');
  // Tiny tangerine, its highlight and leaf are only a few decisive clusters.
  _pocketOval(c, 29, 9, 4, 4, 'A');
  c.rect(27, 7, 3, 2, 'B');
  c.dot(27, 9, 'W');
  c.line(29, 5, 29 + leaf, 3, 'O');
  c.line(29, 4, 33 + leaf, 3, 'D', thickness: 2);
  c.dot(32 + leaf, 2, 'H');
}

void _pocketDuck(_SpriteCanvas c, double p, bool moving) {
  final wing = _pocketSway(p - 0.6, moving);
  final scarf = _pocketSway(p - 0.9, moving, 2);
  _pocketFoot(c, 25, 29, p + math.pi, moving, fill: 'D', width: 6);
  // Two jaunty tail feathers, visible beyond the rounded body.
  c.polygon([
    math.Point(17, 25),
    math.Point(7, 20),
    math.Point(8, 25),
    math.Point(5, 24),
    math.Point(10, 30),
    math.Point(19, 29),
  ], 'O');
  c.polygon([
    math.Point(16, 25),
    math.Point(9, 22),
    math.Point(11, 27),
    math.Point(8, 26),
    math.Point(12, 29),
    math.Point(18, 28),
  ], 'X');
  c.line(10, 24, 14, 26, 'H');
  _pocketOval(c, 23, 25, 13, 8, 'X');
  c.ellipse(25, 27, 8, 4, 'H');
  c.line(15, 30, 29, 31, 'S');
  _pocketFoot(c, 21, 29, p, moving, fill: 'D', width: 7);
  final (dx, dy) = _pocketStep(p, moving);
  c.rect(20 + dx, 34 - dy, 4, 1, 'C');
  // Bill faces right while both eyes remain visible.
  _pocketOval(c, 31, 14, 11, 10, 'X');
  c.ellipse(29, 9, 6, 3, 'H');
  c.rect(24, 11, 2, 4, 'H');
  c.rect(28, 3, 3, 3, 'O');
  c.rect(29, 4, 1, 3, 'X');
  c.rect(31, 2, 3, 4, 'O');
  c.rect(32, 3, 1, 4, 'H');
  c.rect(34, 4, 3, 3, 'O');
  c.rect(35, 5, 1, 2, 'X');
  _pocketEye(c, 28, 12);
  _pocketEye(c, 36, 12, small: true);
  c.rect(25, 18, 3, 2, 'N');
  c.rect(37, 17, 2, 2, 'N');
  c.polygon([
    math.Point(35, 17),
    math.Point(42, 16),
    math.Point(45, 18),
    math.Point(44, 21),
    math.Point(36, 21),
    math.Point(34, 19),
  ], 'O');
  c.rect(36, 17, 7, 2, 'C');
  c.rect(36, 19, 8, 1, 'D');
  c.line(37, 20, 42, 20, 'C');
  c.dot(40, 17, 'D');
  // Jade scarf, folded horizontally with a trailing double point.
  c.polygon([
    math.Point(24, 22),
    math.Point(14, 21 + scarf),
    math.Point(15, 25 + scarf),
    math.Point(13, 26 + scarf),
    math.Point(21, 27),
    math.Point(28, 24),
  ], 'O');
  c.polygon([
    math.Point(24, 23),
    math.Point(16, 23 + scarf),
    math.Point(17, 25 + scarf),
    math.Point(21, 25),
    math.Point(27, 23),
  ], 'A');
  c.line(25, 22, 34, 23, 'O', thickness: 3);
  c.line(25, 22, 34, 23, 'A');
  c.line(26, 22, 29, 22, 'B');
  // Small scalloped wing gestures behind the scarf.
  c.polygon([
    math.Point(15, 25 + wing),
    math.Point(19, 23 + wing),
    math.Point(26, 25 + wing),
    math.Point(25, 28 + wing),
    math.Point(21, 30 + wing),
    math.Point(16, 28 + wing),
  ], 'S');
  c.polygon([
    math.Point(16, 25 + wing),
    math.Point(19, 24 + wing),
    math.Point(24, 25 + wing),
    math.Point(23, 28 + wing),
    math.Point(19, 28 + wing),
  ], 'H');
  c.line(18, 26 + wing, 21, 27 + wing, 'X');
}

void _pocketCrab(_SpriteCanvas c, double p, bool moving) {
  final left = _pocketSway(p - 0.6, moving, 2);
  final right = _pocketSway(p + 1.5, moving, 2);
  // Legs splay low and far from the shell, with opposite stepping banks.
  for (final side in [-1, 1]) {
    for (var leg = 0; leg < 3; leg++) {
      final phase = p + (side < 0 ? 0 : math.pi) + leg * 0.8;
      final (step, lift) = _pocketStep(phase, moving, clearance: 2);
      final rootX = side < 0 ? 16 : 32;
      final bendX = side < 0 ? 10 - leg * 2 : 38 + leg * 2;
      final footX = bendX + side + step;
      c.line(rootX, 25 + leg, bendX, 28 + leg, 'O', thickness: 3);
      c.line(bendX, 28 + leg, footX, 35 - lift, 'O', thickness: 3);
      c.line(rootX, 25 + leg, bendX, 28 + leg, 'S');
      c.line(bendX, 28 + leg, footX, 34 - lift, 'X');
      c.dot(footX, 34 - lift, 'H');
    }
  }
  // Upturned crescent claws, each with a readable empty pincer gap.
  for (final side in [-1, 1]) {
    final x = side < 0 ? 7 : 40;
    final dy = side < 0 ? left : right;
    c.line(side < 0 ? 15 : 33, 23, x, 21 + dy, 'O', thickness: 5);
    c.line(side < 0 ? 15 : 33, 23, x, 21 + dy, 'S', thickness: 3);
    _pocketOval(c, x.toDouble(), (16 + dy).toDouble(), 5, 7, 'X');
    c.rect(x - 2, 10 + dy, 4, 5, '.');
    c.rect(x - 1, 14 + dy, 2, 3, 'O');
    c.dot(x - 2, 14 + dy, 'O');
    c.dot(x + 2, 14 + dy, 'O');
    c.line(x - 3, 13 + dy, x - 3, 17 + dy, 'H');
    c.line(x + 3, 17 + dy, x + 2, 20 + dy, 'S');
  }
  _pocketBox(c, 12, 17, 25, 14, 'X');
  c.rect(16, 18, 16, 2, 'H');
  c.rect(13, 21, 2, 4, 'H');
  c.rect(15, 28, 20, 2, 'S');
  c.ellipse(25, 26, 8, 3, 'N');
  // Eye stalks lean towards the viewer; asymmetry is cheerful, not angry.
  c.line(20, 18, 19, 13, 'O', thickness: 4);
  c.line(30, 18, 31, 12, 'O', thickness: 4);
  c.line(20, 18, 19, 13, 'X', thickness: 2);
  c.line(30, 18, 31, 12, 'X', thickness: 2);
  _pocketOval(c, 19, 12, 4, 4, 'H');
  _pocketOval(c, 31, 11, 4, 4, 'H');
  _pocketEye(c, 19, 10, small: true);
  _pocketEye(c, 30, 9, small: true);
  c.rect(16, 22, 4, 2, 'N');
  c.rect(31, 22, 3, 2, 'N');
  c.dot(22, 24, 'E');
  c.rect(23, 25, 4, 1, 'E');
  c.dot(27, 24, 'E');
  c.dot(24, 26, 'H');
  // A tiny golden sea-star clasp, left of the mouth.
  c.polygon([
    math.Point(16, 22),
    math.Point(17, 24),
    math.Point(20, 24),
    math.Point(18, 26),
    math.Point(19, 29),
    math.Point(16, 28),
    math.Point(14, 29),
    math.Point(14, 26),
    math.Point(12, 24),
    math.Point(15, 24),
  ], 'O');
  c.polygon([
    math.Point(16, 24),
    math.Point(17, 25),
    math.Point(18, 25),
    math.Point(17, 26),
    math.Point(17, 27),
    math.Point(16, 27),
    math.Point(15, 28),
    math.Point(15, 26),
    math.Point(14, 25),
    math.Point(16, 25),
  ], 'A');
  c.dot(16, 25, 'B');
}

void _pocketAxo(_SpriteCanvas c, double p, bool moving) {
  final tail = _pocketSway(p - 0.7, moving, 2);
  final gills = _pocketSway(p - 1.1, moving);
  // Transparent-looking lilac tail fin around a more solid pink center.
  c.polygon([
    math.Point(20, 27),
    math.Point(11, 24 + tail),
    math.Point(4, 19 + tail),
    math.Point(3, 25 + tail),
    math.Point(6, 30 + tail),
    math.Point(14, 32),
    math.Point(23, 30),
  ], 'O');
  c.polygon([
    math.Point(19, 27),
    math.Point(11, 25 + tail),
    math.Point(5, 21 + tail),
    math.Point(4, 25 + tail),
    math.Point(7, 29 + tail),
    math.Point(14, 31),
    math.Point(22, 29),
  ], 'C');
  c.line(7, 26 + tail, 13, 28, 'S', thickness: 3);
  c.line(13, 28, 21, 29, 'X', thickness: 4);
  c.dot(5, 24 + tail, 'W');
  _pocketFoot(c, 20, 28, p + math.pi, moving, fill: 'S', width: 4, stride: 1);
  _pocketFoot(c, 33, 28, p, moving, fill: 'S', width: 4, stride: 1);
  _pocketOval(c, 26, 27, 11, 5, 'X');
  c.ellipse(27, 28, 7, 2, 'H');
  _pocketFoot(c, 20, 29, p, moving, width: 5, stride: 1);
  _pocketFoot(c, 32, 29, p + math.pi, moving, width: 5, stride: 1);
  // Three feathery gills on each side; left bank is larger in 3/4 view.
  for (final side in [-1, 1]) {
    final x = side < 0 ? 21 : 38;
    final sway = side < 0 ? gills : -gills;
    final points = side < 0
        ? [(15, 8 + sway), (12, 15 + sway), (16, 23 + sway)]
        : [(42, 9 + sway), (44, 15 + sway), (43, 23 + sway)];
    for (var i = 0; i < points.length; i++) {
      final (tx, ty) = points[i];
      final by = 14 + i * 3;
      c.line(x, by, tx, ty, 'O', thickness: 5);
      c.line(x, by, tx, ty, 'A', thickness: 3);
      c.line(tx, ty, tx + side, ty - 2, 'O', thickness: 3);
      c.line(tx, ty, tx + side, ty - 2, 'B');
      c.dot(tx - side, ty - 1, 'C');
      c.line(tx - side, ty + 1, tx, ty + 2, 'B', thickness: 2);
      c.dot(tx, ty, 'H');
    }
  }
  _pocketBox(c, 21, 10, 20, 18, 'X');
  c.rect(25, 11, 10, 2, 'H');
  c.rect(22, 14, 2, 7, 'H');
  c.rect(24, 25, 14, 2, 'S');
  c.ellipse(32, 22, 7, 3, 'H');
  _pocketEye(c, 26, 16);
  _pocketEye(c, 35, 16, small: true);
  c.rect(23, 22, 4, 2, 'N');
  c.rect(37, 21, 3, 2, 'N');
  c.dot(30, 22, 'E');
  c.rect(31, 23, 3, 1, 'E');
  c.dot(34, 22, 'E');
  // Pearly crown freckles, a tiny star that reads only at full resolution.
  c.dot(31, 13, 'W');
  c.dot(30, 14, 'W');
  c.dot(32, 14, 'W');
  c.dot(31, 15, 'W');
  c.dot(26, 14, 'N');
  c.dot(36, 14, 'N');
  c.dot(25, 23, 'W');
  c.dot(38, 22, 'W');
}

// ============================================================================
// V4 — Bouncy Slime (Jelly translucent body, glowing nucleus, splash droplets)
// ============================================================================

PixelSprite _slimeSprite(PixelGait gait) {
  final Map<String, Color> palette = switch (gait) {
    PixelGait.clawd => const <String, Color>{
      'O': Color(0xFF1A4F55),
      'X': Color(0xFF45D6C6),
      'S': Color(0xFF289E96),
      'H': Color(0xFF9DF7E5),
      'E': Color(0xFF142E33),
      'W': Color(0xFFF0FFFF),
      'N': Color(0xFFFF7A9E),
      'A': Color(0xFFFF9F59),
      'B': Color(0xFFFFE57F),
      'C': Color(0xFFFFF5BA),
      'D': Color(0xFF1E7A74),
    },
    PixelGait.miu => const <String, Color>{
      'O': Color(0xFF472A5E),
      'X': Color(0xFFB689F5),
      'S': Color(0xFF885BD1),
      'H': Color(0xFFE3C8FF),
      'E': Color(0xFF271538),
      'W': Color(0xFFFAF2FF),
      'N': Color(0xFFFF82A9),
      'A': Color(0xFFFF70A6),
      'B': Color(0xFFFFB8D9),
      'C': Color(0xFFFFE8F5),
      'D': Color(0xFF6B3FA8),
    },
    PixelGait.capy => const <String, Color>{
      'O': Color(0xFF2B4F28),
      'X': Color(0xFF7ED665),
      'S': Color(0xFF53A641),
      'H': Color(0xFFBFF5A6),
      'E': Color(0xFF1D331B),
      'W': Color(0xFFF3FFE8),
      'N': Color(0xFFFF9678),
      'A': Color(0xFFFFB742),
      'B': Color(0xFFFFE47A),
      'C': Color(0xFFFFF9C4),
      'D': Color(0xFF3E802F),
    },
    PixelGait.duck => const <String, Color>{
      'O': Color(0xFF634418),
      'X': Color(0xFFFFCF48),
      'S': Color(0xFFDEA026),
      'H': Color(0xFFFFEC99),
      'E': Color(0xFF3B260E),
      'W': Color(0xFFFFFDE6),
      'N': Color(0xFFFF8066),
      'A': Color(0xFFFF7338),
      'B': Color(0xFFFFA866),
      'C': Color(0xFFFFF0B8),
      'D': Color(0xFFE86A24),
    },
    PixelGait.crab => const <String, Color>{
      'O': Color(0xFF611F33),
      'X': Color(0xFFFF6680),
      'S': Color(0xFFD63E5C),
      'H': Color(0xFFFFADB8),
      'E': Color(0xFF3B101E),
      'W': Color(0xFFFFF0F3),
      'N': Color(0xFFFFB37A),
      'A': Color(0xFFFFD152),
      'B': Color(0xFFFFEB99),
      'C': Color(0xFFFFF9D2),
      'D': Color(0xFFA82440),
    },
    PixelGait.axolotl => const <String, Color>{
      'O': Color(0xFF22426B),
      'X': Color(0xFF6BB8FF),
      'S': Color(0xFF4288D9),
      'H': Color(0xFFB5E2FF),
      'E': Color(0xFF142842),
      'W': Color(0xFFF0F9FF),
      'N': Color(0xFFFF85B3),
      'A': Color(0xFFFF70A6),
      'B': Color(0xFFFFB5D8),
      'C': Color(0xFFE8FFFF),
      'D': Color(0xFF2D66AD),
    },
  };
  final frames = List<List<String>>.generate(17, (int frame) {
    final c = _SpriteCanvas(48, 36);
    final phase = frame == 0 ? 0.0 : (frame - 1) / 16 * math.pi * 2;
    _slimeDraw(c, gait, phase, frame != 0);
    return c.finish();
  });
  return PixelSprite(
    frames: List.unmodifiable(frames),
    palette: Map.unmodifiable(palette),
    gait: gait,
    version: PixelSpriteVersion.v4,
    pixelRatio: 3,
  );
}

void _slimeCore(_SpriteCanvas c, int cx, int cy, double p, bool moving) {
  final int dx = moving ? (math.cos(p) * 1.6).round() : 0;
  final int dy = moving ? (math.sin(p) * 1.4).round() : 0;
  c.ellipse((cx + dx).toDouble(), (cy + dy).toDouble(), 4, 3, 'A');
  c.ellipse((cx + dx).toDouble(), (cy + dy).toDouble(), 2.6, 2, 'B');
  c.rect(cx + dx - 1, cy + dy - 1, 2, 2, 'C');
}

void _slimeDroplets(_SpriteCanvas c, double p, bool moving) {
  if (!moving) {
    c.ellipse(6, 30, 2, 1.5, 'O');
    c.dot(6, 30, 'H');
    return;
  }
  // Smooth periodic Lissajous orbit so frame 16 wraps seamlessly into frame 1:
  final int x1 = 6 + (math.cos(p) * 2.4).round();
  final int y1 = 27 + (math.sin(p) * 3.0).round();
  c.ellipse(x1.toDouble(), y1.toDouble(), 2, 2, 'O');
  c.dot(x1, y1, 'H');

  final int x2 = 5 - (math.sin(p) * 2.2).round();
  final int y2 = 19 + (math.cos(p) * 2.5).round();
  c.ellipse(x2.toDouble(), y2.toDouble(), 1.6, 1.6, 'O');
  c.dot(x2, y2, 'W');
}

void _slimePod(
  _SpriteCanvas c,
  int x,
  double p,
  bool moving, {
  int width = 4,
  String fill = 'S',
}) {
  final (offset, lift) = _pocketStep(p, moving, stride: 2, clearance: 2);
  final int px = x + offset;
  final int py = 33 - lift;
  c.ellipse(px.toDouble(), py.toDouble(), width.toDouble(), 2.5, 'O');
  c.ellipse(px.toDouble(), py.toDouble(), (width - 1).toDouble(), 1.6, fill);
  c.rect(px - 1, py - 1, 2, 1, 'H');
}

void _slimeDraw(_SpriteCanvas c, PixelGait gait, double p, bool moving) {
  final int wave = _pocketSway(p, moving, 1.5);
  _slimeDroplets(c, p, moving);

  switch (gait) {
    case PixelGait.clawd:
      for (var i = 0; i < 3; i++) {
        _slimePod(c, 13 + i * 5, p + i * 1.0, moving, width: 3);
        _slimePod(c, 26 + i * 5, p + math.pi + i * 1.0, moving, width: 3);
      }
      c.ellipse(25, 22, 15, 11, 'O');
      c.ellipse(25, 22, 14, 10, 'X');
      c.ellipse(25, 26, 12, 5, 'S');
      c.ellipse(19, (9 - wave).toDouble(), 3, 3, 'O');
      c.ellipse(19, (9 - wave).toDouble(), 2, 2, 'H');
      c.ellipse(30, (9 + wave).toDouble(), 3, 3, 'O');
      c.ellipse(30, (9 + wave).toDouble(), 2, 2, 'H');
      _slimeCore(c, 24, 23, p, moving);
      c.line(15, 15, 20, 13, 'W', thickness: 2);
      c.dot(14, 17, 'W');
      _pocketEye(c, 19, 17);
      _pocketEye(c, 29, 17);
      c.rect(16, 22, 3, 2, 'N');
      c.rect(32, 22, 3, 2, 'N');

    case PixelGait.miu:
      final int tail = _pocketSway(p - 0.8, moving, 2);
      c.ellipse(10, (19 + tail).toDouble(), 5, 7, 'O');
      c.ellipse(10, (19 + tail).toDouble(), 4, 6, 'H');
      _slimePod(c, 18, p, moving);
      _slimePod(c, 32, p + math.pi, moving);
      c.ellipse(24, 24, 13, 8, 'O');
      c.ellipse(24, 24, 12, 7, 'X');
      _slimeCore(c, 22, 24, p, moving);
      c.polygon([
        const math.Point(23, 14),
        math.Point(24, 5 + wave),
        const math.Point(30, 12),
      ], 'O');
      c.polygon([
        const math.Point(24, 13),
        math.Point(25, 7 + wave),
        const math.Point(29, 12),
      ], 'H');
      c.polygon([
        const math.Point(33, 12),
        math.Point(38, 5 - wave),
        const math.Point(41, 15),
      ], 'O');
      c.polygon([
        const math.Point(34, 12),
        math.Point(38, 7 - wave),
        const math.Point(40, 14),
      ], 'H');
      c.ellipse(32, 19, 11, 9, 'O');
      c.ellipse(32, 19, 10, 8, 'X');
      c.line(25, 13, 29, 12, 'W', thickness: 2);
      _pocketEye(c, 28, 17);
      _pocketEye(c, 37, 17, small: true);
      c.rect(25, 22, 3, 2, 'N');
      c.dot(34, 21, 'E');

    case PixelGait.capy:
      _slimePod(c, 15, p, moving, width: 5);
      _slimePod(c, 31, p + math.pi, moving, width: 5);
      c.ellipse(23, 24, 16, 9, 'O');
      c.ellipse(23, 24, 15, 8, 'X');
      c.ellipse(23, 27, 13, 4, 'S');
      _slimeCore(c, 20, 23, p, moving);
      c.ellipse(34, 21, 10, 8, 'O');
      c.ellipse(34, 21, 9, 7, 'X');
      c.ellipse(39, 23, 5, 4, 'H');
      c.line(14, 18, 22, 17, 'W', thickness: 2);
      c.ellipse(30, (9 - wave).toDouble(), 3.5, 3.5, 'O');
      c.ellipse(30, (9 - wave).toDouble(), 2.5, 2.5, 'B');
      c.dot(29, 8 - wave, 'W');
      c.rect(30, 19, 4, 1, 'E');
      c.rect(31, 20, 2, 2, 'E');
      c.dot(41, 21, 'E');

    case PixelGait.duck:
      _slimePod(c, 21, p, moving, width: 5, fill: 'D');
      _slimePod(c, 28, p + math.pi, moving, width: 5, fill: 'D');
      c.ellipse(23, 25, 13, 8, 'O');
      c.ellipse(23, 25, 12, 7, 'X');
      _slimeCore(c, 22, 25, p, moving);
      c.ellipse(31, 15, 10, 9, 'O');
      c.ellipse(31, 15, 9, 8, 'X');
      c.ellipse(31, (5 - wave).toDouble(), 3, 2.5, 'H');
      c.line(25, 10, 29, 9, 'W', thickness: 2);
      c.ellipse(40, 18, 5, 3, 'O');
      c.ellipse(40, 18, 4, 2, 'D');
      _pocketEye(c, 29, 13);
      _pocketEye(c, 36, 13, small: true);

    case PixelGait.crab:
      for (var i = 0; i < 3; i++) {
        _slimePod(c, 13 + i * 3, p + i * 0.7, moving, width: 3);
        _slimePod(c, 29 + i * 3, p + math.pi + i * 0.7, moving, width: 3);
      }
      final int claw = _pocketSway(p - 0.5, moving, 2);
      c.ellipse(8, (16 + claw).toDouble(), 4.5, 5.5, 'O');
      c.ellipse(8, (16 + claw).toDouble(), 3.5, 4.5, 'H');
      c.ellipse(40, (16 - claw).toDouble(), 4.5, 5.5, 'O');
      c.ellipse(40, (16 - claw).toDouble(), 3.5, 4.5, 'H');
      c.ellipse(24, 24, 14, 8, 'O');
      c.ellipse(24, 24, 13, 7, 'X');
      _slimeCore(c, 24, 24, p, moving);
      c.line(16, 19, 22, 18, 'W', thickness: 2);
      c.ellipse(19, 11, 3.5, 4, 'O');
      c.ellipse(19, 11, 2.5, 3, 'W');
      c.ellipse(30, 11, 3.5, 4, 'O');
      c.ellipse(30, 11, 2.5, 3, 'W');
      _pocketEye(c, 19, 10, small: true);
      _pocketEye(c, 29, 10, small: true);

    case PixelGait.axolotl:
      _slimePod(c, 19, p, moving, width: 4);
      _slimePod(c, 31, p + math.pi, moving, width: 4);
      c.ellipse(25, 26, 11, 6, 'O');
      c.ellipse(25, 26, 10, 5, 'X');
      _slimeCore(c, 25, 26, p, moving);
      for (final side in [-1, 1]) {
        final int rx = side < 0 ? 15 : 37;
        for (int g = 0; g < 3; g++) {
          c.ellipse(
            (rx + side * 3).toDouble(),
            (10 + g * 5 + side * wave).toDouble(),
            3.5,
            2,
            'O',
          );
          c.ellipse(
            (rx + side * 3).toDouble(),
            (10 + g * 5 + side * wave).toDouble(),
            2.5,
            1.2,
            'B',
          );
        }
      }
      c.ellipse(26, 17, 12, 9, 'O');
      c.ellipse(26, 17, 11, 8, 'X');
      c.line(19, 11, 24, 10, 'W', thickness: 2);
      _pocketEye(c, 21, 15);
      _pocketEye(c, 31, 15);
      c.rect(18, 20, 3, 2, 'N');
      c.rect(33, 20, 3, 2, 'N');
  }
}

// ============================================================================
// V5 — Cyber Mecha (Metal chassis, glowing LED visor, jetpack thruster plume)
// ============================================================================

PixelSprite _mechaSprite(PixelGait gait) {
  final Map<String, Color> palette = switch (gait) {
    PixelGait.clawd => const <String, Color>{
      'O': Color(0xFF1E2430),
      'X': Color(0xFF8B9BB4),
      'S': Color(0xFF5A6988),
      'H': Color(0xFFD4E0F0),
      'E': Color(0xFF121721),
      'W': Color(0xFFFFFFFF),
      'N': Color(0xFFFF5277),
      'A': Color(0xFFFF7733),
      'B': Color(0xFFFFCC33),
      'C': Color(0xFF00F5D4),
      'D': Color(0xFF3A445E),
    },
    PixelGait.miu => const <String, Color>{
      'O': Color(0xFF281E38),
      'X': Color(0xFFC2B2D6),
      'S': Color(0xFF83719E),
      'H': Color(0xFFEDE4F7),
      'E': Color(0xFF171124),
      'W': Color(0xFFFFFFFF),
      'N': Color(0xFFFF5E97),
      'A': Color(0xFFFF6B4A),
      'B': Color(0xFFFFD15C),
      'C': Color(0xFFFF47B5),
      'D': Color(0xFF4C3B63),
    },
    PixelGait.capy => const <String, Color>{
      'O': Color(0xFF262B22),
      'X': Color(0xFF9BA88D),
      'S': Color(0xFF6B785E),
      'H': Color(0xFFD2DEC5),
      'E': Color(0xFF171A14),
      'W': Color(0xFFF7FFF0),
      'N': Color(0xFFFF7A45),
      'A': Color(0xFFFF6624),
      'B': Color(0xFFFFC83B),
      'C': Color(0xFF70FF66),
      'D': Color(0xFF464F3D),
    },
    PixelGait.duck => const <String, Color>{
      'O': Color(0xFF332718),
      'X': Color(0xFFEBB852),
      'S': Color(0xFFB88428),
      'H': Color(0xFFFFE294),
      'E': Color(0xFF1F170D),
      'W': Color(0xFFFFFBE8),
      'N': Color(0xFFFF5533),
      'A': Color(0xFFFF5522),
      'B': Color(0xFFFFCC22),
      'C': Color(0xFF38E8FF),
      'D': Color(0xFFDF8546),
    },
    PixelGait.crab => const <String, Color>{
      'O': Color(0xFF361820),
      'X': Color(0xFFE05A6D),
      'S': Color(0xFFA83246),
      'H': Color(0xFFFF9CA8),
      'E': Color(0xFF210D13),
      'W': Color(0xFFFFF0F2),
      'N': Color(0xFFFFAA33),
      'A': Color(0xFFFF661A),
      'B': Color(0xFFFFDD44),
      'C': Color(0xFFFFEE55),
      'D': Color(0xFF6B1D2F),
    },
    PixelGait.axolotl => const <String, Color>{
      'O': Color(0xFF192B3D),
      'X': Color(0xFF7CC7E8),
      'S': Color(0xFF498FB3),
      'H': Color(0xFFC4EEFF),
      'E': Color(0xFF0E1A26),
      'W': Color(0xFFF2FBFF),
      'N': Color(0xFFFF66B2),
      'A': Color(0xFFFF6E40),
      'B': Color(0xFFFFD740),
      'C': Color(0xFF40FFFF),
      'D': Color(0xFF2C5375),
    },
  };
  final frames = List<List<String>>.generate(17, (int frame) {
    final c = _SpriteCanvas(48, 36);
    final phase = frame == 0 ? 0.0 : (frame - 1) / 16 * math.pi * 2;
    _mechaDraw(c, gait, phase, frame != 0);
    return c.finish();
  });
  return PixelSprite(
    frames: List.unmodifiable(frames),
    palette: Map.unmodifiable(palette),
    gait: gait,
    version: PixelSpriteVersion.v5,
    pixelRatio: 3,
  );
}

void _mechaJetpack(_SpriteCanvas c, int x, int y, double p, bool moving) {
  c.rect(x, y, 6, 9, 'O');
  c.rect(x + 1, y + 1, 4, 7, 'D');
  c.rect(x + 1, y + 2, 3, 2, 'H');
  if (!moving) {
    c.rect(x - 2, y + 6, 2, 2, 'A');
    return;
  }
  final int flame = 3 + ((math.sin(p * 2) + 1) * 1.5).round();
  c.polygon([
    math.Point(x, y + 5),
    math.Point(x - flame - 2, y + 7),
    math.Point(x, y + 9),
  ], 'A');
  c.polygon([
    math.Point(x, y + 6),
    math.Point(x - flame, y + 7),
    math.Point(x, y + 8),
  ], 'B');
  c.dot(x - 1, y + 7, 'W');

  final int sx = x - 5 + (math.cos(p) * 2).round();
  final int sy = y + 6 + (math.sin(p) * 2).round();
  c.rect(sx, sy, 2, 2, 'H');
}

void _mechaVisor(_SpriteCanvas c, int x, int y, int w, double p, bool moving) {
  c.rect(x - 1, y - 1, w + 2, 6, 'O');
  c.rect(x, y, w, 4, 'E');
  final int scan = moving
      ? ((math.sin(p) + 1) * 0.5 * (w - 3)).round()
      : w ~/ 2 - 1;
  c.rect(x + 1, y + 1, w - 2, 2, 'C');
  c.rect(x + scan, y + 1, 2, 2, 'W');
}

void _mechaDraw(_SpriteCanvas c, PixelGait gait, double p, bool moving) {
  final int bob = _pocketSway(p, moving, 1);
  _mechaJetpack(c, 9, 18 + bob, p, moving);

  switch (gait) {
    case PixelGait.clawd:
      _pocketFoot(c, 16, 27, p, moving, fill: 'D', width: 5);
      _pocketFoot(c, 31, 27, p + math.pi, moving, fill: 'D', width: 5);
      _pocketBox(c, 13, 9, 25, 21, 'X');
      c.rect(15, 11, 21, 2, 'H');
      c.rect(15, 26, 21, 2, 'S');
      c.line(25, 9, 25, 4, 'O', thickness: 2);
      c.rect(24, 3, 3, 2, math.sin(p) >= 0 ? 'N' : 'C');
      _mechaVisor(c, 17, 15, 17, p, moving);
      c.rect(18, 22, 15, 3, 'D');
      c.rect(20, 23, 3, 1, 'C');
      c.rect(25, 23, 3, 1, 'B');

    case PixelGait.miu:
      _pocketFoot(c, 18, 28, p, moving, fill: 'D', width: 5);
      _pocketFoot(c, 32, 28, p + math.pi, moving, fill: 'D', width: 5);
      _pocketBox(c, 15, 19, 20, 11, 'X');
      c.polygon([
        const math.Point(23, 13),
        const math.Point(24, 4),
        const math.Point(30, 11),
      ], 'O');
      c.polygon([
        const math.Point(25, 12),
        const math.Point(25, 6),
        const math.Point(28, 11),
      ], 'C');
      c.polygon([
        const math.Point(34, 11),
        const math.Point(39, 4),
        const math.Point(42, 14),
      ], 'O');
      c.polygon([
        const math.Point(36, 11),
        const math.Point(39, 6),
        const math.Point(40, 13),
      ], 'C');
      _pocketBox(c, 22, 11, 21, 16, 'X');
      _mechaVisor(c, 26, 15, 15, p, moving);
      c.rect(28, 22, 8, 2, 'D');

    case PixelGait.capy:
      _pocketFoot(c, 15, 28, p, moving, fill: 'D', width: 6, stride: 1);
      _pocketFoot(c, 31, 28, p + math.pi, moving, fill: 'D', width: 6, stride: 1);
      _pocketBox(c, 11, 16, 26, 15, 'X');
      c.line(22, 12, 22, 6, 'O', thickness: 2);
      c.rect(21, 5, 3, 2, 'C');
      _pocketBox(c, 24, 11, 20, 18, 'X');
      c.rect(27, 13, 14, 2, 'H');
      _mechaVisor(c, 28, 16, 14, p, moving);
      c.rect(36, 23, 6, 4, 'D');
      c.dot(40, 24, 'C');

    case PixelGait.duck:
      _pocketFoot(c, 21, 29, p, moving, fill: 'D', width: 6);
      _pocketFoot(c, 27, 29, p + math.pi, moving, fill: 'D', width: 6);
      _pocketBox(c, 14, 20, 21, 11, 'X');
      c.rect(29, 5, 4, 4, 'O');
      c.rect(30, 6, 2, 2, 'C');
      _pocketBox(c, 23, 9, 17, 15, 'X');
      _mechaVisor(c, 26, 13, 13, p, moving);
      c.rect(38, 17, 7, 4, 'O');
      c.rect(39, 18, 5, 2, 'D');

    case PixelGait.crab:
      for (var i = 0; i < 3; i++) {
        _pocketFoot(c, 14 + i * 3, 28, p + i * 0.8, moving, fill: 'D', width: 3);
        _pocketFoot(
          c,
          28 + i * 3,
          28,
          p + math.pi + i * 0.8,
          moving,
          fill: 'D',
          width: 3,
        );
      }
      c.rect(19, 9, 3, 6, 'O');
      c.rect(28, 9, 3, 6, 'O');
      c.rect(19, 8, 3, 2, 'C');
      c.rect(28, 8, 3, 2, 'C');
      _pocketBox(c, 13, 14, 24, 16, 'X');
      _mechaVisor(c, 16, 18, 18, p, moving);
      c.rect(6, 13 + bob, 6, 8, 'O');
      c.rect(7, 14 + bob, 4, 6, 'C');
      c.rect(39, 13 - bob, 6, 8, 'O');
      c.rect(40, 14 - bob, 4, 6, 'C');

    case PixelGait.axolotl:
      _pocketFoot(c, 19, 28, p, moving, fill: 'D', width: 5, stride: 1);
      _pocketFoot(c, 31, 28, p + math.pi, moving, fill: 'D', width: 5, stride: 1);
      for (int g = 0; g < 3; g++) {
        c.rect(14, 9 + g * 5, 5, 3, 'O');
        c.rect(15, 10 + g * 5, 3, 1, 'C');
        c.rect(38, 9 + g * 5, 5, 3, 'O');
        c.rect(39, 10 + g * 5, 3, 1, 'C');
      }
      _pocketBox(c, 18, 9, 21, 21, 'X');
      _mechaVisor(c, 21, 15, 16, p, moving);
      c.rect(23, 23, 11, 2, 'D');
  }
}

// ============================================================================
// V6 — Wind-up Toy (Clockwork brass key rotating on back, riveted toy blocks)
// ============================================================================

PixelSprite _windupSprite(PixelGait gait) {
  final Map<String, Color> palette = switch (gait) {
    PixelGait.clawd => const <String, Color>{
      'O': Color(0xFF3D251E),
      'X': Color(0xFFE86A4A),
      'S': Color(0xFFB8462E),
      'H': Color(0xFFFFA987),
      'E': Color(0xFF261510),
      'W': Color(0xFFFFF8EB),
      'N': Color(0xFFFFC857),
      'A': Color(0xFFF5B82E),
      'B': Color(0xFFFFE58F),
      'D': Color(0xFF9E6B1B),
    },
    PixelGait.miu => const <String, Color>{
      'O': Color(0xFF3B2820),
      'X': Color(0xFFF0B665),
      'S': Color(0xFFC4833B),
      'H': Color(0xFFFFDFAA),
      'E': Color(0xFF241711),
      'W': Color(0xFFFFF9EB),
      'N': Color(0xFFE86F68),
      'A': Color(0xFF4FA89B),
      'B': Color(0xFF9EE6D8),
      'D': Color(0xFF8C5A2B),
    },
    PixelGait.capy => const <String, Color>{
      'O': Color(0xFF38261B),
      'X': Color(0xFFC98E5B),
      'S': Color(0xFF996236),
      'H': Color(0xFFE8B98A),
      'E': Color(0xFF21150E),
      'W': Color(0xFFFFF4E0),
      'N': Color(0xFFE06D53),
      'A': Color(0xFFF2B632),
      'B': Color(0xFFFFE180),
      'D': Color(0xFF7A4924),
    },
    PixelGait.duck => const <String, Color>{
      'O': Color(0xFF3D2E17),
      'X': Color(0xFFF7CE46),
      'S': Color(0xFFCC9E22),
      'H': Color(0xFFFFEB99),
      'E': Color(0xFF241A0B),
      'W': Color(0xFFFFFBE8),
      'N': Color(0xFFE8684A),
      'A': Color(0xFFE87A33),
      'B': Color(0xFFFFC478),
      'C': Color(0xFFFFA84A),
      'D': Color(0xFF8F6518),
    },
    PixelGait.crab => const <String, Color>{
      'O': Color(0xFF421C22),
      'X': Color(0xFFE65555),
      'S': Color(0xFFB33236),
      'H': Color(0xFFFF9999),
      'E': Color(0xFF290F13),
      'W': Color(0xFFFFF2EB),
      'N': Color(0xFFFFB84D),
      'A': Color(0xFFF5C13B),
      'B': Color(0xFFFFE899),
      'D': Color(0xFF8F5E1E),
    },
    PixelGait.axolotl => const <String, Color>{
      'O': Color(0xFF402338),
      'X': Color(0xFFF29BC2),
      'S': Color(0xFFC46894),
      'H': Color(0xFFFFCCE3),
      'E': Color(0xFF291423),
      'W': Color(0xFFFFF5FA),
      'N': Color(0xFFFF6E87),
      'A': Color(0xFFF5C242),
      'B': Color(0xFFFFE89E),
      'C': Color(0xFFE6D4F5),
      'D': Color(0xFF8F6824),
    },
  };
  final frames = List<List<String>>.generate(17, (int frame) {
    final c = _SpriteCanvas(48, 36);
    final phase = frame == 0 ? 0.0 : (frame - 1) / 16 * math.pi * 2;
    _windupDraw(c, gait, phase, frame != 0);
    return c.finish();
  });
  return PixelSprite(
    frames: List.unmodifiable(frames),
    palette: Map.unmodifiable(palette),
    gait: gait,
    version: PixelSpriteVersion.v6,
    pixelRatio: 3,
  );
}

void _windupKey(_SpriteCanvas c, int x, int y, double p, bool moving) {
  c.rect(x - 4, y - 1, 5, 3, 'O');
  c.rect(x - 3, y, 4, 1, 'A');
  final int bowR = moving ? (math.cos(p).abs() * 3.5 + 1.2).round() : 4;
  c.ellipse((x - 6).toDouble(), (y - bowR).toDouble(), 3, bowR.toDouble(), 'O');
  c.ellipse(
    (x - 6).toDouble(),
    (y - bowR).toDouble(),
    2,
    math.max(1, bowR - 1).toDouble(),
    'B',
  );
  c.ellipse((x - 6).toDouble(), (y + bowR).toDouble(), 3, bowR.toDouble(), 'O');
  c.ellipse(
    (x - 6).toDouble(),
    (y + bowR).toDouble(),
    2,
    math.max(1, bowR - 1).toDouble(),
    'A',
  );
}

void _windupDraw(_SpriteCanvas c, PixelGait gait, double p, bool moving) {
  switch (gait) {
    case PixelGait.clawd:
      _windupKey(c, 13, 19, p, moving);
      _pocketClawd(c, p, moving);
      c.rect(15, 12, 2, 2, 'B');
      c.rect(33, 12, 2, 2, 'B');
    case PixelGait.miu:
      _windupKey(c, 16, 18, p, moving);
      _pocketMiu(c, p, moving);
      c.rect(25, 14, 2, 2, 'B');
    case PixelGait.capy:
      _windupKey(c, 11, 21, p, moving);
      _pocketCapy(c, p, moving);
      c.rect(12, 18, 2, 2, 'B');
      c.rect(25, 16, 2, 2, 'B');
    case PixelGait.duck:
      _windupKey(c, 15, 18, p, moving);
      _pocketDuck(c, p, moving);
      c.rect(26, 10, 2, 2, 'B');
    case PixelGait.crab:
      _windupKey(c, 24, 12, p, moving);
      _pocketCrab(c, p, moving);
      c.rect(15, 19, 2, 2, 'B');
      c.rect(32, 19, 2, 2, 'B');
    case PixelGait.axolotl:
      _windupKey(c, 15, 22, p, moving);
      _pocketAxo(c, p, moving);
      c.rect(24, 12, 2, 2, 'B');
  }
}

// ============================================================================
// V7 — Astral Ghost (Floating halo, wisp trail, stardust in matrix)
// ============================================================================

PixelSprite _astralSprite(PixelGait gait) {
  final Map<String, Color> palette = switch (gait) {
    PixelGait.clawd => const <String, Color>{
      'O': Color(0xFF281B4D),
      'X': Color(0xFF9378FF),
      'S': Color(0xFF6347D1),
      'H': Color(0xFFD0C2FF),
      'E': Color(0xFF160D30),
      'W': Color(0xFFFFFFFF),
      'N': Color(0xFFFF82C4),
      'A': Color(0xFF5CE1E6),
      'B': Color(0xFFFFE875),
      'C': Color(0xFFB8F2FF),
      'D': Color(0xFF472F85),
    },
    PixelGait.miu => const <String, Color>{
      'O': Color(0xFF1F2957),
      'X': Color(0xFF7AA2FF),
      'S': Color(0xFF4B6ED6),
      'H': Color(0xFFC4D9FF),
      'E': Color(0xFF101738),
      'W': Color(0xFFFFFFFF),
      'N': Color(0xFFFF8AB8),
      'A': Color(0xFFFFD166),
      'B': Color(0xFFFFF099),
      'C': Color(0xFFA8F0FF),
      'D': Color(0xFF344687),
    },
    PixelGait.capy => const <String, Color>{
      'O': Color(0xFF1B3B4B),
      'X': Color(0xFF5CD6D6),
      'S': Color(0xFF349EAB),
      'H': Color(0xFFB5F7F2),
      'E': Color(0xFF0E2430),
      'W': Color(0xFFFFFFFF),
      'N': Color(0xFFFF94B8),
      'A': Color(0xFFFFD166),
      'B': Color(0xFFFFF3B0),
      'C': Color(0xFFD6FFF9),
      'D': Color(0xFF265C70),
    },
    PixelGait.duck => const <String, Color>{
      'O': Color(0xFF3B234A),
      'X': Color(0xFFE580FF),
      'S': Color(0xFFB34ED4),
      'H': Color(0xFFF7C6FF),
      'E': Color(0xFF241130),
      'W': Color(0xFFFFFFFF),
      'N': Color(0xFFFF85A2),
      'A': Color(0xFFFFD152),
      'B': Color(0xFFFFEE99),
      'C': Color(0xFFFFB5E8),
      'D': Color(0xFF6B3887),
    },
    PixelGait.crab => const <String, Color>{
      'O': Color(0xFF421838),
      'X': Color(0xFFFF66B5),
      'S': Color(0xFFC93888),
      'H': Color(0xFFFFB5DC),
      'E': Color(0xFF290B22),
      'W': Color(0xFFFFFFFF),
      'N': Color(0xFFFFAE70),
      'A': Color(0xFF66F0FF),
      'B': Color(0xFFFFF08A),
      'C': Color(0xFFD4FAFF),
      'D': Color(0xFF782864),
    },
    PixelGait.axolotl => const <String, Color>{
      'O': Color(0xFF1F305E),
      'X': Color(0xFF8CD9FF),
      'S': Color(0xFF569ED6),
      'H': Color(0xFFD6F3FF),
      'E': Color(0xFF111C3B),
      'W': Color(0xFFFFFFFF),
      'N': Color(0xFFFF8CC6),
      'A': Color(0xFFC77DFF),
      'B': Color(0xFFFFEE99),
      'C': Color(0xFFE8FAFF),
      'D': Color(0xFF39559E),
    },
  };
  final frames = List<List<String>>.generate(17, (int frame) {
    final c = _SpriteCanvas(48, 36);
    final phase = frame == 0 ? 0.0 : (frame - 1) / 16 * math.pi * 2;
    _astralDraw(c, gait, phase, frame != 0);
    return c.finish();
  });
  return PixelSprite(
    frames: List.unmodifiable(frames),
    palette: Map.unmodifiable(palette),
    gait: gait,
    version: PixelSpriteVersion.v7,
    pixelRatio: 3,
  );
}

void _astralHalo(_SpriteCanvas c, int cx, int y, double p, bool moving) {
  final int swayX = _pocketSway(p, moving, 1);
  c.ellipse((cx + swayX).toDouble(), y.toDouble(), 6, 1.5, 'O');
  c.ellipse((cx + swayX).toDouble(), y.toDouble(), 5, 1.0, 'B');
  c.dot(cx + swayX - 3, y, 'W');
  c.dot(cx + swayX + 3, y, 'W');
}

void _astralStardust(_SpriteCanvas c, double p, bool moving) {
  if (!moving) {
    c.dot(7, 16, 'B');
    c.dot(9, 25, 'C');
    return;
  }
  for (int i = 0; i < 3; i++) {
    final double angle = p + i * 2.1;
    final int sx = 8 + (math.cos(angle) * 3).round();
    final int sy = 15 + i * 6 + (math.sin(angle) * 2).round();
    c.rect(sx, sy, 2, 2, i.isEven ? 'B' : 'C');
    c.dot(sx, sy, 'W');
  }
}

void _astralDraw(_SpriteCanvas c, PixelGait gait, double p, bool moving) {
  _astralStardust(c, p, moving);
  // Keep halo y >= 4 so minY >= 35 on 120x110 header test:
  switch (gait) {
    case PixelGait.clawd:
      _pocketClawd(c, p, moving);
      _astralHalo(c, 25, 4, p, moving);
    case PixelGait.miu:
      _pocketMiu(c, p, moving);
      _astralHalo(c, 31, 4, p, moving);
    case PixelGait.capy:
      _pocketCapy(c, p, moving);
      _astralHalo(c, 29, 4, p, moving);
    case PixelGait.duck:
      _pocketDuck(c, p, moving);
      _astralHalo(c, 31, 4, p, moving);
    case PixelGait.crab:
      _pocketCrab(c, p, moving);
      _astralHalo(c, 25, 5, p, moving);
    case PixelGait.axolotl:
      _pocketAxo(c, p, moving);
      _astralHalo(c, 30, 5, p, moving);
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

/// Pixel-art worlds available to [PixelWalker].
enum PixelWalkerScene {
  city,
  nightCity,
  forest,
  spaceStation,
  ancientRuins,
  cyberGrid,
}

/// Cảnh pixel-art neo đáy với mascot ở giữa và sáu thế giới dựng bằng code:
/// thành phố, thành phố đêm, rừng, trạm vũ trụ, di tích cổ và lưới synthwave.
/// [progress] 0→1 hiện dần cảnh; [walking] bật chu kỳ bước và parallax;
/// [scene] chọn thế giới, mặc định là [PixelWalkerScene.city].
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

  /// true = mascot bước tại chỗ và các layer nền trôi ngang. false = đứng yên,
  /// không ticker nào chạy (an toàn để giữ trong cây widget lâu dài).
  final bool walking;

  /// Thế giới nền; mặc định [PixelWalkerScene.city].
  final PixelWalkerScene scene;

  /// Mật độ chi tiết: 1.0 → ô dither 3px, ô mascot 6px / sprite.pixelRatio
  /// (V1: 6px; V2–V7: 2px). Tăng khi render vùng
  /// lớn (fullscreen ~1.5–2.0) để pixel không quá mịn, giảm khi nhét vào ô
  /// nhỏ. Đây là kích thước ô lưới, không phải scale transform.
  final double scale;

  /// Sprite thay thế; null → [PixelSprite.clawd] tô bằng [mascotColor].
  final PixelSprite? sprite;

  /// Màu mascot mặc định (chỉ dùng khi [sprite] null).
  final Color mascotColor;

  /// Màu các chấm của layer nền; mây dùng cùng màu ở opacity thấp hơn.
  final Color skylineColor;

  /// Màu chi tiết phát sáng như cửa sổ, đom đóm, beacon và rune.
  final Color windowColor;

  /// Màu sao, trăng và các điểm sáng trên nền không gian.
  final Color starColor;

  /// Nền vẽ dưới cảnh; mặc định trong suốt để đặt lên nền app.
  final Color backgroundColor;

  /// Nhân tốc độ bước đi và chuyển động parallax của nền.
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

  /// Đổi seed để sinh bố cục procedural khác (deterministic).
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
    final bool night = widget.scene != PixelWalkerScene.city;
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

    // Núi: ridge một chu kỳ 160 ô = max của 5 đỉnh tam giác,
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
    final double t = state._phase;

    final PixelSprite sprite = w.sprite ?? state._defaultSprite;
    final double spriteCell = cell * 2 / sprite.pixelRatio;
    final double spriteH = sprite.rowCount * spriteCell;
    final double spriteW = sprite.colCount * spriteCell;

    final double feetY = size.height - cell;
    // Chân trời: đáy skyline ngang tầm đầu mascot (như bản gốc).
    final double skylineBaseY = feetY - spriteH * 0.9 + (1 - eased) * 3 * cell;
    // Reserve a strip of sky even in the 110px refresh header. Compress the
    // number of skyline rows, not the pixel grid, to keep square dither dots.
    final double skyScale =
        ((skylineBaseY - 8 * cell) /
                ((w.scene != PixelWalkerScene.city ? 24 : 17) * cell))
            .clamp(0.12, 1.0);

    switch (w.scene) {
      case PixelWalkerScene.city:
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
      case PixelWalkerScene.nightCity:
        _paintStars(canvas, size, w, cell, skylineBaseY, eased);
        _paintMoon(canvas, size, w, cell, skylineBaseY, eased);
        _paintMountains(
          canvas,
          size,
          w,
          cell,
          t,
          skylineBaseY,
          eased,
          skyScale,
        );
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
      case PixelWalkerScene.forest:
        _paintStars(canvas, size, w, cell, skylineBaseY, eased);
        _paintMountains(
          canvas,
          size,
          w,
          cell,
          t,
          skylineBaseY,
          eased,
          skyScale,
        );
        _paintForestScene(
          canvas,
          size,
          w,
          cell,
          t,
          skylineBaseY,
          eased,
          skyScale,
        );
      case PixelWalkerScene.spaceStation:
        _paintStars(canvas, size, w, cell, skylineBaseY, eased);
        _paintRingedPlanet(canvas, size, w, cell, skylineBaseY, eased);
        _paintSpaceStationScene(
          canvas,
          size,
          w,
          cell,
          t,
          skylineBaseY,
          eased,
          skyScale,
        );
      case PixelWalkerScene.ancientRuins:
        _paintStars(canvas, size, w, cell, skylineBaseY, eased);
        _paintTwinMoons(canvas, size, w, cell, skylineBaseY, eased);
        _paintMountains(
          canvas,
          size,
          w,
          cell,
          t,
          skylineBaseY,
          eased,
          skyScale,
        );
        _paintAncientRuinsScene(
          canvas,
          size,
          w,
          cell,
          t,
          skylineBaseY,
          eased,
          skyScale,
        );
      case PixelWalkerScene.cyberGrid:
        _paintSynthSun(canvas, size, w, cell, skylineBaseY, eased);
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
        _paintCyberGridFloor(
          canvas,
          size,
          w,
          cell,
          t,
          skylineBaseY,
          feetY,
          eased,
        );
      // Đêm: sao/trăng tĩnh sau cùng, rồi núi (parallax chậm nhất), mây, và
      // toà nhà vẽ SAU mây để tháp cao che mây → có chiều sâu.
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
        // Điểm sáng nằm trong thân công trình (không dính mép
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

  void _paintForestScene(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double t,
    double baseY,
    double eased,
    double skyScale,
  ) {
    final _PointSink trees = state._skySink..clear();
    final _PointSink fireflies = state._windowSink..clear();
    final double scroll = t * 7.5;
    final int first = scroll.floor();
    final double frac = scroll - first;
    final int cols = (size.width / cell).ceil() + 1;

    for (int i = 0; i <= cols; i++) {
      final int wx = first + i;
      final double sx = (i - frac) * cell + cell / 2;
      final int treeSlot = wx % 14;
      final int treeIdx = wx ~/ 14;
      final int treeH =
          ((10 + (_hash(treeIdx, 0, w.seed ^ 0x71e3) * 12).round()) * skyScale)
              .round();
      final int halfSpan = (treeSlot - 7).abs();
      for (int y = 0; y < treeH; y++) {
        final double py = baseY - y * cell - cell / 2;
        if (py < 0) break;
        final double maxRadius = (1.0 - y / math.max(1, treeH)) * 6.0 + 1.0;
        final bool isTrunk = y < 3 && halfSpan <= 1;
        if (isTrunk || halfSpan <= maxRadius) {
          final double density = isTrunk ? 0.85 : (0.72 - halfSpan * 0.08);
          if (_hash(wx, y, w.seed ^ 0x4f12) < density * eased) {
            trees.add(sx, py);
          }
        }
      }
      if (_hash(wx, 3, w.seed ^ 0xf12e) < 0.09 * eased) {
        final double fy =
            baseY -
            (3 +
                    (_hash(wx, 9, w.seed) * 14) +
                    math.sin(t * 2.5 + wx * 0.7) * 2.5) *
                cell;
        if (fy > 0) fireflies.add(sx, fy);
      }
    }
    if (trees.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.skylineColor.withValues(alpha: w.skylineColor.a * eased);
      canvas.drawRawPoints(ui.PointMode.points, trees.view, _dotPaint);
    }
    if (fireflies.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.windowColor.withValues(alpha: w.windowColor.a * eased);
      canvas.drawRawPoints(ui.PointMode.points, fireflies.view, _dotPaint);
    }
  }

  void _paintRingedPlanet(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double baseY,
    double eased,
  ) {
    final _PointSink sink = state._fxSink..clear();
    final double cx = (size.width * 0.76 / cell).floor() * cell + cell / 2;
    final double cy =
        (math.max(6 * cell, baseY - 20 * cell) / cell).floor() * cell +
        cell / 2;
    for (int dy = -6; dy <= 6; dy++) {
      for (int dx = -10; dx <= 10; dx++) {
        final double d2 = (dx * dx + dy * dy).toDouble();
        final double ring =
            (dx * 0.45) * (dx * 0.45) + (dy + dx * 0.25) * (dy + dx * 0.25);
        final bool onPlanet = d2 <= 16.0;
        final bool onRing = ring >= 5.5 && ring <= 11.5;
        if ((onPlanet || onRing) &&
            _hash(dx + 16, dy + 16, w.seed ^ 0x91a2) <
                (onRing ? 0.75 : 0.88) * eased) {
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

  void _paintSpaceStationScene(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double t,
    double baseY,
    double eased,
    double skyScale,
  ) {
    final _PointSink domes = state._skySink..clear();
    final _PointSink beacons = state._windowSink..clear();
    final double scroll = t * 8.5;
    final int first = scroll.floor();
    final double frac = scroll - first;
    final int cols = (size.width / cell).ceil() + 1;

    for (int i = 0; i <= cols; i++) {
      final int wx = first + i;
      final double sx = (i - frac) * cell + cell / 2;
      final int mod = wx % 22;
      final int domeH = (14 * skyScale).round();
      for (int y = 0; y < domeH + 5; y++) {
        final double py = baseY - y * cell - cell / 2;
        if (py < 0) break;
        final double dx = (mod - 9).toDouble();
        final bool inDome =
            mod <= 18 &&
            (dx * dx) / 64.0 + (y * y) / math.max(1.0, domeH * domeH) <= 1.0;
        final bool inSpire = mod == 9 && y < domeH + 4;
        if (inSpire && y == domeH + 3) {
          beacons.add(sx, py);
          continue;
        }
        if (inDome || inSpire) {
          if (y == 3 && mod % 3 == 0) {
            beacons.add(sx, py);
          } else if (_hash(wx, y, w.seed ^ 0x55c1) < 0.75 * eased) {
            domes.add(sx, py);
          }
        }
      }
    }
    if (domes.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.skylineColor.withValues(alpha: w.skylineColor.a * eased);
      canvas.drawRawPoints(ui.PointMode.points, domes.view, _dotPaint);
    }
    if (beacons.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.windowColor.withValues(alpha: w.windowColor.a * eased);
      canvas.drawRawPoints(ui.PointMode.points, beacons.view, _dotPaint);
    }
  }

  void _paintTwinMoons(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double baseY,
    double eased,
  ) {
    _paintMoon(canvas, size, w, cell, baseY, eased);
    final _PointSink sink = state._fxSink..clear();
    final double cx = (size.width * 0.68 / cell).floor() * cell + cell / 2;
    final double cy =
        (math.max(4 * cell, baseY - 16 * cell) / cell).floor() * cell +
        cell / 2;
    for (int dy = -2; dy <= 2; dy++) {
      for (int dx = -2; dx <= 2; dx++) {
        if (dx * dx + dy * dy <= 5) {
          sink.add(cx + dx * cell, cy + dy * cell);
        }
      }
    }
    if (sink.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.windowColor.withValues(
          alpha: w.windowColor.a * eased * 0.75,
        );
      canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
    }
  }

  void _paintAncientRuinsScene(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double t,
    double baseY,
    double eased,
    double skyScale,
  ) {
    final _PointSink stones = state._skySink..clear();
    final _PointSink runes = state._windowSink..clear();
    final double scroll = t * 7.0;
    final int first = scroll.floor();
    final double frac = scroll - first;
    final int cols = (size.width / cell).ceil() + 1;

    for (int i = 0; i <= cols; i++) {
      final int wx = first + i;
      final double sx = (i - frac) * cell + cell / 2;
      final int slot = wx % 28;
      final int maxH = (16 * skyScale).round();
      for (int y = 0; y < maxH; y++) {
        final double py = baseY - y * cell - cell / 2;
        if (py < 0) break;
        final int stepIndent = (y * 2) ~/ 3;
        final bool inPyramid =
            slot >= 2 + stepIndent && slot <= 18 - stepIndent;
        final bool inPillar =
            (slot == 22 || slot == 25) && y < (maxH * 0.65).round();
        if (inPyramid || inPillar) {
          if (slot == 10 && y > 2 && y < maxH - 3 && y.isEven) {
            runes.add(sx, py);
          } else if (_hash(wx, y, w.seed ^ 0x88b4) < 0.78 * eased) {
            stones.add(sx, py);
          }
        }
      }
    }
    if (stones.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.skylineColor.withValues(alpha: w.skylineColor.a * eased);
      canvas.drawRawPoints(ui.PointMode.points, stones.view, _dotPaint);
    }
    if (runes.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.windowColor.withValues(alpha: w.windowColor.a * eased);
      canvas.drawRawPoints(ui.PointMode.points, runes.view, _dotPaint);
    }
  }

  void _paintSynthSun(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double baseY,
    double eased,
  ) {
    final _PointSink sink = state._fxSink..clear();
    final double cx = (size.width * 0.5 / cell).floor() * cell + cell / 2;
    final double cy = baseY - 8 * cell;
    for (int dy = -9; dy <= 7; dy++) {
      if (dy > 0 && dy.isOdd) continue;
      for (int dx = -9; dx <= 9; dx++) {
        if (dx * dx + dy * dy <= 81 &&
            _hash(dx + 12, dy + 12, w.seed ^ 0x77c9) < 0.85 * eased) {
          sink.add(cx + dx * cell, cy + dy * cell);
        }
      }
    }
    if (sink.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.windowColor.withValues(
          alpha: w.windowColor.a * eased * 0.75,
        );
      canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
    }
  }

  void _paintCyberGridFloor(
    Canvas canvas,
    Size size,
    PixelWalker w,
    double cell,
    double t,
    double baseY,
    double feetY,
    double eased,
  ) {
    final _PointSink sink = state._fxSink..clear();
    final int cols = (size.width / cell).ceil();
    final double scroll = t * 9.0;
    for (int cx = 0; cx <= cols; cx++) {
      final double sx = cx * cell + cell / 2;
      sink.add(sx, baseY);
      if (((cx + scroll.floor()) % 6) == 0) {
        for (double py = baseY + cell; py <= feetY; py += cell * 1.5) {
          sink.add(sx, py);
        }
      }
    }
    if (sink.isNotEmpty) {
      _dotPaint
        ..strokeWidth = cell
        ..color = w.starColor.withValues(alpha: w.starColor.a * eased * 0.45);
      canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
    }
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
