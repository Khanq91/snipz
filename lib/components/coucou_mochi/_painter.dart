// Canvas renderer for CoucouMochiFrame. Geometry follows the Canvas 2D
// renderer in Coucou's Windows build so Flutter uses the same unit ratios.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Colors;
import 'package:flutter/rendering.dart';

import '_engine.dart';

const Color _baseTop = Color(0xFFEDEDEF);
const Color _baseBottom = Color(0xFFC4C5CA);
const Color _ink = Color(0xFF1A1412);
const double _tau = math.pi * 2;

class CoucouMochiPainter extends CustomPainter {
  const CoucouMochiPainter({
    required this.frame,
    this.isMini = false,
    this.bodyColor,
    this.backgroundColor,
    super.repaint,
  });

  final CoucouMochiFrame frame;
  final bool isMini;
  final Color? bodyColor;
  Color get _eyeInk => isMini ? const Color(0xFF10131A) : _ink;
  final Color? backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (backgroundColor != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor!);
    }
    final double r = size.width * .3;
    final double rx = r * 1.14;
    final double ry = r * .88;
    final double cx = size.width / 2 + frame.offsetX * r;
    final double cy = size.height / 2 + frame.offsetY * r + r * .06;

    _drawHands(canvas, r, rx, ry, cx, cy);

    canvas.save();
    canvas.translate(cx, cy);
    if (frame.tilt != 0) canvas.rotate(frame.tilt);
    canvas.scale(frame.scaleX, frame.scaleY);

    final Path body = _bodyPath(rx, ry, r, frame.morph);
    _drawBody(canvas, body, r, rx, ry);
    final double blushValue =
        math.max(frame.blush, frame.tint * .5) * (1 - frame.morph);
    if (blushValue > .01) _drawBlush(canvas, body, rx, ry, r, blushValue);
    _drawEyes(canvas, body, r, rx, ry);
    if (frame.morph > .05) _drawMouth(canvas, body, r);
    canvas.restore();

    if (frame.badge != null && frame.badgeScale > .01 && frame.morph < .25) {
      _drawBadge(canvas, frame.badge!, frame.badgeColor, r, cx, cy);
    }
    _drawParticles(canvas, r, cx, cy);
  }

  Path _bodyPath(double rx, double ry, double r, double morph) {
    const int n = 72;
    const double exponent = 2 / 2.7;
    final double w = r;
    final double h = r * .94;
    final double corner = r * .42;
    final Path path = Path();
    for (int i = 0; i <= n; i++) {
      final double a = i / n * math.pi * 2;
      final double ca = math.cos(a);
      final double sa = math.sin(a);
      final double px0 =
          rx *
          (ca >= 0
              ? math.pow(ca, exponent).toDouble()
              : -math.pow(-ca, exponent).toDouble());
      final double py0 =
          ry *
          (sa >= 0
              ? math.pow(sa, exponent).toDouble()
              : -math.pow(-sa, exponent).toDouble());
      double px = px0;
      double py = py0;
      if (morph >= .005) {
        final Offset rounded = _roundedRectPoint(ca, sa, w, h, corner);
        px = _lerp(px0, rounded.dx, morph);
        py = _lerp(py0, rounded.dy, morph);
      }
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    return path..close();
  }

  Offset _roundedRectPoint(
    double ca,
    double sa,
    double w,
    double h,
    double cr,
  ) {
    const double eps = 1e-6;
    final double kx = ca >= 0 ? 1 : -1;
    final double ky = sa >= 0 ? 1 : -1;
    final double cx = kx * (w - cr);
    final double cy = ky * (h - cr);
    final double dot = ca * cx + sa * cy;
    final double disc = dot * dot - (cx * cx + cy * cy - cr * cr);
    if (disc >= 0) {
      final double t = dot + math.sqrt(disc);
      if (t > eps) {
        final double px = ca * t;
        final double py = sa * t;
        if (px.abs() >= w - cr - eps && py.abs() >= h - cr - eps) {
          return Offset(px, py);
        }
      }
    }
    if (sa.abs() > eps) {
      final double t = ky * h / sa;
      if (t > eps) {
        final double x = ca * t;
        if (x.abs() <= w - cr + eps) return Offset(x, ky * h);
      }
    }
    if (ca.abs() > eps) {
      final double t = kx * w / ca;
      if (t > eps) {
        final double y = sa * t;
        if (y.abs() <= h - cr + eps) return Offset(kx * w, y);
      }
    }
    return Offset(kx * w, ky * h);
  }

  void _drawBody(Canvas canvas, Path body, double r, double rx, double ry) {
    if (isMini && bodyColor != null) {
      canvas.drawPath(body, Paint()..color = bodyColor!);
      return;
    }
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(rx * .7, -ry * .85),
          Offset(-rx * .8, ry * .9),
          const [_baseTop, _baseBottom],
        ),
    );
    final double tint = frame.tint * (1 - frame.morph);
    if (tint > .01) {
      final Color state = Color(frame.bodyColor);
      canvas.drawPath(
        body,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, ry), Offset(0, -ry), [
            state.withValues(alpha: .72 * tint),
            state.withValues(alpha: 0),
          ]),
      );
    }
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          r * 1.25,
          [
            const Color(0x00000000),
            const Color(0x00000000),
            const Color(0x33000000),
          ],
          // Canvas 2D's inner radius is .15R and outer radius is 1.25R.
          const [0, .648, 1],
        ),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.radial(Offset(rx * .34, -ry * .46), r * .42, [
          const Color(0x8CFFFFFF),
          const Color(0x00FFFFFF),
        ]),
    );
  }

  void _drawBlush(
    Canvas canvas,
    Path body,
    double rx,
    double ry,
    double r,
    double amount,
  ) {
    canvas.save();
    canvas.clipPath(body);
    final double offset = math.sin(frame.yaw) * rx * .8;
    final Paint paint = Paint()
      ..color = const Color(0xFFFF7896).withValues(alpha: .5 * amount);
    for (final double side in const [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(side * rx * .55 + offset, ry * .2),
          width: r * .34,
          height: r * .2,
        ),
        paint,
      );
    }
    canvas.restore();
  }

  void _drawEyes(Canvas canvas, Path body, double r, double rx, double ry) {
    canvas.save();
    canvas.clipPath(body);
    for (final double side in const [-1, 1]) {
      final double eyeYaw = side * .37 + frame.yaw;
      double eyePitch = -.12 + frame.pitch + frame.roll;
      eyePitch =
          ((eyePitch + math.pi) % (math.pi * 2) + math.pi * 2) % (math.pi * 2) -
          math.pi;
      final double cp = math.cos(eyePitch);
      if (math.cos(eyeYaw) * cp <= .04) continue;
      final double ex = math.sin(eyeYaw) * cp * rx;
      final double ey =
          -math.sin(eyePitch) * ry +
          (frame.morph > 0 ? ry * .14 * frame.morph : 0);
      final double fx = _lerp(
        math.max(.18, math.cos(eyeYaw)),
        1,
        frame.morph * .7,
      );
      final double fy = _lerp(math.max(.18, cp), 1, frame.morph * .7);
      final double eyeW = r * .25 * frame.eyeScale * (isMini ? 1.9 : 1);
      final double eyeH = r * .27 * frame.eyeScale * (isMini ? 1.9 : 1);
      canvas.save();
      canvas.translate(ex, ey);
      canvas.scale(fx, fy);
      _drawEye(canvas, frame.eye, eyeW, eyeH, frame.eyeOpen, side, r);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawEye(
    Canvas canvas,
    CoucouMochiEye shape,
    double w,
    double h,
    double open,
    double side,
    double r,
  ) {
    final Paint ink = Paint()..color = _eyeInk;
    switch (shape) {
      case CoucouMochiEye.wide:
        _drawEye(
          canvas,
          CoucouMochiEye.pill,
          w * 1.16,
          h * 1.12,
          open,
          side,
          r,
        );
        break;
      case CoucouMochiEye.pill:
        final double hh = math.max(h * open, w * .3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: hh),
            Radius.circular(math.min(w / 2, hh / 2)),
          ),
          ink,
        );
        break;
      case CoucouMochiEye.dot:
        canvas.drawCircle(Offset.zero, w * .45, ink);
        break;
      case CoucouMochiEye.line:
        canvas.save();
        canvas.rotate(-side * .2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: w * 1.56,
              height: w * .42,
            ),
            Radius.circular(w * .21),
          ),
          ink,
        );
        canvas.restore();
        break;
      case CoucouMochiEye.flat:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: w * 1.44,
              height: w * .4,
            ),
            Radius.circular(w * .2),
          ),
          ink,
        );
        break;
      case CoucouMochiEye.happy:
        final Path p = Path()
          ..addArc(
            Rect.fromCircle(center: Offset(0, h * .18), radius: w * .82),
            math.pi * 1.12,
            math.pi * .76,
          );
        canvas.drawPath(
          p,
          Paint()
            ..color = _eyeInk
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .5
            ..strokeCap = StrokeCap.round,
        );
        break;
      case CoucouMochiEye.closed:
        final Path p = Path()
          ..addArc(
            Rect.fromCircle(center: Offset(0, -h * .08), radius: w * .78),
            math.pi * .15,
            math.pi * .7,
          );
        canvas.drawPath(
          p,
          Paint()
            ..color = _eyeInk
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .36
            ..strokeCap = StrokeCap.round,
        );
        break;
      case CoucouMochiEye.spiral:
        final Path p = Path();
        for (double a = 0; a < 4.4 * math.pi; a += .2) {
          final double rr = w * .06 + a * w * .058;
          final double aa = a + frame.time * 9 * side;
          final Offset pt = Offset(math.cos(aa) * rr, math.sin(aa) * rr);
          if (a == 0) {
            p.moveTo(pt.dx, pt.dy);
          } else {
            p.lineTo(pt.dx, pt.dy);
          }
        }
        canvas.drawPath(
          p,
          Paint()
            ..color = _eyeInk
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .22
            ..strokeCap = StrokeCap.round,
        );
        break;
      case CoucouMochiEye.heart:
        canvas.drawPath(
          _heartPath(w * 1.2),
          Paint()..color = const Color(0xFFFF4D6D),
        );
        break;
      case CoucouMochiEye.star:
        canvas.save();
        canvas.rotate(frame.time * 1.5 * side);
        canvas.drawPath(
          _starPath(w * 1.05, w * .46),
          Paint()..color = const Color(0xFFF7B32B),
        );
        canvas.restore();
        break;
      case CoucouMochiEye.tired:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-w / 2, -h * .02, w, h * .38),
            Radius.circular(w / 2),
          ),
          ink,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-w * .62, -h * .1, w * 1.24, w * .22),
            Radius.circular(w * .11),
          ),
          ink,
        );
        break;
      case CoucouMochiEye.wink:
        if (side < 0) {
          _drawEye(canvas, CoucouMochiEye.pill, w, h, open, side, r);
        } else {
          _drawEye(canvas, CoucouMochiEye.happy, w, h, open, side, r);
        }
        break;
      case CoucouMochiEye.cup:
        final double hh = math.max(h * open, w * .3);
        final double cr = math.min(w / 2, hh / 2);
        final Path p = Path()
          ..moveTo(-w / 2, -hh / 2)
          ..lineTo(w / 2, -hh / 2)
          ..lineTo(w / 2, hh / 2 - cr)
          ..quadraticBezierTo(w / 2, hh / 2, w / 2 - cr, hh / 2)
          ..lineTo(-w / 2 + cr, hh / 2)
          ..quadraticBezierTo(-w / 2, hh / 2, -w / 2, hh / 2 - cr)
          ..close();
        canvas.drawPath(p, ink);
        break;
    }
  }

  void _drawMouth(Canvas canvas, Path body, double r) {
    canvas.save();
    canvas.clipPath(body);
    final double morph = frame.morph;
    final double w = r * 1.8 * morph;
    final double h = frame.slotOpen * r * morph;
    final double top = -r * (.88 + .06 * morph);
    final double y = top + r * .08 * morph;
    canvas.drawLine(
      Offset(-r * .9 * morph, top + 1),
      Offset(r * .9 * morph, top + 1),
      Paint()
        ..color = Colors.white.withValues(alpha: .55 * morph)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
    if (h > .8) {
      final Rect rect = Rect.fromLTWH(-w / 2, y, w, h);
      final double radius = math.min(w / 2, h / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, y), Offset(0, y + h), const [
            Color(0xFF07080A),
            Color(0xFF10131A),
          ]),
      );
      if (h > 4) {
        canvas.drawLine(
          Offset(-w / 2 + radius, y + h - .5),
          Offset(w / 2 - radius, y + h - .5),
          Paint()
            ..color = Colors.white.withValues(alpha: .28 * morph)
            ..strokeWidth = 1
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    canvas.restore();
  }

  void _drawHands(
    Canvas canvas,
    double r,
    double rx,
    double ry,
    double cx,
    double cy,
  ) {
    if (frame.hands <= .01 || r <= 14 || isMini) return;
    final double bodyH = 2 * ry;
    final double handW = .3 * ry * frame.hands;
    final double handH = .26 * ry * frame.hands;
    final double bodyX = rx * frame.scaleX;
    final double bodyY = ry * frame.scaleY;
    final bool waving = frame.handWave >= .45 && frame.handWave < 1.55;
    final double waveT = frame.handWave - .45;
    for (final double side in const [-1, 1]) {
      double x = side * bodyX * 1.08;
      double y = bodyY * .7;
      double rotation = 0;
      if (waving && side > 0) {
        final double rise = _easeOut((waveT / .18).clamp(0.0, 1.0).toDouble());
        final double restX = bodyX * 1.08;
        final double restY = bodyY * .7;
        final double waveX = bodyX * 1.1 + math.cos(13 * waveT) * .06 * bodyH;
        final double waveY = -bodyY * .15 - math.sin(13 * waveT) * .14 * bodyH;
        x = _lerp(restX, waveX, rise);
        y = _lerp(restY, waveY, rise);
        rotation = (-.5 + math.sin(13 * waveT) * .35) * rise;
      } else if (waving && side < 0) {
        y += math.sin(6 * waveT) * .04 * bodyH;
      }
      final double cosT = math.cos(frame.tilt);
      final double sinT = math.sin(frame.tilt);
      final double worldX = cx + cosT * x - sinT * y;
      final double worldY = cy + sinT * x + cosT * y;
      canvas.save();
      canvas.translate(worldX, worldY);
      canvas.rotate(rotation);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: handW * 2,
          height: handH * 2,
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(handW * .7, -handH * .85),
            Offset(-handW * .8, handH * .9),
            const [_baseTop, _baseBottom],
          ),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: handW * 2,
          height: handH * 2,
        ),
        Paint()
          ..color = const Color(0x14000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.restore();
    }
  }

  void _drawBadge(
    Canvas canvas,
    CoucouMochiBadge badge,
    int colorValue,
    double r,
    double cx,
    double cy,
  ) {
    canvas.save();
    canvas.translate(cx - r * .72 * frame.scaleX, cy - r * .72 * frame.scaleY);
    canvas.scale(frame.badgeScale * (isMini ? 1.25 : 1));
    final Color color = Color(colorValue);
    switch (badge) {
      case CoucouMochiBadge.dots:
        if (isMini) {
          final radius =
              r * .22 * (1 + .25 * math.sin(frame.time * 2.4 * _tau));
          canvas.drawCircle(
            Offset.zero,
            radius + r * .055,
            Paint()..color = Colors.black,
          );
          canvas.drawCircle(Offset.zero, radius, Paint()..color = color);
          break;
        }
        final RRect pill = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * .72, height: r * .36),
          Radius.circular(r * .18),
        );
        canvas.drawRRect(pill, Paint()..color = color);
        for (int i = 0; i < 3; i++) {
          final double phase = ((frame.time * 2.4 - i * .22) % 1 + 1) % 1;
          final double radius =
              r * .055 * (1 + .4 * math.max(0.0, math.sin(phase * _tau)));
          canvas.drawCircle(
            Offset((i - 1) * r * .18, 0),
            radius,
            Paint()..color = Colors.white,
          );
        }
        break;
      case CoucouMochiBadge.bang:
      case CoucouMochiBadge.question:
        canvas.drawCircle(Offset.zero, r * .3, Paint()..color = Colors.black);
        canvas.drawCircle(Offset.zero, r * .23, Paint()..color = color);
        if (!isMini) {
          _drawBadgeGlyph(
            canvas,
            badge == CoucouMochiBadge.bang ? '!' : '?',
            r,
          );
        }
        break;
      case CoucouMochiBadge.dot:
        canvas.drawCircle(Offset.zero, r * .2, Paint()..color = Colors.black);
        canvas.drawCircle(Offset.zero, r * .135, Paint()..color = color);
        break;
    }
    canvas.restore();
  }

  void _drawBadgeGlyph(Canvas canvas, String glyph, double r) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          color: Colors.white,
          fontSize: r * .32,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      Offset(-painter.width / 2, -painter.height / 2 + r * .02),
    );
    painter.dispose();
  }

  void _drawParticles(Canvas canvas, double r, double cx, double cy) {
    for (final CoucouMochiParticle particle in frame.particles) {
      canvas.save();
      canvas.translate(cx + particle.x * r * 1.3, cy + particle.y * r * 1.3);
      canvas.rotate(particle.rotation);
      canvas.scale(particle.size * r);
      final Paint paint = Paint()
        ..color = _particleColor(
          particle.type,
        ).withValues(alpha: particle.alpha);
      switch (particle.type) {
        case CoucouMochiParticleType.heart:
          canvas.drawPath(_heartPath(1), paint);
          break;
        case CoucouMochiParticleType.star:
          canvas.drawPath(_starPath(1, .45), paint);
          break;
        case CoucouMochiParticleType.spark:
          canvas.drawPath(_starPath(.8, .18), paint);
          break;
        case CoucouMochiParticleType.sweat:
          final Path p = Path()
            ..moveTo(0, -1)
            ..quadraticBezierTo(.8, .2, 0, .6)
            ..quadraticBezierTo(-.8, .2, 0, -1)
            ..close();
          canvas.drawPath(p, paint);
          break;
        case CoucouMochiParticleType.z:
          final TextPainter painter = TextPainter(
            text: TextSpan(
              text: 'z',
              style: TextStyle(
                color: const Color(
                  0xFFD1DBEB,
                ).withValues(alpha: particle.alpha),
                fontSize: 1.9,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          painter.paint(
            canvas,
            Offset(-painter.width / 2, -painter.height / 2),
          );
          painter.dispose();
          break;
      }
      canvas.restore();
    }
  }

  Color _particleColor(CoucouMochiParticleType type) => switch (type) {
    CoucouMochiParticleType.heart => const Color(0xFFFF4D6D),
    CoucouMochiParticleType.star => const Color(0xFFF7B32B),
    CoucouMochiParticleType.spark => Colors.white,
    CoucouMochiParticleType.sweat => const Color(0xFF7CC7FF),
    CoucouMochiParticleType.z => const Color(0xFFD1DBEB),
  };

  Path _heartPath(double size) {
    final Path p = Path()
      ..moveTo(0, size * .38)
      ..cubicTo(
        -size * 1.05,
        -size * .15,
        -size * .5,
        -size * .95,
        0,
        -size * .38,
      )
      ..cubicTo(size * .5, -size * .95, size * 1.05, -size * .15, 0, size * .38)
      ..close();
    return p;
  }

  Path _starPath(double outer, double inner) {
    final Path p = Path();
    for (int i = 0; i < 10; i++) {
      final double a = -math.pi / 2 + i * math.pi / 5;
      final double rr = i.isEven ? outer : inner;
      final Offset point = Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        p.moveTo(point.dx, point.dy);
      } else {
        p.lineTo(point.dx, point.dy);
      }
    }
    return p..close();
  }

  @override
  bool shouldRepaint(covariant CoucouMochiPainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.isMini != isMini ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.bodyColor != bodyColor;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();
