/// PixelLoader
/// Origin: reimplemented — dựng lại màn "Loading session..." của app Claude
/// Code mobile (mascot pixel giậm chân tại chỗ ~6fps, exit squash, hard cut,
/// content fade-in) từ phân tích video từng frame.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Sprite của loader dạng ma trận ký tự: mỗi pose là một list dòng, mỗi ký tự
/// tra màu trong [palette]; `.` (hoặc ký tự không có trong palette) là trong
/// suốt — hai mắt của mascot mặc định là 2 ô trống để lộ nền phía sau, đúng
/// kiểu "mắt = background" của bản gốc. Mọi dòng trong một pose phải dài bằng
/// nhau; các pose ĐƯỢC PHÉP khác kích thước nhau (vẽ neo đáy-giữa).
///
/// Chỉ cần 3 pose: [stand] (đứng), [crouch] (khuỵu — đáy giữ nguyên, thân
/// thấp hơn ~1 ô), [squash] (bẹt người lúc kết thúc — rộng hơn, lùn hơn;
/// null thì dùng [crouch]). Hai pose nghiêng trái/phải của chu kỳ đi bộ được
/// suy ra tự động từ [stand] bằng shear lượng tử hoá theo ô (bậc thang pixel,
/// không rotate mượt) — sprite tự chế cũng được nghiêng đúng kiểu.
class PixelLoaderSprite {
  const PixelLoaderSprite({
    required this.stand,
    required this.crouch,
    this.squash,
    required this.palette,
  }) : assert(stand.length > 0 && crouch.length > 0);

  /// Mascot mặc định: sinh vật coral 11×8 macro-pixel đo từ video (sprite
  /// 132×97px vật lý, macro-pixel ~12px, mắt 1 ô cách nhau 4 ô, 4 chân).
  factory PixelLoaderSprite.coral({Color color = const Color(0xFFD77655)}) {
    return PixelLoaderSprite(
      stand: _coralStand,
      crouch: _coralCrouch,
      squash: _coralSquash,
      palette: <String, Color>{'X': color},
    );
  }

  final List<String> stand;
  final List<String> crouch;
  final List<String>? squash;
  final Map<String, Color> palette;
}

// Pose đứng 11×8: đầu 7 ô có 2 hốc mắt, vai xoè hết 11 ô, thân dưới 7 ô,
// 4 chân. Tỷ lệ bám theo bản đo: 132×97px / ô 12px.
const List<String> _coralStand = <String>[
  '..XXXXXXX..',
  '..X.XXX.X..',
  'XXXXXXXXXXX',
  'XXXXXXXXXXX',
  '..XXXXXXX..',
  '..XXXXXXX..',
  '..X.X.X.X..',
  '..X.X.X.X..',
];

// Pose khuỵu 11×7: chân + đáy giữ nguyên vị trí, thân mất đúng 1 ô chiều cao
// (97→86px trong video) — KHÔNG translate cả sprite xuống.
const List<String> _coralCrouch = <String>[
  '..XXXXXXX..',
  '..X.XXX.X..',
  'XXXXXXXXXXX',
  'XXXXXXXXXXX',
  '..XXXXXXX..',
  '..X.X.X.X..',
  '..X.X.X.X..',
];

// Pose exit squash 12×7: rộng thêm 1 ô, lùn 1 ô (~scaleX 1.05 / scaleY 0.90
// của video), chân xoè rộng — dáng "dậm chân bẹt người" trước khi biến mất.
const List<String> _coralSquash = <String>[
  '.XXXXXXXXXX.',
  '.XX.XXXX.XX.',
  'XXXXXXXXXXXX',
  'XXXXXXXXXXXX',
  '.XXXXXXXXXX.',
  '.XXXXXXXXXX.',
  '.X..X..X..X.',
];

// tan(5°) ≈ 0.0875 — độ nghiêng của 2 pose lean. Mỗi hàng tính từ đáy dịch
// ngang thêm chừng này Ô, round về số nguyên → cạnh nghiêng thành bậc thang
// pixel (2 hàng trên cùng của sprite 8 hàng lệch đúng 1 ô) thay vì đường xiên
// anti-alias.
const double _leanShearPerRow = 0.0875;

/// Mascot pixel + label đứng yên bên dưới — phần nhìn thấy của loader, tách
/// riêng để dùng độc lập (đặt trong empty state, dialog, flow tự chế...).
/// Chu kỳ đi-tại-chỗ 6 nhịp × [stepDuration] (~1s): đứng → khuỵu → nghiêng
/// phải → khuỵu → nghiêng trái → khuỵu. Mỗi nhịp giữ nguyên pose rồi NHẢY
/// sang pose kế (steps(1), không tween) — sprite chỉ đổi hình ~6 lần/giây dù
/// ticker chạy theo vsync.
///
/// [completed] = true: dừng chu kỳ, đứng im ở pose squash (dùng làm trạng
/// thái "load xong" trước khi tự ẩn). [animated] = false: đứng im pose đứng,
/// không ticker nào chạy.
class PixelLoaderIndicator extends StatefulWidget {
  const PixelLoaderIndicator({
    super.key,
    this.sprite,
    this.creatureColor = const Color(0xFFD77655),
    this.label,
    this.labelStyle,
    this.scale = 1.0,
    this.gap,
    this.completed = false,
    this.animated = true,
    this.stepDuration = const Duration(milliseconds: 166),
  });

  /// Sprite thay thế; null → [PixelLoaderSprite.coral] tô bằng
  /// [creatureColor].
  final PixelLoaderSprite? sprite;

  /// Màu mascot mặc định (chỉ dùng khi [sprite] null).
  final Color creatureColor;

  /// Dòng chữ tĩnh dưới sprite; null = không có. Cố ý không animate (không
  /// ellipsis chạy, không pulse) — bản gốc để text đứng im cho sprite là thứ
  /// duy nhất động.
  final String? label;

  /// Merge đè lên style mặc định (12.5px, w400, #EAEAEA, hệ thống).
  final TextStyle? labelStyle;

  /// Cỡ macro-pixel: 1.0 → ô 6px logical (sprite mặc định rộng 66px — đúng
  /// kích thước đo từ video trên màn 360px logical). Đây là mật độ chi tiết,
  /// không phải scale transform.
  final double scale;

  /// Khoảng cách sprite → label; null → 2.5 ô (~15px tại scale 1).
  final double? gap;

  /// true → đứng im ở pose squash (trạng thái "xong").
  final bool completed;

  /// false → đứng im ở pose đứng, không chạy ticker.
  final bool animated;

  /// Thời lượng giữ một pose của chu kỳ (~166ms ≈ 6fps như video).
  final Duration stepDuration;

  @override
  State<PixelLoaderIndicator> createState() => _PixelLoaderIndicatorState();
}

class _PixelLoaderIndicatorState extends State<PixelLoaderIndicator>
    with SingleTickerProviderStateMixin {
  // Tạo trong initState (không lazy) — lazy thì lần đụng đầu tiên có thể là
  // dispose(), lúc đó createTicker tra cứu TickerMode trên cây đã deactivate.
  late final Ticker _ticker;
  final _RepaintTrigger _repaint = _RepaintTrigger();
  final _PointSink _sink = _PointSink();

  // Nhịp hiện tại trong chu kỳ 6 pose; chỉ repaint khi nhịp ĐỔI — painter
  // được gọi ~6 lần/giây dù ticker bám vsync.
  int _step = 0;

  bool get _shouldTick => widget.animated && !widget.completed;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (_shouldTick) _ticker.start();
  }

  @override
  void didUpdateWidget(PixelLoaderIndicator old) {
    super.didUpdateWidget(old);
    if (_shouldTick && !_ticker.isActive) {
      _step = 0; // ticker restart đếm elapsed từ 0 → chu kỳ vào lại từ pose đứng
      _ticker.start();
    } else if (!_shouldTick && _ticker.isActive) {
      _ticker.stop();
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
    final int us = widget.stepDuration.inMicroseconds;
    if (us <= 0) return;
    final int step = (elapsed.inMicroseconds ~/ us) % 6;
    if (step != _step) {
      _step = step;
      _repaint.bump();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PixelLoaderSprite sprite =
        widget.sprite ?? PixelLoaderSprite.coral(color: widget.creatureColor);
    final double cell = 6.0 * widget.scale;

    // Khung chứa pose to nhất + 2 ô margin ngang để phần đầu nghiêng không
    // tràn; mọi pose vẽ neo đáy-giữa nên khuỵu/squash không làm layout nhảy.
    int cols = sprite.stand.first.length;
    int rows = sprite.stand.length;
    for (final List<String> f in <List<String>>[
      sprite.crouch,
      if (sprite.squash != null) sprite.squash!,
    ]) {
      if (f.first.length > cols) cols = f.first.length;
      if (f.length > rows) rows = f.length;
    }

    final TextStyle style = const TextStyle(
      color: Color(0xFFEAEAEA),
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none,
    ).merge(widget.labelStyle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CustomPaint(
          size: Size((cols + 2) * cell, rows * cell),
          painter: _LoaderSpritePainter(this, sprite),
        ),
        if (widget.label != null) ...<Widget>[
          SizedBox(height: widget.gap ?? cell * 2.5),
          Text(widget.label!, style: style),
        ],
      ],
    );
  }
}

class _RepaintTrigger extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// Buffer Float32List tự giãn, tái dùng giữa các frame (không cấp phát trong
/// paint).
class _PointSink {
  Float32List _buf = Float32List(256);
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

class _LoaderSpritePainter extends CustomPainter {
  _LoaderSpritePainter(this.state, this.sprite)
    : super(repaint: state._repaint);

  final _PixelLoaderIndicatorState state;
  final PixelLoaderSprite sprite;

  // AA tắt hẳn: ô vuông cạnh cứng đúng chất pixel, kể cả khi lean.
  static final Paint _dot = Paint()
    ..strokeCap = StrokeCap.square
    ..style = PaintingStyle.stroke
    ..isAntiAlias = false;

  @override
  void paint(Canvas canvas, Size size) {
    final PixelLoaderIndicator w = state.widget;
    final double cell = 6.0 * w.scale;

    // Chu kỳ: 0 đứng, 1 khuỵu, 2 nghiêng phải, 3 khuỵu, 4 nghiêng trái,
    // 5 khuỵu. Lean chỉ áp lên pose đứng, dưới dạng shear theo ô.
    List<String> frame = sprite.stand;
    double lean = 0;
    if (w.completed) {
      frame = sprite.squash ?? sprite.crouch;
    } else if (w.animated) {
      final int step = state._step;
      if (step.isOdd) {
        frame = sprite.crouch;
      } else if (step == 2) {
        lean = _leanShearPerRow;
      } else if (step == 4) {
        lean = -_leanShearPerRow;
      }
    }

    final int rows = frame.length;
    final double cx = size.width / 2;
    final double bottom = size.height;

    for (final MapEntry<String, Color> entry in sprite.palette.entries) {
      final _PointSink sink = state._sink..clear();
      for (int r = 0; r < rows; r++) {
        final String row = frame[r];
        final int fromBottom = rows - 1 - r;
        // Dịch ngang nguyên-ô theo độ cao hàng → nghiêng kiểu bậc thang.
        final double shift = lean == 0
            ? 0
            : (lean * fromBottom).roundToDouble();
        final double y = bottom - (fromBottom + 0.5) * cell;
        for (int c = 0; c < row.length; c++) {
          if (row[c] != entry.key) continue;
          sink.add(cx + (c - (row.length - 1) / 2 + shift) * cell, y);
        }
      }
      if (sink.isEmpty) continue;
      _dot
        ..strokeWidth = cell
        ..color = entry.value;
      canvas.drawRawPoints(ui.PointMode.points, sink.view, _dot);
    }
  }

  @override
  bool shouldRepaint(_LoaderSpritePainter oldDelegate) => true;
}

/// Màn loading trọn gói kiểu "Loading session...": phủ [backgroundColor] kín
/// vùng chứa, mascot pixel giậm chân + [label] tĩnh đặt tại [alignment]
/// (mặc định hơi cao hơn tâm như bản gốc). Khi [loading] chuyển false, chạy
/// đúng choreography của video:
///
///   squash [squashDuration] → hard cut (loader biến mất KHÔNG fade) →
///   ~40ms màn trống → [child] fade-in [revealDuration] ease-out.
///
/// [loading] quay lại true thì cắt ngược về loader ngay (dùng lại được cho
/// refresh). Mount với [loading] false ngay từ đầu → hiện [child] luôn,
/// không chạy transition. Sau khi reveal xong, cây widget chỉ còn đúng
/// [child] — không ticker, không layer thừa.
///
/// Cần đặt trong vùng có kích thước xác định (body của Scaffold, Expanded...).
class PixelLoader extends StatefulWidget {
  const PixelLoader({
    super.key,
    required this.loading,
    this.child,
    this.label = 'Loading session...',
    this.labelStyle,
    this.sprite,
    this.creatureColor = const Color(0xFFD77655),
    this.backgroundColor = const Color(0xFF141414),
    this.scale = 1.0,
    this.alignment = const Alignment(0, -0.06),
    this.gap,
    this.animated = true,
    this.stepDuration = const Duration(milliseconds: 166),
    this.squashDuration = const Duration(milliseconds: 160),
    this.revealDuration = const Duration(milliseconds: 300),
    this.onRevealComplete,
  });

  /// true = đang load (hiện mascot); chuyển sang false để chạy exit + reveal.
  final bool loading;

  /// Nội dung hiện sau loader; null → sau reveal chỉ còn nền trong suốt.
  final Widget? child;

  /// Dòng chữ tĩnh dưới sprite; null = không có.
  final String? label;

  /// Merge đè lên style mặc định của label (12.5px, w400, #EAEAEA).
  final TextStyle? labelStyle;

  /// Sprite thay thế; null → [PixelLoaderSprite.coral] tô [creatureColor].
  final PixelLoaderSprite? sprite;

  /// Màu mascot mặc định (chỉ dùng khi [sprite] null).
  final Color creatureColor;

  /// Nền phủ kín trong lúc load + transition; mắt mascot mặc định là ô trống
  /// nên tự mang màu này. Sau khi reveal xong lớp nền được gỡ bỏ.
  final Color backgroundColor;

  /// Cỡ macro-pixel (xem [PixelLoaderIndicator.scale]).
  final double scale;

  /// Vị trí cụm sprite+label; mặc định tâm cụm ~47% chiều cao (hơi cao hơn
  /// tâm màn hình như video gốc).
  final Alignment alignment;

  /// Khoảng cách sprite → label; null → 2.5 ô.
  final double? gap;

  /// false → mascot đứng im, không ticker (vẫn giữ nguyên choreography exit).
  final bool animated;

  /// Thời lượng một nhịp của chu kỳ đi bộ.
  final Duration stepDuration;

  /// Thời gian giữ pose squash trước khi hard cut.
  final Duration squashDuration;

  /// Thời gian fade-in của [child] (ease-out).
  final Duration revealDuration;

  /// Gọi một lần khi [child] hiện xong (kết thúc reveal).
  final VoidCallback? onRevealComplete;

  @override
  State<PixelLoader> createState() => _PixelLoaderState();
}

class _PixelLoaderState extends State<PixelLoader>
    with SingleTickerProviderStateMixin {
  // ~1 frame màn hình gần trống giữa hard cut và lúc content bắt đầu fade
  // (đo từ video 24fps). Cũng là lúc child được mount trước ở opacity 0 để
  // layout xong trước khi fade chạy.
  static const int _cutGapMs = 40;

  late final AnimationController _exit;

  int get _totalMs =>
      widget.squashDuration.inMilliseconds +
      _cutGapMs +
      widget.revealDuration.inMilliseconds;

  double get _squashEnd => widget.squashDuration.inMilliseconds / _totalMs;

  double get _fadeStart =>
      (widget.squashDuration.inMilliseconds + _cutGapMs) / _totalMs;

  @override
  void initState() {
    super.initState();
    _exit = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMs),
      // Mount với loading=false → coi như đã reveal xong, không chạy gì.
      value: widget.loading ? 0.0 : 1.0,
    );
    _exit.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) widget.onRevealComplete?.call();
    });
  }

  @override
  void didUpdateWidget(PixelLoader old) {
    super.didUpdateWidget(old);
    final Duration total = Duration(milliseconds: _totalMs);
    if (_exit.duration != total) _exit.duration = total;
    if (widget.loading != old.loading) {
      if (widget.loading) {
        // Quay lại loading: cắt ngược về loader ngay, không animation.
        _exit.stop();
        _exit.value = 0.0;
      } else {
        _exit.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exit,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double v = _exit.value;
        final bool done = !widget.loading && v >= 1.0;
        if (done) return child ?? const SizedBox.shrink();

        // Loader hiện tới hết pha squash rồi biến mất trong 1 frame (hard
        // cut) — cố ý không fade-out, đúng video.
        final bool showLoader = widget.loading || v < _squashEnd;
        // Child mount từ thời điểm hard cut (opacity 0 trong ~40ms gap).
        final bool mountChild =
            child != null && !widget.loading && v >= _squashEnd;
        final double denom = 1 - _fadeStart;
        final double fade = (widget.loading || denom <= 0)
            ? 0
            : Curves.easeOut.transform(
                ((v - _fadeStart) / denom).clamp(0.0, 1.0),
              );

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: widget.backgroundColor),
            if (mountChild) Opacity(opacity: fade, child: child),
            if (showLoader)
              Align(
                alignment: widget.alignment,
                child: PixelLoaderIndicator(
                  sprite: widget.sprite,
                  creatureColor: widget.creatureColor,
                  label: widget.label,
                  labelStyle: widget.labelStyle,
                  scale: widget.scale,
                  gap: widget.gap,
                  animated: widget.animated,
                  stepDuration: widget.stepDuration,
                  // loading vừa chuyển false → đứng im ở pose squash.
                  completed: !widget.loading,
                ),
              ),
          ],
        );
      },
    );
  }
}
