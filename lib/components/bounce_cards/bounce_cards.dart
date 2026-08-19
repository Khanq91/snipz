/// BounceCards
/// Origin: reimplemented — dựng lại "BounceCards" của react-bits
/// (GSAP elastic stagger) bằng AnimationController thuần
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Per-card resting pose, mirroring the CSS `rotate(θ) translate(dx)` order:
/// the offset is applied in the card's rotated frame.
class BounceCardPose {
  const BounceCardPose({this.rotationDeg = 0, this.offset = Offset.zero});

  final double rotationDeg;
  final Offset offset;
}

/// A fanned pile of cards that pop in one by one with an elastic bounce
/// (scale 0 → 1, staggered). Cards are arbitrary widgets clipped into
/// rounded, bordered squares. Replay/stop from outside via
/// `GlobalKey<BounceCardsState>`.
class BounceCards extends StatefulWidget {
  const BounceCards({
    super.key,
    required this.cards,
    this.width = 400,
    this.height = 400,
    this.cardSize = 200,
    this.poses,
    this.delay = const Duration(milliseconds: 500),
    this.stagger = const Duration(milliseconds: 60),
    this.bounceDuration = const Duration(milliseconds: 500),
    this.curve = const ElasticOutCurve(0.8),
    this.borderWidth = 8,
    this.borderColor = Colors.white,
    this.borderRadius = 30,
    this.shadow = true,
    this.autoPlay = true,
  });

  /// Card contents, painted in order (last on top, like the original DOM).
  final List<Widget> cards;

  final double width;
  final double height;

  /// Cards are squares of this side.
  final double cardSize;

  /// One pose per card; null uses the original 5-card fan and repeats its
  /// last entry for extra cards.
  final List<BounceCardPose>? poses;

  /// Wait before the first card pops in.
  final Duration delay;

  /// Delay between consecutive cards.
  final Duration stagger;

  /// One card's scale-in time.
  final Duration bounceDuration;

  /// Elastic ease of the pop (`elastic.out(1, 0.8)` in the original).
  final Curve curve;

  final double borderWidth;
  final Color borderColor;
  final double borderRadius;
  final bool shadow;

  /// False = start hidden; call [BounceCardsState.play] yourself.
  final bool autoPlay;

  static const List<BounceCardPose> _defaultPoses = <BounceCardPose>[
    BounceCardPose(rotationDeg: 10, offset: Offset(-170, 0)),
    BounceCardPose(rotationDeg: 5, offset: Offset(-85, 0)),
    BounceCardPose(rotationDeg: -3),
    BounceCardPose(rotationDeg: -10, offset: Offset(85, 0)),
    BounceCardPose(rotationDeg: 2, offset: Offset(170, 0)),
  ];

  @override
  State<BounceCards> createState() => BounceCardsState();
}

class BounceCardsState extends State<BounceCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration());
    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(BounceCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = _totalDuration();
  }

  Duration _totalDuration() {
    final int n = math.max(widget.cards.length, 1);
    return widget.delay + widget.stagger * (n - 1) + widget.bounceDuration;
  }

  /// Restart the pop-in from scale 0.
  void play() => _controller.forward(from: 0);

  /// Freeze the animation where it is.
  void stop() => _controller.stop();

  BounceCardPose _poseAt(int i) {
    final List<BounceCardPose> poses = widget.poses ?? BounceCards._defaultPoses;
    if (poses.isEmpty) {
      return const BounceCardPose();
    }
    return i < poses.length ? poses[i] : poses.last;
  }

  /// Scale of card [i] for overall progress [t] (in 0..1 of the controller).
  double _scaleAt(int i, double t) {
    final int totalMs = _totalDuration().inMilliseconds;
    if (totalMs == 0) {
      return 1;
    }
    final double startMs = (widget.delay + widget.stagger * i).inMilliseconds
        .toDouble();
    final double durMs = math.max(
      widget.bounceDuration.inMilliseconds.toDouble(),
      1,
    );
    final double local = ((t * totalMs - startMs) / durMs).clamp(0.0, 1.0);
    return widget.curve.transform(local);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              for (int i = 0; i < widget.cards.length; i++)
                _buildCard(i, _scaleAt(i, _controller.value)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(int i, double scale) {
    final BounceCardPose pose = _poseAt(i);
    final double rad = pose.rotationDeg * math.pi / 180;
    // CSS `rotate(θ) translate(dx)` == translate by the rotated offset, then
    // rotate; the entrance scale composes innermost.
    final Matrix4 matrix = Matrix4.rotationZ(rad)
      ..multiply(Matrix4.translationValues(pose.offset.dx, pose.offset.dy, 0))
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1));
    return Transform(
      transform: matrix,
      alignment: Alignment.center,
      child: Container(
        width: widget.cardSize,
        height: widget.cardSize,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
          boxShadow: widget.shadow
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: widget.cards[i],
      ),
    );
  }
}
