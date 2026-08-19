/// GradualBlur
/// Origin: adapted — port of react-bits "GradualBlur" (stacked
/// gradient-masked CSS backdrop-filter divs) as N adjacent BackdropFilter
/// strips, since Flutter cannot gradient-mask a BackdropFilter
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Which edge the blur is strongest at (= which edge of the parent the
/// overlay is meant to sit on). Mirrors the original `position` prop.
enum GradualBlurPosition { top, bottom, left, right }

/// Progress-remap curves, ported 1:1 from the original CURVE_FUNCTIONS map.
enum GradualBlurCurve { linear, bezier, easeIn, easeOut, easeInOut }

/// Ready-made configurations, ported from the original PRESETS map
/// (rem sizes converted to logical px, 1rem = 16). Use via
/// [GradualBlur.preset]. The web-only presets (`sidebar` variants tied to
/// `page` target, `page-header`, `page-footer`) are not ported.
enum GradualBlurPreset { subtle, intense, smooth, sharp, header, footer }

/// A progressive "gradual blur" overlay: content behind it stays sharp on
/// the inner side and gets increasingly frosted toward the [position] edge.
/// Classic use: pinned over the bottom of a scrollable list.
///
/// The original stacks `divCount` full-size backdrop-filter divs, each
/// masked by a linear gradient. Flutter's [BackdropFilter] composites the
/// backdrop directly and ignores parent ShaderMask/Opacity, so a gradient
/// mask is impossible — instead this renders `divCount` **adjacent strips**
/// along the axis, each its own ClipRect + BackdropFilter with the same
/// per-step blur value the original computes.
///
/// This widget is a plain sized box ([size] thick, unbounded on the other
/// axis) that ignores pointers. Position it yourself, e.g.:
///
/// ```dart
/// Stack(children: [
///   ListView(...),
///   const Align(
///     alignment: Alignment.bottomCenter,
///     child: GradualBlur(),
///   ),
/// ])
/// ```
class GradualBlur extends StatelessWidget {
  const GradualBlur({
    super.key,
    this.position = GradualBlurPosition.bottom,
    this.size = 96,
    this.strength = 2,
    this.divCount = 5,
    this.curve = GradualBlurCurve.linear,
    this.exponential = false,
    this.opacity = 1,
  })  : assert(size > 0),
        assert(divCount > 0),
        assert(strength >= 0),
        assert(opacity >= 0 && opacity <= 1);

  /// Builds a [GradualBlur] from one of the ported presets. Any explicit
  /// parameter overrides the preset value (same merge order as the
  /// original: defaults < preset < props).
  factory GradualBlur.preset(
    GradualBlurPreset preset, {
    Key? key,
    GradualBlurPosition? position,
    double? size,
    double? strength,
    int? divCount,
    GradualBlurCurve? curve,
    bool? exponential,
    double? opacity,
  }) {
    // Defaults (mirror DEFAULT_CONFIG).
    GradualBlurPosition pPosition = GradualBlurPosition.bottom;
    double pSize = 96; // 6rem
    double pStrength = 2;
    int pDivCount = 5;
    GradualBlurCurve pCurve = GradualBlurCurve.linear;
    bool pExponential = false;
    double pOpacity = 1;

    switch (preset) {
      case GradualBlurPreset.subtle:
        pSize = 64; // 4rem
        pStrength = 1;
        pOpacity = 0.8;
        pDivCount = 3;
      case GradualBlurPreset.intense:
        pSize = 160; // 10rem
        pStrength = 4;
        pDivCount = 8;
        pExponential = true;
      case GradualBlurPreset.smooth:
        pSize = 128; // 8rem
        pCurve = GradualBlurCurve.bezier;
        pDivCount = 10;
      case GradualBlurPreset.sharp:
        pSize = 80; // 5rem
        pCurve = GradualBlurCurve.linear;
        pDivCount = 4;
      case GradualBlurPreset.header:
        pPosition = GradualBlurPosition.top;
        pSize = 128; // 8rem
        pCurve = GradualBlurCurve.easeOut;
      case GradualBlurPreset.footer:
        pPosition = GradualBlurPosition.bottom;
        pSize = 128; // 8rem
        pCurve = GradualBlurCurve.easeOut;
    }

    return GradualBlur(
      key: key,
      position: position ?? pPosition,
      size: size ?? pSize,
      strength: strength ?? pStrength,
      divCount: divCount ?? pDivCount,
      curve: curve ?? pCurve,
      exponential: exponential ?? pExponential,
      opacity: opacity ?? pOpacity,
    );
  }

  /// Edge the blur is strongest at.
  final GradualBlurPosition position;

  /// Thickness of the overlay in logical px along the blur axis (height for
  /// top/bottom, width for left/right). Replaces the original's
  /// `height`/`width` rem strings; default 96 = the original 6rem.
  final double size;

  /// Blur intensity multiplier (same unit-less number as the original).
  final double strength;

  /// Number of blur strips. More strips = smoother gradient, higher cost
  /// (each strip is one backdrop readback per frame).
  final int divCount;

  /// Remap applied to each strip's progress before computing its blur.
  final GradualBlurCurve curve;

  /// Exponential blur progression (2^(p*4)) instead of linear steps.
  final bool exponential;

  /// 0..1 fade of the blurred layer over the sharp backdrop (approximates
  /// the original's CSS `opacity` on each blur div).
  final double opacity;

  /// rem → logical px conversion used for blur sigmas (browser default
  /// 1rem = 16px; CSS blur() length and Flutter blur sigma are both the
  /// Gaussian standard deviation, so the mapping is 1:1 after this).
  static const double _pxPerRem = 16;

  double _applyCurve(double p) {
    switch (curve) {
      case GradualBlurCurve.linear:
        return p;
      case GradualBlurCurve.bezier: // smoothstep, as in the original
        return p * p * (3 - 2 * p);
      case GradualBlurCurve.easeIn:
        return p * p;
      case GradualBlurCurve.easeOut:
        return 1 - (1 - p) * (1 - p);
      case GradualBlurCurve.easeInOut:
        if (p < 0.5) {
          return 2 * p * p;
        }
        final double q = -2 * p + 2; // 1 - (-2p+2)^2 / 2, as in the original
        return 1 - q * q / 2;
    }
  }

  /// Per-strip filter — the blur formula is copied verbatim from the
  /// original (rem), then converted to logical px.
  ui.ImageFilter _filterForStrip(int i) {
    double progress = i / divCount;
    progress = _applyCurve(progress);

    final double blurRem = exponential
        ? math.pow(2, progress * 4).toDouble() * 0.0625 * strength
        : 0.0625 * (progress * divCount + 1) * strength;
    final double sigma = blurRem * _pxPerRem;

    ui.ImageFilter filter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    if (opacity < 1) {
      // CSS `opacity` on a backdrop-filter div ≈ blurred backdrop drawn
      // with scaled alpha over the sharp backdrop. ColorFilter implements
      // ImageFilter, so compose an alpha-scaling matrix onto the blur.
      filter = ui.ImageFilter.compose(
        outer: ui.ColorFilter.matrix(<double>[
          1, 0, 0, 0, 0, //
          0, 1, 0, 0, 0, //
          0, 0, 1, 0, 0, //
          0, 0, 0, opacity, 0, //
        ]),
        inner: filter,
      );
    }
    return filter;
  }

  @override
  Widget build(BuildContext context) {
    final bool vertical = position == GradualBlurPosition.top ||
        position == GradualBlurPosition.bottom;

    // Strips i = 1..divCount, weakest blur first (the original's div order).
    final List<Widget> strips = <Widget>[
      for (int i = 1; i <= divCount; i++)
        Expanded(
          child: ClipRect(
            child: BackdropFilter(
              filter: _filterForStrip(i),
              child: const SizedBox.expand(),
            ),
          ),
        ),
    ];

    // The strongest blur must sit on the [position] edge (outer edge).
    // Column/Row lay out top→bottom / left→right, so top and left need the
    // reversed order.
    final List<Widget> ordered = (position == GradualBlurPosition.top ||
            position == GradualBlurPosition.left)
        ? strips.reversed.toList()
        : strips;

    return IgnorePointer(
      child: SizedBox(
        width: vertical ? double.infinity : size,
        height: vertical ? size : double.infinity,
        child: Flex(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          children: ordered,
        ),
      ),
    );
  }
}
