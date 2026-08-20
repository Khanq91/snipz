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
    return PixelSprite(
      frames: _clawdFrames,
      palette: <String, Color>{'X': color},
    );
  }

  /// Mascot mèo "Miu" (tự chế): nhìn nghiêng bước sang phải, tai nhọn, mắt
  /// khe dọc, sọc lưng + chóp đuôi màu [stripe], đuôi vẫy theo nhịp bước —
  /// 4 frame (đứng / sải chân / đứng / thu chân).
  factory PixelSprite.miu({
    Color body = const Color(0xFFEBD3A0),
    Color stripe = const Color(0xFFC9884A),
  }) {
    return PixelSprite(
      frames: _miuFrames,
      palette: <String, Color>{'X': body, 'S': stripe},
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
      palette: <String, Color>{'X': body, 'S': dark, 'E': eye},
    );
  }

  /// Mascot vịt "Quạc": đầu tròn nhô trước, mỏ bè 2 ô, thân bầu đuôi hất,
  /// chân mảnh bàn bè — frame lẻ đuôi hất lên + chân sải, cộng tilt/bob của
  /// painter thành dáng lạch bạch. [beak] tô mỏ + chân.
  factory PixelSprite.duck({
    Color body = const Color(0xFFF2DE96),
    Color beak = const Color(0xFFE8963F),
    Color eye = const Color(0xFF241A12),
  }) {
    return PixelSprite(
      frames: _duckFrames,
      palette: <String, Color>{'X': body, 'B': beak, 'E': eye},
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
      palette: <String, Color>{'X': body, 'W': eyeWhite, 'E': eye},
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
      palette: <String, Color>{'X': body, 'S': accent, 'E': eye},
    );
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

const List<String> _miuStand = <String>[
  '..........X....X',
  '..........XX..XX',
  '..S.......XXXXXX',
  '.X........XXX.XX',
  '.X........XXX.XX',
  '.XXXSXSXSXXXXXXX',
  '..XXSXSXSXXXXXXX',
  '..XXXXXXXXXX....',
  '..XXXXXXXXXX....',
  '...XX....XX.....',
  '...XX....XX.....',
];

const List<List<String>> _miuFrames = <List<String>>[
  _miuStand,
  <String>[
    '..........X....X',
    '..........XX..XX',
    'S.........XXXXXX',
    '.X........XXX.XX',
    '.X........XXX.XX',
    '.XXXSXSXSXXXXXXX',
    '..XXSXSXSXXXXXXX',
    '..XXXXXXXXXX....',
    '..XXXXXXXXXX....',
    '..XX.....XX.....',
    '.XX........XX...',
  ],
  _miuStand,
  <String>[
    '..........X....X',
    '..........XX..XX',
    '.S........XXXXXX',
    '.X........XXX.XX',
    '.X........XXX.XX',
    '.XXXSXSXSXXXXXXX',
    '..XXSXSXSXXXXXXX',
    '..XXXXXXXXXX....',
    '..XXXXXXXXXX....',
    '....XX..XX......',
    '....XX..XX......',
  ],
];

// Capy 18×10: thân dài lưng ngang, đầu liền thân, mõm vuông chóp mũi S,
// tai S trên đỉnh, chân S ngắn — frame bước chỉ đảo chéo 2 cặp chân.
const List<String> _capyStand = <String>[
  '............S..S..',
  '...........XXXXXX.',
  '...........XXXEXXX',
  '..XXXXXXXXXXXXXXXS',
  '.XXXXXXXXXXXXXXXXS',
  '.XXXXXXXXXXXXXXXX.',
  '.XXXXXXXXXXXXXXX..',
  '..XXXXXXXXXXXXXX..',
  '...SS.......SS....',
  '...SS.......SS....',
];

const List<List<String>> _capyFrames = <List<String>>[
  _capyStand,
  <String>[
    '............S..S..',
    '...........XXXXXX.',
    '...........XXXEXXX',
    '..XXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXXXXX.',
    '.XXXXXXXXXXXXXXX..',
    '..XXXXXXXXXXXXXX..',
    '..SS.........SS...',
    '..SS.........SS...',
  ],
  _capyStand,
  <String>[
    '............S..S..',
    '...........XXXXXX.',
    '...........XXXEXXX',
    '..XXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXXXXXS',
    '.XXXXXXXXXXXXXXXX.',
    '.XXXXXXXXXXXXXXX..',
    '..XXXXXXXXXXXXXX..',
    '....SS.....SS.....',
    '....SS.....SS.....',
  ],
];

// Vịt 14×10: đầu tròn nhô trước, mỏ B bè 2 ô, thân bầu, đuôi hất 1 ô sau
// lưng (frame sải hất lên 1 hàng), chân B mảnh + bàn bè.
const List<String> _duckStand = <String>[
  '........XXXX..',
  '........XXEX..',
  '........XXXXBB',
  '........XXXX..',
  '.X......XXXX..',
  '.XXXXXXXXXXX..',
  '..XXXXXXXXXXX.',
  '..XXXXXXXXXX..',
  '....B....B....',
  '...BB...BB....',
];

const List<List<String>> _duckFrames = <List<String>>[
  _duckStand,
  <String>[
    '........XXXX..',
    '........XXEX..',
    '........XXXXBB',
    '.X......XXXX..',
    '........XXXX..',
    '.XXXXXXXXXXX..',
    '..XXXXXXXXXXX.',
    '..XXXXXXXXXX..',
    '...B......B...',
    '..BB.....BB...',
  ],
  _duckStand,
  <String>[
    '........XXXX..',
    '........XXEX..',
    '........XXXXBB',
    '........XXXX..',
    '.X......XXXX..',
    '.XXXXXXXXXXX..',
    '..XXXXXXXXXXX.',
    '..XXXXXXXXXX..',
    '.....B..B.....',
    '....BB..BB....',
  ],
];

// Cua 16×10: front-facing — mắt lồi 2×2 (W lòng trắng, E đồng tử lé vào
// trong) trên cuống, thân 8 ô tách rời 2 càng (khối kiểu chữ C, kìm há ra
// ngoài) nối bằng cánh tay 1 hàng; frame bước thay phiên giơ hẳn một càng
// lên ngang mắt, chân chỉ xoè nhẹ — "cáu nhưng ngáo".
const List<String> _crabStand = <String>[
  '.....WW..WW.....',
  '.....WE..EW.....',
  '......X..X......',
  '....XXXXXXXX....',
  'XX..XXXXXXXX..XX',
  '.XXXXXXXXXXXXXX.',
  'XX..XXXXXXXX..XX',
  '....XXXXXXXX....',
  '....XX.XX.XX....',
  '....XX.XX.XX....',
];

const List<List<String>> _crabFrames = <List<String>>[
  _crabStand,
  <String>[
    'XX...WW..WW.....',
    '.X...WE..EW.....',
    'XXX...X..X......',
    '..XXXXXXXXXX....',
    '....XXXXXXXX..XX',
    '....XXXXXXXXXXX.',
    '....XXXXXXXX..XX',
    '....XXXXXXXX....',
    '....XX.XX.XX....',
    '...XX..XX..XX...',
  ],
  _crabStand,
  <String>[
    '.....WW..WW...XX',
    '.....WE..EW...X.',
    '......X..X...XXX',
    '....XXXXXXXXXX..',
    'XX..XXXXXXXX....',
    '.XXXXXXXXXXX....',
    'XX..XXXXXXXX....',
    '....XXXXXXXX....',
    '....XX.XX.XX....',
    '...XX..XX..XX...',
  ],
];

// Axo 18×10: đầu to vuông bo bên phải, quạt mang S 7 ô xoè sau gáy (rung 1 ô
// ở frame sải), thân ngắn, đuôi S dài phía sau cong lên/xuống theo nhịp.
const List<String> _axoStand = <String>[
  '.........S.S......',
  '........SSXXXXXX..',
  '........SSXXXXEX..',
  '.........SXXXXXX..',
  '..........XXXXXX..',
  '....XXXXXXXXXXXX..',
  '.SXXXXXXXXXXXXXX..',
  'SS..XXXXXXXXXX....',
  '.....XX......XX...',
  '....XXX.....XXX...',
];

const List<List<String>> _axoFrames = <List<String>>[
  _axoStand,
  <String>[
    '........S.S.......',
    '........SSXXXXXX..',
    '........SSXXXXEX..',
    '.........SXXXXXX..',
    '..........XXXXXX..',
    '....XXXXXXXXXXXX..',
    '.SXXXXXXXXXXXXXX..',
    '.SS.XXXXXXXXXX....',
    '....XX.......XX...',
    '...XXX......XXX...',
  ],
  _axoStand,
  <String>[
    '.........S.S......',
    '........SSXXXXXX..',
    '........SSXXXXEX..',
    '.........SXXXXXX..',
    '..........XXXXXX..',
    'S...XXXXXXXXXXXX..',
    '.SXXXXXXXXXXXXXX..',
    '....XXXXXXXXXX....',
    '......XX....XX....',
    '.....XXX...XXX....',
  ],
];

/// Bố cục cảnh nền. [city] là cảnh gốc (skyline dither trung tính + mây);
/// [nightCity] là thành phố đêm: nhà cao tầng cửa sổ sáng đèn, dãy núi
/// parallax phía xa, sao + trăng khuyết, mây. Cả hai đều procedural — không
/// asset ngoài.
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
  double _timeBase = 0;

  // Bố cục skyline/mây/núi cho một chu kỳ, sinh từ seed (núi rỗng khi scene
  // không có núi).
  late Int16List _heights;
  late Int16List _antennae;
  late List<_CloudSpec> _clouds;
  int _period = 1;
  late Int16List _mountains;
  int _mountPeriod = 1;

  // Buffer điểm tái dùng giữa các frame (không cấp phát trong paint).
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
    _rebuildLayout();
    if (widget.walking) _ticker.start();
  }

  @override
  void didUpdateWidget(PixelWalker old) {
    super.didUpdateWidget(old);
    if (widget.seed != old.seed || widget.scene != old.scene) _rebuildLayout();
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

    if (w.scene == PixelWalkerScene.nightCity) {
      // Đêm: sao/trăng tĩnh sau cùng, rồi núi (parallax chậm nhất), mây, và
      // toà nhà vẽ SAU mây để tháp cao che mây → có chiều sâu.
      _paintStars(canvas, size, w, cell, skylineBaseY, eased);
      _paintMoon(canvas, size, w, cell, skylineBaseY, eased);
      _paintMountains(canvas, size, w, cell, t, skylineBaseY, eased);
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
      _paintSkyline(canvas, size, w, cell, t, skylineBaseY, eased, night: true);
    } else {
      _paintSkyline(canvas, size, w, cell, t, skylineBaseY, eased);
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
      t,
      w.walking,
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
      final int h = state._heights[pi];
      if (h == 0) continue;
      final int extra = state._antennae[pi];
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
    final double cloudBandY = baseY - bandCells * cell;

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
      final int h = state._mountains[wx % state._mountPeriod];
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
    final double cy = ((baseY - 22 * cell) / cell).floor() * cell + cell / 2;
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
    double t,
    bool walking,
    double eased,
    double reveal,
  ) {
    final int frameCount = sprite.frames.length;
    final int fi = walking && frameCount > 1 ? (t * 7).floor() % frameCount : 0;
    final List<String> frame = sprite.frames[fi];
    final double lean = walking && fi.isOdd
        ? (fi % 4 == 1 ? 0.09 : -0.09)
        : 0.0;
    final double bob = walking && fi.isOdd ? -spriteCell * 0.35 : 0.0;
    final double rise = (1 - reveal) * (spriteH + spriteCell);

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
