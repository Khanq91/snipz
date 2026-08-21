// Part of bloub_bot — where to sit the face on a customizer shape. Mirrors
// the upstream src/bot/eyefit.ts (jeremy-prt/bloub, MIT) — its OUTPUT, not
// its solver. Pure Dart.
//
// The eyes live on a sphere; `radiusAtAngle` re-anchors their CENTER to the
// real outline, but the eye has a size: on a silhouette that is narrow in
// its direction, the remaining margin shrinks by the same pro-rata and the
// capsule used to open the mask outward (capsule, triangle, cloud, droplet —
// 55 combinations out of 680, up to 11.6 units on a 100-radius ball).
//
// Upstream solves this ONCE at load and yields a TABLE of common offsets —
// one per (shape, base-body state, expression) — that the engine merely
// interpolates between morph ENDPOINTS. Seven per-frame solver attempts all
// produced visible motion artefacts (chattering, active-set jumps); the
// tabulated form makes trembling impossible by construction (pose space
// deformation, Lewis et al. 2000).
//
// This file vendors that table, extracted by running the actual upstream
// solver (npx tsx over the bloub checkout). Only non-zero entries are kept:
// zero covers the circle (both profiles identical), unknown shapes and null.

import '_skins.dart';
import '_states.dart';

/// `shapeId|state|expressionId` -> offset in resting-ball-radius units.
/// Only `idle` and `swirl` carry the resting face, so only they decline per
/// expression; wink/wide/notify have a single entry (empty expression).
const Map<String, ({double x, double y})> kBotEyeOffsets = {
  'galet|idle|': (x: -0.011836, y: 0.020501),
  'galet|idle|neutre': (x: -0.011836, y: 0.020501),
  'galet|idle|excite': (x: 0, y: -0.070507),
  'galet|idle|triste': (x: 0, y: -0.21489),
  'galet|idle|effraye': (x: 0, y: -0.064218),
  'galet|idle|confus': (x: 0.260393, y: 0),
  'galet|idle|curieux': (x: -0.035521, y: -0.020508),
  'galet|idle|timide': (x: 0.014352, y: -0.024859),
  'galet|idle|somnolent': (x: 0, y: -0.21),
  'galet|wide|': (x: -0.017386, y: -0.030113),
  'galet|notify|': (x: 0.010082, y: -0.005821),
  'galet|swirl|': (x: -0.011836, y: 0.020501),
  'galet|swirl|neutre': (x: -0.011836, y: 0.020501),
  'galet|swirl|excite': (x: 0, y: -0.070507),
  'galet|swirl|triste': (x: 0, y: -0.21489),
  'galet|swirl|effraye': (x: 0, y: -0.064218),
  'galet|swirl|confus': (x: 0.260393, y: 0),
  'galet|swirl|curieux': (x: -0.035521, y: -0.020508),
  'galet|swirl|timide': (x: 0.014352, y: -0.024859),
  'galet|swirl|somnolent': (x: 0, y: -0.21),
  'squircle|idle|mefiant': (x: -0.016576, y: -0.00957),
  'squircle|idle|timide': (x: 0.005488, y: -0.009505),
  'squircle|idle|blase': (x: 0.017819, y: 0),
  'squircle|wide|': (x: -0.01666, y: -0.028855),
  'squircle|notify|': (x: 0.010652, y: -0.00615),
  'squircle|swirl|mefiant': (x: -0.016576, y: -0.00957),
  'squircle|swirl|timide': (x: 0.005488, y: -0.009505),
  'squircle|swirl|blase': (x: 0.017819, y: 0),
  'capsule|idle|': (x: -0.044766, y: 0.077537),
  'capsule|idle|neutre': (x: -0.044766, y: 0.077537),
  'capsule|idle|excite': (x: -0.105, y: -0.181865),
  'capsule|idle|heureux': (x: -0.105, y: 0.181865),
  'capsule|idle|hilare': (x: -0.033496, y: 0.058017),
  'capsule|idle|triste': (x: -0.105, y: -0.181865),
  'capsule|idle|effraye': (x: 0, y: -0.249108),
  'capsule|idle|mefiant': (x: -0.090933, y: 0.0525),
  'capsule|idle|confus': (x: 0.030963, y: 0),
  'capsule|idle|curieux': (x: -0.058017, y: -0.033496),
  'capsule|idle|fier': (x: 0, y: 0.080664),
  'capsule|idle|timide': (x: 0.113419, y: -0.065483),
  'capsule|idle|somnolent': (x: -0.061569, y: -0.035547),
  'capsule|wide|': (x: -0.328689, y: -0.189769),
  'capsule|notify|': (x: 0.046789, y: 0),
  'capsule|swirl|': (x: -0.044766, y: 0.077537),
  'capsule|swirl|neutre': (x: -0.044766, y: 0.077537),
  'capsule|swirl|excite': (x: -0.105, y: -0.181865),
  'capsule|swirl|heureux': (x: -0.105, y: 0.181865),
  'capsule|swirl|hilare': (x: -0.033496, y: 0.058017),
  'capsule|swirl|triste': (x: -0.105, y: -0.181865),
  'capsule|swirl|effraye': (x: 0, y: -0.249108),
  'capsule|swirl|mefiant': (x: -0.090933, y: 0.0525),
  'capsule|swirl|confus': (x: 0.030963, y: 0),
  'capsule|swirl|curieux': (x: -0.058017, y: -0.033496),
  'capsule|swirl|fier': (x: 0, y: 0.080664),
  'capsule|swirl|timide': (x: 0.113419, y: -0.065483),
  'capsule|swirl|somnolent': (x: -0.061569, y: -0.035547),
  'triangle|idle|': (x: -0.003002, y: 0.0052),
  'triangle|idle|neutre': (x: -0.003002, y: 0.0052),
  'triangle|idle|hilare': (x: -0.010254, y: 0.01776),
  'triangle|idle|mefiant': (x: -0.105, y: 0.181865),
  'triangle|idle|confus': (x: 0.056172, y: 0.032431),
  'triangle|idle|curieux': (x: -0.21, y: 0),
  'triangle|idle|fier': (x: -0.027344, y: 0.047361),
  'triangle|wide|': (x: -0.147315, y: -0.255158),
  'triangle|notify|': (x: 0.197162, y: 0),
  'triangle|swirl|': (x: -0.003002, y: 0.0052),
  'triangle|swirl|neutre': (x: -0.003002, y: 0.0052),
  'triangle|swirl|hilare': (x: -0.010254, y: 0.01776),
  'triangle|swirl|mefiant': (x: -0.105, y: 0.181865),
  'triangle|swirl|confus': (x: 0.056172, y: 0.032431),
  'triangle|swirl|curieux': (x: -0.21, y: 0),
  'triangle|swirl|fier': (x: -0.027344, y: 0.047361),
  'hexagone|idle|hilare': (x: 0, y: 0.047852),
  'hexagone|idle|mefiant': (x: -0.015039, y: 0.026048),
  'hexagone|idle|confus': (x: 0.268356, y: 0),
  'hexagone|idle|curieux': (x: -0.031969, y: -0.018457),
  'hexagone|idle|fier': (x: -0.01709, y: 0.0296),
  'hexagone|idle|timide': (x: 0.016915, y: -0.009766),
  'hexagone|idle|blase': (x: 0.009308, y: 0),
  'hexagone|notify|': (x: 0.013554, y: -0.023476),
  'hexagone|swirl|hilare': (x: 0, y: 0.047852),
  'hexagone|swirl|mefiant': (x: -0.015039, y: 0.026048),
  'hexagone|swirl|confus': (x: 0.268356, y: 0),
  'hexagone|swirl|curieux': (x: -0.031969, y: -0.018457),
  'hexagone|swirl|fier': (x: -0.01709, y: 0.0296),
  'hexagone|swirl|timide': (x: 0.016915, y: -0.009766),
  'hexagone|swirl|blase': (x: 0.009308, y: 0),
  'nuage|idle|': (x: -0.017075, y: 0.029574),
  'nuage|idle|neutre': (x: -0.017075, y: 0.029574),
  'nuage|idle|mefiant': (x: -0.105, y: 0.181865),
  'nuage|idle|confus': (x: 0.045727, y: 0.026401),
  'nuage|idle|curieux': (x: -0.080664, y: 0),
  'nuage|idle|timide': (x: 0.325652, y: -0.188015),
  'nuage|idle|blase': (x: 0.031067, y: 0.017936),
  'nuage|wide|': (x: -0.144685, y: -0.250601),
  'nuage|swirl|': (x: -0.017075, y: 0.029574),
  'nuage|swirl|neutre': (x: -0.017075, y: 0.029574),
  'nuage|swirl|mefiant': (x: -0.105, y: 0.181865),
  'nuage|swirl|confus': (x: 0.045727, y: 0.026401),
  'nuage|swirl|curieux': (x: -0.080664, y: 0),
  'nuage|swirl|timide': (x: 0.325652, y: -0.188015),
  'nuage|swirl|blase': (x: 0.031067, y: 0.017936),
  'goutte|idle|': (x: -0.017095, y: 0.029609),
  'goutte|idle|neutre': (x: -0.017095, y: 0.029609),
  'goutte|idle|hilare': (x: -0.008203, y: 0.014208),
  'goutte|idle|mefiant': (x: -0.023926, y: 0.041441),
  'goutte|idle|confus': (x: 0.046177, y: 0.02666),
  'goutte|idle|fier': (x: -0.020508, y: 0.035521),
  'goutte|wide|': (x: -0.126981, y: -0.073313),
  'goutte|notify|': (x: 0.041035, y: 0.071074),
  'goutte|swirl|': (x: -0.017095, y: 0.029609),
  'goutte|swirl|neutre': (x: -0.017095, y: 0.029609),
  'goutte|swirl|hilare': (x: -0.008203, y: 0.014208),
  'goutte|swirl|mefiant': (x: -0.023926, y: 0.041441),
  'goutte|swirl|confus': (x: 0.046177, y: 0.02666),
  'goutte|swirl|fier': (x: -0.020508, y: 0.035521),
};

const ({double x, double y}) _zero = (x: 0, y: 0);

/// Offset to apply to BOTH eyes for this shape on this state — a pure
/// translation, hence an isometry: spacing, sizes and tilts preserved to the
/// pixel. Zero when the shape is not in the catalog (covers null and the
/// circle) — the measured video shape never moves, with no special case.
({double x, double y}) botEyeOffset(
    List<double>? radii, BloubBotState state, String? expressionId) {
  if (radii == null) return _zero;
  // Keyed by radii-list identity, the engine's existing convention (its
  // `identical(radii, _shape)` guards rely on the same stability).
  String? shapeId;
  for (final BotShape s in kBotShapes) {
    if (identical(s.radii, radii)) {
      shapeId = s.id;
      break;
    }
  }
  if (shapeId == null) return _zero;
  return kBotEyeOffsets['$shapeId|${state.name}|${expressionId ?? ''}'] ??
      // a state without a resting face has one entry, whatever the expression
      kBotEyeOffsets['$shapeId|${state.name}|'] ??
      _zero;
}
