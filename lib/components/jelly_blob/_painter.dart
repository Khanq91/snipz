// Draws one JellyFrame into the 900x720 design space, mirroring the upstream
// SVG's group tree: shadow -> (gaze-lean/boop/shake -> nod -> arms -> body ->
// face -> fx -> decor). SVG blur filters become MaskFilter.blur (sigma ==
// stdDeviation; the canvas scale carries it), objectBoundingBox gradients
// become radial shaders drawn through a squashed-circle transform, and group
// opacity is multiplied into each paint instead of saveLayer (cheaper; the
// double-blend on overlapping translucent shapes is invisible here).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '_engine.dart';
import '_geom.dart';
import '_palette.dart';

const Color _ink = Color(0xFF21102F); // face ink — fixed on every skin
const Color _happyMouthFill = Color(0xFF3A0F24);
const Color _tearBlue = Color(0xFF9DE8FF);

class JellyBlobPainter extends CustomPainter {
  JellyBlobPainter({
    required this.frame,
    required this.palette,
    super.repaint,
  });

  final JellyFrame frame;
  final JellyBlobPalette palette;

  final JellyStaticPaths _sp = JellyStaticPaths.instance;

  // Shaders are constant per palette; the painter is rebuilt when the
  // palette changes, so plain late finals are safe caches.
  late final ui.Shader _bodyFill = ui.Gradient.radial(
    const Offset(345, 192),
    520,
    [palette.bodyTop, palette.bodyMid, palette.bodyDeep, palette.bodyRim],
    const [0, .32, .67, 1],
  );
  late final ui.Shader _bodyEdge = ui.Gradient.linear(
    const Offset(215, 150),
    const Offset(735, 600),
    [palette.outlineLight, palette.outline, palette.outlineLight],
    const [0, .55, 1],
  );
  late final ui.Shader _armFillL = _armShader(const Offset(211.5, 398));
  late final ui.Shader _armFillR = _armShader(const Offset(681.5, 398));
  // objectBoundingBox radials, in "squashed-circle" local space (see
  // _gradEllipse): unit coords scale by the ellipse WIDTH on both axes.
  late final ui.Shader _cheekFill = ui.Gradient.radial(
    const Offset(-11.2, -15.4),
    54.6,
    [palette.cheekLight, palette.cheek, palette.cheekDeep],
    const [0, .6, 1],
  );
  late final ui.Shader _eyeFill = ui.Gradient.radial(
    const Offset(-10.24, -16.64),
    51.2,
    [palette.eyeLight, palette.eye, palette.eyeDeep],
    const [0, .55, 1],
  );
  late final ui.Shader _bellyGlow = ui.Gradient.radial(
    Offset.zero,
    240,
    [
      palette.bellyGlow.withValues(alpha: .5),
      palette.bellyGlow.withValues(alpha: .22),
      palette.bellyGlow.withValues(alpha: 0),
    ],
    const [0, .7, 1],
  );
  late final ui.Shader _shadowFill = ui.Gradient.radial(
    Offset.zero,
    236,
    [
      palette.effectiveShadow.withValues(alpha: .38),
      palette.effectiveShadowLight.withValues(alpha: .17),
      palette.effectiveShadowLight.withValues(alpha: 0),
    ],
    const [0, .58, 1],
  );

  ui.Shader _armShader(Offset center) => ui.Gradient.radial(
        center,
        56,
        [palette.armLight, palette.armMid, palette.armDeep],
        const [0, .55, 1],
      );

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / kJellyViewBox.width;
    canvas.save();
    canvas.scale(s);

    _drawShadow(canvas);

    final JellyFrame f = frame;
    _pose(canvas,
        x: f.attX,
        y: f.attY,
        rot: f.shakeRot,
        sx: f.boopSx,
        sy: f.boopSy,
        pivot: kJellyPivotOuter);
    _pose(canvas,
        x: f.nodX,
        y: f.nodY,
        rot: f.nodRot,
        sx: f.nodSx,
        sy: f.nodSy,
        pivot: kJellyPivotNod);

    _drawArm(canvas, left: true);
    _drawArm(canvas, left: false);
    _drawBody(canvas);
    _drawFace(canvas);
    _drawFx(canvas);
    _drawHappyDecor(canvas);

    canvas.restore(); // nod
    canvas.restore(); // outer
    canvas.restore(); // viewBox scale
  }

  // translate -> rotate -> skew -> scale about a pivot; caller must restore.
  void _pose(Canvas c,
      {double x = 0,
      double y = 0,
      double rot = 0,
      double sx = 1,
      double sy = 1,
      double skewX = 0,
      required Offset pivot}) {
    c.save();
    c.translate(x + pivot.dx, y + pivot.dy);
    if (rot != 0) c.rotate(rot * math.pi / 180);
    if (skewX != 0) c.skew(math.tan(skewX * math.pi / 180), 0);
    if (sx != 1 || sy != 1) c.scale(sx, sy);
    c.translate(-pivot.dx, -pivot.dy);
  }

  /// Draws an ellipse with an objectBoundingBox-style radial gradient: in the
  /// squashed space both unit axes scale by the ellipse width, so the shader
  /// stretches with the bounds exactly like the SVG.
  void _gradEllipse(Canvas c, Offset center, double rx, double ry,
      ui.Shader shader, double opacity,
      {MaskFilter? blur}) {
    if (opacity <= 0) return;
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(1, ry / rx);
    final Paint p = Paint()
      ..shader = shader
      ..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0));
    if (blur != null) p.maskFilter = blur;
    c.drawCircle(Offset.zero, rx, p);
    c.restore();
  }

  void _ellipse(Canvas c, Offset center, double rx, double ry, Paint p,
      {double rotDeg = 0}) {
    c.save();
    c.translate(center.dx, center.dy);
    if (rotDeg != 0) c.rotate(rotDeg * math.pi / 180);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), p);
    c.restore();
  }

  Paint _fill(Color color, double opacity) => Paint()
    ..color = color.withValues(alpha: color.a * opacity.clamp(0.0, 1.0));

  Paint _stroke(Color color, double width, double opacity,
      {StrokeCap cap = StrokeCap.round, MaskFilter? blur}) {
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = cap
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: color.a * opacity.clamp(0.0, 1.0));
    if (blur != null) p.maskFilter = blur;
    return p;
  }

  // ── ground shadow ─────────────────────────────────────────────────────────

  void _drawShadow(Canvas c) {
    final JellyFrame f = frame;
    // big soft glow — the relative gradient stretches with rx/ry like the SVG
    c.save();
    c.translate(450, 600);
    c.scale(f.sh1Rx / 236, f.sh1Ry / 43);
    c.drawCircle(
        Offset.zero,
        236,
        Paint()
          ..shader = _shadowFill
          ..color = Color.fromRGBO(0, 0, 0, f.sh1Op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    c.restore();
    // tighter contact shadow
    _ellipse(
        c,
        const Offset(450, 593),
        f.sh2Rx,
        f.sh2Ry,
        _fill(palette.effectiveShadow, f.sh2Op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
  }

  // ── arms ──────────────────────────────────────────────────────────────────

  void _drawArm(Canvas c, {required bool left}) {
    final JellyFrame f = frame;
    final Offset pivot = left ? kJellyPivotArmLeft : kJellyPivotArmRight;
    // curated rest pose (fixed per seed)
    _pose(c,
        x: left ? f.armRestLDx : f.armRestRDx,
        y: left ? f.armRestLDy : f.armRestRDy,
        rot: left ? f.armRestLRot : f.armRestRRot,
        pivot: pivot);
    // mood pose
    _pose(c,
        y: left ? f.armLY : f.armRY,
        rot: left ? f.armLRot : f.armRRot,
        sx: left ? f.armLS : f.armRS,
        sy: left ? f.armLS : f.armRS,
        pivot: pivot);
    // idle fidget
    _pose(c,
        y: left ? f.armLFidgetLift : f.armRFidgetLift,
        rot: left ? f.armLFidgetRot : f.armRFidgetRot,
        pivot: pivot);

    final Path base = left ? _sp.armLeft : _sp.armRight;
    c.drawPath(base, Paint()..shader = (left ? _armFillL : _armFillR));
    c.drawPath(base, _stroke(palette.armDeep, 5.5, 1));
    c.drawPath(
        left ? _sp.armLeftShadow : _sp.armRightShadow,
        _stroke(palette.armDeep, 9, .14,
            blur: const MaskFilter.blur(BlurStyle.normal, 9)));
    _ellipse(c, left ? const Offset(196, 405) : const Offset(704, 405), 5.6, 9,
        _fill(const Color(0xFFFFFFFF), .6),
        rotDeg: left ? 24 : -24);

    c.restore();
    c.restore();
    c.restore();
  }

  // ── body ──────────────────────────────────────────────────────────────────

  void _drawBody(Canvas c) {
    final JellyFrame f = frame;
    _pose(c,
        x: f.bodyX,
        y: f.bodyY,
        rot: f.bodyRot,
        sx: f.bodySx,
        sy: f.bodySy,
        skewX: f.bodySkewX,
        pivot: kJellyPivotBody);

    final Path body = f.body.toPath();
    c.drawPath(body, Paint()..shader = _bodyFill);
    c.drawPath(
        body,
        Paint()
          ..shader = _bodyEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.8
          ..strokeJoin = StrokeJoin.round);

    // interior shading, clipped to the live silhouette
    c.save();
    c.clipPath(body);
    const MaskFilter wide = MaskFilter.blur(BlurStyle.normal, 14);
    const MaskFilter soft = MaskFilter.blur(BlurStyle.normal, 9);
    c.drawPath(_sp.leftInnerShine,
        _stroke(const Color(0xFFFFFFFF), 22, .13, blur: wide));
    c.drawPath(_sp.rightInnerShade, _stroke(palette.outline, 24, .14, blur: wide));
    _ellipse(c, const Offset(470, 175), 92, 27,
        _fill(const Color(0xFFFFFFFF), .14)..maskFilter = soft,
        rotDeg: 1);
    _ellipse(c, const Offset(592, 252), 16, 36,
        _fill(const Color(0xFFFFFFFF), .14)..maskFilter = soft,
        rotDeg: -26);
    c.restore();

    // belly glow (outside the clip so the sad y-shift never drops it)
    _pose(c,
        x: f.bellyX,
        y: f.bellyY,
        sx: f.bellySx,
        sy: f.bellySy,
        pivot: kJellyPivotBelly);
    _gradEllipse(c, const Offset(450, 504), 240, 62, _bellyGlow, .95);
    c.restore();

    // head gloss + faint side glosses
    _pose(c,
        y: f.headHlY,
        sx: f.headHlSx,
        sy: f.headHlSy,
        pivot: kJellyPivotHeadHighlight);
    final double hl = f.headHlOp;
    c.save();
    c.translate(f.glossGazeX, f.glossGazeY);
    final double gl = f.glossOp * hl;
    _ellipse(c, const Offset(372, 212), 37, 21,
        _fill(const Color(0xFFFFFFFF), .9 * gl),
        rotDeg: -36);
    c.drawCircle(const Offset(320, 268), 12,
        _fill(const Color(0xFFFFFFFF), .86 * gl));
    c.drawCircle(const Offset(424, 172), 10,
        _fill(const Color(0xFFFFFFFF), f.topDotOp * gl));
    c.restore();
    const MaskFilter soft2 = MaskFilter.blur(BlurStyle.normal, 9);
    _ellipse(c, const Offset(252, 470), 17, 56,
        _fill(const Color(0xFFFFFFFF), .09 * hl)..maskFilter = soft2,
        rotDeg: -6);
    _ellipse(c, const Offset(648, 470), 17, 56,
        _fill(const Color(0xFFFFFFFF), .09 * hl)..maskFilter = soft2,
        rotDeg: 8);
    c.restore();

    c.restore(); // body pose
  }

  // ── face ──────────────────────────────────────────────────────────────────

  void _drawFace(Canvas c) {
    final JellyFrame f = frame;
    _pose(c,
        x: f.faceX,
        y: f.faceY,
        rot: f.faceRot,
        sx: f.faceSx,
        sy: f.faceSy,
        pivot: kJellyPivotFace);

    _drawCheek(c, kJellyPivotCheekLeft);
    _drawCheek(c, kJellyPivotCheekRight);

    // eyes follow the gaze as one group
    c.save();
    c.translate(f.eyesGazeX, f.eyesGazeY);
    _drawEye(c, left: true);
    _drawEye(c, left: false);
    c.restore();

    _drawOverlayFaces(c);
    _drawMouths(c);

    c.restore(); // face pose
  }

  void _drawCheek(Canvas c, Offset center) {
    final JellyFrame f = frame;
    _pose(c,
        x: f.cheekX,
        y: f.cheekY,
        sx: f.cheekSx,
        sy: f.cheekSy,
        pivot: center);
    _gradEllipse(c, center, 35, 23, _cheekFill, .82 * f.cheekOp);
    final double side = center == kJellyPivotCheekLeft ? 0 : 308;
    _ellipse(c, Offset(294 + side, 421), 6.2, 4.2,
        _fill(const Color(0xFFFFFFFF), .44 * f.cheekOp),
        rotDeg: -20);
    _ellipse(c, Offset(319 + side, 420), 5.8, 4,
        _fill(const Color(0xFFFFFFFF), .36 * f.cheekOp),
        rotDeg: 22);
    c.restore();
  }

  void _drawEye(Canvas c, {required bool left}) {
    final JellyFrame f = frame;
    final Offset center = left ? kJellyPivotEyeLeft : kJellyPivotEyeRight;
    c.save();
    c.translate(left ? f.eyeLOffX : f.eyeROffX, left ? f.eyeLOffY : f.eyeROffY);

    final double op = f.normalEyeOp;
    if (op > .003) {
      final double blink = left ? f.blinkL : f.blinkR;
      final double blinkSx = left ? f.blinkLSx : f.blinkRSx;
      _pose(c,
          y: f.eyeYOff,
          sx: f.eyeSx * blinkSx,
          sy: f.eyeSy * blink,
          pivot: center);
      _gradEllipse(c, center, 32, 39, _eyeFill, op);
      _ellipse(c, center + const Offset(0, 22), 23, 12,
          _fill(palette.eyeLight, .3 * op));
      c.drawCircle(left ? const Offset(364, 353) : const Offset(540, 353),
          10.5, _fill(const Color(0xFFFFFFFF), f.mainHlOp * op));
      if (f.starOp > .003) {
        final Offset sp = left ? kJellyPivotStarLeft : kJellyPivotStarRight;
        _pose(c, sx: f.starScale, sy: f.starScale, pivot: sp);
        c.drawPath(left ? _sp.eyeStarLeft : _sp.eyeStarRight,
            _fill(const Color(0xFFFFFFFF), f.starOp * op));
        c.restore();
      }
      c.drawCircle(left ? const Offset(359, 347) : const Offset(545, 347),
          3.2, _fill(const Color(0xFFFFFFFF), .58 * op));
      c.drawCircle(left ? const Offset(339, 391) : const Offset(565, 391),
          5.8, _fill(palette.eyeSparkle, .62 * op));
      c.restore();
    }

    // ^_^ arc (happyEyes: smile)
    if (f.arcOp > .003) {
      final Offset ap = left ? kJellyPivotArcLeft : kJellyPivotArcRight;
      _pose(c, sy: f.arcSy, pivot: ap);
      c.drawPath(left ? _sp.happyArcLeft : _sp.happyArcRight,
          _stroke(palette.eye, 11, f.arcOp));
      c.restore();
    }
    c.restore();
  }

  void _drawOverlayFaces(Canvas c) {
    final JellyFrame f = frame;
    if (f.pwOp > .003) {
      c.save();
      c.translate(0, f.pwBobY * f.pwOp);
      final Paint p = _stroke(_ink, 12, .92 * f.pwOp);
      c.drawPath(_sp.passwordEyeLeft, p);
      c.drawPath(_sp.passwordEyeRight, p);
      _ellipse(c, const Offset(452, 397), 13, 9, _fill(_ink, .92 * f.pwOp));
      c.restore();
    }
    if (f.sideOp > .003) {
      c.save();
      c.translate(-4 * f.sideOp, 1 * f.sideOp);
      final Paint p = _stroke(_ink, 11, .92 * f.sideOp);
      c.drawPath(_sp.sideEyeBrowLeft, p);
      c.drawPath(_sp.sideEyeBrowRight, p);
      _ellipse(c, const Offset(373, 360), 10.5, 13.5,
          _fill(_ink, .92 * f.sideOp),
          rotDeg: -16);
      _ellipse(c, const Offset(579, 360), 10.5, 13.5,
          _fill(_ink, .92 * f.sideOp),
          rotDeg: -16);
      c.restore();
    }
    if (f.hmmOp > .003) {
      c.save();
      final double u = (f.hmmOp / .52).clamp(0.0, 1.0);
      c.translate(-2 * u, 2);
      final Paint p = _stroke(_ink, 6.5, .62 * f.hmmOp);
      c.drawPath(_sp.hmmLidLeft, p);
      c.drawPath(_sp.hmmLidRight, p);
      c.restore();
    }
    if (f.sadBrowOp > .003) {
      c.save();
      c.translate(0, f.sadBrowY);
      final Paint p = _stroke(_ink, 7, .58 * f.sadBrowOp);
      c.drawPath(_sp.sadBrowLeft, p);
      c.drawPath(_sp.sadBrowRight, p);
      c.restore();
    }
  }

  void _drawMouths(Canvas c) {
    final JellyFrame f = frame;
    if (f.happyMouthOp > .003) {
      c.drawPath(_sp.happyMouthFill, _fill(_happyMouthFill, f.happyMouthOp));
      c.drawPath(_sp.happyMouthTongue, _fill(palette.cheek, f.happyMouthOp));
      _ellipse(c, const Offset(452, 427), 9, 3.4,
          _fill(const Color(0xFFFFC2DC), .7 * f.happyMouthOp));
    }
    if (f.mouthOp > .003) {
      final Path m = Path()
        ..moveTo(f.mouthPts[0], f.mouthPts[1])
        ..cubicTo(f.mouthPts[2], f.mouthPts[3], f.mouthPts[4], f.mouthPts[5],
            f.mouthPts[6], f.mouthPts[7]);
      c.drawPath(m, _stroke(_ink, f.mouthW, f.mouthOp));
    }
    if (f.talkOp > .003) {
      // collapse toward a small flat shape as the talk mouth fades out
      final double u = f.talkOp;
      _pose(c,
          y: f.talkY,
          sx: .72 + (f.talkSx - .72) * u,
          sy: .35 + (f.talkSy - .35) * u,
          pivot: kJellyPivotMouth);
      c.drawPath(jellyTalkPath(f.talkPts), _fill(_ink, u));
      c.restore();
    }
  }

  // ── emotion fx + happy decor ──────────────────────────────────────────────

  void _drawFx(Canvas c) {
    final JellyFrame f = frame;
    if (f.fxOp <= .003) return;
    _pose(c, y: f.fxY, sx: f.fxScale, sy: f.fxScale, pivot: kJellyPivotFx);

    if (f.tearOp > .003) {
      c.save();
      c.translate(0, f.tearY);
      final double top = f.tearOp * f.fxOp;
      c.drawPath(_sp.tearLeft, _fill(_tearBlue, .82 * top));
      c.drawPath(_sp.tearRight, _fill(_tearBlue, .82 * top));
      _ellipse(c, const Offset(335, 410), 3.2, 5.8,
          _fill(const Color(0xFFFFFFFF), .48 * top),
          rotDeg: 18);
      _ellipse(c, const Offset(570, 410), 3.2, 5.8,
          _fill(const Color(0xFFFFFFFF), .48 * top),
          rotDeg: 18);
      c.restore();
    }

    if (f.angryOp > .003) {
      c.save();
      c.translate(f.angryX, 0);
      c.drawPath(_sp.angryMarks, _stroke(palette.outline, 9, .86 * f.fxOp));
      c.drawCircle(const Offset(260, 306), 13, _fill(palette.bodyRim, .55 * f.fxOp));
      c.drawCircle(const Offset(241, 292), 8, _fill(palette.bodyRim, .45 * f.fxOp));
      c.drawCircle(const Offset(683, 304), 13, _fill(palette.bodyRim, .55 * f.fxOp));
      c.drawCircle(const Offset(704, 290), 8, _fill(palette.bodyRim, .45 * f.fxOp));
      c.restore();
    }

    c.restore();
  }

  void _drawHappyDecor(Canvas c) {
    final JellyFrame f = frame;
    if (f.decorOp <= .003) return;
    c.save();
    c.translate(0, f.sparkY);
    c.drawPath(_sp.happySpark, _fill(const Color(0xFFFFE07A), f.decorOp));
    c.restore();
    c.drawCircle(const Offset(662, 318), 4,
        _fill(const Color(0xFFFFF2A8), f.decorOp));
    c.save();
    c.translate(0, f.heartY);
    c.drawPath(_sp.happyHeart, _fill(palette.cheek, f.decorOp));
    c.restore();
    c.drawCircle(const Offset(263, 328), 2.6,
        _fill(const Color(0xFFFFD0E6), .85 * f.decorOp));
  }

  @override
  bool shouldRepaint(JellyBlobPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.palette != palette;
}
