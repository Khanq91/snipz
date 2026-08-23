/// Calm Email
/// Origin: adapted — port of EmailScreen.tsx from mortspace's FeralUI
/// calm-app screen set (React + motion), rebuilt with Flutter widgets.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Curve _soft = Cubic(.22, 1, .3, 1);

/// Warm sunset palette (the upstream `--sc-*` custom properties).
class CalmEmailPalette {
  const CalmEmailPalette({
    this.bg = const Color(0xFFF9F0E4),
    this.glowA = const Color(0xFFC66E4A),
    this.glowB = const Color(0xFFDB8F69),
    this.glowC = const Color(0xFFEEB491),
    this.ink = const Color(0xFF6E3D28),
    this.ink2 = const Color(0xFF4F3120),
    this.deep = const Color(0xFFB3603F),
    this.accent = const Color(0xFFC67F68),
    this.btnA = const Color(0xFFCD7C58),
    this.btnB = const Color(0xFFB3603F),
    this.shadow = const Color(0xFF783C23),
  });

  final Color bg,
      glowA,
      glowB,
      glowC,
      ink,
      ink2,
      deep,
      accent,
      btnA,
      btnB,
      shadow;
}

/// Email sign-in form: frosted fields with focus glow, a warm CTA that
/// enables once the form is plausible, and a soft glow floor. Fills
/// whatever box it is given (designed at 390x844).
class CalmEmailScreen extends StatefulWidget {
  const CalmEmailScreen({
    super.key,
    this.onBack,
    this.onSignIn,
    this.onForgot,
    this.onCreate,
    this.palette = const CalmEmailPalette(),
    this.title = 'Welcome back.',
    this.body = 'Good to see you again.',
    this.animate = true,
  });

  final VoidCallback? onBack;
  final VoidCallback? onSignIn;
  final VoidCallback? onForgot;
  final VoidCallback? onCreate;
  final CalmEmailPalette palette;
  final String title;
  final String body;

  /// False renders the settled end state with no ticker (thumbnails, tests).
  final bool animate;

  @override
  State<CalmEmailScreen> createState() => _CalmEmailScreenState();
}

class _CalmEmailScreenState extends State<CalmEmailScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  bool get _still =>
      !widget.animate || MediaQuery.maybeDisableAnimationsOf(context) == true;

  bool get _ready => _email.text.contains('@') && _pass.text.length >= 6;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _t.value = e.inMicroseconds / 1e6);
    for (final Listenable l in [_email, _pass, _emailFocus, _passFocus]) {
      l.addListener(_onForm);
    }
  }

  void _onForm() => setState(() {});

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
    _email.dispose();
    _pass.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  double _ease(double t, double t0, double dur) =>
      _soft.transform(((t - t0) / dur).clamp(0.0, 1.0));

  Widget _enter(
    double t,
    double t0,
    double dur, {
    double dy = 0,
    required Widget child,
  }) {
    final double e = _ease(t, t0, dur);
    if (e >= 1) return child;
    return Opacity(
      opacity: e,
      child: dy == 0
          ? child
          : Transform.translate(offset: Offset(0, dy * (1 - e)), child: child),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focus,
    required IconData icon,
    required String hint,
    bool obscure = false,
  }) {
    final CalmEmailPalette p = widget.palette;
    final bool focused = focus.hasFocus;
    return _CssShadow(
      radius: 16,
      shadowOffset: const Offset(0, 12),
      blur: 26,
      spread: -18,
      color: p.shadow.withValues(alpha: focused ? .34 : .3),
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: focused
              ? const [Color(0xD9FFFDF9), Color(0xB8FFFBF5)]
              : const [Color(0xA8FFFCF6), Color(0x80FFFAF2)],
        ),
        border: Border.all(
          color: focused ? p.accent : p.shadow.withValues(alpha: .1),
          width: focused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: focused ? p.deep : p.ink.withValues(alpha: .52),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              obscureText: obscure,
              autocorrect: false,
              style: TextStyle(
                color: p.ink2,
                fontSize: 15.2,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: p.ink.withValues(alpha: .48),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CalmEmailPalette p = widget.palette;
    return ClipRect(
      // TextField needs a Material ancestor; carry our own so the screen
      // works in any host
      child: Material(
        type: MaterialType.transparency,
        child: ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, t, _) {
            final double glowIn = _ease(t, .08, .9);
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: p.bg),
                Opacity(
                  opacity: (.6 * glowIn).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 60 * (1 - glowIn)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, 1.2),
                          radius: 1.1,
                          colors: [
                            p.glowA.withValues(alpha: .48),
                            p.glowB.withValues(alpha: .30),
                            p.glowC.withValues(alpha: .16),
                            p.glowC.withValues(alpha: 0),
                          ],
                          stops: const [0, .4, .62, .82],
                        ),
                      ),
                    ),
                  ),
                ),
                // back button
                Positioned(
                  top: 54,
                  left: 18,
                  child: _enter(
                    t,
                    .3,
                    .45,
                    child: _PressScale(
                      pressed: .88,
                      onTap: widget.onBack,
                      child: _CssShadow(
                        radius: 19,
                        shadowOffset: const Offset(0, 6),
                        blur: 18,
                        spread: -10,
                        color: p.shadow.withValues(alpha: .28),
                        child: _Frost(
                        radius: 19,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .55),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 15,
                            color: p.deep,
                          ),
                        ),
                      ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 110, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _enter(
                        t,
                        .2,
                        .55,
                        dy: 12,
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            color: p.ink,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      _enter(
                        t,
                        .3,
                        .5,
                        dy: 10,
                        child: Text(
                          widget.body,
                          style: TextStyle(
                            color: p.ink.withValues(alpha: .68),
                            fontSize: 13.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _enter(
                        t,
                        .42,
                        .5,
                        dy: 12,
                        child: _field(
                          controller: _email,
                          focus: _emailFocus,
                          icon: Icons.mail_outline_rounded,
                          hint: 'Email',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _enter(
                        t,
                        .5,
                        .5,
                        dy: 12,
                        child: _field(
                          controller: _pass,
                          focus: _passFocus,
                          icon: Icons.lock_outline_rounded,
                          hint: 'Password',
                          obscure: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _enter(
                        t,
                        .6,
                        .45,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _PressScale(
                            onTap: widget.onForgot,
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: p.deep,
                                fontSize: 12.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _enter(
                        t,
                        .68,
                        .5,
                        dy: 10,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _ready ? 1 : .45,
                          child: _PressScale(
                            onTap: _ready ? widget.onSignIn : null,
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [p.btnA, p.btnB],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(0, 14),
                                    blurRadius: 28,
                                    spreadRadius: -16,
                                    color: p.shadow.withValues(alpha: .6),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.7,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _enter(
                        t,
                        .8,
                        .45,
                        child: Center(
                          child: _PressScale(
                            onTap: widget.onCreate,
                            child: Text.rich(
                              TextSpan(
                                text: 'New here? ',
                                children: [
                                  TextSpan(
                                    text: 'Create an account',
                                    style: TextStyle(
                                      color: p.deep,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                color: p.ink.withValues(alpha: .62),
                                fontSize: 12.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Frosted-glass backdrop (the upstream `.glass` fallback: blur 3).
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
  const _PressScale({required this.child, this.onTap, this.pressed = .97});
  final Widget child;
  final VoidCallback? onTap;
  final double pressed;

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
        scale: _down ? widget.pressed : 1,
        duration: const Duration(milliseconds: 220),
        curve: const Cubic(.34, 1.56, .64, 1),
        child: widget.child,
      ),
    );
  }
}

/// CSS-style outer drop shadow. Flutter's BoxShadow also paints *under* the
/// box, which shows straight through the translucent glass fills here and
/// muddies them — CSS clips the border-box region out, so this painter does
/// the same: blurred rrect shifted/spread, with the box itself cut away.
class _CssShadow extends StatelessWidget {
  const _CssShadow({
    required this.radius,
    required this.shadowOffset,
    required this.blur,
    required this.spread,
    required this.color,
    required this.child,
  });

  final double radius;
  final Offset shadowOffset;
  final double blur;
  final double spread;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CssShadowPainter(
        radius: radius,
        offset: shadowOffset,
        blur: blur,
        spread: spread,
        color: color,
      ),
      child: child,
    );
  }
}

class _CssShadowPainter extends CustomPainter {
  const _CssShadowPainter({
    required this.radius,
    required this.offset,
    required this.blur,
    required this.spread,
    required this.color,
  });

  final double radius;
  final Offset offset;
  final double blur;
  final double spread;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = Offset.zero & size;
    final RRect rbox = RRect.fromRectAndRadius(box, Radius.circular(radius));
    // Keep everything inside the border box unpainted (the CSS behavior).
    final Path outside = Path()
      ..addRect(box.inflate(blur * 2 + offset.distance + spread.abs()))
      ..addRRect(rbox)
      ..fillType = PathFillType.evenOdd;
    canvas.save();
    canvas.clipPath(outside);
    final RRect shadow = RRect.fromRectAndRadius(
      box.shift(offset).inflate(spread),
      Radius.circular((radius + spread).clamp(0, double.infinity)),
    );
    canvas.drawRRect(
      shadow,
      Paint()
        ..color = color
        // CSS blur radius ≈ 2×sigma.
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CssShadowPainter old) =>
      old.radius != radius ||
      old.offset != offset ||
      old.blur != blur ||
      old.spread != spread ||
      old.color != color;
}
