/// PullRevealRefresh
/// Origin: reimplemented — dựng lại cơ chế pull-to-refresh "giãn header" của
/// app Claude Code mobile (kéo → header lộ dần, nhả đủ ngưỡng → refresh,
/// xong → thu gọn) từ video demo. Header là builder tự do — cắm cảnh gì
/// cũng được.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PullRevealMode {
  /// Nghỉ, header đóng.
  idle,

  /// Đang kéo, chưa qua ngưỡng — nhả sẽ thu về.
  dragging,

  /// Đang kéo và đã qua ngưỡng — nhả sẽ refresh.
  armed,

  /// `onRefresh` đang chạy, header giữ ở [PullRevealRefresh.triggerExtent].
  refreshing,

  /// Refresh xong, header đang thu về 0.
  settling,
}

/// Snapshot trạng thái đưa vào [PullRevealHeaderBuilder] mỗi frame.
class PullRevealStatus {
  const PullRevealStatus({
    required this.mode,
    required this.extent,
    required this.triggerExtent,
    required this.maxExtent,
  });

  final PullRevealMode mode;

  /// Chiều cao header hiện tại (px).
  final double extent;

  final double triggerExtent;
  final double maxExtent;

  /// 0→1 so với ngưỡng trigger — hợp để lái hiệu ứng "hiện dần khi kéo".
  double get progress => (extent / triggerExtent).clamp(0.0, 1.0);

  bool get isRefreshing => mode == PullRevealMode.refreshing;
}

typedef PullRevealHeaderBuilder =
    Widget Function(BuildContext context, PullRevealStatus status);

/// Pull-to-refresh kiểu "giãn header": kéo xuống ở đỉnh danh sách thì một
/// vùng header cao dần lộ ra phía trên và đẩy nội dung xuống (nội dung chỉ
/// bị translate — không relayout mỗi frame). Nhả khi qua ngưỡng → header
/// giữ ở [triggerExtent], gọi [onRefresh]; xong → thu về 0.
///
/// Header hoàn toàn do [headerBuilder] quyết định — nhận [PullRevealStatus]
/// (extent, progress, mode) để tự lái hiệu ứng. Có haptic khi kéo qua ngưỡng
/// ([hapticOnArm]).
///
/// Thiết kế cho `ClampingScrollPhysics` (Android mặc định). Với
/// `BouncingScrollPhysics` vẫn chạy qua nhánh đọc overscroll âm — xem
/// Caveats trong README.
class PullRevealRefresh extends StatefulWidget {
  const PullRevealRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    required this.headerBuilder,
    this.triggerExtent = 96.0,
    this.maxExtent = 168.0,
    this.hapticOnArm = true,
    this.settleDuration = const Duration(milliseconds: 200),
    this.collapseDuration = const Duration(milliseconds: 320),
    this.collapseCurve = Curves.easeOutCubic,
    this.notificationDepth = 0,
  }) : assert(maxExtent >= triggerExtent);

  /// Scrollable bên trong (ListView/CustomScrollView/...). Nên đặt
  /// `physics: AlwaysScrollableScrollPhysics()` để kéo được cả khi nội dung
  /// ngắn hơn viewport.
  final Widget child;

  /// Chạy khi người dùng nhả qua ngưỡng. Header giữ mở tới khi Future xong.
  final Future<void> Function() onRefresh;

  /// Dựng nội dung header; được gọi lại mỗi frame extent đổi.
  final PullRevealHeaderBuilder headerBuilder;

  /// Kéo tới đây thì armed; cũng là chiều cao giữ khi đang refresh.
  final double triggerExtent;

  /// Trần chiều cao header khi kéo quá tay (có lực cản dần).
  final double maxExtent;

  /// `HapticFeedback.mediumImpact` đúng lúc kéo vượt ngưỡng.
  final bool hapticOnArm;

  /// Thời gian header lún về [triggerExtent] sau khi nhả tay.
  final Duration settleDuration;

  /// Thời gian thu về 0 sau khi refresh xong (hoặc nhả không đủ ngưỡng).
  final Duration collapseDuration;

  final Curve collapseCurve;

  /// Chỉ nghe notification ở depth này (0 = scrollable ngoài cùng).
  final int notificationDepth;

  @override
  State<PullRevealRefresh> createState() => _PullRevealRefreshState();
}

class _PullRevealRefreshState extends State<PullRevealRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _extent = AnimationController.unbounded(
    vsync: this,
  );

  PullRevealMode _mode = PullRevealMode.idle;

  /// true khi extent đến từ overscroll âm của BouncingScrollPhysics (gap do
  /// chính list tạo ra — không translate thêm).
  bool _bounceMode = false;
  final ValueNotifier<double> _bounceGap = ValueNotifier<double>(0);

  @override
  void dispose() {
    _extent.dispose();
    _bounceGap.dispose();
    super.dispose();
  }

  void _setMode(PullRevealMode mode) {
    if (_mode == mode || !mounted) return;
    setState(() => _mode = mode);
  }

  void _setExtent(double value) {
    _extent.value = value.clamp(0.0, widget.maxExtent);
  }

  void _onPulled(double delta) {
    // Lực cản tăng dần khi vượt ngưỡng để có cảm giác đàn hồi.
    final double room = (1 - _extent.value / widget.maxExtent).clamp(0.0, 1.0);
    _setExtent(_extent.value + delta * (0.25 + 0.75 * room));
    _updateArm();
  }

  void _updateArm() {
    if (_extent.value >= widget.triggerExtent) {
      if (_mode != PullRevealMode.armed) {
        if (widget.hapticOnArm) HapticFeedback.mediumImpact();
        _setMode(PullRevealMode.armed);
      }
    } else if (_extent.value > 0) {
      _setMode(PullRevealMode.dragging);
    }
  }

  void _finishDrag() {
    if (_mode == PullRevealMode.armed) {
      _setMode(PullRevealMode.refreshing);
      unawaited(
        _extent.animateTo(
          widget.triggerExtent,
          duration: widget.settleDuration,
          curve: Curves.easeOutCubic,
        ),
      );
      unawaited(_runRefresh());
    } else if (_mode == PullRevealMode.dragging) {
      unawaited(_collapse(then: PullRevealMode.idle));
    }
  }

  Future<void> _runRefresh() async {
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        unawaited(
          _collapse(from: PullRevealMode.settling, then: PullRevealMode.idle),
        );
      }
    }
  }

  Future<void> _collapse({PullRevealMode? from, PullRevealMode? then}) async {
    if (from != null) _setMode(from);
    try {
      await _extent
          .animateTo(
            0,
            duration: widget.collapseDuration,
            curve: widget.collapseCurve,
          )
          .orCancel;
    } on TickerCanceled {
      return; // Bị người dùng kéo tiếp đè lên — trạng thái mới tự lo.
    }
    if (then != null) _setMode(then);
  }

  bool _onNotification(ScrollNotification n) {
    if (n.depth != widget.notificationDepth) return false;
    final bool busy =
        _mode == PullRevealMode.refreshing || _mode == PullRevealMode.settling;

    if (n is OverscrollNotification &&
        !busy &&
        n.overscroll < 0 &&
        n.dragDetails != null) {
      // ClampingScrollPhysics: list đứng ở 0, mình tự cộng dồn độ kéo.
      _bounceMode = false;
      _onPulled(-n.overscroll);
      return false;
    }

    if (n is ScrollUpdateNotification) {
      if (n.metrics.pixels < 0 && !busy && n.dragDetails != null) {
        // BouncingScrollPhysics: gap là chính overscroll của list.
        _bounceMode = true;
        _setExtent(-n.metrics.pixels);
        _updateArm();
      }
      if (_bounceMode) _bounceGap.value = math.max(0.0, -n.metrics.pixels);
      final bool draggingUs =
          _mode == PullRevealMode.dragging || _mode == PullRevealMode.armed;
      if (draggingUs) {
        if (n.dragDetails == null) {
          // Tay đã rời (fling) — chốt luôn.
          _finishDrag();
        } else if (!_bounceMode &&
            (n.scrollDelta ?? 0) > 0 &&
            _extent.value > 0) {
          // Kéo ngược lên khi header đang mở: nuốt vào header trước.
          _setExtent(_extent.value - n.scrollDelta!);
          _updateArm();
          if (_extent.value <= 0) _setMode(PullRevealMode.idle);
        }
      }
      return false;
    }

    if (n is ScrollEndNotification &&
        (_mode == PullRevealMode.dragging || _mode == PullRevealMode.armed)) {
      _finishDrag();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final Widget scrollable = NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_extent, _bounceGap]),
      child: scrollable,
      builder: (BuildContext context, Widget? child) {
        final double extent = _extent.value;
        final double translate = _bounceMode
            ? math.max(0.0, extent - _bounceGap.value)
            : extent;
        final double headerHeight = math.max(extent, _bounceGap.value);
        return Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.passthrough,
          children: <Widget>[
            if (headerHeight > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: headerHeight,
                child: ClipRect(
                  child: widget.headerBuilder(
                    context,
                    PullRevealStatus(
                      mode: _mode,
                      extent: headerHeight,
                      triggerExtent: widget.triggerExtent,
                      maxExtent: widget.maxExtent,
                    ),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(0, translate),
              child: child,
            ),
          ],
        );
      },
    );
  }
}
