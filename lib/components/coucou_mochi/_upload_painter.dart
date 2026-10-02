// Canvas port of Coucou's UploadCanvas: body, mouth, suction and progress.
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '_scene_math.dart';
import '_upload.dart';

class CoucouMochiUploadPainter extends CustomPainter {
  const CoucouMochiUploadPainter({
    required this.frame,
    this.fileName = 'sample.txt',
  });
  final CoucouMochiUploadFrame frame;
  final String fileName;
  @override
  void paint(Canvas c, Size size) {
    final f = frame;
    c.save();
    c.scale(size.width / 640, size.height / 176);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 640, 176),
      Paint()..color = const Color(0xFF000000),
    );
    final card = mochiRect(10, 42, 620, 124, 20);
    c.save();
    c.clipRRect(card);
    c.drawRRect(card, Paint()..color = const Color(0xFF0D0E10));
    if (f.greenWash > 0) {
      c.drawRRect(
        card,
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(320, 166),
            186,
            [
              Color.fromRGBO(40, 212, 130, f.greenWash * .9),
              Color.fromRGBO(40, 212, 130, f.greenWash * .3),
              const Color(0x0028D482),
            ],
            const [0, .55, 1],
          ),
      );
    }
    c.restore();
    if (f.zoneAlpha > 0) {
      final border = Path()
        ..addRRect(mochiRect(10.75, 42.75, 618.5, 122.5, 19.5));
      for (final metric in border.computeMetrics()) {
        for (double d = -(f.t * 20) % 11; d < metric.length; d += 11) {
          c.drawPath(
            metric.extractPath(math.max(0, d), math.min(d + 6, metric.length)),
            mochiStroke(
              (f.zoneOver ? const Color(0xFF34D499) : const Color(0xFFFFFFFF))
                  .withValues(alpha: (f.zoneOver ? .55 : .14) * f.zoneAlpha),
              1.5,
            ),
          );
        }
      }
      _text(
        c,
        'Drop your files here',
        196,
        90,
        13,
        const Color(0xFFD5D7DB),
        alpha: f.textAlpha,
      );
      double x = 196;
      for (final label in ['PDF', 'Images', 'Code', 'Docs']) {
        final w = label.length * 6.5 + 16;
        c.drawRRect(
          mochiRect(x, 103, w, 18, 9),
          Paint()..color = Color.fromRGBO(255, 255, 255, .07 * f.textAlpha),
        );
        _text(
          c,
          label,
          x + 8,
          112,
          11,
          const Color(0xFFB9BDC4),
          alpha: f.textAlpha,
        );
        x += w + 6;
      }
    }
    if (f.barAlpha > 0 || f.barReveal > 0) {
      final alpha = f.barAlpha.clamp(0.0, 1.0);
      _text(
        c,
        'Uploading $fileName',
        46,
        88,
        12.5,
        const Color(0xFFA9ADB5),
        alpha: alpha,
      );
      if (f.check <= 0) {
        _text(
          c,
          '${(f.progress * 100).round()} %',
          520,
          88,
          12.5,
          const Color(0xFFA9ADB5),
          alpha: alpha,
          right: true,
        );
      }
      c.drawRRect(
        mochiRect(46, 115, 474 * f.barReveal, 6, 3),
        Paint()..color = Color.fromRGBO(255, 255, 255, .08 * alpha),
      );
      final fx = mochiLerp(46, 520, f.progress);
      if (fx > 47) {
        c.drawRRect(
          mochiRect(46, 115, fx - 46, 6, 3),
          Paint()
            ..shader = ui.Gradient.linear(const Offset(46, 0), Offset(fx, 0), [
              const Color(0xFF1FA87A).withValues(alpha: alpha),
              Color.lerp(
                const Color(0xFF34D399),
                const Color(0xFF6EE7B7),
                f.flash,
              )!.withValues(alpha: alpha),
            ]),
        );
      }
      if (f.progress > .01 && f.progress < 1) {
        c.drawRRect(
          mochiRect(fx - 20, 114, 20, 8, 4),
          Paint()
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3)
            ..shader = ui.Gradient.linear(Offset(fx - 20, 0), Offset(fx, 0), [
              const Color(0x0034D499),
              Color.fromRGBO(110, 231, 183, .6 * alpha),
            ]),
        );
      }
      if (f.check > 0) {
        c.save();
        c.translate(512, 88);
        c.scale(f.check);
        c.drawCircle(
          Offset.zero,
          8,
          Paint()..color = const Color(0xFF34D399).withValues(alpha: alpha),
        );
        c.drawPath(
          Path()
            ..moveTo(-3.6, .2)
            ..lineTo(-1, 2.8)
            ..lineTo(3.8, -2.6),
          mochiStroke(const Color(0xFF07130E).withValues(alpha: alpha), 2),
        );
        c.restore();
      }
    }
    if (f.chooseAlpha > 0) {
      _text(
        c,
        '$fileName is ready.',
        114,
        80,
        14,
        const Color(0xFFF5F6F8),
        alpha: f.chooseAlpha,
      );
      _text(
        c,
        'Upload complete',
        114,
        100,
        12.5,
        const Color(0xFF9398A1),
        alpha: f.chooseAlpha,
      );
    }
    _mochi(c, f);
    if (f.fileVisible) _file(c, f);
    c.restore();
  }

  void _mochi(Canvas c, CoucouMochiUploadFrame f) {
    final r = f.d / 2 / 1.04, m = f.morph.clamp(0.0, 1.0);
    final rx = r * (1.04 - .04 * m), ry = r * (.97 - .03 * m);
    c.save();
    c.translate(f.x, f.y + f.hop);
    c.rotate(f.tilt);
    c.scale(f.sx, f.sy);
    final body = mochiSuperellipse(rx, ry, 2.15 + (5.5 - 2.15) * m);
    c.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(rx * .7, -ry * .9),
          Offset(-rx * .8, ry * .9),
          const [Color(0xFFEDEDEF), Color(0xFFC4C5CA)],
        ),
    );
    c.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          r * 1.3,
          const [Color(0x00000000), Color(0x00000000), Color(0x1F000000)],
          const [0, .67846, 1],
        ),
    );
    c.save();
    c.clipPath(body);
    if (m > .3) {
      c.drawLine(
        Offset(-rx * .72, -ry + .9),
        Offset(rx * .72, -ry + .9),
        mochiStroke(Color.fromRGBO(255, 255, 255, .6 * (m - .3) / .7), 1.2),
      );
    }
    final mh = f.mouth * r * m, mw = 2 * rx - .24 * r, my = -ry + .1 * r;
    if (mh > .3) {
      c.drawRRect(
        mochiRect(-mw / 2, my, mw, mh, math.min(mw / 2, mh / 2)),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, my),
            Offset(0, my + mh),
            const [Color(0xFF030304), Color(0xFF101114)],
          ),
      );
      if (mh > 4) {
        final radius = math.min(mw / 2, mh / 2);
        c.drawLine(
          Offset(-mw / 2 + radius, my + mh + .5),
          Offset(mw / 2 - radius, my + mh + .5),
          mochiStroke(const Color(0x8CFFFFFF), 1),
        );
      }
    }
    final ew = r * .25,
        eh = r * (.62 - .16 * m),
        ey = r * (.02 + .28 * m),
        sp = r * .3;
    final lx = f.lookX * r * (.34 - .08 * m),
        ly = f.lookY * r * (.16 - .09 * m);
    for (final side in [-1, 1]) {
      c.save();
      c.translate(side * sp + lx, ey + ly);
      final ink = Paint()..color = const Color(0xFF0E0F12);
      if (f.eye == 'content') {
        c.drawArc(
          Rect.fromCircle(center: Offset(0, -eh * .12), radius: ew * .85),
          math.pi * .15,
          math.pi * .7,
          false,
          mochiStroke(ink.color, ew * .5),
        );
      } else if (f.eye == 'cup') {
        final h = eh * .55;
        c.drawPath(
          Path()
            ..moveTo(-ew / 2, -h / 2)
            ..lineTo(ew / 2, -h / 2)
            ..lineTo(ew / 2, h / 2 - ew / 2)
            ..arcTo(
              Rect.fromCircle(
                center: Offset(0, h / 2 - ew / 2),
                radius: ew / 2,
              ),
              0,
              math.pi,
              false,
            )
            ..close(),
          ink,
        );
      } else {
        c.drawRRect(mochiRect(-ew / 2, -eh / 2, ew, eh, ew / 2), ink);
      }
      c.restore();
    }
    c.restore();
    c.restore();
  }

  void _file(Canvas c, CoucouMochiUploadFrame f) {
    final cx = f.cursorX, cy = f.cursorY + 14;
    if (f.suck <= 0) {
      _doc(c, cx, cy, 1, 1);
      return;
    }
    final m = f.mouthRect, p = mochiIn(f.suck);
    final top = mochiLerp(cy - 21, m.top - 2, mochiInOut(f.suck));
    final hs = mochiLerp(1.08, .55, mochiInOut(f.suck)),
        height = 42 * mochiLerp(1.08, .55, mochiInOut(f.suck));
    final sc = mochiLerp(1, .55, p), q = mochiOut(f.suck);
    final x = mochiLerp(cx, m.center.dx, mochiOut(f.suck));
    final wob = math.sin(f.suck * math.pi * 2) * .1 * (1 - p);
    c.save();
    c.clipRect(Rect.fromLTWH(0, 0, 640, math.max(0, m.top + m.height * .5)));
    for (int i = 0; i < 28; i++) {
      final v = i / 28,
          wsc =
              mochiLerp(
                1,
                mochiLerp(.92, .22 * m.width / 34, math.pow(i / 28, 1.2)),
                q,
              ) *
              sc;
      final y = top + v * height;
      c.save();
      c.translate(x, y);
      c.rotate(wob);
      c.clipRect(Rect.fromLTWH(-34 * wsc / 2, 0, 34 * wsc, height / 28 + .6));
      c.translate(-x, -y);
      _doc(c, x, top + height / 2, wsc, hs);
      c.restore();
    }
    c.restore();
    for (int i = 0; i < 4; i++) {
      final a = i / 4 * math.pi * 2 + .6,
          k = ((f.suck - i * .08) / .7).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final kk = math.pow(k, .7);
      final x = mochiLerp(cx + math.cos(a) * 24, m.center.dx, kk);
      final y =
          mochiLerp(cy + math.sin(a) * 24, m.top + m.height * .3, kk) -
          math.sin(math.pi * k) * 6;
      c.drawCircle(
        Offset(x, y),
        2.2 * (1 - k * .5),
        Paint()..color = Color.fromRGBO(52, 212, 153, 1 - k),
      );
    }
  }

  void _doc(Canvas c, double cx, double cy, double wsc, double hsc) {
    final w = 34 * wsc,
        h = 42 * hsc,
        x = cx - 17 * wsc,
        y = cy - 21 * hsc,
        fold = 8 * math.min(wsc, hsc);
    final p = Path()
      ..moveTo(x + 2, y)
      ..lineTo(x + w - fold, y)
      ..lineTo(x + w, y + fold)
      ..lineTo(x + w, y + h - 2)
      ..quadraticBezierTo(x + w, y + h, x + w - 2, y + h)
      ..lineTo(x + 2, y + h)
      ..quadraticBezierTo(x, y + h, x, y + h - 2)
      ..lineTo(x, y + 2)
      ..quadraticBezierTo(x, y, x + 2, y)
      ..close();
    c.drawShadow(p, const Color(0x73000000), 3, false);
    c.drawPath(p, Paint()..color = const Color(0xFFF4F4F6));
    c.drawPath(
      Path()
        ..moveTo(x + w - fold, y)
        ..lineTo(x + w - fold, y + fold)
        ..lineTo(x + w, y + fold)
        ..close(),
      Paint()..color = const Color(0xFFD5D6DB),
    );
    c.drawRRect(
      mochiRect(x + w * .18, y + h * .58, w * .64, h * .16, 2),
      Paint()..color = const Color(0xFF3B82F5),
    );
  }

  void _text(
    Canvas c,
    String text,
    double x,
    double y,
    double size,
    Color color, {
    double alpha = 1,
    bool right = false,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color.withValues(alpha: alpha.clamp(0.0, 1.0)),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(c, Offset(right ? x - p.width : x, y - p.height / 2));
    p.dispose();
  }

  @override
  bool shouldRepaint(CoucouMochiUploadPainter oldDelegate) =>
      frame != oldDelegate.frame || fileName != oldDelegate.fileName;
}
