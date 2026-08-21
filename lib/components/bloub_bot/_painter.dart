// Part of bloub_bot — the Flutter layer: BotFrame -> Canvas. This is the
// only rendering file; everything upstream of it is pure Dart. Mirrors the
// SVG structure of the upstream BloubBot.vue (jeremy-prt/bloub, MIT),
// including its draw order and its mask trick.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '_decor.dart';
import '_engine.dart';
import '_shape.dart';

/// Catmull-Rom tension of the silhouette outline (upstream value).
const double _tension = 1 / 6;

/// Closed polyline -> Catmull-Rom cubics, same construction as the SVG
/// `closedPath`.
Path _closedPath(List<BotPoint> pts) {
  final Path path = Path();
  final int n = pts.length;
  if (n < 3) return path;
  path.moveTo(pts[0].x, pts[0].y);
  for (int i = 0; i < n; i++) {
    final BotPoint p0 = pts[(i - 1 + n) % n];
    final BotPoint p1 = pts[i];
    final BotPoint p2 = pts[(i + 1) % n];
    final BotPoint p3 = pts[(i + 2) % n];
    path.cubicTo(
      p1.x + (p2.x - p0.x) * _tension,
      p1.y + (p2.y - p0.y) * _tension,
      p2.x - (p3.x - p1.x) * _tension,
      p2.y - (p3.y - p1.y) * _tension,
      p2.x,
      p2.y,
    );
  }
  path.close();
  return path;
}

Path _polyPath(List<BotPoint> pts, [double scale = 1]) {
  final Path path = Path();
  if (pts.length < 3) return path;
  path.moveTo(pts[0].x * scale, pts[0].y * scale);
  for (int i = 1; i < pts.length; i++) {
    path.lineTo(pts[i].x * scale, pts[i].y * scale);
  }
  path.close();
  return path;
}

/// Stadium shape centered on the origin: the exact eye shape.
RRect _capsule(double w, double h) => RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Radius.circular((w < h ? w : h) / 2),
    );

class BloubBotPainter extends CustomPainter {
  const BloubBotPainter({
    required this.frame,
    required this.ink,
    required this.paper,
  });

  final BotFrame frame;

  /// Body color (upstream default #0a0a0c).
  final Color ink;

  /// The color BEHIND the bot. Load-bearing, not cosmetic: the eyes are real
  /// holes, and the back half of arcs and the burst particles are drawn
  /// behind the body to be occluded by it — an opaque body-shaped backing in
  /// this color is what keeps them from reappearing inside the eyes.
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide / (2 * kBotDemiViewbox);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);
    final Rect viewBox = Rect.fromLTRB(
        -kBotDemiViewbox, -kBotDemiViewbox, kBotDemiViewbox, kBotDemiViewbox);

    // back half of the orbits: drawn before the body, hence occluded
    _drawArcs(canvas, back: true);

    // burst particles: they pass behind the core
    if (frame.dotsBehind) _drawDots(canvas);

    final Path body = _closedPath(frame.body);
    final bool translucentBody = frame.bodyAlpha < 0.999;
    if (translucentBody) {
      canvas.saveLayer(
          viewBox,
          Paint()
            ..color = Color.fromRGBO(0, 0, 0, frame.bodyAlpha.clamp(0, 1)));
    }

    // Opaque backing in the page color, under the body itself (see [paper]).
    canvas.drawPath(body, Paint()..color = paper);

    // The body with the eyes and the notch as REAL HOLES (like x.ai), not
    // white shapes on top: they self-clip against the silhouette when they
    // slide toward the edge. SVG does it with a mask; here a layer where the
    // eyes erase the ink (dstOut), which also supports the fractional eye
    // alpha of a mid-fade (a partial hole).
    canvas.saveLayer(viewBox, Paint());
    canvas.drawPath(body, Paint()..color = ink);
    for (final BotRenderedEye eye in frame.eyes) {
      canvas.save();
      canvas.transform(Float64List.fromList([
        eye.a, eye.b, 0, 0, //
        eye.c, eye.d, 0, 0, //
        0, 0, 1, 0, //
        eye.tx, eye.ty, 0, 1,
      ]));
      canvas.drawRRect(
        _capsule(eye.w, eye.h),
        Paint()
          ..blendMode = BlendMode.dstOut
          ..color = Color.fromRGBO(0, 0, 0, eye.alpha.clamp(0, 1)),
      );
      canvas.restore();
    }
    final BotCircleRender? notch = frame.notch;
    if (notch != null) {
      canvas.drawCircle(
        Offset(notch.x, notch.y),
        notch.r,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..color = const Color(0xFF000000),
      );
    }
    canvas.restore(); // ink + holes layer

    if (translucentBody) canvas.restore();

    if (!frame.dotsBehind) _drawDots(canvas);

    final BotCircleRender? notif = frame.notif;
    if (notif != null) {
      canvas.drawCircle(Offset(notif.x, notif.y), notif.r,
          Paint()..color = const Color(kBotNotifBlue));
    }

    // front half of the orbits
    _drawArcs(canvas, back: false);

    canvas.restore();
  }

  void _drawDots(Canvas canvas) {
    for (final BotDot dot in frame.dots) {
      // The color follows the body's by default; `depth` melts particles
      // into the background as they recede.
      final Color color = dot.colorArgb != null
          ? Color(dot.colorArgb!)
          : (dot.depth == null
              ? ink
              : Color.lerp(paper, ink, dot.depth!.clamp(0, 1))!);
      final Paint paint = Paint()
        ..color = color.withValues(alpha: dot.opacity.clamp(0, 1));
      final List<BotPoint>? shape = dot.shape;
      if (shape != null) {
        // shape is in resting-ball-radius units, centered on the origin
        canvas.save();
        canvas.translate(dot.x, dot.y);
        canvas.rotate(dot.rotDeg * 3.141592653589793 / 180);
        canvas.drawPath(_polyPath(shape, kBotRayon), paint);
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(dot.x, dot.y), dot.r, paint);
      }
    }
  }

  void _drawArcs(Canvas canvas, {required bool back}) {
    for (final BotArcRender arc in frame.arcs) {
      final List<List<BotPoint>> runs = back ? arc.back : arc.front;
      if (runs.isEmpty) continue;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = arc.width
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(arc.gradX1, arc.gradY1),
          Offset(arc.gradX2, arc.gradY2),
          [for (final int c in arc.gradArgb) Color(c)],
          const [0, 0.5, 1],
        )
        ..color = Color.fromRGBO(0, 0, 0, arc.opacity.clamp(0, 1));
      // With a shader set, the paint's alpha still applies — that is the
      // arc's fade in and out.
      final Path path = Path();
      for (final List<BotPoint> run in runs) {
        if (run.isEmpty) continue;
        path.moveTo(run[0].x, run[0].y);
        for (int i = 1; i < run.length; i++) {
          path.lineTo(run[i].x, run[i].y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(BloubBotPainter old) =>
      old.frame != frame || old.ink != ink || old.paper != paper;
}
