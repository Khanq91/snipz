// Port of Coucou windows/src/upload/sequence.ts. Reference coordinates 640x176.
// Input history is replayed at 240 Hz, so reverse scrubbing and live playback
// share the same springs, lock thresholds and phase boundaries.
import 'dart:math' as math;
import 'dart:ui';
import '_scene_math.dart';

class CoucouMochiUploadFrame {
  double t = 0,
      cursorX = 600,
      cursorY = 280,
      morph = 0,
      x = 140,
      y = 104,
      d = 62;
  double sx = 1, sy = 1, tilt = 0, hop = 0, mouth = 0;
  Rect mouthRect = Rect.zero;
  String eye = 'pill';
  double lookX = 0, lookY = 0, suck = 0;
  bool fileVisible = true, zoneOver = false;
  double zoneAlpha = 1,
      textAlpha = 1,
      barReveal = 0,
      barAlpha = 0,
      progress = 0;
  double flash = 0, check = 0, greenWash = 0, chooseAlpha = 0;
  double progEnd = 5.65, growStart = 5.9, growEnd = 6.35;
}

class CoucouMochiUploadEngine {
  final List<({double at, double x, double y})> _cursor = [];
  double? _dropAt;
  double _duration = 2.4;
  void enter(double t, double x, double y) {
    _cursor
      ..clear()
      ..add((at: t, x: x, y: y));
    _dropAt = null;
  }

  void move(double t, double x, double y) {
    if (_cursor.isEmpty || _dropAt != null) return;
    _cursor.add((at: t, x: x, y: y));
  }

  void drop(double t, {double uploadDuration = 2.4}) {
    if (_cursor.isEmpty || _dropAt != null) return;
    assert(uploadDuration > 0);
    _dropAt = t;
    _duration = uploadDuration;
  }

  double? get dropAt => _dropAt;
  CoucouMochiUploadFrame sample(double time) {
    if (_cursor.isEmpty || time < _cursor.first.at) {
      return CoucouMochiUploadFrame();
    }
    final first = _cursor.first;
    final s = _UploadSimulation()
      ..uploadDuration = _duration
      ..cursorX = first.x
      ..cursorY = first.y;
    var wall = first.at;
    var index = 1;
    var dropped = false;
    final end = math.min(time, (_dropAt ?? time) + _duration + 5);
    while (wall < end - 1e-10) {
      if (index < _cursor.length && _cursor[index].at <= wall + 1e-10) {
        final next = _cursor[index++];
        final prev = _cursor[index - 2];
        final dt = next.at - prev.at;
        if (dt > .001) {
          s.speed =
              math.sqrt(
                math.pow(next.x - prev.x, 2) + math.pow(next.y - prev.y, 2),
              ) /
              dt;
        }
        s.cursorX = next.x;
        s.cursorY = next.y;
        continue;
      }
      if (!dropped && _dropAt != null && _dropAt! <= wall + 1e-10) {
        s.dropTime = _dropAt;
        s.t = 1.95;
        dropped = true;
      }
      var dt = math.min(1 / 240, end - wall);
      if (index < _cursor.length) {
        dt = math.min(dt, math.max(0, _cursor[index].at - wall));
      }
      if (!dropped && _dropAt != null) {
        dt = math.min(dt, math.max(0, _dropAt! - wall));
      }
      if (dt <= 1e-10) break;
      s.step(dt);
      s.t += dt;
      wall += dt;
    }
    // Events at the exact requested timestamp affect the pose immediately,
    // even though no integration step follows them yet.
    while (index < _cursor.length && _cursor[index].at <= time + 1e-10) {
      final cursor = _cursor[index++];
      s.cursorX = cursor.x;
      s.cursorY = cursor.y;
    }
    if (!dropped && _dropAt != null && time >= _dropAt!) {
      s.dropTime = _dropAt;
      s.t = 1.95;
    }
    final referenceTime = _dropAt != null && time >= _dropAt!
        ? 1.95 + (time - _dropAt!)
        : 1.55 + (time - first.at);
    return s.computeFrame(referenceTime);
  }
}

class _Spring {
  _Spring(this.value);
  double value, velocity = 0;
  void step(double target, double response, double damping, double dt) {
    final k = math.pow(2 * math.pi / response, 2);
    final c = 2 * damping * math.sqrt(k);
    velocity += (k * (target - value) - c * velocity) * dt;
    value += velocity * dt;
  }
}

class _UploadSimulation {
  double uploadDuration = 2.4;
  double get progEnd => 3.25 + uploadDuration;
  double get growStart => progEnd + .25;
  double get growEnd => progEnd + .7;
  double cursorX = 600,
      cursorY = 280,
      t = 1.55,
      entered = 1.55,
      tilt = 0,
      speed = 0,
      lockAt = -9;
  double? dropTime;
  final bx = _Spring(140), by = _Spring(104), mouth = _Spring(0);
  bool locked = false;
  void step(double dt) {
    final dragging = dropTime == null;
    if (dragging) {
      final dist = math.sqrt(
        math.pow(cursorX - bx.value, 2) + math.pow(cursorY + 14 - by.value, 2),
      );
      if (!locked && dist < 60 && speed < 180) {
        locked = true;
        lockAt = t;
      }
      if (locked && dist > 90) locked = false;
      bx.step(
        cursorX.clamp(60.0, 580.0),
        locked ? .18 : .35,
        locked ? .75 : .7,
        dt,
      );
      by.step(104, locked ? .18 : .35, locked ? .75 : .7, dt);
    }
    final target = dragging ? (bx.velocity * .0015).clamp(-.18, .18) : 0.0;
    tilt = mochiLerp(tilt, target, 1 - math.pow(.0005, dt));
    if (!dragging && t >= 2.33) {
      mouth.value = math.max(
        0,
        mochiLerp(.5, 0, mochiIn(mochiSeg(t, 2.33, 2.42))),
      );
    } else {
      final target = !dragging
          ? .5
          : locked
          ? .42
          : .2;
      mouth.step(target, .25, .6, dt);
      mouth.value = math.max(0, mouth.value);
    }
  }

  CoucouMochiUploadFrame computeFrame(double t) {
    final f = CoucouMochiUploadFrame();
    f.t = t;
    f.cursorX = cursorX;
    f.cursorY = cursorY;
    final progEnd = this.progEnd;
    final growStart = this.growStart;
    final growEnd = this.growEnd;
    f.progEnd = progEnd;
    f.growStart = growStart;
    f.growEnd = growEnd;

    final entered = this.entered >= 0 ? this.entered : 1e9;
    final isDragging = dropTime == null;
    // Clamp the phase clock to just before the drop while still dragging, so a
    // long hover never trips the post-drop visuals.
    final pt = isDragging ? math.min(t, 1.95 - (1 / 240)) : t;

    // Morph: 0→1 on entry, 1→0 shrinking to a ball, 0→1 growing back at choose.
    late double morph;
    if (pt < 2.88) {
      morph = mochiBack(mochiSeg(pt, entered, entered + 0.38));
    } else if (pt < growStart) {
      morph = 1 - mochiOut(mochiSeg(pt, 2.88, 3.23));
    } else {
      morph = mochiBack(mochiSeg(pt, growStart, growEnd));
    }
    f.morph = math.max(0, math.min(morph, 1.08));

    // Position and diameter.
    var x = bx.value;
    var y = by.value;
    double d = 62;
    if (pt >= 2.88 && pt < 3.25) {
      final k = mochiInOut(mochiSeg(pt, 2.88, 3.23));
      x = mochiLerp(bx.value, 46, k);
      y = mochiLerp(by.value, 118, k);
      d = mochiLerp(62, 14, k);
    }
    if (pt >= 3.25) {
      final p = _progressAt(pt, 3.25, progEnd);
      x = mochiLerp(46, 520, p);
      y = 118;
      d = 14;
    }
    if (pt >= progEnd) {
      x = 520;
      y = 118 - 8 * math.sin(math.pi * mochiSeg(pt, progEnd, progEnd + 0.2));
    }
    if (pt >= growStart) {
      final k = mochiInOut(mochiSeg(pt, growStart, growEnd));
      x = mochiLerp(520, 60, k);
      y = mochiLerp(118, 101, k);
      d = mochiLerp(14, 62, mochiBack(mochiSeg(pt, growStart, growEnd)));
    }
    f.x = x;
    f.y = y;
    f.d = d;

    // Squeeze.
    double sx = 1;
    double sy = 1;
    if (pt >= 1.95 && pt < 2.03) {
      final k = mochiOut(mochiSeg(pt, 1.95, 2.03));
      sy = mochiLerp(1, 0.92, k);
      sx = mochiLerp(1, 1.06, k);
    }
    if (pt >= 2.03 && pt < 2.33) {
      final k = mochiInOut(mochiSeg(pt, 2.03, 2.33));
      sy = mochiLerp(0.92, 1.06, k);
      sx = mochiLerp(1.06, 0.97, k);
    }
    if (pt >= 2.33 && pt < 2.6) {
      sy = _squeezeY(pt);
      sx = _squeezeX(pt);
    }
    if (pt >= 2.6 && pt < 2.88) {
      final k = ((pt - 2.6) % 0.14) / 0.14;
      sy = 1 - 0.05 * math.sin(math.pi * k);
      sx = 1 + 0.03 * math.sin(math.pi * k);
    }
    if (pt >= 2.88 && pt < 3.23) {
      final k = mochiSeg(pt, 2.88, 3.23);
      sy = 1 + 0.12 * math.sin(math.pi * k);
      sx = 1 - 0.06 * math.sin(math.pi * k);
    }
    if (pt >= 3.25 && pt < progEnd) {
      final v =
          (_progressAt(pt + 0.01, 3.25, progEnd) -
              _progressAt(pt, 3.25, progEnd)) /
          0.01;
      final st = math.max(0, math.min(1, v * 0.18));
      sx = 1 + 0.25 * st;
      sy = 1 - 0.15 * st;
    }
    if (pt >= growStart && pt < growEnd) {
      sy = 1 + 0.06 * math.sin(math.pi * mochiSeg(pt, growStart, growEnd));
    }
    f.sx = sx;
    f.sy = sy;
    f.tilt = tilt;
    f.hop = lockAt > 0 && isDragging
        ? -5 * math.sin(math.pi * mochiSeg(pt, lockAt, lockAt + 0.15))
        : 0;

    f.mouth = mouth.value;

    // Eyes.
    String eye = 'pill';
    if (locked && pt < 2.33) eye = 'cup';
    if (pt >= 2.33 && pt < 2.88 + 0.1) eye = 'content';
    if (pt >= progEnd && pt < growEnd + 0.3) eye = 'content';
    f.eye = eye;

    final lkx = pt < 2.33
        ? cursorX - x
        : pt < 3.25
        ? 0
        : 40;
    final lky = pt < 2.33 ? cursorY + 10 - y : 0;
    f.lookX = math.max(-1, math.min(1, lkx / 200));
    f.lookY = math.max(-1, math.min(1, lky / 150));

    f.fileVisible = pt < 2.33;
    f.suck = mochiSeg(pt, 2.03, 2.33);

    // Content alphas.
    f.zoneOver = entered >= 0 && pt < 2.88;
    f.zoneAlpha = 1 - mochiSeg(pt, 2.88, 2.88 + 0.2);
    f.textAlpha = f.zoneAlpha * (x > 196 - 40 && isDragging ? 0.25 : 1);
    f.barReveal =
        mochiOut(mochiSeg(pt, 3.0, 3.0 + 0.25)) *
        (1 - mochiSeg(pt, growStart, growStart + 0.2));
    f.barAlpha =
        mochiSeg(pt, 3.0 + 0.05, 3.0 + 0.25) *
        (1 - mochiSeg(pt, growStart, growStart + 0.2));
    f.progress = _progressAt(pt, 3.25, progEnd);
    f.flash = pt >= progEnd
        ? math.sin(math.pi * mochiSeg(pt, progEnd, progEnd + 0.3))
        : 0;
    f.check = pt >= progEnd
        ? mochiBack(mochiSeg(pt, progEnd, progEnd + 0.25))
        : 0;

    final hoverGreen = f.zoneOver ? 0.22 : 0.0;
    double uploadGreen = 0;
    if (pt >= 3.25) {
      final baseGreen = f.progress * 0.5;
      final flashExtra = pt >= progEnd
          ? 0.2 * math.sin(math.pi * mochiSeg(pt, progEnd, progEnd + 0.4))
          : 0;
      final fadmochiOut = 1 - mochiSeg(pt, growEnd, growEnd + 0.6);
      uploadGreen = (baseGreen + flashExtra) * fadmochiOut;
    }
    f.greenWash = math.max(hoverGreen, uploadGreen);
    f.chooseAlpha = mochiSeg(pt, growStart + 0.15, growEnd);

    // Mouth rect in island coordinates — the file is clipped against it.
    final R = f.d / 2 / 1.04;
    final mc = math.max(0, math.min(f.morph, 1));
    final rx = R * (1.04 - 0.04 * mc);
    final ry = R * (0.97 - 0.03 * mc);
    final mh = f.mouth * R * mc;
    final mw = 2 * rx - 0.24 * R;
    f.mouthRect = Rect.fromLTWH(
      x + (-mw / 2) * sx,
      y + f.hop + (-ry + 0.1 * R) * sy,
      mw * sx,
      mh * sy,
    );
    return f;
  }
}

double _squeezeY(double t) {
  if (t <= 2.33) return 1.06;
  if (t <= 2.4) return mochiLerp(1.06, .82, mochiOut(mochiSeg(t, 2.33, 2.4)));
  if (t <= 2.53) return mochiLerp(.82, 1.1, mochiOut(mochiSeg(t, 2.4, 2.53)));
  if (t <= 2.6) return mochiLerp(1.1, 1, mochiInOut(mochiSeg(t, 2.53, 2.6)));
  return 1;
}

double _squeezeX(double t) {
  if (t <= 2.33) return .97;
  if (t <= 2.4) return mochiLerp(.97, 1.14, mochiOut(mochiSeg(t, 2.33, 2.4)));
  if (t <= 2.53) return mochiLerp(1.14, .95, mochiOut(mochiSeg(t, 2.4, 2.53)));
  if (t <= 2.6) return mochiLerp(.95, 1, mochiInOut(mochiSeg(t, 2.53, 2.6)));
  return 1;
}

double _progressAt(double t, double start, double end) {
  final u = mochiSeg(t, start, end);
  if (u < .4) return .6 * mochiOut(u / .4);
  if (u < .85) return .6 + .32 * mochiInOut((u - .4) / .45);
  return .92 + .08 * mochiIn((u - .85) / .15);
}
