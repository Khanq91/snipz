/// PixelWalker
/// Origin: reimplemented — dựng lại cảnh pull-to-refresh của app Claude Code
/// mobile (mascot pixel đi qua skyline thành phố dither) từ video demo.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Sprite pixel-art dạng ma trận ký tự: mỗi frame là một list dòng, mỗi ký tự
/// tra màu trong [palette]; `.` (hoặc ký tự không có trong palette) là trong
/// suốt. Mọi dòng trong một frame phải dài bằng nhau, mọi frame cùng kích cỡ.
///
/// Frame 0 là pose đứng yên; các frame còn lại là chu kỳ bước đi. Frame lẻ
/// được nghiêng nhẹ + nhấc người (bob) khi đi bộ.
class PixelSprite {
  const PixelSprite({required this.frames, required this.palette})
    : assert(frames.length > 0);

  /// Mascot mặc định: con bọ cam kiểu Clawd — thân vuông bo, 2 hốc mắt,
  /// 3 cặp chân, 2 frame bước.
  factory PixelSprite.clawd({Color color = const Color(0xFFE8875C)}) {
    return PixelSprite(frames: _clawdFrames, palette: <String, Color>{'X': color});
  }

  final List<List<String>> frames;
  final Map<String, Color> palette;

  int get rowCount => frames.first.length;
  int get colCount => frames.first.first.length;
}

const List<String> _clawdStand = <String>[
  '..XXXXXXXX..',
  '.XXXXXXXXXX.',
  'XXXXXXXXXXXX',
  'XXX..XX..XXX',
  'XXX..XX..XXX',
  'XXXXXXXXXXXX',
  'XXXXXXXXXXXX',
  '.XXXXXXXXXX.',
  '..XX.XX.XX..',
  '..XX.XX.XX..',
];

const List<List<String>> _clawdFrames = <List<String>>[
  _clawdStand,
  <String>[
    '..XXXXXXXX..',
    '.XXXXXXXXXX.',
    'XXXXXXXXXXXX',
    'XXX..XX..XXX',
    'XXX..XX..XXX',
    'XXXXXXXXXXXX',
    'XXXXXXXXXXXX',
    '.XXXXXXXXXX.',
    '.XX...XX.XX.',
    'XX....XX..XX',
  ],
  _clawdStand,
  <String>[
    '..XXXXXXXX..',
    '.XXXXXXXXXX.',
    'XXXXXXXXXXXX',
    'XXX..XX..XXX',
    'XXX..XX..XXX',
    'XXXXXXXXXXXX',
    'XXXXXXXXXXXX',
    '.XXXXXXXXXX.',
    '.XX.XX...XX.',
    'XX..XX....XX',
  ],
];

/// Cảnh pixel-art neo đáy: mascot đứng giữa, skyline thành phố + mây vẽ bằng
/// dither procedural. [progress] 0→1 hiện dần cảnh (mascot trồi lên từ mép
/// dưới, dither dày dần); [walking] bật chu kỳ bước đi + skyline/mây trôi
/// ngang (parallax). Sinh ra cho vùng header pull-to-refresh nhưng dùng được
/// làm empty-state/loading bất kỳ.
///
/// Không expose factory `Shader`: cảnh nhiều layer + sprite animation không
/// biểu diễn được bằng một `ui.Gradient`/`ImageShader` (xem README Caveats).
class PixelWalker extends StatefulWidget {
  const PixelWalker({
    super.key,
    this.progress = 1.0,
    this.walking = false,
    this.scale = 1.0,
    this.sprite,
    this.mascotColor = const Color(0xFFE8875C),
    this.skylineColor = const Color(0xFFB9B4AE),
    this.backgroundColor = Colors.transparent,
    this.speed = 1.0,
    this.seed = 7,
  });

  /// 0 = ẩn hoàn toàn, 1 = hiện đủ. Điều khiển từ ngoài (ví dụ theo độ kéo).
  final double progress;

  /// true = mascot bước tại chỗ, skyline + mây trôi ngang. false = đứng yên,
  /// không ticker nào chạy (an toàn để giữ trong cây widget lâu dài).
  final bool walking;

  /// Mật độ chi tiết: 1.0 → ô dither 3px, ô mascot 6px. Tăng khi render vùng
  /// lớn (fullscreen ~1.5–2.0) để pixel không quá mịn, giảm khi nhét vào ô
  /// nhỏ. Đây là kích thước ô lưới, không phải scale transform.
  final double scale;

  /// Sprite thay thế; null → [PixelSprite.clawd] tô bằng [mascotColor].
  final PixelSprite? sprite;

  /// Màu mascot mặc định (chỉ dùng khi [sprite] null).
  final Color mascotColor;

  /// Màu dither của skyline; mây dùng cùng màu ở opacity thấp hơn.
  final Color skylineColor;

  /// Nền vẽ dưới cảnh; mặc định trong suốt để đặt lên nền app.
  final Color backgroundColor;

  /// Nhân tốc độ bước đi + trôi skyline.
  final double speed;

  /// Đổi seed để được skyline/mây bố cục khác (deterministic).
  final int seed;

  @override
  State<PixelWalker> createState() => _PixelWalkerState();
}

class _PixelWalkerState extends State<PixelWalker>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _RepaintTrigger _repaint = _RepaintTrigger();

  // Thời gian animation tích lũy qua các lần start/stop ticker.
  double _timeSec = 0;
  double _timeBase = 0;

  // Bố cục skyline/mây cho một chu kỳ, sinh từ seed.
  late Int16List _heights;
  late Int16List _antennae;
  late List<_CloudSpec> _clouds;
  int _period = 1;

  // Buffer điểm tái dùng giữa các frame (không cấp phát trong paint).
  final _PointSink _skySink = _PointSink();
  final _PointSink _cloudSink = _PointSink();
  final _PointSink _spriteSink = _PointSink();

  @override
  void initState() {
    super.initState();
    _rebuildLayout();
    if (widget.walking) _ticker.start();
  }

  @override
  void didUpdateWidget(PixelWalker old) {
    super.didUpdateWidget(old);
    if (widget.seed != old.seed) _rebuildLayout();
    if (widget.walking != old.walking) {
      if (widget.walking) {
        _ticker.start();
      } else {
        _timeBase = _timeSec;
        _ticker.stop();
      }
    }
    _repaint.bump();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _timeSec = _timeBase + elapsed.inMicroseconds / 1e6;
    _repaint.bump();
  }

  void _rebuildLayout() {
    int r = (widget.seed * 2654435761) & 0x7fffffff;
    int next(int lo, int hi) {
      r = (r * 1103515245 + 12345) & 0x7fffffff;
      return lo + r % (hi - lo + 1);
    }

    // Skyline: dựng cột chiều cao cho một chu kỳ ~96 ô.
    final List<int> heights = <int>[];
    final List<int> antennae = <int>[];
    while (heights.length < 96) {
      final int gap = next(3, 9);
      final int width = next(6, 16);
      final int height = next(4, 13);
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

  Float32List get view => Float32List.sublistView(_buf, 0, _len);
}

class _PixelWalkerPainter extends CustomPainter {
  _PixelWalkerPainter(this.state) : super(repaint: state._repaint);

  final _PixelWalkerState state;

  static final Paint _dotPaint = Paint()
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
    final double t = state._timeSec * w.speed;

    final PixelSprite sprite =
        w.sprite ?? PixelSprite.clawd(color: w.mascotColor);
    final double spriteH = sprite.rowCount * spriteCell;
    final double spriteW = sprite.colCount * spriteCell;

    final double feetY = size.height - cell;
    // Chân trời: đáy skyline ngang tầm đầu mascot (như bản gốc).
    final double skylineBaseY = feetY - spriteH * 0.9 + (1 - eased) * 3 * cell;

    _paintSkyline(canvas, size, w, cell, t, skylineBaseY, eased);
    _paintClouds(canvas, size, w, cell, t, skylineBaseY, eased);
    _paintSprite(canvas, size, sprite, spriteCell, spriteW, spriteH, feetY, t,
        w.walking, eased);
  }

  void _paintSkyline(Canvas canvas, Size size, PixelWalker w, double cell,
      double t, double baseY, double eased) {
    final _PointSink sink = state._skySink..clear();
    final double scroll = t * 9.0;
    final int first = scroll.floor();
    final double frac = scroll - first;
    final int cols = (size.width / cell).ceil() + 1;

    for (int i = 0; i <= cols; i++) {
      final int wx = first + i;
      final double sx = (i - frac) * cell + cell / 2;
      final int pi = wx % state._period;
      final int h = state._heights[pi];
      if (h == 0) continue;
      final int extra = state._antennae[pi];
      for (int y = 0; y < h + extra; y++) {
        final double py = baseY - y * cell - cell / 2;
        if (py < 0) break;
        final double density = y >= h
            ? 0.30
            : y >= h - 2
                ? 0.38
                : 0.62;
        if (_hash(wx, y, w.seed) < density * eased) sink.add(sx, py);
      }
    }
    if (sink.isEmpty) return;
    _dotPaint
      ..strokeWidth = cell
      ..color = w.skylineColor.withValues(alpha: w.skylineColor.a * eased);
    canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
  }

  void _paintClouds(Canvas canvas, Size size, PixelWalker w, double cell,
      double t, double baseY, double eased) {
    final _PointSink sink = state._cloudSink..clear();
    const int periodCells = 160;
    final double scroll = t * 3.0;
    // Đỉnh cao nhất skyline có thể chạm 13 + antenna 4 ô — mây bay trên đó.
    final double cloudBandY = baseY - 19 * cell;

    for (final _CloudSpec c in state._clouds) {
      double pos = (c.start - scroll) % periodCells;
      if (pos < 0) pos += periodCells;
      // Vẽ cả bản wrap trước đó để mây đi vào từ mép phải liền mạch.
      for (final double base in <double>[pos, pos - periodCells]) {
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
      ..color = w.skylineColor.withValues(alpha: w.skylineColor.a * eased * 0.55);
    canvas.drawRawPoints(ui.PointMode.points, sink.view, _dotPaint);
  }

  void _paintSprite(Canvas canvas, Size size, PixelSprite sprite,
      double spriteCell, double spriteW, double spriteH, double feetY,
      double t, bool walking, double eased) {
    final int frameCount = sprite.frames.length;
    final int fi = walking && frameCount > 1 ? (t * 7).floor() % frameCount : 0;
    final List<String> frame = sprite.frames[fi];
    final double lean = walking && fi.isOdd
        ? (fi % 4 == 1 ? 0.09 : -0.09)
        : 0.0;
    final double bob = walking && fi.isOdd ? -spriteCell * 0.35 : 0.0;
    final double rise = (1 - eased) * (spriteH + spriteCell);

    canvas.save();
    canvas.translate(size.width / 2, feetY + rise + bob);
    if (lean != 0) canvas.rotate(lean);

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
