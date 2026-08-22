// JellyBlobSpeech — the speech cloud that hugs its text. One silhouette
// (rounded-rect body + downward tail) carries the glass fill AND the single
// hairline stroke, the width springs to the measured line, the words stagger
// in, and the whole cloud bobs along with the mascot's mood, swinging from
// its tail like a sign on a post. Optional by construction: it is a separate
// widget — render it above a [JellyBlobMascot] or don't.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '_engine.dart';

const double _bubbleH = 56; // 44px body + 12px tail band
const double _bodyH = 44;
const double _padX = 22;
const double _minW = 112;

/// Upstream default line per mood.
const Map<JellyBlobMood, String> kJellySpeechDefaults = {
  JellyBlobMood.sideEye: '…seriously?',
  JellyBlobMood.hmm: 'Hmm… really?',
  JellyBlobMood.password: 'Secret safe.',
  JellyBlobMood.neutral: 'Going somewhere?',
  JellyBlobMood.happy: 'Yay, stay with me!',
  JellyBlobMood.sad: 'Aww, don’t go…',
  JellyBlobMood.angry: 'Hmph. Rude!',
};

// small local copies of the engine's easing math (kept file-private there)
double _easeInOut(double t) =>
    t < .5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();
double _lerpD(double a, double b, double t) => a + (b - a) * t;

double _springP(double tau, double k, double c, [double m = 1]) {
  if (tau <= 0) return 0;
  final double w = math.sqrt(k / m);
  final double zeta = c / (2 * math.sqrt(k * m));
  if (zeta < 1) {
    final double wd = w * math.sqrt(1 - zeta * zeta);
    final double e = math.exp(-zeta * w * tau);
    return 1 - e * (math.cos(wd * tau) + (zeta * w / wd) * math.sin(wd * tau));
  }
  final double e = math.exp(-w * tau);
  return 1 - e * (1 + w * tau);
}

double _loopKeys(double tau, double dur, List<double> vals) {
  if (tau < 0) tau = 0;
  final double u = (tau % dur) / dur;
  final int n = vals.length;
  final int seg = math.min(n - 2, (u * (n - 1)).floor());
  final double local = (u * (n - 1) - seg).clamp(0.0, 1.0);
  return _lerpD(vals[seg], vals[seg + 1], _easeInOut(local));
}

double _keys(double tau, List<double> times, List<double> vals) {
  if (tau <= times.first) return vals.first;
  if (tau >= times.last) return vals.last;
  for (int i = 0; i < times.length - 1; i++) {
    if (tau <= times[i + 1]) {
      final double local = (tau - times[i]) / (times[i + 1] - times[i]);
      return _lerpD(vals[i], vals[i + 1], _easeInOut(local));
    }
  }
  return vals.last;
}

/// A speech cloud for [JellyBlobMascot] — pair its [mood] with the blob's.
class JellyBlobSpeech extends StatefulWidget {
  const JellyBlobSpeech({
    super.key,
    this.mood = JellyBlobMood.neutral,
    this.messages,
    this.text,
    this.brightness,
    this.textStyle,
    this.maxWidth = 300,
    this.animate = true,
    this.frozenAt,
  });

  /// Which line to show; pair it with the blob's mood.
  final JellyBlobMood mood;

  /// Override the default copy for any mood.
  final Map<JellyBlobMood, String>? messages;

  /// Hard text override — wins over [messages] and the defaults.
  final String? text;

  /// Dark glass cloud (dark) or frosted-white chip (light). Defaults to the
  /// ambient [Theme] brightness.
  final Brightness? brightness;

  /// Merged over the built-in bubble text style.
  final TextStyle? textStyle;

  /// The cloud clamps its width to this; the single line never wraps.
  final double maxWidth;

  /// Stop the internal ticker from outside.
  final bool animate;

  /// Render exactly one deterministic frame at this many seconds — no
  /// ticker (state boards, golden tests).
  final double? frozenAt;

  @override
  State<JellyBlobSpeech> createState() => _JellyBlobSpeechState();
}

class _JellyBlobSpeechState extends State<JellyBlobSpeech>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  double _lastElapsed = 0;

  // width spring
  double _wFrom = 180, _wTarget = 180, _tWidth = -1e9;
  // mood follow channel [y, rotate]
  double _followFromY = 0, _followFromRot = 0, _tMood = 0;
  bool _followSpringMode = true;
  double _followK = 200, _followC = 18, _followDelay = 0, _followDur = .5;
  // text swap
  String _shownText = '';
  String _oldText = '';
  double _tText = -1e9;

  bool get _static =>
      !widget.animate ||
      widget.frozenAt != null ||
      MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void initState() {
    super.initState();
    _shownText = _currentText;
    _ticker = createTicker((elapsed) {
      final double e = elapsed.inMicroseconds / 1e6;
      // clamp dt so an app resume doesn't teleport every animation
      final double dt = (e - _lastElapsed).clamp(0.0, .064);
      _lastElapsed = e;
      _clock.value += dt;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_static && !_ticker.isActive) {
      _lastElapsed = 0; // Ticker.start() restarts its elapsed from zero
      _ticker.start();
    }
    if (_static && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  String get _currentText =>
      widget.text ??
      widget.messages?[widget.mood] ??
      kJellySpeechDefaults[widget.mood]!;

  @override
  void didUpdateWidget(JellyBlobSpeech old) {
    super.didUpdateWidget(old);
    final double t = _clock.value;
    if (widget.mood != old.mood) {
      // snapshot the follow pose, then head for the new mood's motion
      final _Follow f = _follow(t);
      _followFromY = f.y;
      _followFromRot = f.rot;
      _tMood = t;
      switch (widget.mood) {
        case JellyBlobMood.sad:
          _followSpringMode = true;
          _followK = 130;
          _followC = 14;
          _followDelay = .1;
        case JellyBlobMood.hmm:
        case JellyBlobMood.sideEye:
          _followSpringMode = true;
          _followK = 200;
          _followC = 18;
          _followDelay = .1;
        case JellyBlobMood.happy:
        case JellyBlobMood.angry:
          _followSpringMode = false;
          _followDur = .12;
          _followDelay = 0;
        default:
          _followSpringMode = false;
          _followDur = .5;
          _followDelay = 0;
      }
    }
    if (_currentText != _shownText) {
      _oldText = _shownText;
      _shownText = _currentText;
      _tText = t;
    }
  }

  // mood-follow target (the cloud swings from its tail)
  _Follow _followTarget(double tau) {
    switch (widget.mood) {
      case JellyBlobMood.happy:
        return _Follow(
          _keys(tau, const [0, .2, .44, .68, .88, 1.05],
              const [0, -16, -5, -9.6, -8.6, -9]),
          _keys(tau, const [0, .3, .6], const [0, -1.5, 0]),
        );
      case JellyBlobMood.sad:
        return const _Follow(6, 0);
      case JellyBlobMood.angry:
        return _Follow(
            4,
            _keys(tau, const [0, .1, .2, .31, .42],
                const [0, -3, 3, -1.5, 0]));
      case JellyBlobMood.hmm:
      case JellyBlobMood.sideEye:
        return const _Follow(2, 4);
      default: // neutral, password
        return _Follow(
            _loopKeys(math.max(0, tau - .55), 3.6, const [0, -3, 0]), 0);
    }
  }

  _Follow _follow(double t) {
    final double tau = t - _tMood;
    final _Follow target = _followTarget(tau);
    final double p = _followSpringMode
        ? _springP(tau - _followDelay, _followK, _followC)
        : (tau <= 0 ? 0.0 : _easeOut(math.min(1, tau / _followDur)));
    return _Follow(
      _lerpD(_followFromY, target.y, p),
      _lerpD(_followFromRot, target.rot, p),
    );
  }

  double _width(double t) {
    final double p = _springP(t - _tWidth, 300, 30);
    return _lerpD(_wFrom, _wTarget, p);
  }

  @override
  Widget build(BuildContext context) {
    final bool dark =
        (widget.brightness ?? Theme.of(context).brightness) == Brightness.dark;
    final TextStyle style = TextStyle(
      color: dark ? const Color(0xFFF7F7FA) : const Color(0xFF2B2735),
      fontWeight: FontWeight.w600,
      fontSize: 15.2,
      height: 1.3,
      letterSpacing: -.15,
      shadows: dark
          ? const [Shadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x59000000))]
          : null,
    ).merge(widget.textStyle);

    // measure the line to size the cloud (same font, single line)
    final TextPainter tp = TextPainter(
      text: TextSpan(text: _shownText, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final double target = (tp.width + _padX * 2)
        .clamp(_minW, math.max(_minW, widget.maxWidth))
        .roundToDouble();
    if (target != _wTarget) {
      _wFrom = _static ? target : _width(_clock.value);
      _wTarget = target;
      _tWidth = _clock.value;
    }

    return ValueListenableBuilder<double>(
      valueListenable: _clock,
      builder: (context, t, _) {
        if (widget.frozenAt != null) t = widget.frozenAt!;
        final bool still = _static;
        final double w = still ? _wTarget : _width(t);
        final _Follow follow =
            still ? _followTarget(t) : _follow(t);
        // entry: fade + spring-up scale from the tail
        final double entryOp =
            still ? 1 : math.min(1, t / .22).toDouble();
        final double entryScale =
            still ? 1 : _lerpD(.87, 1, _springP(t, 350, 26));

        final Matrix4 m = Matrix4.identity()
          ..translateByDouble(0, follow.y, 0, 1)
          ..rotateZ(follow.rot * math.pi / 180)
          ..scaleByDouble(entryScale, entryScale, 1, 1);

        return SizedBox(
          height: _bubbleH,
          child: Center(
            child: Opacity(
              opacity: entryOp,
              child: Transform(
                transform: m,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: w,
                  height: _bubbleH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                            painter: _BubblePainter(dark: dark)),
                      ),
                      // text sits in the 44px body only — the tail band
                      // below must not drag it down
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: _bodyH,
                        child: Center(child: _buildText(t, still, style)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildText(double t, bool still, TextStyle style) {
    final double tc = t - _tText;
    if (still || tc > 2) {
      return Text(_shownText, maxLines: 1, overflow: TextOverflow.clip,
          style: style);
    }
    // old line fades out (0.12s), then the new words stagger in
    if (tc < .12 && _oldText.isNotEmpty) {
      return Opacity(
        opacity: (1 - tc / .12).clamp(0.0, 1.0),
        child: Text(_oldText, maxLines: 1, overflow: TextOverflow.clip,
            style: style),
      );
    }
    final List<String> words = _shownText.split(' ');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < words.length; i++)
          _word(words[i] + (i < words.length - 1 ? ' ' : ''),
              tc - .12 - .05 - i * .08, style),
      ],
    );
  }

  Widget _word(String s, double tau, TextStyle style) {
    final double u = (tau / .34).clamp(0.0, 1.0);
    final double e = _easeOut(u);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 9 * (1 - e)),
        child: Text(s, maxLines: 1, style: style),
      ),
    );
  }
}

class _Follow {
  const _Follow(this.y, this.rot);
  final double y, rot;
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.dark});
  final bool dark;

  // Inset 1px so the centre-aligned stroke is never clipped; tail tip at
  // y~=54 for the same reason.
  Path _bubblePath(double w) {
    final double cx = w / 2;
    final double tr = w - 17;
    const Radius r = Radius.circular(16);
    return Path()
      ..moveTo(17, 1)
      ..lineTo(tr, 1)
      ..arcToPoint(Offset(w - 1, 17), radius: r)
      ..lineTo(w - 1, 28)
      ..arcToPoint(Offset(tr, 44), radius: r)
      ..lineTo(cx + 11, 44)
      ..lineTo(cx + 3, 53)
      ..quadraticBezierTo(cx, 55, cx - 3, 53)
      ..lineTo(cx - 11, 44)
      ..lineTo(17, 44)
      ..arcToPoint(const Offset(1, 28), radius: r)
      ..lineTo(1, 17)
      ..arcToPoint(const Offset(17, 1), radius: r)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _bubblePath(size.width);

    // drop-shadow follows the real silhouette, tail included
    if (dark) {
      canvas.save();
      canvas.translate(0, 1);
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0x24000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .7));
      canvas.translate(0, 3);
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0x29000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.restore();
    } else {
      canvas.save();
      canvas.translate(0, 8);
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0x1F1F1636)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      canvas.restore();
    }

    // glass fill with a subtle vertical luminance gradient
    final ui.Shader fill = ui.Gradient.linear(
      Offset.zero,
      const Offset(0, _bubbleH),
      dark
          ? const [Color(0xF738373F), Color(0xFA28272F)]
          : const [Color(0xFAFFFFFF), Color(0xFAF4F3F9)],
    );
    canvas.drawPath(path, Paint()..shader = fill);

    // sheen: catches light at the top, fades away
    final ui.Shader sheen = ui.Gradient.linear(
      Offset.zero,
      const Offset(0, _bubbleH),
      const [Color(0x2EFFFFFF), Color(0x0AFFFFFF), Color(0x00FFFFFF)],
      const [0, .5, 1],
    );
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(Offset.zero & size, Paint()..shader = sheen);
    canvas.restore();

    // hairline stroke, brightest at the top edge
    final ui.Shader stroke = ui.Gradient.linear(
      Offset.zero,
      const Offset(0, _bubbleH),
      dark
          ? const [Color(0x29FFFFFF), Color(0x0AFFFFFF), Color(0x0AFFFFFF)]
          : const [Color(0x24141028), Color(0x0D141028), Color(0x0D141028)],
      const [0, .6, 1],
    );
    canvas.drawPath(
        path,
        Paint()
          ..shader = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.dark != dark;
}
