// Launch choreography from Coucou windows/src/mochi/greeting.ts.
// Reference space and timings are kept separate from the small peek wave.
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '_scene_math.dart';

class CoucouMochiGreetingFrame {
  double hb = 58, x = 320, y = 90, sx = 1, sy = 1, tilt = 0;
  String eye = 'dot';
  double open = 1, eyeRoll = 0, lookX = 0, lookY = 0;
  double handL = 0, handR = 0, wave = -1, badge = 0, tint = 0;
  double halo = 0, haloBlue = 0, minis = 0, fx = 1, card = 0;
  double islandWidth = 184, islandHeight = 32;
}

class CoucouMochiGreetingEngine {
  static const duration = 4.6;
  static const collapseDuration = .34;
  CoucouMochiGreetingFrame sample(double t, {double? collapseAt}) {
    final p = _pose(collapseAt == null ? t : math.min(t, collapseAt));
    if (collapseAt == null || t < collapseAt) return p;
    final e = mochiInOut(mochiSeg(t, collapseAt, collapseAt + .34));
    p.islandWidth = mochiLerp(p.islandWidth, 288, e);
    p.islandHeight = mochiLerp(p.islandHeight, 32, e);
    p.x = mochiLerp(p.x, 216, e);
    p.y = mochiLerp(p.y, 16, e);
    p.hb = mochiLerp(p.hb, 17, e);
    p.badge = mochiLerp(p.badge, 1, e);
    p.tint = mochiLerp(p.tint, .6, e);
    p.halo = mochiLerp(p.halo, .6, e);
    p.haloBlue = mochiLerp(p.haloBlue, 1, e);
    p.card *= 1 - mochiSeg(t, collapseAt, collapseAt + .18);
    p.handL *= 1 - mochiSeg(t, collapseAt, collapseAt + .15);
    p.handR *= 1 - mochiSeg(t, collapseAt, collapseAt + .15);
    p.tilt *= 1 - e;
    p.sx = mochiLerp(p.sx, 1, e);
    p.sy = mochiLerp(p.sy, 1, e);
    p.eyeRoll *= 1 - e;
    p.eye = 'dot';
    final bk = mochiSeg(t, collapseAt + .14, collapseAt + .26);
    p.open = bk > 0 && bk < 1 ? 1 - math.sin(math.pi * bk) * .94 : 1;
    p.lookX *= 1 - e;
    p.lookY *= 1 - e;
    p.minis = mochiBack(mochiSeg(t, collapseAt + .24, collapseAt + .42));
    p.fx = 1 - mochiSeg(t, collapseAt, collapseAt + .2);
    return p;
  }

  CoucouMochiGreetingFrame _pose(double t) {
    final p = CoucouMochiGreetingFrame();
    final gx = mochiSeg(t, 0, .5);
    final g = math.sin(math.pi * gx / 2) + .04 * math.sin(math.pi * gx) * gx;
    p.islandWidth = mochiLerp(184, 640, g);
    p.islandHeight = mochiLerp(32, 150, g);
    p.hb = mochiLerp(3, 58, mochiBack(mochiSeg(t, .02, .45)));
    p.y = mochiLerp(16, 90, mochiOut(mochiSeg(t, .02, .45)));
    if (t >= 1.25 && t < 1.52) {
      final k = math.sin(math.pi * mochiSeg(t, 1.25, 1.52));
      p.y += p.hb * .22 * k;
      p.sy = 1 - .06 * k;
      p.sx = 1 + .04 * k;
      p.eyeRoll = k;
    }
    if (t >= 1.52 && t < 2.8) {
      final w = t - 1.52, fade = 1 - mochiSeg(t, 2.58, 2.8);
      p.x += math.sin(w * 2 * math.pi * .9) * p.hb * 1.34 * .05 * fade;
      p.tilt = math.sin(w * 2 * math.pi * .9 + .6) * .05 * fade;
      p.y += math.sin(w * 2 * math.pi * 1.8) * .8 * fade;
    }
    if (t >= 2.58 && t < 3.2) {
      p.y += p.hb * .12 * math.sin(math.pi * mochiSeg(t, 2.58, 3.2));
    }
    if (t >= .6 && t < .82) p.eye = 'happy';
    if ((t >= 2.45 && t < 2.58) || (t >= 2.85 && t < 3.2)) p.eye = 'content';
    double blink(double at) {
      final k = mochiSeg(t, at, at + .12);
      return k > 0 && k < 1 ? 1 - math.sin(math.pi * k) * .94 : 1;
    }

    p.open = math.min(blink(1.95), blink(3.8));
    if (t >= .82 && t < 1.25) p.lookY = -.2;
    if (t >= 1.52 && t < 2.45) {
      p.lookX = .55;
      p.lookY = -.45;
    }
    if (t >= 2.45 && t < 3.2) {
      p.lookX = -.3;
      p.lookY = .6;
    }
    if (t >= 3.2) {
      final k = mochiInOut(mochiSeg(t, 3.2, 3.55));
      p.lookX = mochiLerp(-.3, 0, k);
      p.lookY = mochiLerp(.6, 0, k);
    }
    p.handL = t < 2.58
        ? mochiBack(mochiSeg(t, 1.36, 1.5))
        : 1 - mochiIn(mochiSeg(t, 2.58, 2.77));
    p.handR = t < 2.58
        ? mochiBack(mochiSeg(t, 1.4, 1.54))
        : 1 - mochiIn(mochiSeg(t, 2.61, 2.8));
    p.wave = t >= 1.52 && t < 2.58 ? t - 1.52 : -1;
    p.badge = mochiBack(mochiSeg(t, 2.72, 3));
    p.tint = .6 * mochiInOut(mochiSeg(t, 3.85, 4.15));
    p.halo = mochiOut(mochiSeg(t, .3, .7));
    p.haloBlue = mochiSeg(t, 3.85, 4.15);
    p.card = mochiSeg(t, .18, .45);
    return p;
  }
}

class CoucouMochiGreetingPainter extends CustomPainter {
  CoucouMochiGreetingPainter({required this.time, this.collapseAt});
  final double time;
  final double? collapseAt;
  @override
  void paint(Canvas c, Size size) {
    final p = CoucouMochiGreetingEngine().sample(time, collapseAt: collapseAt);
    c.save();
    c.scale(size.width / 640, size.height / 150);
    c.drawRRect(
      mochiRect(320 - p.islandWidth / 2, 0, p.islandWidth, p.islandHeight, 20),
      Paint()..color = const Color(0xFF000000),
    );
    if (p.card > 0) {
      final card = mochiRect(10, 36, 620, 104, 20);
      c.drawRRect(card, Paint()..color = Color.fromRGBO(20, 21, 24, p.card));
      c.save();
      c.clipRRect(card);
      _particles(c, p);
      c.restore();
    } else if (collapseAt != null && time >= collapseAt!) {
      _particles(c, p);
    }
    if (p.minis > .01) {
      const colors = [0xFFE86A6A, 0xFF3E86E0, 0xFFEFAE5A, 0xFF8C73F2];
      for (int i = 0; i < 4; i++) {
        c.save();
        c.translate(437 + (i % 2 == 0 ? -6 : 6), 16 + (i < 2 ? -6 : 6));
        c.scale(p.minis);
        c.drawPath(
          mochiSuperellipse(5.3, 4, 3.2),
          Paint()..color = Color(colors[i]),
        );
        c.restore();
      }
    }
    _body(c, p);
    c.restore();
  }

  void _body(Canvas c, CoucouMochiGreetingFrame p) {
    final hh = p.hb / 2, hw = p.hb / 2 * 1.34;
    if (hh <= .4) return;
    final halo = Color.lerp(
      const Color(0xFFE8C39A),
      const Color(0xFF3B9EFF),
      p.haloBlue,
    )!;
    for (final pair in [(2.6, .18), (4.2, .07)]) {
      c.drawCircle(
        Offset(p.x, p.y),
        hw * pair.$1,
        Paint()
          ..shader = ui.Gradient.radial(Offset(p.x, p.y), hw * pair.$1, [
            halo.withValues(alpha: pair.$2 * p.halo),
            halo.withValues(alpha: 0),
          ]),
      );
    }
    c.save();
    c.translate(p.x, p.y);
    c.rotate(p.tilt);
    c.scale(p.sx, p.sy);
    if (p.handL > .01) {
      final r = p.hb * .15 * p.handL;
      final x = mochiLerp(-hw * .35, -hw - p.hb * .22, p.handL);
      final y =
          mochiLerp(hh * .85, hh * .62, p.handL) +
          (p.wave >= 0 ? math.sin(p.wave * 6) * p.hb * .02 : 0);
      c.save();
      c.translate(x, y);
      _white(
        c,
        Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)),
        Offset(r, -r),
        Offset(-r, r),
        outline: true,
      );
      c.restore();
    }
    if (p.handR > .01) {
      final l = p.hb * .4 * p.handR, h = p.hb * .22 * p.handR;
      var x = mochiLerp(hw * .35, hw + p.hb * .2, p.handR);
      var y = mochiLerp(hh * .85, hh * .2, p.handR);
      var angle = -.61;
      if (p.wave >= 0) {
        final w = p.wave * 2 * math.pi * 2.5;
        angle += math.sin(w) * .21;
        y += math.sin(w + .8) * p.hb * .04;
        x += math.cos(w) * p.hb * .015;
      }
      c.save();
      c.translate(x, y);
      c.rotate(angle);
      _white(
        c,
        Path()..addRRect(mochiRect(-l / 2, -h / 2, l, h, h / 2)),
        Offset(l / 2, -h / 2),
        Offset(-l / 2, h / 2),
        outline: true,
      );
      c.restore();
    }
    final body = mochiSuperellipse(hw, hh, 3.2);
    _white(c, body, Offset(hw * .6, -hh), Offset(-hw * .6, hh));
    c.save();
    c.clipPath(body);
    c.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, hh), Offset(0, -hh * .1), [
          Color.fromRGBO(127, 180, 234, p.tint),
          const Color(0x007FB4EA),
        ]),
    );
    final er = p.hb * .06, sp = p.hb * .19;
    final lx = p.lookX * hw * .42,
        ly = p.lookY * hh * .28 + hh * .12 + p.eyeRoll * hh * 1.25;
    for (final side in [-1, 1]) {
      c.save();
      c.translate(side * sp + lx, ly);
      if (p.eye == 'dot') {
        c.scale(1, math.max(.12, p.open));
        c.drawCircle(Offset.zero, er, Paint()..color = const Color(0xFF16171A));
      } else {
        final happy = p.eye == 'happy';
        c.drawArc(
          Rect.fromCircle(
            center: Offset(0, er * (happy ? .6 : -.5)),
            radius: er * 1.25,
          ),
          math.pi * (happy ? 1.15 : .15),
          math.pi * .7,
          false,
          mochiStroke(const Color(0xFF16171A), er * .95),
        );
      }
      c.restore();
    }
    c.restore();
    if (p.badge > .01) {
      final br = hh * .3;
      c.save();
      c.translate(-hw * .78, -hh * .72);
      c.scale(p.badge);
      c.drawCircle(
        Offset.zero,
        br + hh * .07,
        Paint()..color = const Color(0xFF000000),
      );
      c.drawCircle(Offset.zero, br, Paint()..color = const Color(0xFF3BA0F5));
      for (final i in [-1, 0, 1]) {
        c.drawCircle(
          Offset(i * br * .5, 0),
          br * .17,
          Paint()..color = const Color(0xFF0B1B3A),
        );
      }
      c.restore();
    }
    c.restore();
  }

  void _white(
    Canvas c,
    Path p,
    Offset start,
    Offset end, {
    bool outline = false,
  }) {
    c.drawPath(
      p,
      Paint()
        ..shader = ui.Gradient.linear(start, end, const [
          Color(0xFFFBFBFC),
          Color(0xFFE7E9EC),
        ]),
    );
    if (outline) c.drawPath(p, mochiStroke(const Color(0x14000000), .8));
  }

  void _particles(Canvas c, CoucouMochiGreetingFrame p) {
    // Same LCG, order and seed as the Swift/TS launch effect.
    int seed = 7;
    double rnd() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    for (final at in [.1, .2, .3, .45, .6]) {
      final k = mochiSeg(time, at, at + 1.35);
      final rx = mochiLerp(14, 380, mochiOut(k)),
          ry = mochiLerp(14, 380, mochiOut(k)) * .34;
      final fade = (1 - k) * (k < .08 ? k / .08 : 1) * p.fx * p.card;
      for (int i = 0; i < 170; i++) {
        final a = rnd() * math.pi * 2,
            r = 1 + (rnd() - .5) * .22,
            s = .7 + rnd() * .9,
            al = .45 + rnd() * .55;
        if (k <= 0 || k >= 1) continue;
        c.drawRect(
          Rect.fromLTWH(
            320 + math.cos(a) * rx * r,
            90 + math.sin(a) * ry * r,
            s,
            s,
          ),
          Paint()..color = Color.fromRGBO(255, 255, 255, al * fade),
        );
      }
    }
    const colors = [0xFF3B9EFF, 0xFFF29B38, 0xFFFF5A4E, 0xFF2EC4A0, 0xFFA78BFA];
    for (int i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + (rnd() - .5) * .3;
      final speed = 230 + rnd() * 260,
          length = 6 + rnd() * 9,
          at = .08 + rnd() * .14;
      final k = mochiSeg(time, at, at + .6);
      if (k <= 0 || k >= 1) continue;
      final d = speed * mochiOut(k) * .9 + 10;
      c.drawLine(
        Offset(
          320 + math.cos(a) * (d - length),
          90 + math.sin(a) * (d - length) * .42,
        ),
        Offset(320 + math.cos(a) * d, 90 + math.sin(a) * d * .42),
        mochiStroke(
          Color(colors[i % 5]).withValues(alpha: (1 - k) * p.fx),
          1.6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(CoucouMochiGreetingPainter oldDelegate) =>
      time != oldDelegate.time || collapseAt != oldDelegate.collapseAt;
}
