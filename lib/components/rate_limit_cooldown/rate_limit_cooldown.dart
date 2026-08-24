/// RateLimitCooldown
/// Origin: reimplemented — kinetics "Rate Limit Cooldown" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Token-bucket rate limiter as a looping state animation (6.4s cycle):
/// five pips are spent left-to-right in quick succession, the status flips
/// from a calm `200 · ok` to a warning `429 · cooling` while a cooldown bar
/// drains, then the pips are re-credited one by one on a slow drip with a
/// small overshoot. The asymmetry is the point: spending is instant,
/// recovery is patient.
class RateLimitCooldown extends StatefulWidget {
  const RateLimitCooldown({
    super.key,
    this.tokenCount = 5,
    this.width = 214,
    this.okText = '200 · ok',
    this.coolText = '429 · cooling',
    this.tokenColor = const Color(0xFFFF8A00),
    this.okColor = const Color(0xFF4CD08A),
    this.dangerColor = const Color(0xFFFF5C5C),
    this.cardColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.arcTrackColor = const Color(0xFF1A1A1D),
    this.showCard = true,
    this.animate = true,
    this.frozenAt,
  }) : assert(tokenCount >= 1);

  final int tokenCount;
  final double width;

  /// Status labels (cross-faded).
  final String okText;
  final String coolText;

  /// Pip fill (kinetics amber).
  final Color tokenColor;
  final Color okColor;
  final Color dangerColor;

  /// Card chrome; ignored when [showCard] is false.
  final Color cardColor;
  final Color borderColor;

  /// Cooldown bar background.
  final Color arcTrackColor;
  final bool showCard;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<RateLimitCooldown> createState() => _RateLimitCooldownState();
}

class _RateLimitCooldownState extends State<RateLimitCooldown>
    with SingleTickerProviderStateMixin {
  /// One full spend → throttle → refill cycle (6.4s in the original).
  static const double _period = 6.4;

  /// CSS `cubic-bezier(0.4, 0, 0.2, 1)` on the cooldown sweep.
  static const Curve _sweep = Cubic(0.4, 0, 0.2, 1);

  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker =
        createTicker((elapsed) => _t.value = elapsed.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(RateLimitCooldown old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  void _syncTicker() {
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool run = widget.animate && widget.frozenAt == null && !reduced;
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  /// Piecewise keyframe track: values at fractional positions of the cycle,
  /// each segment eased with [curve]. Positions must be sorted, 0..1.
  static double _kf(
    double u,
    List<double> pos,
    List<double> val,
    Curve curve,
  ) {
    if (u <= pos.first) return val.first;
    for (int i = 1; i < pos.length; i++) {
      if (u <= pos[i]) {
        final double span = pos[i] - pos[i - 1];
        final double p = span <= 0 ? 1 : (u - pos[i - 1]) / span;
        return val[i - 1] + (val[i] - val[i - 1]) * curve.transform(p);
      }
    }
    return val.last;
  }

  /// Local cycle position for an element delayed by [delay] seconds.
  static double _local(double t, double delay) {
    double local = (t - delay) % _period;
    if (local < 0) local += _period;
    return local / _period;
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = ValueListenableBuilder<double>(
      valueListenable: _t,
      builder: (context, live, _) {
        final double t = widget.frozenAt ?? live;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < widget.tokenCount; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 8),
                  _pip(t, i),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _cooldownBar(t),
            const SizedBox(height: 12),
            _stateLine(t),
          ],
        );
      },
    );
    if (!widget.showCard) return body;
    return Container(
      width: widget.width,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        border: Border.all(color: widget.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: body,
    );
  }

  /// token-cycle (linear): full → spent (9%) → throttled hold (52%) →
  /// refill overshoot 1.22 (62%) → settled (70%). Per-pip delay 0.14s.
  Widget _pip(double t, int i) {
    final double u = _local(t, i * 0.14);
    const List<double> pos = <double>[0, .04, .09, .52, .62, .70, 1];
    final double opacity =
        _kf(u, pos, const <double>[1, 1, .12, .12, 1, 1, 1], Curves.linear);
    final double scale =
        _kf(u, pos, const <double>[1, 1, .5, .5, 1.22, 1, 1], Curves.linear);
    // Glow follows the pip state (the original zeroes box-shadow when spent).
    final double glow = ((opacity - .12) / .88).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.tokenColor.withValues(alpha: opacity),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: widget.tokenColor.withValues(alpha: 0.45 * glow),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  /// cooldown-sweep: full bar drains scaleX 1 → 0 over 8%..62%, then hides.
  Widget _cooldownBar(double t) {
    final double u = _local(t, 0);
    final double scaleX = _kf(
        u, const <double>[0, .08, .62, 1], const <double>[1, 1, 0, 0], _sweep);
    final double opacity = _kf(u, const <double>[0, .62, .64, 1],
        const <double>[.9, .9, 0, 0], _sweep);
    return Container(
      width: 148,
      height: 3,
      decoration: BoxDecoration(
        color: widget.arcTrackColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.diagonal3Values(scaleX, 1, 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: <Color>[widget.dangerColor, widget.tokenColor],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  /// `200 · ok` ↔ `429 · cooling` cross-fade (ease-in-out).
  Widget _stateLine(double t) {
    final double u = _local(t, 0);
    final double okOpacity = _kf(u, const <double>[0, .05, .10, .62, .70, 1],
        const <double>[1, 1, 0, 0, 1, 1], Curves.easeInOut);
    TextStyle style(Color color) => TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.72,
          color: color,
        );
    return SizedBox(
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Opacity(
            opacity: okOpacity,
            child: Text(widget.okText, style: style(widget.okColor)),
          ),
          Opacity(
            opacity: 1 - okOpacity,
            child: Text(widget.coolText, style: style(widget.dangerColor)),
          ),
        ],
      ),
    );
  }
}
