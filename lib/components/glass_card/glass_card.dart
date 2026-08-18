/// GlassCard
/// Origin: original — written for the Snipz vault
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Frosted-glass card: blurs whatever sits behind it and lays a translucent
/// tint plus a hairline border on top. Needs a busy background to read as
/// glass — over a flat color it just looks like a rounded rectangle.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blurSigma = 18,
    this.tint,
    this.tintOpacity = 0.14,
    this.borderOpacity = 0.35,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double borderRadius;

  /// Backdrop blur strength. Every GlassCard costs one saveLayer per frame —
  /// keep the number of simultaneous cards low on mobile.
  final double blurSigma;

  /// Frost color. Defaults to white, which works on both dark and light
  /// backgrounds; pass a themed color to match the host app.
  final Color? tint;
  final double tintOpacity;
  final double borderOpacity;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Color base = tint ?? Colors.white;
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: base.withValues(alpha: borderOpacity)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withValues(alpha: tintOpacity + 0.08),
                base.withValues(alpha: tintOpacity * 0.5),
              ],
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
