/// ClaudeThinking
/// Origin: reimplemented — "claude-thinking" của brainless (theswerd/brainless,
/// CSS background-clip shimmer → ShaderMask + ui.Gradient.linear), rút gọn
/// còn phần thinking: glyph nhấp nháy + verb shimmer. Bỏ đồng hồ giây, token
/// count và hint "esc to interrupt".
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Cách render glyph nhấp nháy. [text] dùng đúng ký tự Dingbats của capture
/// gốc (cần font hệ thống có block U+2700); [painted] vẽ lại các frame bằng
/// CustomPainter — không bao giờ tofu, dùng khi máy đích thiếu glyph.
enum ClaudeThinkingGlyphStyle { text, painted }

/// Chu kỳ glyph capture từ claude/thinking frames: · ✢ ✳ ✶ ✻ ✽ ✻ ✶ ✳ ✢
const List<String> _glyphCycle = <String>[
  '·', '✢', '✳', '✶', '✻', '✽', '✻', '✶', '✳', '✢',
];

/// Bản render text của chu kỳ trên. ✳ (U+2733) có emoji presentation — không
/// có U+FE0E (text variation selector) thì Android lấy nó từ NotoColorEmoji:
/// sao XANH LÁ to gấp rưỡi các frame khác, làm dòng chữ giật theo chu kỳ.
/// Chỉ ✳ cần selector; các glyph còn lại không có bản emoji.
const List<String> _glyphCycleText = <String>[
  '·', '✢', '✳︎', '✶', '✻', '✽', '✻', '✶', '✳︎', '✢',
];

/// Frame đứng yên khi reduced-motion / animate=false (bản gốc dùng ✳).
const int _staticFrame = 2;

const List<String> _defaultVerbs = <String>[
  'Thinking',
  'Levitating',
  'Schlepping',
  'Herding',
  'Percolating',
  'Noodling',
  'Conjuring',
];

/// Shader shimmer như CSS gốc: `linear-gradient(100deg, base 43%, highlight
/// 50%, base 57%)`, background-size 200%, position chạy 100% → -100%. Ảnh
/// gradient rộng 2× [bounds], highlight quét qua chữ ở nửa đầu chu kỳ rồi
/// nghỉ ở nửa sau (đúng nhịp bản gốc). Góc 100deg gần như ngang nên vẽ ngang
/// cho một dòng chữ — không phân biệt được bằng mắt.
ui.Shader createClaudeShimmerShader(
  ui.Rect bounds, {
  ui.Color base = const ui.Color(0xFFCD694A),
  ui.Color highlight = const ui.Color(0xFFE79475),
  double progress = 0,
}) {
  final double w = math.max(bounds.width, 1);
  // background-position 100% → -100% ⇔ offset ảnh -w → +w.
  final double dx = -w + 2 * w * (progress % 1);
  final Float64List matrix = Float64List(16)
    ..[0] = 1
    ..[5] = 1
    ..[10] = 1
    ..[15] = 1
    ..[12] = dx;
  return ui.Gradient.linear(
    bounds.centerLeft,
    bounds.centerLeft + ui.Offset(2 * w, 0),
    <ui.Color>[base, highlight, base],
    <double>[0.43, 0.50, 0.57],
    ui.TileMode.repeated,
    matrix,
  );
}

/// Dòng "đang làm việc" của Claude Code: glyph asterisk nhấp nháy + một verb
/// ngẫu hứng ("Thinking…", "Noodling…") màu terracotta với vệt sáng shimmer
/// trượt ngang. Tôn trọng reduced-motion (đứng yên ở ✳, verb màu đặc).
class ClaudeThinking extends StatefulWidget {
  const ClaudeThinking({
    super.key,
    this.running = true,
    this.verbs = _defaultVerbs,
    this.baseColor = const ui.Color(0xFFCD694A),
    this.highlightColor = const ui.Color(0xFFE79475),
    this.fontSize = 13,
    this.fontFamily = 'monospace',
    this.glyphStyle = ClaudeThinkingGlyphStyle.text,
    this.animate = true,
    this.glyphInterval = const Duration(milliseconds: 110),
    this.verbInterval = const Duration(milliseconds: 5200),
    this.shimmerPeriod = const Duration(milliseconds: 2800),
    this.typeEffect = true,
    this.typeCharInterval = const Duration(milliseconds: 55),
  });

  /// `false` render rỗng — như bản gốc return null khi không chạy.
  final bool running;

  /// Danh sách verb xoay vòng. Một phần tử = một chữ cố định.
  final List<String> verbs;

  /// Terracotta của Claude — màu chữ và màu glyph.
  final ui.Color baseColor;

  /// Màu vệt sáng shimmer quét qua chữ.
  final ui.Color highlightColor;

  final double fontSize;

  /// Font chữ; default monospace hệ thống cho đúng chất terminal.
  final String fontFamily;

  /// [ClaudeThinkingGlyphStyle.painted] khi font máy đích thiếu Dingbats.
  final ClaudeThinkingGlyphStyle glyphStyle;

  /// Công tắc đóng băng (thumbnail/screenshot): `false` dừng ticker, glyph
  /// đứng ở ✳, verb đầu tiên màu đặc — deterministic.
  final bool animate;

  /// Nhịp đổi glyph (bản gốc 110ms).
  final Duration glyphInterval;

  /// Nhịp đổi verb (bản gốc 5.2s — đổi chậm, như thật).
  final Duration verbInterval;

  /// Chu kỳ một lượt shimmer (bản gốc 2.8s).
  final Duration shimmerPeriod;

  /// Verb mới gõ ra từng ký tự trái → phải (một chiều, không xoá lùi) mỗi
  /// khi đổi verb — kiểu text-type. `false` = swap tức thì như CLI thật.
  final bool typeEffect;

  /// Nhịp gõ mỗi ký tự của [typeEffect].
  final Duration typeCharInterval;

  @override
  State<ClaudeThinking> createState() => _ClaudeThinkingState();
}

class _ClaudeThinkingState extends State<ClaudeThinking>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _elapsed = ValueNotifier<double>(0);
  double _timeBase = 0;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    _elapsed.value = _timeBase + elapsed.inMicroseconds / 1e6;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(ClaudeThinking oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    final bool shouldRun = widget.running && widget.animate && !_reducedMotion;
    if (shouldRun && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _timeBase = _elapsed.value;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.running) {
      return const SizedBox.shrink();
    }
    final bool still = !widget.animate || _reducedMotion;
    return ValueListenableBuilder<double>(
      valueListenable: _elapsed,
      builder: (context, elapsed, _) {
        final int glyphFrame = still
            ? _staticFrame
            : (elapsed * 1000 / widget.glyphInterval.inMilliseconds).floor() %
                _glyphCycle.length;
        final int verbIdx = still || widget.verbs.length <= 1
            ? 0
            : (elapsed * 1000 / widget.verbInterval.inMilliseconds).floor() %
                widget.verbs.length;
        final double shimmer = still
            ? 0
            : (elapsed * 1000 % widget.shimmerPeriod.inMilliseconds) /
                widget.shimmerPeriod.inMilliseconds;

        final TextStyle style = TextStyle(
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize,
          height: 1.4,
          color: widget.baseColor,
        );

        final String verb =
            widget.verbs.isEmpty ? '' : widget.verbs[verbIdx];
        final String full = '$verb…';
        String shown = full;
        if (!still && widget.typeEffect) {
          // one-way typewriter: chars revealed is a pure function of the
          // time into this verb's cycle (single verb: since mount) — no
          // accumulated state, frozen frames stay deterministic
          final double ms = elapsed * 1000;
          final double cycleMs =
              widget.verbInterval.inMilliseconds.toDouble();
          final double sinceStart = widget.verbs.length <= 1
              ? ms
              : ms - (ms / cycleMs).floorToDouble() * cycleMs;
          final int chars = widget.typeCharInterval.inMilliseconds <= 0
              ? full.characters.length
              : sinceStart ~/ widget.typeCharInterval.inMilliseconds;
          shown = full.characters.take(chars).toString();
        }
        final Widget verbText = Text(shown, style: style);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Ô glyph bề rộng cố định (≈1ch) để dòng không xê dịch khi frame
            // đổi — kể cả khi font fallback không phải monospace.
            SizedBox(
              width: widget.fontSize * 0.75,
              height: widget.fontSize * 1.4,
              child: widget.glyphStyle == ClaudeThinkingGlyphStyle.painted
                  ? CustomPaint(
                      painter: _GlyphPainter(
                        frame: glyphFrame,
                        color: widget.baseColor,
                      ),
                    )
                  : Center(
                      child: Text(_glyphCycleText[glyphFrame], style: style),
                    ),
            ),
            const SizedBox(width: 8),
            if (still)
              verbText
            else
              ShaderMask(
                blendMode: ui.BlendMode.srcIn,
                shaderCallback: (bounds) => createClaudeShimmerShader(
                  bounds,
                  base: widget.baseColor,
                  highlight: widget.highlightColor,
                  progress: shimmer,
                ),
                child: verbText,
              ),
          ],
        );
      },
    );
  }
}

/// Vẽ lại 6 frame Dingbats (· ✢ ✳ ✶ ✻ ✽) bằng canvas: chấm tròn, asterisk
/// 4/6/8 cánh (capsule bo tròn) và sao 6 cánh đặc. Ở cỡ 13px các bản vẽ này
/// gần như trùng khít glyph thật — dùng khi font máy đích thiếu block U+2700.
class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.frame, required this.color});

  /// Index trong chu kỳ [_glyphCycle].
  final int frame;
  final ui.Color color;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final ui.Offset c = size.center(ui.Offset.zero);
    final double s = size.shortestSide;
    final String glyph = _glyphCycle[frame % _glyphCycle.length];
    final ui.Paint fill = ui.Paint()..color = color;

    switch (glyph) {
      case '·':
        canvas.drawCircle(c, s * 0.10, fill);
      case '✢':
        _spokes(canvas, c, count: 4, radius: s * 0.42, width: s * 0.16,
            color: color);
      case '✳':
        _spokes(canvas, c, count: 8, radius: s * 0.44, width: s * 0.11,
            color: color);
      case '✶':
        _star6(canvas, c, outer: s * 0.46, inner: s * 0.20, paint: fill);
      case '✻':
        _spokes(canvas, c, count: 6, radius: s * 0.44, width: s * 0.14,
            color: color);
      case '✽':
        _spokes(canvas, c, count: 6, radius: s * 0.46, width: s * 0.20,
            color: color);
    }
  }

  /// Asterisk [count] cánh: các capsule tròn đầu tỏa từ tâm — xấp xỉ dạng
  /// teardrop-spoked của Dingbats ở cỡ chữ nhỏ.
  void _spokes(
    ui.Canvas canvas,
    ui.Offset c, {
    required int count,
    required double radius,
    required double width,
    required ui.Color color,
  }) {
    final ui.Paint p = ui.Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = ui.StrokeCap.round;
    // Cánh đầu hướng thẳng lên, như glyph thật.
    for (int i = 0; i < count; i++) {
      final double a = -math.pi / 2 + i * 2 * math.pi / count;
      final ui.Offset dir = ui.Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * width * 0.4, c + dir * radius, p);
    }
  }

  void _star6(
    ui.Canvas canvas,
    ui.Offset c, {
    required double outer,
    required double inner,
    required ui.Paint paint,
  }) {
    final ui.Path path = ui.Path();
    for (int i = 0; i < 12; i++) {
      final double r = i.isEven ? outer : inner;
      final double a = -math.pi / 2 + i * math.pi / 6;
      final ui.Offset v = c + ui.Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(v.dx, v.dy);
      } else {
        path.lineTo(v.dx, v.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.color != color;
}
