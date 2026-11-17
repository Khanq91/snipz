/// Liquid Voice
/// Origin: reimplemented — ported from Pin-UI LiquidVoice (React/WebGL)
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

enum LiquidVoiceTheme { light, dark }

/// A voice-input pill made of liquid glass.
///
/// Idle: a 72×72 frosted-glass pill with a mic button.
/// Recording: stretches (spring) to 300×84, shows waveform bars + cancel/send.
/// Processing: bars gather, 3-dot spinner appears.
/// Done: checkmark draws itself, pill returns to idle.
///
/// No real microphone — waveform is simulated.
class LiquidVoiceWidget extends StatefulWidget {
  const LiquidVoiceWidget({
    super.key,
    this.theme = LiquidVoiceTheme.light,
    this.fill = false,
    this.onSend,
    this.onCancel,
    this.animate = true,
  });

  final LiquidVoiceTheme theme;

  /// Fill the container edge-to-edge; otherwise 16:10 box.
  final bool fill;

  /// Called when a take is sent, with how long it was recorded.
  final void Function(Duration recordDuration)? onSend;

  /// Called when a take is cancelled.
  final VoidCallback? onCancel;

  /// Set false to freeze all animation (TickerMode-compatible).
  final bool animate;

  @override
  State<LiquidVoiceWidget> createState() => _LiquidVoiceWidgetState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State machine
// ─────────────────────────────────────────────────────────────────────────────

enum _VoiceState { idle, recording, processing, done }

class _LiquidVoiceWidgetState extends State<LiquidVoiceWidget>
    with TickerProviderStateMixin {
  // ── pill size (spring-animated) ──────────────────────────────────────────
  static const _idleW = 72.0;
  static const _idleH = 72.0;
  static const _openW = 300.0;
  static const _openH = 84.0;

  late final AnimationController _pillW;
  late final AnimationController _pillH;
  // For spring physics we drive manually with a SpringSimulation
  _SpringDrive? _pillWDrive;
  _SpringDrive? _pillHDrive;

  // ── sky / theme reveal ───────────────────────────────────────────────────
  late final Ticker _skyTicker;
  double _elapsedSky = 0;
  Duration _skyLast = Duration.zero;

  // theme reveal: expanding circle from pill center
  double _revealFrom = 0; // 0=day, 1=night
  double _revealTo = 0;
  double _revealR = 0; // current radius (pixels)
  double _revealMaxR = 1000;
  late final AnimationController _revealAnim;

  // ── bars ─────────────────────────────────────────────────────────────────
  static const _bars = 15;
  final _barLevels = List.filled(_bars, 0.2);
  final _barIn = List.filled(_bars, 0.0); // 0..1 presence spring
  final _barInDrives = <_SpringDrive?>[];
  bool _waveLive = false;

  // ── UI controls fade ─────────────────────────────────────────────────────
  late final AnimationController _micOpacity;
  late final AnimationController _cancelOpacity;
  late final AnimationController _actionOpacity;
  late final AnimationController _dotsOpacity;
  late final AnimationController _doneOpacity;
  late final AnimationController _checkAnim; // 0..1 stroke dash progress

  // action icon: 0=send, 1=stop-square
  late final AnimationController _stopIcoOpacity;

  // button press scale
  final _micScale = _SpringValue(1.0);
  final _cancelScale = _SpringValue(1.0);
  final _actionScale = _SpringValue(1.0);

  // spinner rotation (continuous)
  late final AnimationController _spinner;

  // vertical breathe on send
  double _pillY = 0;

  // ── machine state ────────────────────────────────────────────────────────
  _VoiceState _state = _VoiceState.idle;
  int _token = 0;
  DateTime? _startedAt;

  // waveform ticker
  late final Ticker _waveTicker;
  double _waveT = 0;
  Duration _waveLast = Duration.zero;

  // ── jelly squash ─────────────────────────────────────────────────────────
  double _pillWPrev = _idleW;
  double _squash = 0;

  @override
  void initState() {
    super.initState();

    // init bar drives list
    for (int i = 0; i < _bars; i++) {
      _barInDrives.add(null);
    }

    // ── pill spring controllers (1-tick, we use SpringDrive) ──────────────
    _pillW = AnimationController.unbounded(vsync: this, value: _idleW);
    _pillH = AnimationController.unbounded(vsync: this, value: _idleH);

    // ── sky ticker ────────────────────────────────────────────────────────
    _skyTicker = createTicker(_onSkyTick)..start();

    // ── reveal ────────────────────────────────────────────────────────────
    final dark0 = widget.theme == LiquidVoiceTheme.dark ? 1.0 : 0.0;
    _revealFrom = dark0;
    _revealTo = dark0;
    _revealR = 1e6; // start fully revealed
    _revealAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _revealAnim.addListener(() {
      _revealR = _revealAnim.value * _revealMaxR;
    });

    // ── bars opacity springs ───────────────────────────────────────────────
    _waveTicker = createTicker(_onWaveTick);

    // ── control animators ─────────────────────────────────────────────────
    _micOpacity = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..value = 0;
    _cancelOpacity = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))
      ..value = 0;
    _actionOpacity = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))
      ..value = 0;
    _dotsOpacity = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))
      ..value = 0;
    _doneOpacity = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))
      ..value = 0;
    _checkAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))
      ..value = 0;
    _stopIcoOpacity = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))
      ..value = 0;
    _spinner = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();

    // Entrance: pill grows from small
    _pillW.value = 16;
    _pillH.value = 16;
    _drivePillTo(_idleW, _idleH, stiffness: 180, damping: 14);
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _micOpacity.forward();
    });
  }

  @override
  void didUpdateWidget(LiquidVoiceWidget old) {
    super.didUpdateWidget(old);
    if (old.theme != widget.theme) {
      _setTheme(widget.theme == LiquidVoiceTheme.dark);
    }
    if (old.animate != widget.animate) {
      if (widget.animate) {
        _skyTicker.start();
        if (_waveLive) _waveTicker.start();
      } else {
        _skyTicker.stop();
        _waveTicker.stop();
      }
    }
  }

  @override
  void dispose() {
    _skyTicker.dispose();
    _waveTicker.dispose();
    _pillW.dispose();
    _pillH.dispose();
    _revealAnim.dispose();
    _micOpacity.dispose();
    _cancelOpacity.dispose();
    _actionOpacity.dispose();
    _dotsOpacity.dispose();
    _doneOpacity.dispose();
    _checkAnim.dispose();
    _stopIcoOpacity.dispose();
    _spinner.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sky tick
  // ─────────────────────────────────────────────────────────────────────────

  void _onSkyTick(Duration elapsed) {
    if (!widget.animate) return;
    final dt = _skyLast == Duration.zero
        ? 1 / 60
        : math.min((elapsed - _skyLast).inMicroseconds / 1e6, 0.064);
    _skyLast = elapsed;
    _elapsedSky += dt;

    // drive pill springs
    _tickPillSpring(dt);
    // drive bar springs
    _tickBarSprings(dt);
    // drive button scales
    _micScale.tick(dt);
    _cancelScale.tick(dt);
    _actionScale.tick(dt);

    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Wave tick
  // ─────────────────────────────────────────────────────────────────────────

  void _onWaveTick(Duration elapsed) {
    if (!widget.animate) return;
    if (!_waveLive) return;
    final dt = _waveLast == Duration.zero
        ? 1 / 60
        : math.min((elapsed - _waveLast).inMicroseconds / 1e6, 0.064);
    _waveLast = elapsed;
    _waveT += dt;

    final t = _waveT;
    final syll = 0.55 + 0.45 * math.sin(t * 5.3) * math.sin(t * 1.7 + 1);
    final pause = math.sin(t * 0.9) > 0.82 ? 0.25 : 1.0;
    for (int i = 0; i < _bars; i++) {
      final n = 0.5 + 0.5 * math.sin(t * 9 + i * 1.9) * math.cos(t * 4.1 - i * 0.7);
      final v = math.max(0.12, syll * pause * (0.35 + 0.65 * n));
      _barLevels[i] += (v - _barLevels[i]) * 0.22;
    }
    // barIn is driven by springs in _tickBarSprings (sky ticker)
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Spring helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _drivePillTo(double w, double h, {double stiffness = 260, double damping = 24}) {
    _pillWDrive = _SpringDrive(from: _pillW.value, to: w, velocity: _pillWDrive?.velocity ?? 0, stiffness: stiffness, damping: damping);
    _pillHDrive = _SpringDrive(from: _pillH.value, to: h, velocity: _pillHDrive?.velocity ?? 0, stiffness: stiffness, damping: damping);
  }

  void _tickPillSpring(double dt) {
    if (_pillWDrive != null) {
      _pillWDrive!.tick(dt);
      _pillW.value = _pillWDrive!.value;
      if (_pillWDrive!.done) _pillWDrive = null;
    }
    if (_pillHDrive != null) {
      _pillHDrive!.tick(dt);
      _pillH.value = _pillHDrive!.value;
      if (_pillHDrive!.done) _pillHDrive = null;
    }

    // compute squash from velocity
    final wVel = _pillW.value - _pillWPrev;
    _pillWPrev = _pillW.value;
    _squash = (wVel / 5200 * 1.0).clamp(-0.14, 0.14);
  }

  void _tickBarSprings(double dt) {
    for (int i = 0; i < _bars; i++) {
      final d = _barInDrives[i];
      if (d != null) {
        d.tick(dt);
        _barIn[i] = d.value.clamp(0.0, 1.0);
        if (d.done) _barInDrives[i] = null;
      }
    }
  }

  void _driveBarIn(int i, double target, {double delay = 0, double stiffness = 260, double damping = 26}) {
    // delay handled via Future
    Future<void>.delayed(Duration(milliseconds: (delay * 1000).round()), () {
      if (!mounted) return;
      _barInDrives[i] = _SpringDrive(from: _barIn[i], to: target, velocity: _barInDrives[i]?.velocity ?? 0, stiffness: stiffness, damping: damping);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Theme
  // ─────────────────────────────────────────────────────────────────────────

  void _setTheme(bool isDark) {
    final target = isDark ? 1.0 : 0.0;
    if (target == _revealTo) return;
    final p = (_revealR / _revealMaxR).clamp(0.0, 1.0);
    _revealFrom = _revealFrom + (_revealTo - _revealFrom) * p;
    _revealTo = target;
    _revealR = 0;
    _revealAnim
      ..stop()
      ..value = 0
      ..animateTo(1.0, curve: const Cubic(0.65, 0, 0.35, 1));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // State machine
  // ─────────────────────────────────────────────────────────────────────────

  static int _fromCentreVal(int i) => (i - (_bars - 1) / 2).abs().round();

  void _open() {
    if (_state != _VoiceState.idle) return;
    _state = _VoiceState.recording;
    _startedAt = DateTime.now();

    _micOpacity.animateTo(0, duration: const Duration(milliseconds: 160), curve: Curves.easeIn);

    _drivePillTo(_openW, _openH);

    _stopIcoOpacity.value = 0;
    _cancelOpacity.animateTo(1, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    _actionOpacity.animateTo(1, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);

    for (int i = 0; i < _bars; i++) {
      _barLevels[i] = 0.2;
      final delay = 0.16 + _fromCentreVal(i) * 0.02;
      _driveBarIn(i, 1.0, delay: delay);
    }
    _waveLive = true;
    _waveLast = Duration.zero;
    _waveT = 0;
    if (widget.animate) _waveTicker.start();
  }

  void _cancel() {
    if (_state == _VoiceState.idle) return;
    _token++;
    widget.onCancel?.call();
    _closeToIdle();
  }

  void _closeToIdle() {
    _state = _VoiceState.idle;
    _cancelOpacity.animateTo(0, duration: const Duration(milliseconds: 160));
    _actionOpacity.animateTo(0, duration: const Duration(milliseconds: 160));
    _dotsOpacity.animateTo(0, duration: const Duration(milliseconds: 160));
    _doneOpacity.animateTo(0, duration: const Duration(milliseconds: 160));
    _checkAnim.value = 0;
    for (int i = 0; i < _bars; i++) {
      _barInDrives[i] = _SpringDrive(from: _barIn[i], to: 0, velocity: 0, stiffness: 260, damping: 26);
    }
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      _waveLive = false;
      _waveTicker.stop();
    });

    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (!mounted || _state != _VoiceState.idle) return;
      _drivePillTo(_idleW, _idleH);
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _state != _VoiceState.idle) return;
      _micOpacity.animateTo(1, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    });
  }

  Future<void> _send() async {
    if (_state != _VoiceState.recording) return;
    final t = ++_token;
    _state = _VoiceState.processing;

    final dur = _startedAt != null ? DateTime.now().difference(_startedAt!) : Duration.zero;
    widget.onSend?.call(dur);

    // breathe: subtle Y wobble
    setState(() => _pillY = 0);
    _animatePillY();

    // bars gather toward center then fade
    final max = (_bars - 1) / 2;
    for (int i = 0; i < _bars; i++) {
      final delay = (max - _fromCentreVal(i)) * 0.012;
      _driveBarIn(i, 0, delay: delay, stiffness: 400, damping: 30);
    }
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (_token != t || !mounted) return;

    _waveLive = false;
    _waveTicker.stop();
    await _dotsOpacity.animateTo(1, duration: const Duration(milliseconds: 180));
    await _stopIcoOpacity.animateTo(1, duration: const Duration(milliseconds: 180));
    _actionOpacity.value = 1;

    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (_token != t || !mounted) return;

    _state = _VoiceState.done;
    await _dotsOpacity.animateTo(0, duration: const Duration(milliseconds: 180));
    await _doneOpacity.animateTo(1, duration: const Duration(milliseconds: 180));
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      _checkAnim.forward(from: 0);
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (_token != t || !mounted) return;
    _closeToIdle();
  }

  void _animatePillY() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      setState(() => _pillY = i == 1 ? 2.5 : 0);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (mounted) setState(() => _pillY = 0);
  }

  void _onAction() {
    if (_state == _VoiceState.recording) {
      _send();
    } else if (_state == _VoiceState.processing) {
      _cancel();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme == LiquidVoiceTheme.dark;
    final w = _pillW.value;
    final h = _pillH.value;
    final sqX = _squash * 0.25;
    final sqY = _squash;
    final visW = w * (1 + sqX);
    final visH = h * (1 - sqY);

    // Sky background + pill overlay
    final Widget body = LayoutBuilder(
      builder: (context, constraints) {
        _revealMaxR = math.sqrt(constraints.maxWidth * constraints.maxWidth +
                constraints.maxHeight * constraints.maxHeight) /
            2 + 90;

        final cx = constraints.maxWidth / 2;
        final cy = constraints.maxHeight / 2 + _pillY;

        return Stack(
          children: [
            // Sky background
            Positioned.fill(
              child: CustomPaint(
                painter: _SkyPainter(
                  t: _elapsedSky * 0.06,
                  revealFrom: _revealFrom,
                  revealTo: _revealTo,
                  revealR: _revealR,
                  revealCenter: Offset(cx, cy),
                  feather: 90,
                  isDark: isDark,
                ),
              ),
            ),
            // Glass pill
            Positioned(
              left: cx - visW / 2,
              top: cy - visH / 2,
              width: visW,
              height: visH,
              child: _GlassPill(
                isDark: isDark,
                child: _PillContents(
                  bars: _bars,
                  barLevels: _barLevels,
                  barIn: _barIn,
                  micOpacity: _micOpacity,
                  cancelOpacity: _cancelOpacity,
                  actionOpacity: _actionOpacity,
                  dotsOpacity: _dotsOpacity,
                  doneOpacity: _doneOpacity,
                  checkProgress: _checkAnim.value,
                  showStop: _stopIcoOpacity.value > 0.5,
                  spinAngle: _spinner.value * 2 * math.pi,
                  micScale: _micScale.value,
                  cancelScale: _cancelScale.value,
                  actionScale: _actionScale.value,
                  isDark: isDark,
                  onMic: _open,
                  onCancel: _cancel,
                  onAction: _onAction,
                  onMicPressDown: () => _micScale.target = 0.92,
                  onMicPressUp: () => _micScale.target = 1.0,
                  onCancelPressDown: () => _cancelScale.target = 0.92,
                  onCancelPressUp: () => _cancelScale.target = 1.0,
                  onActionPressDown: () => _actionScale.target = 0.92,
                  onActionPressUp: () => _actionScale.target = 1.0,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.fill) {
      return SizedBox.expand(child: body);
    } else {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: body,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sky painter (deterministic sum-of-sines sky)
// ─────────────────────────────────────────────────────────────────────────────

class _SkyPainter extends CustomPainter {
  const _SkyPainter({
    required this.t,
    required this.revealFrom,
    required this.revealTo,
    required this.revealR,
    required this.revealCenter,
    required this.feather,
    required this.isDark,
  });

  final double t;
  final double revealFrom;
  final double revealTo;
  final double revealR;
  final Offset revealCenter;
  final double feather;
  final bool isDark;

  /// Approximate the GLSL day() sky — 4 radial/linear blends.
  Color _day(double x, double y) {
    // base: deep sky blue
    final b0 = _smoothstep(0.85, 0.05, y + 0.18 * math.sin(x * 2.4 + t) - 0.1 * x);
    var r = _lerp(0.080, 0.020, b0);
    var g = _lerp(0.430, 0.290, b0);
    var b = _lerp(0.800, 0.690, b0);

    // horizon haze
    final b1 = _smoothstep(0.38, 1.05, x + 0.22 * y + 0.04 * math.sin(t * 1.7 + y * 3.0));
    r = _lerp(r, 0.250, b1);
    g = _lerp(g, 0.700, b1);
    b = _lerp(b, 0.900, b1);

    // top-left cloud
    final d1 = _len2(x - (-0.06), (y - 1.08) * 1.25);
    final b2 = 0.95 * _smoothstep(0.62, 0.0, d1);
    r = _lerp(r, 0.800, b2); g = _lerp(g, 0.890, b2); b = _lerp(b, 0.950, b2);

    // right cloud
    final d2 = _len2(x - 1.06, y - (-0.02));
    final b3 = 0.55 * _smoothstep(0.55, 0.0, d2);
    r = _lerp(r, 0.620, b3); g = _lerp(g, 0.880, b3); b = _lerp(b, 0.980, b3);

    return Color.fromARGB(255, (r * 255).round().clamp(0, 255),
        (g * 255).round().clamp(0, 255), (b * 255).round().clamp(0, 255));
  }

  /// Approximate the GLSL night() sky.
  Color _night(double x, double y) {
    final b0 = _smoothstep(0.85, 0.05, y + 0.18 * math.sin(x * 2.4 + t) - 0.1 * x);
    var r = _lerp(0.035, 0.012, b0);
    var g = _lerp(0.075, 0.030, b0);
    var b = _lerp(0.190, 0.095, b0);

    final b1 = _smoothstep(0.42, 1.08, x + 0.22 * y + 0.04 * math.sin(t * 1.7 + y * 3.0));
    r = _lerp(r, 0.030, b1); g = _lerp(g, 0.230, b1); b = _lerp(b, 0.380, b1);

    final d1 = _len2(x - (-0.06), (y - 1.08) * 1.25);
    final b2 = 0.80 * _smoothstep(0.60, 0.0, d1);
    r = _lerp(r, 0.140, b2); g = _lerp(g, 0.230, b2); b = _lerp(b, 0.420, b2);

    final d2 = _len2(x - 1.06, y - (-0.02));
    final b3 = 0.45 * _smoothstep(0.55, 0.0, d2);
    r = _lerp(r, 0.100, b3); g = _lerp(g, 0.420, b3); b = _lerp(b, 0.620, b3);

    return Color.fromARGB(255, (r * 255).round().clamp(0, 255),
        (g * 255).round().clamp(0, 255), (b * 255).round().clamp(0, 255));
  }

  static double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _len2(double dx, double dy) => math.sqrt(dx * dx + dy * dy);

  @override
  void paint(Canvas canvas, Size size) {
    // We sample a grid of colors to build a reasonable gradient.
    // For performance we use a small grid and draw rects — 8×8 is plenty for
    // a soft sky gradient.
    const cols = 10;
    const rows = 8;
    final cw = size.width / cols;
    final ch = size.height / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final nx = col / (cols - 1); // 0..1
        final ny = row / (rows - 1); // 0..1

        final dayColor = _day(nx, ny);
        final nightColor = _night(nx, ny);

        // reveal blend: how dark is this pixel
        final px = col * cw + cw / 2;
        final py = row * ch + ch / 2;
        final dist = (Offset(px, py) - revealCenter).distance;
        final m = 1.0 - _smoothstep(revealR - feather, revealR, dist);
        final dark = revealFrom + (revealTo - revealFrom) * m;

        final color = Color.lerp(dayColor, nightColor, dark.clamp(0.0, 1.0))!;
        canvas.drawRect(
          Rect.fromLTWH(col * cw, row * ch, cw + 1, ch + 1),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass pill
// ─────────────────────────────────────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.isDark, required this.child});
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: isDark
                ? const Color(0x28a0dcff) // rgb(120 160 220 / 0.16) approx
                : const Color(0x59a0d7fa), // rgb(160 215 250 / 0.35) approx
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0x33b2ccff), Color(0x1a4466aa)]
                  : const [Color(0x55b8e0f7), Color(0x2266aadd)],
            ),
            border: Border.all(
              color: isDark ? const Color(0x47ffffff) : const Color(0x80ffffff),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x5900143c),
                blurRadius: 30,
                offset: const Offset(0, 14),
                spreadRadius: -12,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill contents (mic, bars, cancel, action, dots, done)
// ─────────────────────────────────────────────────────────────────────────────

class _PillContents extends StatelessWidget {
  const _PillContents({
    required this.bars,
    required this.barLevels,
    required this.barIn,
    required this.micOpacity,
    required this.cancelOpacity,
    required this.actionOpacity,
    required this.dotsOpacity,
    required this.doneOpacity,
    required this.checkProgress,
    required this.showStop,
    required this.spinAngle,
    required this.micScale,
    required this.cancelScale,
    required this.actionScale,
    required this.isDark,
    required this.onMic,
    required this.onCancel,
    required this.onAction,
    required this.onMicPressDown,
    required this.onMicPressUp,
    required this.onCancelPressDown,
    required this.onCancelPressUp,
    required this.onActionPressDown,
    required this.onActionPressUp,
  });

  final int bars;
  final List<double> barLevels;
  final List<double> barIn;
  final AnimationController micOpacity;
  final AnimationController cancelOpacity;
  final AnimationController actionOpacity;
  final AnimationController dotsOpacity;
  final AnimationController doneOpacity;
  final double checkProgress;
  final bool showStop;
  final double spinAngle;
  final double micScale;
  final double cancelScale;
  final double actionScale;
  final bool isDark;
  final VoidCallback onMic;
  final VoidCallback onCancel;
  final VoidCallback onAction;
  final VoidCallback onMicPressDown;
  final VoidCallback onMicPressUp;
  final VoidCallback onCancelPressDown;
  final VoidCallback onCancelPressUp;
  final VoidCallback onActionPressDown;
  final VoidCallback onActionPressUp;

  // bar color
  Color get _barColor => isDark ? const Color(0xffe9f2ff) : const Color(0xff050b14);
  // X button colors
  Color get _xBg => isDark ? const Color(0xffeef4ff) : const Color(0xff060606);
  Color get _xInk => isDark ? const Color(0xff07101f) : const Color(0xffffffff);
  // action button
  Color get _actBg => isDark ? const Color(0x1fffffff) : const Color(0x4cffffff);
  Color get _actInk => isDark ? const Color(0xffdce9ff) : const Color(0xff0b2440);

  static const _envelope = [
    0.4762, 0.5991, 0.7059, 0.7936, 0.8594, 0.9009, 0.9239, 0.9271, 0.9100,
    0.8741, 0.8213, 0.7539, 0.6744, 0.5854, 0.4894,
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── mic button (center, idle) ──────────────────────────────────────
        Positioned.fill(
          child: Center(
            child: AnimatedBuilder(
              animation: micOpacity,
              builder: (_, child) => Opacity(
                opacity: micOpacity.value,
                child: Transform.scale(
                  scale: micScale,
                  child: _XButton(
                    size: 46,
                    bg: _xBg,
                    ink: _xInk,
                    onTap: onMic,
                    onPressDown: onMicPressDown,
                    onPressUp: onMicPressUp,
                    child: const _MicIcon(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── cancel button (left) ───────────────────────────────────────────
        Positioned(
          left: 19,
          top: 0,
          bottom: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: cancelOpacity,
              builder: (_, child) => Opacity(
                opacity: cancelOpacity.value,
                child: Transform.scale(
                  scale: cancelScale,
                  child: _XButton(
                    size: 46,
                    bg: _xBg,
                    ink: _xInk,
                    onTap: onCancel,
                    onPressDown: onCancelPressDown,
                    onPressUp: onCancelPressUp,
                    child: const _XIcon(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── waveform bars (center) ─────────────────────────────────────────
        Positioned.fill(
          child: Center(
            child: SizedBox(
              width: 140,
              height: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(bars, (i) {
                  final k = barIn[i];
                  final envH = 3.5 + _envelope[i] * barLevels[i] * 24 * k;
                  return Container(
                    width: 2.2,
                    height: envH.clamp(2.0, 28.0),
                    margin: const EdgeInsets.symmetric(horizontal: 1.75),
                    decoration: BoxDecoration(
                      color: _barColor.withValues(alpha: math.min(1.0, k * 1.4)),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        // ── 3-dot spinner (center) ─────────────────────────────────────────
        Positioned.fill(
          child: Center(
            child: AnimatedBuilder(
              animation: dotsOpacity,
              builder: (_, child) => Opacity(
                opacity: dotsOpacity.value,
                child: Transform.rotate(
                  angle: spinAngle,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomPaint(
                      painter: _DotsSpinnerPainter(color: _barColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── done / checkmark (center) ──────────────────────────────────────
        Positioned.fill(
          child: Center(
            child: AnimatedBuilder(
              animation: doneOpacity,
              builder: (_, child) => Opacity(
                opacity: doneOpacity.value,
                child: SizedBox(
                  width: 21,
                  height: 21,
                  child: CustomPaint(
                    painter: _CheckPainter(
                      progress: checkProgress,
                      color: _barColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── action button (right) ──────────────────────────────────────────
        Positioned(
          right: 27,
          top: 0,
          bottom: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: actionOpacity,
              builder: (_, child) => Opacity(
                opacity: actionOpacity.value,
                child: Transform.scale(
                  scale: actionScale,
                  child: GestureDetector(
                    onTap: onAction,
                    onTapDown: (_) => onActionPressDown(),
                    onTapUp: (_) => onActionPressUp(),
                    onTapCancel: onActionPressUp,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _actBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0x47ffffff) : const Color(0x8cffffff),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: showStop
                            ? _StopIcon(color: _actInk)
                            : _SendIcon(color: _actInk),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widgets / painters
// ─────────────────────────────────────────────────────────────────────────────

class _XButton extends StatelessWidget {
  const _XButton({
    required this.size,
    required this.bg,
    required this.ink,
    required this.onTap,
    required this.onPressDown,
    required this.onPressUp,
    required this.child,
  });
  final double size;
  final Color bg;
  final Color ink;
  final VoidCallback onTap;
  final VoidCallback onPressDown;
  final VoidCallback onPressUp;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) => onPressDown(),
      onTapUp: (_) => onPressUp(),
      onTapCancel: onPressUp,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Center(child: IconTheme(data: IconThemeData(color: ink), child: child)),
      ),
    );
  }
}

class _MicIcon extends StatelessWidget {
  const _MicIcon();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _MicPainter(color: IconTheme.of(context).color ?? Colors.white),
    );
  }
}

class _MicPainter extends CustomPainter {
  const _MicPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final sx = size.width / 24;
    final sy = size.height / 24;

    // mic body rect(9,2.5,6,12,rx3)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(9 * sx, 2.5 * sy, 6 * sx, 12 * sy),
      Radius.circular(3 * math.min(sx, sy)),
    );
    canvas.drawRRect(bodyRect, paint);

    // arc path: M5 11a7 7 0 0 0 14 0
    final arcPath = Path();
    arcPath.moveTo(5 * sx, 11 * sy);
    arcPath.arcToPoint(Offset(19 * sx, 11 * sy),
        radius: Radius.circular(7 * math.min(sx, sy)), clockwise: false);
    // M12 18v3.5
    arcPath.moveTo(12 * sx, 18 * sy);
    arcPath.lineTo(12 * sx, 21.5 * sy);
    canvas.drawPath(arcPath, paint);
  }

  @override
  bool shouldRepaint(_MicPainter old) => old.color != color;
}

class _XIcon extends StatelessWidget {
  const _XIcon();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(21, 21),
      painter: _XPainter(color: IconTheme.of(context).color ?? Colors.white),
    );
  }
}

class _XPainter extends CustomPainter {
  const _XPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final sx = size.width / 24;
    final sy = size.height / 24;
    canvas.drawLine(Offset(6 * sx, 6 * sy), Offset(18 * sx, 18 * sy), paint);
    canvas.drawLine(Offset(18 * sx, 6 * sy), Offset(6 * sx, 18 * sy), paint);
  }

  @override
  bool shouldRepaint(_XPainter old) => old.color != color;
}

class _SendIcon extends StatelessWidget {
  const _SendIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(18, 18),
        painter: _SendPainter(color: color),
      );
}

class _SendPainter extends CustomPainter {
  const _SendPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final sx = size.width / 24;
    final sy = size.height / 24;
    final path = Path();
    // M12 19V5
    path.moveTo(12 * sx, 19 * sy);
    path.lineTo(12 * sx, 5 * sy);
    // M6 11l6-6 6 6
    path.moveTo(6 * sx, 11 * sy);
    path.lineTo(12 * sx, 5 * sy);
    path.lineTo(18 * sx, 11 * sy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SendPainter old) => old.color != color;
}

class _StopIcon extends StatelessWidget {
  const _StopIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(18, 18),
        painter: _StopPainter(color: color),
      );
}

class _StopPainter extends CustomPainter {
  const _StopPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    final sx = size.width / 24;
    final sy = size.height / 24;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5.5 * sx, 5.5 * sy, 13 * sx, 13 * sy),
        Radius.circular(2.5 * math.min(sx, sy)),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_StopPainter old) => old.color != color;
}

class _DotsSpinnerPainter extends CustomPainter {
  const _DotsSpinnerPainter({required this.color});
  final Color color;

  static const _dots = [
    (angle: -120.0, size: 4.4),
    (angle: -78.0, size: 3.7),
    (angle: -36.0, size: 4.4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 6.6;

    for (final d in _dots) {
      final rad = d.angle * math.pi / 180;
      final x = cx + math.cos(rad) * r;
      final y = cy + math.sin(rad) * r;
      canvas.drawCircle(
        Offset(x, y),
        d.size / 2,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsSpinnerPainter old) => old.color != color;
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final sx = size.width / 24;
    final sy = size.height / 24;

    // d="M5 12.5l4.5 4.5L19 7.5"
    final fullPath = Path();
    fullPath.moveTo(5 * sx, 12.5 * sy);
    fullPath.lineTo(9.5 * sx, 17 * sy);
    fullPath.lineTo(19 * sx, 7.5 * sy);

    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final total = metrics.fold(0.0, (s, m) => s + m.length);
    final drawn = total * progress;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    var remaining = drawn;
    for (final metric in metrics) {
      final extract = math.min(remaining, metric.length);
      if (extract > 0) {
        canvas.drawPath(metric.extractPath(0, extract), paint);
      }
      remaining -= extract;
      if (remaining <= 0) break;
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Spring physics helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight spring drive — integrates a SpringSimulation each tick.
class _SpringDrive {
  _SpringDrive({
    required double from,
    required double to,
    required double velocity,
    double stiffness = 260,
    double damping = 24,
  }) : _target = to {
    _sim = SpringSimulation(
      SpringDescription(mass: 1, stiffness: stiffness, damping: damping),
      from,
      to,
      velocity,
    );
  }

  final double _target;
  late final SpringSimulation _sim;
  double _t = 0;
  bool done = false;

  double get value => done ? _target : _sim.x(_t);
  double get velocity => done ? 0 : _sim.dx(_t);

  void tick(double dt) {
    if (done) return;
    _t += dt;
    if (_sim.isDone(_t)) done = true;
  }
}

/// A value that springs toward a target — for button press scale.
class _SpringValue {
  _SpringValue(double initial) : value = initial, _target = initial;

  double value;
  double _target;
  _SpringDrive? _drive;

  set target(double t) {
    if (t == _target) return;
    _target = t;
    _drive = _SpringDrive(from: value, to: t, velocity: _drive?.velocity ?? 0, stiffness: 500, damping: 28);
  }

  void tick(double dt) {
    final d = _drive;
    if (d == null) return;
    d.tick(dt);
    value = d.value;
    if (d.done) _drive = null;
  }
}
