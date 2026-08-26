/// ErrorShake
/// Origin: reimplemented — kinetics "Error Shake" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/material.dart';

/// A text input that can replay a short horizontal error shake on demand.
///
/// [isInvalid] controls whether the error message is visible. Increment or
/// otherwise change [shakeTrigger] for every rejected attempt so the shake can
/// be replayed even while [isInvalid] remains true.
class ErrorShake extends StatefulWidget {
  const ErrorShake({
    super.key,
    this.controller,
    this.focusNode,
    required this.isInvalid,
    required this.shakeTrigger,
    required this.errorMessage,
    this.labelText,
    this.hintText,
    this.semanticsLabel,
    this.errorSemanticsLabel,
    this.onChanged,
    this.onSubmitted,
    this.onShakeComplete,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.animate = true,
    this.duration = const Duration(milliseconds: 450),
    this.messageDuration = const Duration(milliseconds: 200),
    this.errorColor,
    this.borderColor,
    this.focusBorderColor,
    this.fillColor,
    this.textColor,
    this.labelColor,
    this.borderRadius = 12,
    this.borderWidth = 1,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 13,
    ),
    this.messageGap = 6,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Whether the error message should remain visible.
  final bool isInvalid;

  /// A controlled replay signal. Change it for every invalid attempt.
  final int shakeTrigger;

  final String errorMessage;
  final String? labelText;
  final String? hintText;
  final String? semanticsLabel;
  final String? errorSemanticsLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onShakeComplete;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;

  /// Disables all transitions and immediately settles the input when false.
  final bool animate;

  final Duration duration;
  final Duration messageDuration;
  final Color? errorColor;
  final Color? borderColor;
  final Color? focusBorderColor;
  final Color? fillColor;
  final Color? textColor;
  final Color? labelColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry contentPadding;
  final double messageGap;

  @override
  State<ErrorShake> createState() => _ErrorShakeState();
}

class _ErrorShakeState extends State<ErrorShake> with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _messageController;
  late final Animation<double> _horizontalOffset;
  late final Animation<double> _messageProgress;
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController();
    }
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }

    _shakeController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener(_handleShakeStatus);
    const shakeCurve = Cubic(.36, .07, .19, .97);
    _horizontalOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -1,
        ).chain(CurveTween(curve: shakeCurve)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -1,
          end: 2,
        ).chain(CurveTween(curve: shakeCurve)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 2,
          end: -4,
        ).chain(CurveTween(curve: shakeCurve)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -4,
          end: 4,
        ).chain(CurveTween(curve: shakeCurve)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 4,
          end: -4,
        ).chain(CurveTween(curve: shakeCurve)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -4,
          end: 4,
        ).chain(CurveTween(curve: shakeCurve)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 4,
          end: -4,
        ).chain(CurveTween(curve: shakeCurve)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -4,
          end: 2,
        ).chain(CurveTween(curve: shakeCurve)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 2,
          end: -1,
        ).chain(CurveTween(curve: shakeCurve)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -1,
          end: 0,
        ).chain(CurveTween(curve: shakeCurve)),
        weight: 10,
      ),
    ]).animate(_shakeController);

    _messageController = AnimationController(
      vsync: this,
      duration: widget.messageDuration,
      value: widget.isInvalid ? 1 : 0,
    );
    _messageProgress = CurvedAnimation(
      parent: _messageController,
      curve: Curves.ease,
      reverseCurve: Curves.ease,
    );
  }

  @override
  void didUpdateWidget(covariant ErrorShake oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      } else if (widget.controller == null) {
        _internalController = TextEditingController(
          text: oldWidget.controller!.text,
        );
      }
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      } else if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
      }
    }

    if (oldWidget.duration != widget.duration) {
      _shakeController.duration = widget.duration;
    }
    if (oldWidget.messageDuration != widget.messageDuration) {
      _messageController.duration = widget.messageDuration;
    }

    if (!widget.animate) {
      _settleShake();
      _messageController.value = widget.isInvalid ? 1 : 0;
      return;
    }

    if (oldWidget.isInvalid != widget.isInvalid) {
      if (widget.isInvalid) {
        _messageController.forward();
        _replayShake();
      } else {
        _messageController.reverse();
        _settleShake();
      }
      return;
    }

    if (widget.isInvalid && oldWidget.shakeTrigger != widget.shakeTrigger) {
      _replayShake();
    }
  }

  void _replayShake() {
    _shakeController.forward(from: 0);
  }

  void _settleShake() {
    _shakeController.stop();
    _shakeController.value = 0;
  }

  void _handleShakeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onShakeComplete?.call();
    }
  }

  @override
  void dispose() {
    _shakeController
      ..removeStatusListener(_handleShakeStatus)
      ..dispose();
    _messageController.dispose();
    _internalController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorColor = widget.errorColor ?? colorScheme.error;
    final borderColor = widget.borderColor ?? colorScheme.outlineVariant;
    final focusBorderColor = widget.focusBorderColor ?? colorScheme.primary;
    final fillColor = widget.fillColor ?? colorScheme.surface;
    final textColor = widget.textColor ?? colorScheme.onSurface;
    final labelColor = widget.labelColor ?? colorScheme.onSurfaceVariant;
    final radius = BorderRadius.circular(widget.borderRadius);

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final isShaking = widget.animate && _shakeController.isAnimating;
        final activeBorderColor = isShaking ? errorColor : borderColor;
        final activeFocusBorderColor = isShaking
            ? errorColor
            : focusBorderColor;

        return Transform.translate(
          offset: Offset(_horizontalOffset.value, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: widget.semanticsLabel,
                textField: true,
                // TextField needs a Material ancestor; hosts (gallery tiles,
                // bare overlays) don't always provide one.
                child: Material(
                  type: MaterialType.transparency,
                  child: TextField(
                    controller: _effectiveController,
                    focusNode: _effectiveFocusNode,
                    enabled: widget.enabled,
                    readOnly: widget.readOnly,
                    obscureText: widget.obscureText,
                    autocorrect: widget.autocorrect,
                    enableSuggestions: widget.enableSuggestions,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    autofillHints: widget.autofillHints,
                    textCapitalization: widget.textCapitalization,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    cursorColor: activeFocusBorderColor,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      labelText: widget.labelText,
                      hintText: widget.hintText,
                      labelStyle: TextStyle(color: labelColor),
                      floatingLabelStyle: TextStyle(
                        color: activeFocusBorderColor,
                      ),
                      filled: true,
                      fillColor: fillColor,
                      contentPadding: widget.contentPadding,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: radius,
                        borderSide: BorderSide(
                          color: activeBorderColor,
                          width: widget.borderWidth,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: radius,
                        borderSide: BorderSide(
                          color: activeFocusBorderColor,
                          width: widget.borderWidth,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: radius,
                        borderSide: BorderSide(
                          color: borderColor.withValues(alpha: .55),
                          width: widget.borderWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _messageController,
                builder: (context, child) {
                  if (!widget.isInvalid && _messageController.isDismissed) {
                    return const SizedBox.shrink();
                  }
                  return FadeTransition(
                    opacity: _messageProgress,
                    child: child,
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: widget.messageGap,
                  ),
                  child: ExcludeSemantics(
                    excluding: !widget.isInvalid,
                    child: Semantics(
                      liveRegion: true,
                      label: widget.errorSemanticsLabel ?? widget.errorMessage,
                      child: Text(
                        widget.errorMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
