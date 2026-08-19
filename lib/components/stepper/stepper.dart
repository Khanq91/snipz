/// StepFlow (react-bits "Stepper")
/// Origin: adapted — port react-bits Stepper (motion/framer → AnimationController)
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Signature of a custom step-indicator builder, mirroring the original's
/// `renderStepIndicator({ step, currentStep, onStepClick })`.
/// [step] is the 1-based index of the indicator being built; call
/// [onStepClick] with a step number to jump there (direction is inferred).
typedef StepFlowIndicatorBuilder =
    Widget Function(int step, int currentStep, void Function(int step) onStepClick);

/// Multi-step card flow ported from react-bits "Stepper" (named StepFlow —
/// `Stepper` clashes with Flutter's material class).
///
/// A rounded, bordered card with a row of tappable step indicators joined by
/// animated connector lines, a direction-aware sliding content area whose
/// height follows the active step, and a Back / Continue footer. After the
/// last step is completed the content collapses and the footer hides.
///
/// Steps are arbitrary widgets; step numbers are 1-based like the original.
class StepFlow extends StatefulWidget {
  const StepFlow({
    super.key,
    required this.steps,
    this.initialStep = 1,
    this.onStepChange,
    this.onFinalStepCompleted,
    this.backButtonText = 'Back',
    this.nextButtonText = 'Continue',
    this.completeButtonText = 'Complete',
    this.disableStepIndicators = false,
    this.renderStepIndicator,
    this.activeColor = const Color(0xFF5227FF),
    this.inactiveColor = const Color(0xFF222222),
    this.inactiveTextColor = const Color(0xFFA3A3A3),
    this.activeDotColor = const Color(0xFF120F17),
    this.checkColor = Colors.black,
    this.connectorColor = const Color(0xFF525252),
    this.nextButtonColor = const Color(0xFF22C55E),
    this.backTextColor = const Color(0xFFA3A3A3),
    this.borderColor = const Color(0xFF222222),
    this.backgroundColor,
    this.borderRadius = 32,
    this.maxWidth = 448,
  });

  /// Step contents, in order. Step numbers are 1-based (step 1 = steps[0]).
  final List<Widget> steps;

  /// 1-based step shown first.
  final int initialStep;

  /// Called with the new (1-based) step after every change that lands on a
  /// real step. Not called when the flow completes — see
  /// [onFinalStepCompleted].
  final ValueChanged<int>? onStepChange;

  /// Called once when "Complete" is pressed on the last step.
  final VoidCallback? onFinalStepCompleted;

  final String backButtonText;
  final String nextButtonText;

  /// Label of the footer button on the last step ('Complete' in the
  /// original, hardcoded there).
  final String completeButtonText;

  /// True = indicators are dimmed to 50% and not tappable.
  final bool disableStepIndicators;

  /// Replaces the default 32px circle indicator. [disableStepIndicators]
  /// does not apply to custom indicators (same as the original).
  final StepFlowIndicatorBuilder? renderStepIndicator;

  /// Active/complete indicator background + connector fill (#5227FF).
  final Color activeColor;

  /// Inactive indicator background (#222).
  final Color inactiveColor;

  /// Inactive indicator number color (#a3a3a3).
  final Color inactiveTextColor;

  /// 12px inner dot of the active indicator (#120F17).
  final Color activeDotColor;

  /// Checkmark stroke of completed indicators (black in the original).
  final Color checkColor;

  /// Connector track color (Tailwind neutral-600).
  final Color connectorColor;

  /// Next/Complete pill background (Tailwind green-500).
  final Color nextButtonColor;

  /// Back button text color (Tailwind neutral-400).
  final Color backTextColor;

  /// 1px card border (#222).
  final Color borderColor;

  /// Card fill; null = transparent (the original card has no background).
  final Color? backgroundColor;

  /// Card corner radius (Tailwind rounded-4xl = 32).
  final double borderRadius;

  /// Card max width (Tailwind max-w-md = 448).
  final double maxWidth;

  @override
  State<StepFlow> createState() => _StepFlowState();
}

class _StepFlowState extends State<StepFlow> with SingleTickerProviderStateMixin {
  // Original timings: indicator color 0.3s, slide/height/connector 0.4s,
  // checkmark 0.3s after a 0.1s delay.
  static const Duration _indicatorDuration = Duration(milliseconds: 300);
  static const Duration _slideDuration = Duration(milliseconds: 400);

  late int _currentStep = widget.initialStep;

  /// +1 = moving forward, -1 = moving back, 0 = no move yet.
  int _direction = 0;

  /// Previous step's widget while the slide transition runs, else null.
  Widget? _outgoing;

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: _slideDuration,
    value: 1.0, // no enter animation on first build (initial={false})
  );
  late final Animation<double> _slideCurve = CurvedAnimation(
    parent: _slide,
    curve: Curves.easeInOut,
  );

  int get _totalSteps => widget.steps.length;
  bool get _isCompleted => _currentStep > _totalSteps;
  bool get _isLastStep => _currentStep == _totalSteps;

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _goTo(int newStep, int direction) {
    final int oldStep = _currentStep;
    setState(() {
      _direction = direction;
      _outgoing = (oldStep >= 1 && oldStep <= _totalSteps)
          ? widget.steps[oldStep - 1]
          : null;
      _currentStep = newStep;
    });
    // TickerFuture never completes if the controller is disposed mid-flight,
    // so no dangling setState after dispose.
    _slide.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _outgoing = null);
    });
    if (newStep > _totalSteps) {
      widget.onFinalStepCompleted?.call();
    } else {
      widget.onStepChange?.call(newStep);
    }
  }

  void _handleBack() {
    if (_currentStep > 1) _goTo(_currentStep - 1, -1);
  }

  void _handleNext() {
    if (!_isLastStep) _goTo(_currentStep + 1, 1);
  }

  void _handleComplete() => _goTo(_totalSteps + 1, 1);

  void _onStepClick(int step) {
    if (step == _currentStep) return;
    _goTo(step, step > _currentStep ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: widget.borderColor),
        // Tailwind shadow-xl.
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 20),
            blurRadius: 25,
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 8),
            blurRadius: 10,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildHeader(),
          _buildContent(),
          if (!_isCompleted) _buildFooter(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(32), // p-8
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _totalSteps; i++) ...<Widget>[
            widget.renderStepIndicator != null
                ? widget.renderStepIndicator!(i + 1, _currentStep, _onStepClick)
                : _buildIndicator(i + 1),
            if (i < _totalSteps - 1)
              Expanded(child: _buildConnector(isComplete: _currentStep > i + 1)),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicator(int step) {
    final bool isActive = _currentStep == step;
    final bool isComplete = _currentStep > step;

    final Widget inner;
    if (isComplete) {
      inner = _AnimatedCheck(color: widget.checkColor); // draws itself on mount
    } else if (isActive) {
      inner = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.activeDotColor,
        ),
      );
    } else {
      inner = Text(
        '$step',
        style: TextStyle(
          color: widget.inactiveTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final Widget circle = AnimatedContainer(
      duration: _indicatorDuration,
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive || isComplete ? widget.activeColor : widget.inactiveColor,
      ),
      child: inner,
    );

    if (widget.disableStepIndicators) {
      // pointer-events-none + opacity-50
      return Opacity(opacity: 0.5, child: circle);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isActive ? null : () => _onStepClick(step),
      child: circle,
    );
  }

  Widget _buildConnector({required bool isComplete}) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8), // mx-2
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.connectorColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedFractionallySizedBox(
        duration: _slideDuration,
        curve: Curves.easeInOut,
        alignment: Alignment.centerLeft,
        widthFactor: isComplete ? 1.0 : 0.0,
        heightFactor: 1.0,
        child: ColoredBox(color: widget.activeColor),
      ),
    );
  }

  // --------------------------------------------------------------- content

  Widget _buildContent() {
    // Original: relative overflow-hidden container whose height springs to
    // the incoming child's height (0 when completed); old and new children
    // overlap absolutely during the slide. Here the incoming child stays in
    // flow so AnimatedSize can measure it, the outgoing one is Positioned.
    return ClipRect(
      child: AnimatedSize(
        duration: _slideDuration,
        curve: Curves.easeOutBack, // spring(duration: 0.4) stand-in
        alignment: Alignment.topCenter,
        child: _isCompleted && _outgoing == null
            ? const SizedBox(width: double.infinity, height: 0)
            : Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  if (_outgoing != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: IgnorePointer(child: _buildExiting(_outgoing!)),
                    ),
                  if (!_isCompleted)
                    _buildEntering(widget.steps[_currentStep - 1])
                  else
                    const SizedBox(width: double.infinity, height: 0),
                ],
              ),
      ),
    );
  }

  Widget _wrapStep(Widget step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32), // px-8
      child: SizedBox(width: double.infinity, child: step),
    );
  }

  /// enter: x from (dir >= 0 ? -100% : 100%) → 0, opacity 0 → 1.
  Widget _buildEntering(Widget step) {
    return AnimatedBuilder(
      animation: _slideCurve,
      child: _wrapStep(step),
      builder: (BuildContext context, Widget? child) {
        final double t = _slideCurve.value;
        final double beginX = _direction >= 0 ? -1.0 : 1.0;
        return Opacity(
          opacity: t,
          child: FractionalTranslation(
            translation: Offset(beginX * (1 - t), 0),
            child: child,
          ),
        );
      },
    );
  }

  /// exit: x 0 → (dir >= 0 ? 50% : -50%), opacity 1 → 0.
  Widget _buildExiting(Widget step) {
    return AnimatedBuilder(
      animation: _slideCurve,
      child: _wrapStep(step),
      builder: (BuildContext context, Widget? child) {
        final double t = _slideCurve.value;
        final double endX = _direction >= 0 ? 0.5 : -0.5;
        return Opacity(
          opacity: 1 - t,
          child: FractionalTranslation(
            translation: Offset(endX * t, 0),
            child: child,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- footer

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32), // px-8 pb-8 + mt-10
      child: Row(
        mainAxisAlignment: _currentStep != 1
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        children: <Widget>[
          if (_currentStep != 1)
            TextButton(
              onPressed: _handleBack,
              style: TextButton.styleFrom(
                foregroundColor: widget.backTextColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(widget.backButtonText),
            ),
          Material(
            color: widget.nextButtonColor,
            borderRadius: BorderRadius.circular(999),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _isLastStep ? _handleComplete : _handleNext,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text(
                  _isLastStep ? widget.completeButtonText : widget.nextButtonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4, // tracking-tight
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 16px checkmark that draws its stroke on mount (pathLength 0 → 1, 0.3s
/// easeOut after a 0.1s delay — modeled as a 0.4s tween with an Interval).
class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      builder: (BuildContext context, double progress, Widget? _) {
        return CustomPaint(
          size: const Size(16, 16), // h-4 w-4
          painter: _CheckPainter(progress: progress, color: color),
        );
      },
    );
  }
}

/// Draws the SVG path "M5 13l4 4L19 7" (24x24 viewBox, stroke 2, round
/// cap/join) trimmed to [progress] via PathMetrics.extractPath.
class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final double sx = size.width / 24;
    final double sy = size.height / 24;
    final Path path = Path()
      ..moveTo(5 * sx, 13 * sy)
      ..lineTo(9 * sx, 17 * sy)
      ..lineTo(19 * sx, 7 * sy);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * sx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (progress >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    final Path partial = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      partial.addPath(
        metric.extractPath(0, metric.length * progress),
        Offset.zero,
      );
    }
    canvas.drawPath(partial, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
