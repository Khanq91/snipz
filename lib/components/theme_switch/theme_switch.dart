// ignore_for_file: constant_identifier_names

/// Theme Switch
/// Origin: reimplemented — ported from Pin-UI theme-switch-engine.ts (shadcn-labs)
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project to use it.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '_engine.dart';

export '_engine.dart' show LiquidTheme, SwitchEffect, ThemePalette, ThemeColors;

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// A theme-toggle button with three animated transition effects.
///
/// **Droplet** — a coloured drop falls from above, splashes and floods the scene.
/// **Rain** — raindrops fall and leave puddles that spread and merge.
/// **Diwali** — rockets burst into blooming stars that fill the scene.
///
/// All animation is ticker-driven and self-contained. No external assets.
///
/// ```dart
/// ThemeSwitchWidget(
///   theme: LiquidTheme.light,
///   onThemeChange: (t) => setState(() => _theme = t),
/// )
/// ```
class ThemeSwitchWidget extends StatefulWidget {
  const ThemeSwitchWidget({
    super.key,
    this.theme = LiquidTheme.light,
    this.onThemeChange,
    this.defaultEffect = SwitchEffect.droplet,
    this.onEffectChange,
    this.sound = true, // reserved; PCM synthesis not implemented — see README
    this.fill = false,
    this.animate = true,
    this.frozenAt,
  });

  /// The scene's theme. A change from outside lands instantly with no effect.
  final LiquidTheme theme;

  /// Called with the new theme once the transition has covered the scene.
  final void Function(LiquidTheme)? onThemeChange;

  /// Starting effect.
  final SwitchEffect defaultEffect;

  /// Called when the user picks another effect.
  final void Function(SwitchEffect)? onEffectChange;

  /// Reserved for Diwali audio. Currently a no-op — see README caveat.
  final bool sound;

  /// Expand to fill the parent instead of using the default 480 px height.
  final bool fill;

  /// Freeze all animation (for state board / thumbnails).
  final bool animate;

  /// When non-null, render a deterministic still frame at this elapsed time (s).
  final double? frozenAt;

  @override
  State<ThemeSwitchWidget> createState() => _ThemeSwitchWidgetState();
}

class _ThemeSwitchWidgetState extends State<ThemeSwitchWidget> with TickerProviderStateMixin {
  late LiquidTheme _sceneTheme;
  late SwitchEffect _effect;
  bool _busy = false;

  // For painting the effect
  final ValueNotifier<_FxSnapshot> _fxNotifier = ValueNotifier(const _FxSnapshot.empty());

  // Ticker for running effects
  Ticker? _ticker;
  Duration? _lastTick;
  double _elapsedMs = 0;

  // Active effect runner
  _EffectRunner? _runner;

  // Button spring
  double _buttonSpringAge = double.infinity;
  Ticker? _springTicker;
  Duration? _springTickerLast;
  double _buttonScale = 1.0;

  // Pre-planned Diwali
  DiwaliPlan? _preplanned;
  ({double w, double h, double x, double y})? _preplannedFor;

  // Seeded random for each animation run
  math.Random _rng = math.Random(1);

  // Layout — set by LayoutBuilder
  double _w = 480, _h = 480;
  // button center in scene coords
  Offset get _btnCenter => Offset(_w / 2, _h / 2);

  @override
  void initState() {
    super.initState();
    _sceneTheme = widget.theme;
    _effect = widget.defaultEffect;
  }

  @override
  void didUpdateWidget(ThemeSwitchWidget old) {
    super.didUpdateWidget(old);
    if (old.theme != widget.theme && !_busy) {
      setState(() => _sceneTheme = widget.theme);
    }
    if (!widget.animate) _stopAll();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _springTicker?.dispose();
    _fxNotifier.dispose();
    super.dispose();
  }

  void _stopAll() {
    _ticker?.stop();
    _lastTick = null;
    _runner = null;
    _busy = false;
    _elapsedMs = 0;
    _fxNotifier.value = const _FxSnapshot.empty();
  }

  void _startSpring() {
    _buttonSpringAge = 0;
    _springTickerLast = null;
    if (_springTicker == null) {
      _springTicker = createTicker(_onSpringTick)..start();
    } else if (!_springTicker!.isActive) {
      _springTicker!.start();
    }
  }

  void _onSpringTick(Duration elapsed) {
    final Duration prev = _springTickerLast ?? Duration.zero;
    _springTickerLast = elapsed;
    final double dt = ((elapsed - prev).inMicroseconds / 1e6).clamp(0.0, 0.064);
    _buttonSpringAge += dt;
    final double s = ButtonSpring.scale(_buttonSpringAge);
    setState(() => _buttonScale = s);
    if (_buttonSpringAge > 1.5) {
      _springTicker!.stop();
      _springTickerLast = null;
      setState(() => _buttonScale = 1.0);
    }
  }

  void _onToggle() {
    if (_busy || !widget.animate) {
      // instant switch when no animation
      final LiquidTheme next = _sceneTheme == LiquidTheme.light ? LiquidTheme.dark : LiquidTheme.light;
      setState(() => _sceneTheme = next);
      widget.onThemeChange?.call(next);
      return;
    }
    _startSpring();
    _beginEffect();
  }

  void _beginEffect() {
    _stopAll();
    _busy = true;
    _elapsedMs = 0;
    _rng = math.Random(DateTime.now().millisecondsSinceEpoch);

    final LiquidTheme next = _sceneTheme == LiquidTheme.light ? LiquidTheme.dark : LiquidTheme.light;

    _EffectRunner runner;
    switch (_effect) {
      case SwitchEffect.droplet:
        runner = _DropletRunner(next: next, btnCenter: _btnCenter, w: _w, h: _h);
      case SwitchEffect.rain:
        runner = _RainRunner(next: next, btnCenter: _btnCenter, w: _w, h: _h, rng: _rng);
      case SwitchEffect.diwali:
        DiwaliPlan? plan;
        final pre = _preplanned;
        final preFor = _preplannedFor;
        if (pre != null && preFor != null && preFor.w == _w && preFor.h == _h &&
            (_btnCenter.dx - preFor.x).abs() < 0.5 && (_btnCenter.dy - preFor.y).abs() < 0.5) {
          plan = pre;
        }
        plan ??= planDiwali(_w, _h, _btnCenter.dx, _btnCenter.dy, _rng);
        _preplanned = null;
        _preplannedFor = null;
        runner = _DiwaliRunner(next: next, plan: plan, btnCenter: _btnCenter, w: _w, h: _h, rng: math.Random(DateTime.now().millisecondsSinceEpoch + 1));
    }

    _runner = runner;

    _ticker = createTicker(_onEffectTick)..start();
  }

  void _onEffectTick(Duration elapsed) {
    final Duration prev = _lastTick ?? Duration.zero;
    _lastTick = elapsed;
    final double dt = ((elapsed - prev).inMicroseconds / 1e6).clamp(0.0, 0.064);
    _elapsedMs += dt * 1000;

    final _EffectRunner? runner = _runner;
    if (runner == null) return;

    final _EffectResult result = runner.tick(_elapsedMs, dt);
    _fxNotifier.value = result.snapshot;

    // Check progressive theme updates on controls
    for (final _FloodTarget tg in result.floodTargets) {
      if (!tg.done && result.snapshot.floodCoversPoint(tg.position)) {
        tg.done = true;
        // We don't have per-control theme in Flutter widget tree — commit immediately when button is covered
      }
    }

    if (result.commit) {
      _ticker?.stop();
      _lastTick = null;
      setState(() {
        _sceneTheme = runner.next;
        _busy = false;
      });
      _fxNotifier.value = const _FxSnapshot.empty();
      _runner = null;
      widget.onThemeChange?.call(runner.next);
    }
  }

  void _onEffectChanged(SwitchEffect e) {
    setState(() => _effect = e);
    widget.onEffectChange?.call(e);
    // Pre-plan Diwali
    if (e == SwitchEffect.diwali) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted || _busy) return;
        _preplanned = planDiwali(_w, _h, _btnCenter.dx, _btnCenter.dy, math.Random(42));
        _preplannedFor = (w: _w, h: _h, x: _btnCenter.dx, y: _btnCenter.dy);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return LayoutBuilder(builder: (context, constraints) {
      final double containerW = constraints.maxWidth;
      final double containerH = widget.fill ? constraints.maxHeight : 480.0;

      if (_w != containerW || _h != containerH) {
        // Schedule after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() { _w = containerW; _h = containerH; });
        });
      }

      final ThemePalette tc = ThemeColors.of(_sceneTheme);
      final Color bg = Color(tc.bg);
      final double containerActualH = widget.fill ? double.infinity : 480.0;

      return Container(
        width: double.infinity,
        height: containerActualH == double.infinity ? null : containerActualH,
        constraints: widget.fill ? const BoxConstraints.expand() : BoxConstraints.tightFor(height: 480),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: widget.fill ? null : BorderRadius.circular(24),
        ),
        clipBehavior: Clip.hardEdge,
        child: _ThemeSwitchContent(
          sceneTheme: _sceneTheme,
          effect: _effect,
          buttonScale: _buttonScale,
          fxNotifier: _fxNotifier,
          onToggle: reduced ? null : _onToggle,
          onToggleReduced: () {
            final LiquidTheme next = _sceneTheme == LiquidTheme.light ? LiquidTheme.dark : LiquidTheme.light;
            setState(() => _sceneTheme = next);
            widget.onThemeChange?.call(next);
          },
          onEffectChanged: _onEffectChanged,
          isReducedMotion: reduced,
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content widget (separated to keep build() clean)
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeSwitchContent extends StatelessWidget {
  const _ThemeSwitchContent({
    required this.sceneTheme,
    required this.effect,
    required this.buttonScale,
    required this.fxNotifier,
    required this.onToggle,
    required this.onToggleReduced,
    required this.onEffectChanged,
    required this.isReducedMotion,
  });

  final LiquidTheme sceneTheme;
  final SwitchEffect effect;
  final double buttonScale;
  final ValueNotifier<_FxSnapshot> fxNotifier;
  final VoidCallback? onToggle;
  final VoidCallback onToggleReduced;
  final void Function(SwitchEffect) onEffectChanged;
  final bool isReducedMotion;

  @override
  Widget build(BuildContext context) {
    final ThemePalette tc = ThemeColors.of(sceneTheme);
    final Color btnColor = Color(tc.btn);
    final Color iconColor = Color(tc.icon);
    final Color segBg = Color(tc.segBg);
    final Color segThumb = Color(tc.segThumb);
    final Color segText = Color(tc.segText);
    final Color segActive = Color(tc.segActive);

    final VoidCallback effectiveToggle = isReducedMotion ? onToggleReduced : (onToggle ?? onToggleReduced);

    return Stack(
      children: [
        // FX layer (behind controls but above background)
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<_FxSnapshot>(
              valueListenable: fxNotifier,
              builder: (_, snap, child) => CustomPaint(
                painter: _FxPainter(snapshot: snap),
              ),
            ),
          ),
        ),
        // Toggle button (center)
        Align(
          alignment: Alignment.center,
          child: Transform.scale(
            scale: buttonScale,
            child: GestureDetector(
              onTap: effectiveToggle,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: btnColor, width: 1),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Moon (light theme → press for dark)
                    AnimatedOpacity(
                      opacity: sceneTheme == LiquidTheme.light ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 450),
                        transformAlignment: Alignment.center,
                        transform: sceneTheme == LiquidTheme.light
                            ? Matrix4.identity()
                            : (Matrix4.rotationZ(-math.pi / 2)..scaleByDouble(0.6, 0.6, 1.0, 1.0)),
                        child: _MoonIcon(color: iconColor),
                      ),
                    ),
                    // Sun (dark theme → press for light)
                    AnimatedOpacity(
                      opacity: sceneTheme == LiquidTheme.dark ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 450),
                        transformAlignment: Alignment.center,
                        transform: sceneTheme == LiquidTheme.dark
                            ? Matrix4.identity()
                            : (Matrix4.rotationZ(math.pi / 2)..scaleByDouble(0.6, 0.6, 1.0, 1.0)),
                        child: _SunIcon(color: iconColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Segmented control (bottom)
        Positioned(
          bottom: 28,
          left: 0,
          right: 0,
          child: Center(
            child: _SegmentedControl(
              selected: effect,
              onChanged: onEffectChanged,
              segBg: segBg,
              segThumb: segThumb,
              segText: segText,
              segActive: segActive,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segmented control
// ─────────────────────────────────────────────────────────────────────────────

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.selected,
    required this.onChanged,
    required this.segBg,
    required this.segThumb,
    required this.segText,
    required this.segActive,
  });

  final SwitchEffect selected;
  final void Function(SwitchEffect) onChanged;
  final Color segBg, segThumb, segText, segActive;

  static const List<(SwitchEffect, String)> _options = [
    (SwitchEffect.droplet, 'Droplet'),
    (SwitchEffect.rain, 'Rain'),
    (SwitchEffect.diwali, 'Diwali'),
  ];

  @override
  Widget build(BuildContext context) {
    const double segW = 76;
    const double segH = 28;
    const double pad = 3;
    final int selectedIndex = _options.indexWhere((o) => o.$1 == selected);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        decoration: BoxDecoration(
          color: segBg,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(pad),
        child: Stack(
          children: [
            // Sliding thumb
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: const Cubic(0.23, 1, 0.32, 1),
              left: pad - pad + selectedIndex * segW, // relative to padding
              top: 0,
              child: Container(
                width: segW,
                height: segH,
                decoration: BoxDecoration(
                  color: segThumb,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1))],
                ),
              ),
            ),
            // Labels row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: _options.map((o) {
                final bool active = o.$1 == selected;
                return GestureDetector(
                  onTap: () => onChanged(o.$1),
                  child: SizedBox(
                    width: segW,
                    height: segH,
                    child: Center(
                      child: Text(
                        o.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: active ? segActive : segText,
                          decoration: TextDecoration.none,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SVG Icons (moon & sun) — drawn via Canvas paths
// ─────────────────────────────────────────────────────────────────────────────

class _MoonIcon extends StatelessWidget {
  const _MoonIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _MoonPainter(color));
  }
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path path = Path();
    // Approximate moon crescent from SVG path d="M20.985 12.486...":
    path.moveTo(20.985, 12.486);
    path.cubicTo(20.891, 14.222, 20.297, 15.894, 19.273, 17.299);
    path.cubicTo(18.25, 18.705, 16.841, 19.784, 15.217, 20.406);
    path.cubicTo(13.593, 21.027, 11.824, 21.166, 10.124, 20.804);
    path.cubicTo(8.423, 20.441, 6.864, 19.595, 5.634, 18.365);
    path.cubicTo(4.405, 17.136, 3.558, 15.577, 3.196, 13.876);
    path.cubicTo(2.833, 12.176, 2.971, 10.407, 3.593, 8.783);
    path.cubicTo(4.215, 7.159, 5.293, 5.750, 6.699, 4.726);
    path.cubicTo(8.104, 3.703, 9.776, 3.108, 11.512, 3.014);
    path.cubicTo(11.917, 2.992, 12.129, 3.474, 11.914, 3.817);
    path.cubicTo(11.195, 4.968, 10.887, 6.328, 11.041, 7.676);
    path.cubicTo(11.194, 9.024, 11.800, 10.280, 12.759, 11.240);
    path.cubicTo(13.719, 12.199, 14.975, 12.805, 16.323, 12.959);
    path.cubicTo(17.671, 13.112, 19.031, 12.804, 20.182, 12.085);
    path.cubicTo(20.526, 11.870, 21.007, 12.081, 20.985, 12.486);
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.color != color;
}

class _SunIcon extends StatelessWidget {
  const _SunIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _SunPainter(color));
  }
}

class _SunPainter extends CustomPainter {
  const _SunPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Circle
    canvas.drawCircle(const Offset(12, 12), 4, p);
    // Rays
    final List<({double x1, double y1, double x2, double y2})> rays = [
      (x1: 12, y1: 2, x2: 12, y2: 4), (x1: 12, y1: 20, x2: 12, y2: 22),
      (x1: 4.93, y1: 4.93, x2: 6.34, y2: 6.34), (x1: 17.66, y1: 17.66, x2: 19.07, y2: 19.07),
      (x1: 2, y1: 12, x2: 4, y2: 12), (x1: 20, y1: 12, x2: 22, y2: 12),
      (x1: 6.34, y1: 17.66, x2: 4.93, y2: 19.07), (x1: 19.07, y1: 4.93, x2: 17.66, y2: 6.34),
    ];
    for (final r in rays) {
      canvas.drawLine(Offset(r.x1, r.y1), Offset(r.x2, r.y2), p);
    }
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// FX painter — renders all three effects
// ─────────────────────────────────────────────────────────────────────────────

/// Snapshot of the current effect frame, fully immutable.
class _FxSnapshot {
  const _FxSnapshot.empty()
      : kind = _FxKind.none,
        tMs = 0,
        nextTheme = LiquidTheme.light,
        // droplet
        dropX = 0, dropY = 0, dropSx = 1, dropSy = 1, dropOpacity = 0,
        dropVisible = false,
        ripples = const [],
        floodX = 0, floodY = 0, floodR = 0, floodR2 = 0,
        // rain
        rainDrops = const [], rainPuddles = const [], rainScale = 1,
        rainSplashes = const [], rainRings = const [],
        // diwali
        diwaliShells = const [], diwaliLiveStars = const [],
        diwaliSparks = const [], diwaliRings = const [],
        diwaliMergeK = 1, diwaliIgnition = null, diwaliScale = 1,
        // flood targets
        floodTargets = const [],
        floodColor = 0,
        bgColor = 0;

  const _FxSnapshot({
    required this.kind,
    required this.tMs,
    required this.nextTheme,
    // droplet
    required this.dropX, required this.dropY,
    required this.dropSx, required this.dropSy,
    required this.dropOpacity, required this.dropVisible,
    required this.ripples,
    required this.floodX, required this.floodY, required this.floodR, required this.floodR2,
    // rain
    required this.rainDrops, required this.rainPuddles,
    required this.rainScale, required this.rainSplashes, required this.rainRings,
    // diwali
    required this.diwaliShells, required this.diwaliLiveStars,
    required this.diwaliSparks, required this.diwaliRings,
    required this.diwaliMergeK, required this.diwaliIgnition, required this.diwaliScale,
    // common
    required this.floodTargets,
    required this.floodColor,
    required this.bgColor,
  });

  final _FxKind kind;
  final double tMs;
  final LiquidTheme nextTheme;
  // droplet
  final double dropX, dropY, dropSx, dropSy, dropOpacity;
  final bool dropVisible;
  final List<_RippleState> ripples;
  final double floodX, floodY, floodR, floodR2; // 2 ripple rings
  // rain
  final List<RainDrop> rainDrops;
  final List<Spot> rainPuddles;
  final double rainScale;
  final List<SplashParticle> rainSplashes;
  final List<RippleRing> rainRings;
  // diwali
  final List<Shell> diwaliShells;
  final List<Star> diwaliLiveStars;
  final List<DiwaliSpark> diwaliSparks;
  final List<_DiwaliRingState> diwaliRings;
  final double diwaliMergeK, diwaliScale;
  final Spot? diwaliIgnition;
  // common
  final List<_FloodTarget> floodTargets;
  final int floodColor; // ARGB
  final int bgColor; // ARGB

  bool floodCoversPoint(Offset p) {
    switch (kind) {
      case _FxKind.none: return false;
      case _FxKind.droplet: return math.sqrt(math.pow(p.dx - floodX, 2) + math.pow(p.dy - floodY, 2)) < floodR;
      case _FxKind.rain:
        for (final Spot s in rainPuddles) {
          if (math.sqrt(math.pow(p.dx - s.x, 2) + math.pow(p.dy - s.y, 2)) < puddleBase(s, tMs) * rainScale) return true;
        }
        return false;
      case _FxKind.diwali:
        for (final Star d in diwaliLiveStars) {
          final pos = starPos(d, tMs);
          if (math.sqrt(math.pow(p.dx - pos.x, 2) + math.pow(p.dy - pos.y, 2)) < dotRadius(d, tMs) * diwaliMergeK) return true;
        }
        return false;
    }
  }
}

enum _FxKind { none, droplet, rain, diwali }

class _RippleState {
  final double cx, cy, progressFraction; // 0..1
  _RippleState(this.cx, this.cy, this.progressFraction);
}

class _DiwaliRingState {
  final double x, y, bornMs, r;
  _DiwaliRingState(this.x, this.y, this.bornMs, this.r);
}

class _FloodTarget {
  final Offset position;
  bool done;
  _FloodTarget(this.position) : done = false;
}

class _FxPainter extends CustomPainter {
  const _FxPainter({required this.snapshot});
  final _FxSnapshot snapshot;

  @override
  void paint(Canvas canvas, Size size) {
    final _FxSnapshot s = snapshot;
    if (s.kind == _FxKind.none) return;

    final Color fxColor = Color(s.floodColor);
    final Paint fill = Paint()..color = fxColor..style = PaintingStyle.fill;
    final Paint stroke = Paint()..color = fxColor..style = PaintingStyle.stroke;

    switch (s.kind) {
      case _FxKind.none: return;
      case _FxKind.droplet: _paintDroplet(canvas, s, fill, stroke); return;
      case _FxKind.rain: _paintRain(canvas, s, fill, stroke); return;
      case _FxKind.diwali: _paintDiwali(canvas, s, fill, stroke); return;
    }
  }

  void _paintDroplet(Canvas canvas, _FxSnapshot s, Paint fill, Paint stroke) {
    // Flood circle (behind controls)
    if (s.floodR > 0) {
      canvas.drawCircle(Offset(s.floodX, s.floodY), s.floodR, fill);
    }
    // Ripple rings (over everything)
    for (final _RippleState rp in s.ripples) {
      final double scale = 1.1 + (5 + rp.progressFraction * 2.5) * easeOutCubic(rp.progressFraction); // approx two rings with index stagger
      final double opacity = (1 - rp.progressFraction) * 0.6;
      if (opacity <= 0) continue;
      stroke
        ..color = Color(s.floodColor).withValues(alpha: opacity)
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(s.dropX, s.dropY), 27 * scale, stroke);
    }
    // Drop shape
    if (s.dropVisible && s.dropOpacity > 0) {
      canvas.save();
      canvas.translate(s.dropX, s.dropY);
      canvas.scale(s.dropSx, s.dropSy);
      fill.color = Color(s.floodColor).withValues(alpha: s.dropOpacity);
      _drawDropPath(canvas, fill);
      canvas.restore();
    }
  }

  static void _drawDropPath(Canvas canvas, Paint p) {
    // Teardrop shape centred at (0,0), pointing down (belly toward origin)
    // Scaled to 22×30 px natural size; transform applied before call
    const double w = 22, h = 30;
    final Path path = Path();
    path.moveTo(0, -h / 2);
    path.cubicTo(-w * 0.45, -h * 0.1, -w / 2, h * 0.2, -w / 2, h * 0.3);
    path.arcToPoint(Offset(w / 2, h * 0.3), radius: const Radius.circular(w / 2), clockwise: false);
    path.cubicTo(w * 0.45, -h * 0.1, w * 0.2, -h * 0.35, 0, -h / 2);
    path.close();
    canvas.drawPath(path, p);
  }

  void _paintRain(Canvas canvas, _FxSnapshot s, Paint fill, Paint stroke) {
    final Color fxColor = Color(s.floodColor);
    // Puddle layer (below drops)
    fill.color = fxColor;
    canvas.saveLayer(null, Paint());
    for (final Spot p in s.rainPuddles) {
      final double r = puddleBase(p, s.tMs) * s.rainScale;
      fill.color = fxColor;
      canvas.drawCircle(Offset(p.x, p.y), r, fill);
      for (final PuddleLobe lb in p.lobes) {
        final double lx = p.x + lb.dx * r, ly = p.y + lb.dy * r, lr = r * lb.s;
        canvas.drawCircle(Offset(lx, ly), lr, fill);
      }
    }
    canvas.restore();

    // Rain streaks (above puddles)
    final double tanWind = math.tan(kRainWindDeg * math.pi / 180);
    final double tilt = -math.atan(tanWind);
    for (final RainDrop d in s.rainDrops) {
      if (d.landed || s.tMs < d.spawnMs) continue;
      final double y = d.y0 + (d.speed * (s.tMs - d.spawnMs)) / 1000;
      final double x = d.x0 + tanWind * (y - d.y0);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(tilt);
      final Paint streakPaint = Paint()
        ..shader = ui.Gradient.linear(Offset(0, -d.len), Offset.zero, [fxColor.withValues(alpha: 0), fxColor.withValues(alpha: d.alpha)])
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(-d.width / 2, -d.len, d.width, d.len), streakPaint);
      canvas.restore();
    }

    // Ripple rings
    for (final RippleRing ring in s.rainRings) {
      final double p = (s.tMs - ring.bornMs) / kRainRippleMs;
      if (p >= 1 || p < 0) continue;
      final double rad = 1 + ring.rmax * easeOutCubic(p);
      stroke
        ..color = fxColor.withValues(alpha: (1 - p) * (0.3 + 0.4 * ring.z))
        ..strokeWidth = 1;
      canvas.drawOval(Rect.fromCenter(center: Offset(ring.x, ring.y), width: rad * 2, height: rad * 1.7), stroke);
    }

    // Crown splashes
    fill.color = fxColor;
    for (final SplashParticle sp in s.rainSplashes) {
      final double age = s.tMs - sp.bornMs;
      if (age < 0 || age >= sp.lifeMs) continue;
      final double at = age / 1000;
      fill.color = fxColor.withValues(alpha: 1 - age / sp.lifeMs);
      canvas.drawCircle(
        Offset(sp.x + sp.vx * at, sp.y + sp.vy * at + 0.5 * kRainSplashGravity * at * at),
        sp.r,
        fill,
      );
    }
  }

  void _paintDiwali(Canvas canvas, _FxSnapshot s, Paint fill, Paint stroke) {
    final Color fxColor = Color(s.floodColor);

    // Ignition ring
    final Spot? ig = s.diwaliIgnition;
    if (ig != null) {
      final double ir = puddleBase(ig, s.tMs) * s.diwaliMergeK;
      fill.color = fxColor;
      canvas.drawCircle(Offset(ig.x, ig.y), ir, fill);
    }

    // Live star dots + streaks
    fill.color = fxColor;
    final bool streaks = s.diwaliMergeK == 1;
    if (streaks) {
      stroke.color = fxColor;
      stroke.strokeWidth = 2 * math.min(1.3, s.diwaliScale + 0.2);
      stroke.strokeCap = StrokeCap.round;
    }
    for (final Star d in s.diwaliLiveStars) {
      final double ageMs = s.tMs - d.bornMs;
      if (ageMs < 0) continue;
      final pos = starPos(d, s.tMs);
      final double r = dotRadius(d, s.tMs) * s.diwaliMergeK;
      fill.color = fxColor;
      canvas.drawCircle(Offset(pos.x, pos.y), r.clamp(0.1, 500), fill);
      if (streaks) {
        final double age = ageMs / 1000;
        const double K = kDiwaliDragK;
        const double gk = kDiwaliGravity / K;
        final double f = math.exp(-K * age);
        final double vx = d.vx * f;
        final double vy = gk + (d.vy - gk) * f;
        if (vx * vx + vy * vy >= 6400) {
          stroke.color = fxColor;
          canvas.drawLine(Offset(pos.x - vx * 0.04, pos.y - vy * 0.04), Offset(pos.x, pos.y), stroke);
        }
      }
    }

    // Rockets
    fill.color = fxColor;
    for (final Shell shell in s.diwaliShells) {
      if (!shell.launched || shell.burstDone) continue;
      final r = rocketPos(shell, s.tMs);
      canvas.drawCircle(Offset(r.x, r.y), 2.6 * s.diwaliScale, fill);
    }

    // Burst rings
    for (final _DiwaliRingState ring in s.diwaliRings) {
      final double p = (s.tMs - ring.bornMs) / 260;
      if (p >= 1 || p < 0) continue;
      stroke
        ..color = fxColor.withValues(alpha: 1 - p)
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(ring.x, ring.y), ring.r * (0.3 + 0.7 * easeOutCubic(p)), stroke);
    }

    // Sparks
    fill.color = fxColor;
    for (final DiwaliSpark sp in s.diwaliSparks) {
      final double age = s.tMs - sp.bornMs;
      if (age < 0 || age >= sp.lifeMs) continue;
      fill.color = fxColor.withValues(alpha: 1 - age / sp.lifeMs);
      canvas.drawRect(Rect.fromCenter(center: Offset(sp.x, sp.y), width: sp.size, height: sp.size), fill);
    }
  }

  @override
  bool shouldRepaint(_FxPainter old) => old.snapshot != snapshot;
}

// ─────────────────────────────────────────────────────────────────────────────
// Effect runners — produce snapshots each tick
// ─────────────────────────────────────────────────────────────────────────────

class _EffectResult {
  final _FxSnapshot snapshot;
  final bool commit;
  final List<_FloodTarget> floodTargets;
  const _EffectResult({required this.snapshot, required this.commit, required this.floodTargets});
}

abstract class _EffectRunner {
  LiquidTheme get next;
  _EffectResult tick(double tMs, double dt);
}

// ── Droplet ──────────────────────────────────────────────────────────────────

class _DropletRunner extends _EffectRunner {
  _DropletRunner({required this.next, required this.btnCenter, required this.w, required this.h}) {
    _plan = planDropFall(btnCenter.dy);
    _floodR = math.sqrt(math.pow(math.max(btnCenter.dx, w - btnCenter.dx), 2) + math.pow(math.max(btnCenter.dy, h - btnCenter.dy), 2)) + 2;
    _floodTargets = [_FloodTarget(btnCenter)];
  }

  @override
  final LiquidTheme next;
  final Offset btnCenter;
  final double w, h;
  late final DropFallPlan _plan;
  late final double _floodR;
  late final List<_FloodTarget> _floodTargets;

  static const double kFloodMs = 800;
  static const double kSquashMs = kDropSquashMs;

  @override
  _EffectResult tick(double tMs, double dt) {
    final ThemePalette tc = ThemeColors.of(next);
    final int color = tc.bg;

    // Phase 1: falling drop
    if (tMs <= _plan.durationMs) {
      // Interpolate fall keyframes
      final double p = tMs / _plan.durationMs;
      DropFrame f1 = _plan.frames.first, f2 = _plan.frames.first;
      for (int i = 1; i < _plan.frames.length; i++) {
        if (_plan.frames[i].offsetT <= p) f1 = _plan.frames[i];
        if (_plan.frames[i].offsetT >= p) { f2 = _plan.frames[i]; break; }
      }
      final double t2 = (f1.offsetT == f2.offsetT) ? 0 : (p - f1.offsetT) / (f2.offsetT - f1.offsetT);
      final double ty = f1.ty + (f2.ty - f1.ty) * t2;
      final double sx = f1.sx + (f2.sx - f1.sx) * t2;
      final double sy = f1.sy + (f2.sy - f1.sy) * t2;
      return _EffectResult(
        snapshot: _FxSnapshot(
          kind: _FxKind.droplet, tMs: tMs, nextTheme: next,
          dropX: btnCenter.dx, dropY: btnCenter.dy + ty,
          dropSx: sx, dropSy: sy, dropOpacity: 1, dropVisible: true,
          ripples: const [],
          floodX: btnCenter.dx, floodY: btnCenter.dy, floodR: 0, floodR2: 0,
          rainDrops: const [], rainPuddles: const [], rainScale: 1, rainSplashes: const [], rainRings: const [],
          diwaliShells: const [], diwaliLiveStars: const [], diwaliSparks: const [], diwaliRings: const [], diwaliMergeK: 1, diwaliIgnition: null, diwaliScale: 1,
          floodTargets: _floodTargets, floodColor: color, bgColor: tc.bg,
        ),
        commit: false,
        floodTargets: _floodTargets,
      );
    }

    // Phase 2: squash + ripples + flood
    final double phaseT = tMs - _plan.durationMs;

    // Drop squash
    final double squashP = (phaseT / kSquashMs).clamp(0, 1);
    final (double dsx, double dsy, double dopa) = dropSquashFrame(squashP, _plan.impactSy);
    final bool dropVis = squashP < 1;

    // Ripples
    final List<_RippleState> ripples = [];
    for (int i = 0; i < 2; i++) {
      final double delay = i * kDropRippleStaggerMs;
      final double rp = ((phaseT - delay) / kDropRippleMs).clamp(0, 1);
      if (rp > 0 && rp < 1) ripples.add(_RippleState(btnCenter.dx, btnCenter.dy, rp));
    }

    // Flood
    final double floodT = math.max(0, phaseT - kDropFloodDelayMs);
    final double fp = (floodT / kFloodMs).clamp(0, 1);
    final double curR = floodRadiusAt(fp, _floodR);

    final bool done = fp >= 1 && squashP >= 1 && ripples.isEmpty;

    return _EffectResult(
      snapshot: _FxSnapshot(
        kind: _FxKind.droplet, tMs: tMs, nextTheme: next,
        dropX: btnCenter.dx, dropY: btnCenter.dy,
        dropSx: dsx, dropSy: dsy, dropOpacity: dopa, dropVisible: dropVis,
        ripples: ripples,
        floodX: btnCenter.dx, floodY: btnCenter.dy, floodR: curR, floodR2: 0,
        rainDrops: const [], rainPuddles: const [], rainScale: 1, rainSplashes: const [], rainRings: const [],
        diwaliShells: const [], diwaliLiveStars: const [], diwaliSparks: const [], diwaliRings: const [], diwaliMergeK: 1, diwaliIgnition: null, diwaliScale: 1,
        floodTargets: _floodTargets, floodColor: color, bgColor: tc.bg,
      ),
      commit: done,
      floodTargets: _floodTargets,
    );
  }
}

// ── Rain ─────────────────────────────────────────────────────────────────────

class _RainRunner extends _EffectRunner {
  _RainRunner({required this.next, required this.btnCenter, required this.w, required this.h, required math.Random rng}) {
    _plan = planRain(w, h, btnCenter.dx, btnCenter.dy, rng);
    _floodTargets = [_FloodTarget(btnCenter)];
  }

  @override
  final LiquidTheme next;
  final Offset btnCenter;
  final double w, h;
  late final RainPlan _plan;
  late final List<_FloodTarget> _floodTargets;

  final List<SplashParticle> _splashes = [];
  final List<RippleRing> _rings = [];
  final List<Spot> _activePuddles = [];
  bool _revealed = false;
  double _revealedAt = 0;

  @override
  _EffectResult tick(double tMs, double dt) {
    final ThemePalette tc = ThemeColors.of(next);
    final int color = tc.bg;

    // Land drops
    for (final RainDrop d in _plan.drops) {
      if (!d.landed && tMs >= d.landMs) {
        d.landed = true;
        _land(d, tMs);
      }
    }

    // Remove dead splashes/rings
    _splashes.removeWhere((sp) => tMs - sp.bornMs >= sp.lifeMs);
    _rings.removeWhere((r) => (tMs - r.bornMs) / kRainRippleMs >= 1);

    // Merge phase
    double k = 1;
    if (tMs >= _plan.mergeStartMs && !_revealed) {
      final double p = ((tMs - _plan.mergeStartMs) / kRainMergeMs).clamp(0, 1);
      k = 1 + (_plan.mergeK - 1) * easeInOutCubic(p);
      if (p >= 1) {
        _revealed = true;
        _revealedAt = tMs;
      }
    }

    final bool done = _revealed && (tMs - _revealedAt) > kRainTailMs;

    return _EffectResult(
      snapshot: _FxSnapshot(
        kind: _FxKind.rain, tMs: tMs, nextTheme: next,
        dropX: 0, dropY: 0, dropSx: 1, dropSy: 1, dropOpacity: 0, dropVisible: false,
        ripples: const [],
        floodX: 0, floodY: 0, floodR: 0, floodR2: 0,
        rainDrops: List.unmodifiable(_plan.drops),
        rainPuddles: List.unmodifiable(_activePuddles),
        rainScale: k,
        rainSplashes: List.unmodifiable(_splashes),
        rainRings: List.unmodifiable(_rings),
        diwaliShells: const [], diwaliLiveStars: const [], diwaliSparks: const [],
        diwaliRings: const [], diwaliMergeK: 1, diwaliIgnition: null, diwaliScale: 1,
        floodTargets: _floodTargets, floodColor: color, bgColor: tc.bg,
      ),
      commit: done,
      floodTargets: _floodTargets,
    );
  }

  void _land(RainDrop d, double tMs) {
    if (d.isPuddle && d.spot != null) {
      _activePuddles.add(d.spot!);
    }
    // Crown splashes
    final int n = (2 + d.z * 4).round();
    final math.Random rng = math.Random(tMs.toInt() ^ d.landX.toInt());
    for (int j = 0; j < n; j++) {
      final double ang = -math.pi * 0.92 + rng.nextDouble() * math.pi * 0.84;
      final double v = (60 + rng.nextDouble() * 150) * (0.5 + d.z);
      _splashes.add(SplashParticle(
        x: d.landX, y: d.landY,
        vx: math.cos(ang) * v, vy: math.sin(ang) * v,
        r: (0.6 + rng.nextDouble() * 0.6) * (0.6 + d.z),
        bornMs: d.landMs, lifeMs: 200 + rng.nextDouble() * 140,
      ));
    }
    if (!d.isPuddle) {
      _rings.add(RippleRing(x: d.landX, y: d.landY, bornMs: d.landMs, rmax: 5 + 16 * d.z, z: d.z));
    }
  }
}

// ── Diwali ───────────────────────────────────────────────────────────────────

class _DiwaliRunner extends _EffectRunner {
  _DiwaliRunner({required this.next, required this.plan, required this.btnCenter, required this.w, required this.h, required math.Random rng}) : _rng = rng {
    _floodTargets = [_FloodTarget(btnCenter)];
  }

  @override
  final LiquidTheme next;
  final DiwaliPlan plan;
  final Offset btnCenter;
  final double w, h;
  final math.Random _rng;
  late final List<_FloodTarget> _floodTargets;

  final List<Star> _liveStars = [];
  final List<DiwaliSpark> _sparks = [];
  final List<_DiwaliRingState> _rings = [];

  @override
  _EffectResult tick(double tMs, double dt) {
    final ThemePalette tc = ThemeColors.of(next);
    final int color = tc.bg;

    // Launch / burst shells
    for (final Shell s in plan.shells) {
      if (!s.launched && tMs >= s.launchMs) {
        s.launched = true;
      }
      if (s.launched && !s.burstDone && tMs >= s.burstMs) {
        s.burstDone = true;
        _liveStars.addAll(s.stars);
        _rings.add(_DiwaliRingState(s.tx, s.ty, s.burstMs, 46 * plan.scale));
      }
      // Trail sparks
      if (s.launched && !s.burstDone) {
        s.sparkDebt += kDiwaliTrailSparksPerS * dt;
        while (s.sparkDebt >= 1) {
          s.sparkDebt -= 1;
          final double f = _rng.nextDouble();
          final r = rocketPos(s, tMs);
          final prev = s.prevPos ?? r;
          _sparks.add(DiwaliSpark(
            x: prev.x + (r.x - prev.x) * f + (_rng.nextDouble() - 0.5) * 2,
            y: prev.y + (r.y - prev.y) * f + (_rng.nextDouble() - 0.5) * 2,
            vx: (_rng.nextDouble() - 0.5) * 50,
            vy: 15 + _rng.nextDouble() * 45,
            bornMs: tMs, lifeMs: 200 + _rng.nextDouble() * 180,
            size: 1 + _rng.nextDouble(),
          ));
        }
        s.prevPos = rocketPos(s, tMs);
      }
    }

    // Update sparks position (integrate velocity)
    for (final DiwaliSpark sp in _sparks) {
      sp.vy += 220 * dt;
      sp.x += sp.vx * dt;
      sp.y += sp.vy * dt;
    }
    _sparks.removeWhere((sp) => tMs - sp.bornMs >= sp.lifeMs);
    _rings.removeWhere((r) => (tMs - r.bornMs) / 260 >= 1);

    // Merge phase
    double k = 1;
    bool done = false;
    if (tMs >= plan.mergeStartMs) {
      final double p = ((tMs - plan.mergeStartMs) / kDiwaliMergeMs).clamp(0, 1);
      k = 1 + (plan.mergeK - 1) * easeInOutCubic(p);
      if (p >= 1) done = true;
    }

    return _EffectResult(
      snapshot: _FxSnapshot(
        kind: _FxKind.diwali, tMs: tMs, nextTheme: next,
        dropX: 0, dropY: 0, dropSx: 1, dropSy: 1, dropOpacity: 0, dropVisible: false,
        ripples: const [], floodX: 0, floodY: 0, floodR: 0, floodR2: 0,
        rainDrops: const [], rainPuddles: const [], rainScale: 1, rainSplashes: const [], rainRings: const [],
        diwaliShells: List.unmodifiable(plan.shells),
        diwaliLiveStars: List.unmodifiable(_liveStars),
        diwaliSparks: List.unmodifiable(_sparks),
        diwaliRings: List.unmodifiable(_rings),
        diwaliMergeK: k,
        diwaliIgnition: plan.ignition,
        diwaliScale: plan.scale,
        floodTargets: _floodTargets, floodColor: color, bgColor: tc.bg,
      ),
      commit: done,
      floodTargets: _floodTargets,
    );
  }
}
