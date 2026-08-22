/// Calm Paywall
/// Origin: adapted — port of PaywallScreen.tsx from mortspace's FeralUI
/// calm-app screen set (React + motion), rebuilt with Flutter widgets.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Curve _soft = Cubic(.22, 1, .3, 1);
const Curve _pop = Cubic(.34, 1.2, .5, 1);

/// Warm sunset palette (the upstream `--sc-*` custom properties).
class CalmPaywallPalette {
  const CalmPaywallPalette({
    this.bg = const Color(0xFFF7F1EA),
    this.g1 = const Color(0xFFF3DDC8),
    this.g2 = const Color(0xFFDFA17C),
    this.g3 = const Color(0xFFB8674C),
    this.orbA = const Color(0xFFFFF0E2),
    this.orbB = const Color(0xFFFBC9A8),
    this.orbC = const Color(0xFFF0A983),
    this.orbD = const Color(0xFFE0916C),
    this.orbShadow = const Color(0xFFD68060),
    this.orbInset = const Color(0xFFC66A4E),
    this.orbFace = const Color(0xFF7C4630),
    this.orbBlush = const Color(0x70F07E5F),
    this.orbHalo = const Color(0x80F6AC84),
    this.ink = const Color(0xFF5F351F),
    this.deep = const Color(0xFFB3603F),
    this.btnA = const Color(0xFFCD7C58),
    this.btnB = const Color(0xFFB3603F),
    this.shadow = const Color(0xFF783728),
    this.accent = const Color(0xFFC67F68),
    this.btnInk = const Color(0xFFA85A44),
  });

  final Color bg, g1, g2, g3;
  final Color orbA, orbB, orbC, orbD, orbShadow, orbInset, orbFace, orbBlush,
      orbHalo;
  final Color ink, deep, btnA, btnB, shadow, accent, btnInk;
}

/// Soft-sell paywall: the small breathing orb on a lightened sunset
/// gradient, a frosted feature list with tick badges, a price pill and the
/// trial CTA. Fills whatever box it is given (designed at 390x844).
class CalmPaywallScreen extends StatefulWidget {
  const CalmPaywallScreen({
    super.key,
    this.onStart,
    this.onRestore,
    this.palette = const CalmPaywallPalette(),
    this.title = 'A little more space.',
    this.body = 'Unlock everything, at your own pace.',
    this.features = const [
      'Unlimited daily check-ins',
      'Guided wind-downs',
      'Gentle mood insights',
      'Calm, ad-free space',
    ],
    this.priceLead = '7 days free',
    this.priceTail = ', then \$4.99/month',
    this.buttonLabel = 'Start free trial',
    this.restoreLabel = 'Restore purchase',
    this.animate = true,
  });

  final VoidCallback? onStart;
  final VoidCallback? onRestore;
  final CalmPaywallPalette palette;
  final String title;
  final String body;
  final List<String> features;
  final String priceLead;
  final String priceTail;
  final String buttonLabel;
  final String restoreLabel;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmPaywallScreen> createState() => _CalmPaywallScreenState();
}

class _CalmPaywallScreenState extends State<CalmPaywallScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  bool get _still =>
      !widget.animate || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _t.value = e.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _ticker.stop();
      _t.value = 99;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  double _ease(double t, double t0, double dur, [Curve c = _soft]) =>
      c.transform(((t - t0) / dur).clamp(0.0, 1.0));

  Widget _enter(double t, double t0, double dur,
      {double dy = 0, required Widget child}) {
    final double e = _ease(t, t0, dur);
    if (e >= 1) return child;
    return Opacity(
      opacity: e,
      child: dy == 0
          ? child
          : Transform.translate(offset: Offset(0, dy * (1 - e)), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CalmPaywallPalette p = widget.palette;
    return ClipRect(
      child: LayoutBuilder(builder: (context, box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        return ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, t, _) {
            final double gradIn = _ease(t, .25, .9);
            final double orbIn = _ease(t, .1, .8, _pop);
            final double breathe =
                _still ? 0 : .5 - .5 * math.cos(2 * math.pi * (t / 4.2));
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: p.bg),
                Transform.translate(
                  offset: Offset(0, h * (1 - gradIn)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          p.g1.withValues(alpha: 0),
                          p.g1,
                          Color.lerp(Colors.white, p.g2, .74)!,
                          Color.lerp(Colors.white, p.g3, .80)!,
                        ],
                        stops: const [0, .3, .64, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: h * .09,
                  left: w / 2 - 52,
                  width: 104,
                  height: 104,
                  child: Opacity(
                    opacity: orbIn.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - orbIn)),
                      child: Transform.scale(
                        scale: .55 + .45 * orbIn,
                        child: _PaywallOrb(palette: p, breathe: breathe),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 0, 26, 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _enter(
                          t,
                          .35,
                          .55,
                          dy: 14,
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: p.ink,
                              fontSize: 25.6,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _enter(
                          t,
                          .44,
                          .55,
                          dy: 12,
                          child: Text(
                            widget.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: p.ink.withValues(alpha: .78),
                              fontSize: 13.6,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _enter(
                          t,
                          .5,
                          .5,
                          dy: 18,
                          child: _Frost(
                            radius: 18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xC2FFFFFF),
                                    Color(0x99FFFFFF),
                                  ],
                                ),
                                border: Border.all(
                                    color: const Color(0x47FFFFFF)),
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(0, 14),
                                    blurRadius: 30,
                                    spreadRadius: -20,
                                    color:
                                        p.shadow.withValues(alpha: .45),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0;
                                      i < widget.features.length;
                                      i++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: i == 0 ? 0 : 12),
                                      child: _enter(
                                        t,
                                        .56 + i * .045,
                                        .35,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  begin:
                                                      Alignment.topCenter,
                                                  end: Alignment
                                                      .bottomCenter,
                                                  colors: [p.btnA, p.btnB],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    offset:
                                                        const Offset(0, 3),
                                                    blurRadius: 7,
                                                    spreadRadius: -3,
                                                    color: p.shadow
                                                        .withValues(
                                                            alpha: .55),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                  Icons.check_rounded,
                                                  size: 14,
                                                  color: Colors.white),
                                            ),
                                            const SizedBox(width: 11),
                                            Expanded(
                                              child: Text(
                                                widget.features[i],
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: p.ink,
                                                  fontSize: 14.4,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _enter(
                          t,
                          .78,
                          .4,
                          dy: 10,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: .68),
                              ),
                              child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                    text: widget.priceLead,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: p.deep,
                                    ),
                                  ),
                                  TextSpan(text: widget.priceTail),
                                ]),
                                style: TextStyle(
                                  color: p.ink.withValues(alpha: .85),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _enter(
                          t,
                          .86,
                          .45,
                          dy: 12,
                          child: _PressScale(
                            onTap: widget.onStart,
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Color.lerp(
                                        Colors.white, p.accent, .09)!,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(0, 14),
                                    blurRadius: 28,
                                    spreadRadius: -14,
                                    color:
                                        p.shadow.withValues(alpha: .55),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.buttonLabel,
                                style: TextStyle(
                                  color: p.btnInk,
                                  fontSize: 15.7,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _enter(
                          t,
                          .96,
                          .4,
                          child: _PressScale(
                            onTap: widget.onRestore,
                            child: Text(
                              widget.restoreLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xEBFFFFFF),
                                fontSize: 13.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

/// The same breathing orb mascot as the welcome screen, smaller.
class _PaywallOrb extends StatelessWidget {
  const _PaywallOrb({required this.palette, required this.breathe});
  final CalmPaywallPalette palette;
  final double breathe;

  @override
  Widget build(BuildContext context) {
    final CalmPaywallPalette p = palette;
    return Transform.translate(
      offset: Offset(0, -1.5 * breathe),
      child: Transform.scale(
        scale: 1 + .055 * breathe,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: -21,
              top: -21,
              right: -21,
              bottom: -21,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [p.orbHalo, p.orbHalo.withValues(alpha: 0)],
                    stops: const [0, .62],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              left: 8,
              top: 8,
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-.2, -.36),
                    radius: .95,
                    colors: [p.orbA, p.orbB, p.orbC, p.orbD],
                    stops: const [0, .46, .74, .96],
                  ),
                  border: Border.all(color: const Color(0x59FFFFFF)),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 18),
                      blurRadius: 38,
                      spreadRadius: -10,
                      color: p.orbShadow.withValues(alpha: .55),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .5),
                        Colors.white.withValues(alpha: 0),
                        p.orbInset.withValues(alpha: 0),
                        p.orbInset.withValues(alpha: .26),
                      ],
                      stops: const [0, .3, .72, 1],
                    ),
                  ),
                ),
              ),
            ),
            for (final bool left in const [true, false])
              Positioned(
                top: 104 * .505,
                left: left ? 104 * .22 : null,
                right: left ? null : 104 * .22,
                width: 10.4,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: p.orbBlush.withValues(alpha: p.orbBlush.a * .55),
                    boxShadow: [BoxShadow(color: p.orbBlush, blurRadius: 4)],
                  ),
                ),
              ),
            Positioned.fill(
              child: CustomPaint(painter: _PaywallFacePainter(p.orbFace)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallFacePainter extends CustomPainter {
  const _PaywallFacePainter(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 100;
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.6 * s
      ..strokeCap = StrokeCap.round
      ..color = ink;
    canvas.drawPath(
        Path()
          ..moveTo(31 * s, 46 * s)
          ..cubicTo(34.5 * s, 51.2 * s, 39.5 * s, 51.2 * s, 43 * s, 46 * s),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(57 * s, 46 * s)
          ..cubicTo(60.5 * s, 51.2 * s, 65.5 * s, 51.2 * s, 69 * s, 46 * s),
        p);
  }

  @override
  bool shouldRepaint(_PaywallFacePainter old) => old.ink != ink;
}

/// Frosted-glass backdrop (the upstream `.glass` fallback look: blur 3 + a
/// bright inner edge).
class _Frost extends StatelessWidget {
  const _Frost({required this.radius, required this.child});
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: child,
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .97 : 1,
        duration: const Duration(milliseconds: 220),
        curve: const Cubic(.34, 1.56, .64, 1),
        child: widget.child,
      ),
    );
  }
}
