// Part of bloub_bot — the face: eyes on a sphere, resting-life (gaze drift,
// blinks, breath) and expression data types. Mirrors the upstream
// src/bot/face.ts (jeremy-prt/bloub, MIT). Pure Dart, no Flutter imports.
//
// The eyes are painted ON A SPHERE, not laid flat. Measured on the video:
// the eye nearest the edge is 0.69x the width of the other and 0.663x its
// area — exactly the depth factor (z = 0.669) of a sphere point at that
// distance from the center. So a real head orientation is modelled: each eye
// gets the sphere's tangent frame, projected orthographically. Compression
// and tilt fall out by themselves; that is what gives the volume.
//
// The constants are NOT hand-picked: they come from fitting the model on the
// per-frame measured positions and sizes (residual error ~1 px on a 190 px
// radius). Do not round them.

import 'dart:math' as math;

import '_math.dart';

/// Head orientation, degrees. yaw > 0 looks right, pitch > 0 looks up,
/// roll = head tilt.
class BotGaze {
  const BotGaze({required this.yaw, required this.pitch, required this.roll});

  final double yaw;
  final double pitch;
  final double roll;
}

/// Half eye separation on the sphere, degrees (total ~31°).
const double kBotEyeSplit = 15.46;

/// Resting eye size, in resting-ball-radius units.
const double kBotEyeW = 0.186;
const double kBotEyeH = 0.412;

/// Resting head orientation, fitted on the reference frames. Counter to
/// intuition the eyes lean `\\`, not `//` — that is the measurement.
const BotGaze kBotRestGaze = BotGaze(yaw: 28.49, pitch: 28.62, roll: -13);

/// One eye's config: capsule size, openness, own tilt. `tilt` (degrees,
/// positive = top leans right) is applied AFTER the sphere tangent frame —
/// without it both eyes lean the same way (head roll only) and anger/sadness,
/// which need MIRRORED tilts, are out of reach.
class BotEyeCfg {
  const BotEyeCfg({required this.w, required this.h, this.open = 1, this.tilt = 0});

  final double w;
  final double h;
  final double open;
  final double tilt;
}

/// A resting expression (customizer data — the catalog ships with the
/// customizer phase; the engine only needs the type and the blend).
class BotExpression {
  const BotExpression({
    required this.id,
    required this.gaze,
    required this.split,
    required this.eyes,
  });

  final String id;
  final BotGaze gaze;
  final double split;
  final List<BotEyeCfg> eyes; // [inner, outer]
}

BotEyeCfg _lerpEyeCfg(BotEyeCfg a, BotEyeCfg b, double t) => BotEyeCfg(
      w: botLerp(a.w, b.w, t),
      h: botLerp(a.h, b.h, t),
      open: botLerp(a.open, b.open, t),
      tilt: botLerp(a.tilt, b.tilt, t),
    );

/// Interpolation of two expressions: changes glide instead of jumping.
BotExpression botBlendExpression(BotExpression a, BotExpression b, double t) =>
    BotExpression(
      id: b.id,
      gaze: BotGaze(
        yaw: botLerp(a.gaze.yaw, b.gaze.yaw, t),
        pitch: botLerp(a.gaze.pitch, b.gaze.pitch, t),
        roll: botLerp(a.gaze.roll, b.gaze.roll, t),
      ),
      split: botLerp(a.split, b.split, t),
      eyes: [
        _lerpEyeCfg(a.eyes[0], b.eyes[0], t),
        _lerpEyeCfg(a.eyes[1], b.eyes[1], t),
      ],
    );

/// One eye's screen pose: center, 2x2 tangent matrix (SVG matrix(a,b,c,d)
/// sense) and the z of the normal (> 0 = facing the viewer).
typedef BotEyePose = ({
  double x,
  double y,
  double a,
  double b,
  double c,
  double d,
  double depth
});

double _deg(double d) => d * math.pi / 180;

/// Rotates two vectors of an orthonormal frame within their common plane.
(List<double>, List<double>) _spin(List<double> u, List<double> v, double angle) {
  final double c = math.cos(angle);
  final double s = math.sin(angle);
  return (
    [u[0] * c + v[0] * s, u[1] * c + v[1] * s, u[2] * c + v[2] * s],
    [v[0] * c - u[0] * s, v[1] * c - u[1] * s, v[2] * c - u[2] * s],
  );
}

/// Head frame then the two eyes. Screen frame: x right, y down, z toward the
/// viewer. Index 0 is the inner eye, 1 the outer eye.
List<BotEyePose> botEyePoses(BotGaze gaze, double scale,
    [double split = kBotEyeSplit]) {
  List<double> f = [0, 0, 1];
  List<double> right = [1, 0, 0];
  List<double> down = [0, 1, 0];

  // yaw: forward tips toward right
  (f, right) = _spin(f, right, _deg(gaze.yaw));
  // pitch: forward tips upward (opposite of down)
  (down, f) = _spin(down, f, _deg(gaze.pitch));
  // roll: the head leans in its own plane
  (right, down) = _spin(right, down, _deg(gaze.roll));

  BotEyePose build(double side) {
    final (List<double> ef, List<double> er) = _spin(f, right, _deg(split * side));
    return (
      x: ef[0] * scale,
      y: ef[1] * scale,
      a: er[0],
      b: er[1],
      c: down[0],
      d: down[1],
      depth: ef[2],
    );
  }

  return [build(-1), build(1)];
}

/// Resting life: slow gaze drift, blinks, breath. Pure function of time (no
/// internal state), so pause, resume and jumping to an arbitrary date always
/// give the same image. Values are DELTAS to add to the current state's pose.
class BotLiveliness {
  const BotLiveliness({
    required this.dYaw,
    required this.dPitch,
    required this.dRoll,
    required this.lid,
    required this.driftX,
    required this.driftY,
    required this.breath,
  });

  final double dYaw;
  final double dPitch;
  final double dRoll;

  /// 1 = eye open, 0 = closed (vertical squash in screen space).
  final double lid;
  final double driftX;
  final double driftY;
  final double breath;
}

/// Measured: 1-2 frames at 10 fps.
const double kBotBlinkDur = 0.18;

double _blinkLid(double t) {
  for (int i = 0; i < kBotBlinkStarts.length; i++) {
    final double start = kBotBlinkStarts[i];
    if (t < start) break;
    final double k = (t - start) / kBotBlinkDur;
    if (k >= 0 && k <= 1) {
      // fast close, slightly slower re-open
      return k < 0.45 ? 1 - k / 0.45 : (k - 0.45) / 0.55;
    }
  }
  return 1;
}

BotLiveliness botLiveliness(double t,
    {double wander = 1, bool blink = true, bool float = true}) {
  // Periods are mutually prime: the drift never visibly repeats.
  return BotLiveliness(
    dYaw: (botLoopNoise(t, 11.3, 0.4) * 5.5 + botLoopNoise(t, 3.7, 2.1) * 1.6) *
        wander,
    dPitch:
        (botLoopNoise(t, 9.1, 1.3) * 4.2 + botLoopNoise(t, 4.3, 0.7) * 1.3) *
            wander,
    dRoll: botLoopNoise(t, 13.7, 3.2) * 2.2 * wander,
    lid: blink ? _blinkLid(t) : 1,
    // At rest the video is nearly still (center stable to ±0.003, constant
    // radius): all the life is gaze and blinks. Keep just enough not to
    // freeze the image completely.
    driftX: float ? botLoopNoise(t, 7.9, 1.9) * 0.006 : 0,
    driftY: float ? botLoopNoise(t, 5.3, 0.3) * 0.007 : 0,
    // Width is constant; only the height breathes, very slightly.
    breath: float ? 1 + math.sin(t / 3.4 * math.pi * 2) * 0.005 : 1,
  );
}

/// A blink is a VERTICAL squash in screen space around the eye center
/// (measured: bbox width preserved, height drops to ~0.35), not a shrink
/// along the capsule's tilted axis. Composed after the tangent matrix,
/// affecting only the y outputs.
double botBlinkScale(double lid) => 0.06 + 0.94 * botClamp(lid);

/// Pre-drawn blink schedule: deterministic and stateless (upstream builds it
/// at load with a seeded mulberry32; this table is that exact output,
/// regenerated with node from the bloub checkout — see the component README).
/// 1.9 to 4.6 s between blinks, with an occasional double blink.
const List<double> kBotBlinkStarts = [
  1.4, 5.217086499882862, 9.687223591562361, 9.927223591562361, 12.84894120023586, 15.597222574646587, 19.011183814411055, 23.602127513578164,
  27.317622987725777, 30.054484710362743, 34.220439752736134, 36.62472364994232, 39.45427000614349, 41.49533066163771, 43.5526169313211, 46.85495903325267,
  51.29854353182949, 51.53854353182949, 55.39010214469861, 55.63010214469861, 59.47200298770797, 63.298423430374825, 65.75974996602629, 69.84982206591405,
  70.08982206591405, 72.25214820477646, 75.72234939296264, 79.34724550185724, 83.13821440678089, 85.36676454144995, 85.60676454144995, 88.54617149103431,
  92.23566282829269, 92.47566282829268, 96.20015953479799, 98.30894836912395, 102.31387272627092, 105.18999714279546, 109.21679690746589, 112.94507224590981,
  115.87281464902682, 119.71429367590228, 122.34982458249199, 126.76135353425983, 129.74478670350274, 133.16283432160037, 133.40283432160038, 136.94353013596964,
  141.4360601615347, 145.14171643261332, 147.82626941853204, 151.27282142210288, 153.28488200732508, 156.1595117955655, 160.17781812347937, 164.7535192799708,
  166.6540077114897, 170.08982293211855, 173.46434777217917, 173.70434777217918, 177.47224509446417, 177.71224509446418, 180.59902110718193, 184.93330126250166,
  187.64702616950035, 191.6703577021277, 196.13348699008583, 200.38576608897654, 203.1263291443838, 205.67452785518486, 209.89098907980602, 210.13098907980603,
  214.36515986940358, 217.11652027370874, 221.36594959425275, 221.60594959425276, 225.535474159834, 229.72863313770856, 234.02086610860195, 237.4742440350913,
  241.038423818592, 243.89950659723024, 244.13950659723025, 247.04680749861993, 247.28680749861994, 251.62774614980916, 255.5174822575227, 258.7789186010184,
  259.0189186010184, 263.4126591050905, 266.8191160233832, 267.0591160233832, 271.61721208714886, 271.85721208714887, 275.60173521075404, 279.38366096856544,
  279.62366096856545, 283.04890995388394, 283.28890995388394, 286.75842135062453, 289.3500399388188, 291.9472070937791, 294.05746062607983, 297.39721360560986,
  300.49383969777745, 303.46866242099105, 303.70866242099106, 306.71423402879407, 306.9542340287941, 311.16456653364025, 313.924593756255, 317.7116715380226,
  319.8915739249673, 320.1315739249673, 324.2026398785741, 326.15456912818854, 329.08326451974943, 331.800319318413, 335.77957858330126, 340.0010561198557,
  343.9939179682501, 347.4196118767236, 351.95561966070466, 353.92754234001995, 358.3732218634433, 358.6132218634433, 360.79505219016716, 362.8844269223933,
  364.8954882328355, 366.86831740994967, 370.89782684484527, 371.1378268448453, 375.15219894859973, 378.7229190456498, 382.20689584811254, 384.96242904461025,
  388.3194478798708, 390.57135666939934, 393.09929667395113, 395.53415423227045, 397.677087523444, 401.59054204128256, 406.09077615715137, 410.06371458527207,
  413.3716267240051, 415.67935929543376, 418.7126901855044, 422.24925419015847, 425.0602785260234, 428.4661014750883, 428.7061014750883, 431.48457194973287,
  431.7245719497329, 434.62513533108904, 436.7792820591018, 439.970363849332, 443.64733505421356, 447.98919121890833, 448.22919121890834, 452.6938044601683,
  452.9338044601683, 456.87718145451083, 460.36752841767895, 460.60752841767896, 464.81728796873284, 466.91472299721136, 467.15472299721137, 470.943720271057,
  473.26947314431004, 477.1152796321227, 480.8923701227088, 484.5127836228958, 487.8029775591013, 490.0734329721569, 492.1578888729359, 495.5139190103305,
  495.7539190103305, 499.5493197849491, 503.33585180863787, 503.5758518086379, 506.4284003591496, 510.97069722338165, 514.4607521832553, 518.0153878008114,
  521.2594398151948, 523.3062689360562, 527.3409768553781, 529.9379830803122, 534.5155727103917, 536.6244197061151, 536.8644197061151, 540.3896567643113,
  544.0883580187993, 544.3283580187993, 546.9113268462761, 550.7244326376409, 555.0773661285924, 557.3448602005892, 559.6959169838165, 563.327189229923,
  567.5781086933852, 571.9946393241693, 575.9322766657273, 580.5205567766965, 580.7605567766965, 585.0024304822931, 589.5689727968914, 589.8089727968915,
  593.1408628551295, 595.759720789013, 598.9304755653027, 602.8296705623162, 605.519551225659, 608.132168108854, 612.4273418403003, 616.2880719710147,
  620.7804257295566, 623.6420274263719, 625.9402354052761, 630.3845033258904, 632.8798945738008, 637.2577644098322, 637.4977644098323, 641.1264241952548,
  644.332568561575, 648.1456806506828, 651.742649984882, 651.982649984882, 654.9671097930947, 655.2071097930947, 657.2543149963308, 657.4943149963308,
  660.5679005268643, 662.9124972352439, 666.4214200154792, 666.6614200154792, 670.458789253445, 673.4251484186627, 675.9308925637981, 677.8484430501011,
  681.9897303287179, 682.2297303287179, 685.6322153778381, 689.775213032412, 693.7759620563925, 696.9933697693848, 697.2333697693848, 699.5724912604044,
  703.2570617866196, 706.1455864552368, 710.5687125296524, 715.0388618459186, 715.2788618459186, 719.2388492617577, 722.5159738845477, 725.2179566680506,
  729.1664573169598, 732.6137261939054, 735.4762561414443, 739.8028481023206, 743.6532854258834, 747.1368651926803, 750.7104119396821, 750.9504119396821,
  754.4457595873537, 758.3866628442338, 762.5253115062281, 764.5454466949828, 764.7854466949829, 769.2185168011586, 771.9609022874624, 773.8848340727628,
  777.6143825460232, 781.2301884815569, 785.2745143682237, 785.5145143682237, 789.0773050536967, 791.1953144393729, 795.7782332090994, 799.4623682122545,
  803.4867641036732, 806.2264967521986, 809.2464356503084, 812.8098164257461, 815.3963452237293, 818.7239697366821, 818.9639697366821, 822.2156164933656,
  824.7913842277097, 825.0313842277097, 827.2821300388601, 827.5221300388602, 830.6793078708378, 834.2107179058863, 836.4784979700956, 839.3113862891596,
  839.5513862891596, 841.8108436660383, 846.1000814579202, 850.697230825248, 853.496551434487, 853.736551434487, 857.4901781598905, 859.8332513104759,
  862.5218501656184, 866.9457154101094, 868.8660783333804, 872.7398258333893, 875.5800147930494, 878.9033623169045, 881.4495360896093, 885.5543659467818,
  888.7925364494891, 891.5612007725853, 895.2707598017397, 897.5275999327058, 901.8690252061801,
];
