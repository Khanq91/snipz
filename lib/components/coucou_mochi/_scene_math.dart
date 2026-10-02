import 'dart:math' as math;
import 'dart:ui';

double mochiSeg(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);
double mochiLerp(num a, num b, num t) => (a + (b - a) * t).toDouble();
double mochiOut(double t) => 1 - math.pow(1 - t, 3).toDouble();
double mochiIn(double t) => t * t * t;
double mochiInOut(double t) =>
    t < .5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
double mochiBack(double t) =>
    1 + 2.70158 * math.pow(t - 1, 3) + 1.70158 * math.pow(t - 1, 2);

Path mochiSuperellipse(double rx, double ry, double exponent) {
  final p = Path();
  for (int i = 0; i <= 96; i++) {
    final a = i / 96 * math.pi * 2;
    final ca = math.cos(a), sa = math.sin(a);
    final x = rx * ca.sign * math.pow(ca.abs(), 2 / exponent);
    final y = ry * sa.sign * math.pow(sa.abs(), 2 / exponent);
    if (i == 0) {
      p.moveTo(x, y);
    } else {
      p.lineTo(x, y);
    }
  }
  return p..close();
}

Paint mochiStroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

RRect mochiRect(double x, double y, double w, double h, double radius) =>
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(radius));
