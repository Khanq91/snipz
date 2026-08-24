/// Step Progress
/// Origin: reimplemented — kinetics "Step Progress" (Feedback & State),
///   https://github.com/ckissi/kinetics — chỉ lấy thông số + hành vi quan sát
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Horizontal step indicator: numbered circle nodes joined by a connector
/// track. The fill bar springs to `(step - 1) / (count - 1)` of the track and
/// every node up to [step] pops active with a small overshoot scale.
///
/// Controlled component: pass [step] (1-based) and rebuild with a new value
/// to advance — all motion is implicit (no ticker while idle).
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.step,
    this.count = 4,
    this.nodeSize = 30,
    this.trackHeight = 3,
    this.activeColor = const Color(0xFFFF8A00),
    this.nodeColor = const Color(0xFF232326),
    this.trackColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.numberColor = const Color(0xFF6E6C68),
    this.activeNumberColor = const Color(0xFF0E0E10),
  }) : assert(count >= 2, 'count must be at least 2'),
       assert(step >= 1, 'step is 1-based');

  /// Current step, 1-based. Clamped to [count].
  final int step;

  /// Total number of nodes.
  final int count;

  /// Diameter of one node circle. The active pop (scale 1.18) paints slightly
  /// outside this box, like the CSS original.
  final double nodeSize;

  final double trackHeight;

  /// Fill bar + active node background (kinetics amber).
  final Color activeColor;

  /// Inactive node background.
  final Color nodeColor;

  /// Connector track background.
  final Color trackColor;

  /// 1px node border (inactive).
  final Color borderColor;

  /// Number color on inactive nodes.
  final Color numberColor;

  /// Number color on active nodes.
  final Color activeNumberColor;

  // Kinetics --spring: cubic-bezier(0.34, 1.56, 0.64, 1).
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  @override
  Widget build(BuildContext context) {
    final int current = step > count ? count : step;
    final double fraction = (current - 1) / (count - 1);
    return SizedBox(
      height: nodeSize,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Connector track, vertically centered behind the nodes.
          Positioned(
            left: 0,
            right: 0,
            child: Container(
              height: trackHeight,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(trackHeight),
              ),
              // Fill bar: scaleX from the left edge, springs on step change.
              // Overshoot past the track end is intentional (CSS original has
              // no overflow clip); only the negative lobe is clamped so a
              // backwards overshoot never mirror-paints left of the track.
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: fraction),
                duration: const Duration(milliseconds: 500),
                curve: _spring,
                builder: (context, value, child) => Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.diagonal3Values(
                    value < 0 ? 0 : value,
                    1,
                    1,
                  ),
                  child: child,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(trackHeight),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (int i = 1; i <= count; i++)
                _StepNode(
                  number: i,
                  active: i <= current,
                  size: nodeSize,
                  spring: _spring,
                  activeColor: activeColor,
                  nodeColor: nodeColor,
                  borderColor: borderColor,
                  numberColor: numberColor,
                  activeNumberColor: activeNumberColor,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.number,
    required this.active,
    required this.size,
    required this.spring,
    required this.activeColor,
    required this.nodeColor,
    required this.borderColor,
    required this.numberColor,
    required this.activeNumberColor,
  });

  final int number;
  final bool active;
  final double size;
  final Curve spring;
  final Color activeColor;
  final Color nodeColor;
  final Color borderColor;
  final Color numberColor;
  final Color activeNumberColor;

  @override
  Widget build(BuildContext context) {
    // Two implicit layers because the CSS transitions differ per property:
    // transform 0.4s spring, background/border-color 0.3s ease. The number
    // color is NOT transitioned in the original — it switches instantly.
    return AnimatedScale(
      scale: active ? 1.18 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: spring,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? activeColor : nodeColor,
          border: Border.all(color: active ? activeColor : borderColor),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? activeNumberColor : numberColor,
          ),
        ),
      ),
    );
  }
}
