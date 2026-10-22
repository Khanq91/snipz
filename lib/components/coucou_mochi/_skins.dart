// Procedural character skins shared by the mascot, launch and upload scenes.
// All secondary motion uses the caller's animation clock, including previews.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

enum CoucouMochiSkin {
  original('Mochi'),
  nekoPudding('Neko Pudding'),
  cloud('Mây Bông');

  const CoucouMochiSkin(this.label);
  final String label;
}

/// Visual inputs, independent of any one of the three animation engines.
class CoucouMochiSkinPose {
  const CoucouMochiSkinPose({
    required this.time,
    this.morph = 0,
    this.yaw = 0,
    this.pitch = 0,
    this.roll = 0,
    this.tilt = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.blush = 0,
    this.eyeOpen = 1,
    this.eye = 'pill',
    this.eyeWeights,
    this.isMini = false,
    this.accent,
    this.stateColor,
    this.stateTint = 0,
  });

  final double time, morph, yaw, pitch, roll, tilt;
  final double scaleX, scaleY, blush, eyeOpen, stateTint;
  final String eye;
  final Map<String, double>? eyeWeights;
  final bool isMini;
  final Color? accent, stateColor;

  double weight(Set<String> names) {
    if (eyeWeights == null) return names.contains(eye) ? 1 : 0;
    return eyeWeights!.entries
        .where((entry) => names.contains(entry.key))
        .fold(0.0, (value, entry) => value + entry.value)
        .clamp(0.0, 1.0);
  }
}

/// Call on a canvas already translated to the body center and posed/scaled.
/// Original rendering stays with the original painters, unchanged.
class CoucouMochiSkinPainter {
  const CoucouMochiSkinPainter({required this.skin, required this.pose});

  final CoucouMochiSkin skin;
  final CoucouMochiSkinPose pose;

  double get _m => pose.morph.clamp(0.0, 1.0);
  double get _joy => pose.weight({'happy', 'heart', 'star', 'wink', 'content'});
  double get _sleepy => pose.weight({'closed', 'tired'});
  double get _storm => pose.weight({'line', 'spiral'});
  double get _affection => math.max(pose.blush * .65, pose.weight({'heart'}));

  Color get inkColor => switch (skin) {
    CoucouMochiSkin.nekoPudding => const Color(0xFF523326),
    CoucouMochiSkin.cloud => const Color(0xFF29475E),
    CoucouMochiSkin.original => const Color(0xFF1A1412),
  };

  Color get limbColor => switch (skin) {
    CoucouMochiSkin.nekoPudding => const Color(0xFFF6D49E),
    CoucouMochiSkin.cloud => const Color(0xFFDBF1FA),
    CoucouMochiSkin.original => const Color(0xFFEDEDEF),
  };

  /// Both new silhouettes settle into the original rounded mailbox footprint.
  Path bodyPath(double r, double rx, double ry) {
    if (skin == CoucouMochiSkin.cloud) return _cloudPath(r, rx, ry);
    final path = Path();
    const count = 96;
    for (var i = 0; i <= count; i++) {
      final angle = i / count * math.pi * 2;
      final ca = math.cos(angle), sa = math.sin(angle);
      final y = _signedPow(sa, .74);
      final x = _signedPow(ca, .74);
      final pudding = skin == CoucouMochiSkin.nekoPudding;
      final base = Offset(rx * x * (pudding ? .94 + y * .12 : 1), ry * y);
      final mailbox = _roundedRectPoint(ca, sa, r, r * .94, r * .42);
      final point = Offset.lerp(base, mailbox, _m)!;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Path _cloudPath(double r, double rx, double ry) {
    // Nine rounded lobes, paired with nine segments of a rounded rectangle.
    // Interpolating control points preserves a continuous mailbox morph.
    final a = 1 - _m;
    Offset point(double x, double y, double mx, double my) =>
        Offset(x * rx * a + mx * r * _m, y * ry * a + my * r * _m);
    final start = point(0, -1.13, 0, -.94);
    final p = Path()..moveTo(start.dx, start.dy);
    void curve(List<double> cloud, List<double> mailbox) {
      final c1 = point(cloud[0], cloud[1], mailbox[0], mailbox[1]);
      final c2 = point(cloud[2], cloud[3], mailbox[2], mailbox[3]);
      final end = point(cloud[4], cloud[5], mailbox[4], mailbox[5]);
      p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    }

    curve(
      [.24, -1.15, .43, -.98, .46, -.77],
      [.25, -.94, .42, -.94, .58, -.94],
    );
    curve([.74, -.94, 1.01, -.67, .98, -.36], [.812, -.94, 1, -.752, 1, -.52]);
    curve([1.25, -.33, 1.23, .17, 1.02, .36], [1, -.2, 1, .2, 1, .52]);
    curve([1.05, .72, .65, .95, .4, .77], [1, .752, .812, .94, .58, .94]);
    curve([.17, 1.01, -.19, 1.01, -.41, .78], [.2, .94, -.2, .94, -.58, .94]);
    curve([-.69, .95, -1.04, .75, -1, .39], [-.812, .94, -1, .752, -1, .52]);
    curve([-1.25, .27, -1.24, -.21, -.99, -.35], [-1, .2, -1, -.2, -1, -.52]);
    curve(
      [-1.01, -.72, -.7, -.98, -.41, -.78],
      [-1, -.752, -.812, -.94, -.58, -.94],
    );
    curve(
      [-.38, -1.01, -.23, -1.14, 0, -1.13],
      [-.4, -.94, -.2, -.94, 0, -.94],
    );
    return p..close();
  }

  void paintBehind(Canvas c, double r, double rx, double ry) {
    if (r <= 0) return;
    switch (skin) {
      case CoucouMochiSkin.nekoPudding:
        _catTail(c, r, rx, ry);
        _catEars(c, r, rx, ry);
        break;
      case CoucouMochiSkin.cloud:
        _sun(c, r, rx, ry);
        break;
      case CoucouMochiSkin.original:
        break;
    }
  }

  void _catTail(Canvas c, double r, double rx, double ry) {
    // Blend fixed rhythms: changing emotion must not multiply the elapsed
    // clock and whip the tail around after the character has run for hours.
    final sway =
        math.sin(pose.time * 2 - .7) * .09 +
        _joy * math.sin(pose.time * 3 - .7) * .08;
    final flick = math.sin(pose.time * 5.4) * _storm * .09;
    final base = Offset(rx * .84, ry * .52);
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(sway + flick - pose.tilt * .4 - _affection * .12);
    c.scale(1 - _m * .23, 1 - _m * .18);
    final tail = Path()
      ..moveTo(-r * .06, 0)
      ..cubicTo(r * .3, r * .14, r * .5, -r * .12, r * .43, -r * .35)
      ..cubicTo(r * .39, -r * .5, r * .24, -r * .5, r * .21, -r * .36);
    c.drawPath(tail, _stroke(const Color(0xFFD09457), r * .17));
    c.drawPath(tail, _stroke(const Color(0xFFF3CE91), r * .11));
    c.drawCircle(
      Offset(r * .21, -r * .36),
      r * .071,
      Paint()..color = const Color(0xFFAD663C),
    );
    c.restore();
  }

  void _catEars(Canvas c, double r, double rx, double ry) {
    for (final side in [-1.0, 1.0]) {
      final ripple =
          math.sin(pose.time * 3.2 + side * .8) * (.025 + _joy * .035);
      final fold = _storm * .25 + _sleepy * .19 - _affection * .09;
      c.save();
      c.translate(side * rx * (.61 - _m * .04), -ry * (.71 + _m * .02));
      c.rotate(side * (fold + .08) + ripple - pose.yaw * .06);
      c.scale(1 - _m * .22, (1 - _m * .35) * (1 + (pose.scaleY - 1) * .4));
      final ear = Path()
        ..moveTo(-r * .24, r * .08)
        ..cubicTo(-r * .22, -r * .12, -r * .16, -r * .52, -r * .055, -r * .56)
        ..cubicTo(r * .015, -r * .59, r * .25, -r * .13, r * .25, r * .07)
        ..close();
      c.drawPath(
        ear,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, -r * .5),
            Offset(0, r * .1),
            const [Color(0xFFC2814F), Color(0xFFF5D5A1)],
          ),
      );
      final inner = Path()
        ..moveTo(-r * .115, -r * .055)
        ..quadraticBezierTo(-r * .09, -r * .35, -r * .04, -r * .37)
        ..quadraticBezierTo(r * .03, -r * .3, r * .13, -r * .055)
        ..close();
      final pink = Color.lerp(
        const Color(0xFFE9A49C),
        pose.accent ?? const Color(0xFFE9A49C),
        pose.isMini ? .24 : 0,
      )!;
      c.drawPath(inner, Paint()..color = pink);
      c.restore();
    }
  }

  void _sun(Canvas c, double r, double rx, double ry) {
    final visibility = (1 - _m * .65) * (1 - _storm * .8 - _sleepy * .5);
    if (visibility < .01) return;
    c.save();
    c.translate(rx * .72, -ry * .75 - math.sin(pose.time * 1.7) * r * .025);
    c.rotate(math.sin(pose.time * .65) * .15);
    final radius = r * (.23 + _joy * .035);
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * math.pi * 2;
      c.drawLine(
        Offset(math.cos(a), math.sin(a)) * radius * 1.2,
        Offset(math.cos(a), math.sin(a)) * radius * 1.47,
        _stroke(
          const Color(0xFFF7CD77).withValues(alpha: visibility * .85),
          r * .035,
        ),
      );
    }
    c.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, -radius), Offset(0, radius), [
          const Color(0xFFFFEAB2).withValues(alpha: visibility),
          const Color(0xFFF7C46B).withValues(alpha: visibility),
        ]),
    );
    c.restore();
  }

  void paintBody(Canvas c, Path body, double r, double rx, double ry) {
    if (r <= 0) return;
    final cat = skin == CoucouMochiSkin.nekoPudding;
    c.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(rx * .3, -ry),
          Offset(-rx * .2, ry),
          cat
              ? const [Color(0xFFFFF0D0), Color(0xFFF8DDAA), Color(0xFFE6B77A)]
              : const [Color(0xFFFCFEFF), Color(0xFFEAF8FE), Color(0xFFBFDDEA)],
          const [0, .55, 1],
        ),
    );
    c.save();
    c.clipPath(body);
    if (pose.stateColor != null && pose.stateTint > .001) {
      // A restrained lower tint keeps the skin recognizable in every state.
      c.drawPath(
        body,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, ry), Offset(0, -ry * .15), [
            pose.stateColor!.withValues(
              alpha:
                  pose.stateTint.clamp(0.0, 1.0) * (cat ? .19 : .26) * (1 - _m),
            ),
            pose.stateColor!.withValues(alpha: 0),
          ]),
      );
    }
    if (cat) {
      _caramel(c, r, rx, ry);
    } else {
      _cloudMaterial(c, body, r, rx, ry);
    }
    c.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(rx * .15, -ry * .25),
          r * 1.5,
          [
            const Color(0x00000000),
            const Color(0x00000000),
            (cat ? const Color(0xFF9C652F) : const Color(0xFF527F9F))
                .withValues(alpha: .16),
          ],
          const [0, .56, 1],
        ),
    );
    c.restore();
    c.drawPath(
      body,
      _stroke(
        (cat ? const Color(0xFFB37B42) : const Color(0xFF8BBBCF)).withValues(
          alpha: .16,
        ),
        r * .018,
      ),
    );
  }

  void _caramel(Canvas c, double r, double rx, double ry) {
    final y = -ry * (.54 + _m * .18);
    final drip = (1 - _m) * r;
    final cap = Path()
      ..moveTo(-rx * 1.3, -ry * 1.3)
      ..lineTo(rx * 1.3, -ry * 1.3)
      ..lineTo(rx * 1.3, y)
      ..cubicTo(
        rx * .82,
        y - drip * .12,
        rx * .6,
        y + drip * .12,
        rx * .46,
        y + drip * .035,
      )
      ..cubicTo(
        rx * .31,
        y - drip * .04,
        rx * .37,
        y + drip * .23,
        rx * .23,
        y + drip * .24,
      )
      ..cubicTo(
        rx * .11,
        y + drip * .23,
        rx * .17,
        y + drip * .035,
        0,
        y + drip * .035,
      )
      ..cubicTo(
        -rx * .3,
        y + drip * .06,
        -rx * .47,
        y - drip * .065,
        -rx * .62,
        y + drip * .03,
      )
      ..cubicTo(
        -rx * .76,
        y + drip * .09,
        -rx * .98,
        y + drip * .03,
        -rx * 1.3,
        y,
      )
      ..close();
    c.drawPath(
      cap,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -ry),
          Offset(0, y + drip * .24),
          const [Color(0xFFBE7843), Color(0xFFA66035), Color(0xFFD19558)],
          const [0, .65, 1],
        ),
    );
    final shine = Path()
      ..moveTo(-rx * .52, -ry * .79)
      ..quadraticBezierTo(-rx * .18, -ry * .9, rx * .16, -ry * .83);
    c.drawPath(
      shine,
      _stroke(const Color(0xFFFFE2AA).withValues(alpha: .6), r * .055),
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-rx * .39, ry * .5),
        width: r * .55,
        height: r * .16,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-rx * .39, ry * .5),
          r * .35,
          const [Color(0x55FFF8E7), Color(0x00FFF8E7)],
        ),
    );
  }

  void _cloudMaterial(Canvas c, Path body, double r, double rx, double ry) {
    for (final spot in [
      const Offset(-.54, -.47),
      const Offset(.02, -.76),
      const Offset(.61, -.3),
    ]) {
      final center = Offset(spot.dx * rx, spot.dy * ry);
      c.drawCircle(
        center,
        r * .55,
        Paint()
          ..shader = ui.Gradient.radial(center, r * .55, const [
            Color(0xCFFFFFFF),
            Color(0x00FFFFFF),
          ]),
      );
    }
    final shade = Color.lerp(
      const Color(0xFF8DBDD5),
      pose.accent ?? const Color(0xFF8DBDD5),
      pose.isMini ? .25 : 0,
    )!;
    c.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, ry * .15), Offset(0, ry), [
          shade.withValues(alpha: 0),
          shade.withValues(alpha: .15 + _storm * .13),
        ]),
    );
    final hem = Path()
      ..moveTo(-rx * .65, ry * (.62 - _m * .02))
      ..quadraticBezierTo(-rx * .3, ry * .84, -rx * .08, ry * .73);
    c.drawPath(hem, _stroke(const Color(0x9AFFFFFF), r * .035));
  }

  /// Face details are clipped; weather accents remain outside the silhouette.
  /// [faceOffset] is the center between the existing eyes, in local coordinates.
  void paintForeground(
    Canvas c,
    Path body,
    double r,
    double rx,
    double ry, {
    Offset? faceOffset,
  }) {
    if (r <= 0) return;
    if (skin == CoucouMochiSkin.cloud) _weather(c, r, rx, ry);
    final visible = (1 - _m).clamp(0.0, 1.0);
    final eyePitch = pose.pitch + pose.roll - .12;
    if (visible < .01 || (faceOffset == null && math.cos(eyePitch) <= .1)) {
      return;
    }
    final center =
        faceOffset ??
        Offset(
          math.sin(pose.yaw) * math.cos(eyePitch) * rx,
          -math.sin(eyePitch) * ry,
        );
    c.save();
    c.clipPath(body);
    c.translate(center.dx, center.dy + r * (pose.isMini ? .31 : .23));
    final ink = inkColor.withValues(alpha: visible * .85);
    if (skin == CoucouMochiSkin.nekoPudding) {
      final nose = Path()
        ..moveTo(-r * .065, -r * .025)
        ..quadraticBezierTo(0, -r * .057, r * .065, -r * .025)
        ..quadraticBezierTo(r * .04, r * .012, 0, r * .035)
        ..quadraticBezierTo(-r * .04, r * .012, -r * .065, -r * .025)
        ..close();
      c.drawPath(
        nose,
        Paint()..color = const Color(0xFFAD7163).withValues(alpha: visible),
      );
      final mouth = Path()
        ..moveTo(0, r * .025)
        ..quadraticBezierTo(-r * .015, r * .12, -r * .105, r * .085)
        ..moveTo(0, r * .025)
        ..quadraticBezierTo(r * .015, r * .12, r * .105, r * .085);
      c.drawPath(mouth, _stroke(ink, r * .025));
      if (!pose.isMini) {
        for (final side in [-1.0, 1.0]) {
          for (var row = 0; row < 2; row++) {
            c.drawLine(
              Offset(side * r * .55, r * (-.015 + row * .1)),
              Offset(side * r * .76, r * (-.055 + row * .17)),
              _stroke(ink.withValues(alpha: visible * .28), r * .018),
            );
          }
        }
      }
    } else if (skin == CoucouMochiSkin.cloud) {
      final smile = Path()
        ..moveTo(-r * .075, 0)
        ..quadraticBezierTo(
          0,
          r * (.075 + _joy * .045 - _storm * .065),
          r * .075,
          0,
        );
      c.drawPath(smile, _stroke(ink, r * .027));
    }
    c.restore();
  }

  void _weather(Canvas c, double r, double rx, double ry) {
    final amount = _storm * (1 - _m);
    if (amount <= .01 || pose.isMini) return;
    final y = ry * .93 + r * .14 + math.sin(pose.time * 3.2) * r * .045;
    for (var i = 0; i < 2; i++) {
      final x = rx * (.48 + i * .27);
      final drop = Path()
        ..moveTo(x, y - r * .07)
        ..cubicTo(
          x + r * .08,
          y + r * .025,
          x + r * .065,
          y + r * .09,
          x,
          y + r * .09,
        )
        ..cubicTo(
          x - r * .065,
          y + r * .09,
          x - r * .08,
          y + r * .025,
          x,
          y - r * .07,
        )
        ..close();
      c.drawPath(
        drop,
        Paint()..color = const Color(0xFF81CBEA).withValues(alpha: amount * .7),
      );
    }
  }
}

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

double _signedPow(double value, double exponent) =>
    value.sign * math.pow(value.abs(), exponent).toDouble();

Offset _roundedRectPoint(double ca, double sa, double w, double h, double cr) {
  final sx = ca >= 0 ? 1.0 : -1.0, sy = sa >= 0 ? 1.0 : -1.0;
  final cx = sx * (w - cr), cy = sy * (h - cr);
  final dot = ca * cx + sa * cy;
  final disc = dot * dot - (cx * cx + cy * cy - cr * cr);
  if (disc >= 0) {
    final t = dot + math.sqrt(disc);
    final p = Offset(ca * t, sa * t);
    if (t > 1e-6 &&
        p.dx.abs() >= w - cr - 1e-6 &&
        p.dy.abs() >= h - cr - 1e-6) {
      return p;
    }
  }
  if (sa.abs() > 1e-6) {
    final t = sy * h / sa;
    if (t > 1e-6 && (ca * t).abs() <= w - cr + 1e-6) {
      return Offset(ca * t, sy * h);
    }
  }
  if (ca.abs() > 1e-6) {
    final t = sx * w / ca;
    if (t > 1e-6 && (sa * t).abs() <= h - cr + 1e-6) {
      return Offset(sx * w, sa * t);
    }
  }
  return Offset(sx * w, sy * h);
}
