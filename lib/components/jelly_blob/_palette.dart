// Palette of the jelly blob — the Flutter port of feral-blob's `--jelly-*`
// CSS custom properties (styles/blob.css). Every tinted part of the mascot
// reads from one of these slots; the white glints, the near-black face ink
// and the blue tears stay fixed upstream ("they read on every palette") and
// are therefore hard-coded in the painter.

import 'dart:ui';

/// All the colors of one jelly skin. Pass a whole palette to re-skin the
/// blob; [JellyBlobPalette.violet] is the upstream default, the other
/// presets are hand-mixed for this port (upstream advertises mint/coral/gold
/// but ships no values).
class JellyBlobPalette {
  const JellyBlobPalette({
    required this.bodyTop,
    required this.bodyMid,
    required this.bodyDeep,
    required this.bodyRim,
    required this.outline,
    required this.outlineLight,
    required this.armLight,
    required this.armMid,
    required this.armDeep,
    required this.cheekLight,
    required this.cheek,
    required this.cheekDeep,
    required this.eyeLight,
    required this.eye,
    required this.eyeDeep,
    required this.bellyGlow,
    required this.eyeSparkle,
    this.shadow,
    this.shadowLight,
  });

  /// Body radial gradient, top of the head down to the rim.
  final Color bodyTop;
  final Color bodyMid;
  final Color bodyDeep;
  final Color bodyRim;

  /// Body outline (also tints the inner right-side shade and the angry
  /// scratch marks).
  final Color outline;
  final Color outlineLight;

  /// The two side nubs.
  final Color armLight;
  final Color armMid;
  final Color armDeep;

  /// Cheek radial gradient.
  final Color cheekLight;
  final Color cheek;
  final Color cheekDeep;

  /// Eye radial gradient (near-black on every upstream skin).
  final Color eyeLight;
  final Color eye;
  final Color eyeDeep;

  /// Soft glow across the lower belly.
  final Color bellyGlow;

  /// The little colored pop inside each eye.
  final Color eyeSparkle;

  /// Ground-shadow tint. Null falls back to [outline] like the CSS var chain
  /// (`--jelly-shadow` -> `--jelly-outline`); on a light background a cool
  /// neutral (upstream light theme uses #8e88a6 / #aaa4c0) reads cleaner
  /// than the saturated body color.
  final Color? shadow;
  final Color? shadowLight;

  Color get effectiveShadow => shadow ?? outline;
  Color get effectiveShadowLight => shadowLight ?? outlineLight;

  /// The upstream violet jelly — exact values from styles/blob.css.
  static const JellyBlobPalette violet = JellyBlobPalette(
    bodyTop: Color(0xFFECB8FF),
    bodyMid: Color(0xFFC57AF3),
    bodyDeep: Color(0xFFA662E8),
    bodyRim: Color(0xFFD292FB),
    outline: Color(0xFF8D52DE),
    outlineLight: Color(0xFFB66AF0),
    armLight: Color(0xFFE1A8FF),
    armMid: Color(0xFFBC78ED),
    armDeep: Color(0xFF9C5DE2),
    cheekLight: Color(0xFFFFC5E2),
    cheek: Color(0xFFF68FC8),
    cheekDeep: Color(0xFFE87CB9),
    eyeLight: Color(0xFF37204B),
    eye: Color(0xFF170D25),
    eyeDeep: Color(0xFF0D0715),
    bellyGlow: Color(0xFFFFB2DC),
    eyeSparkle: Color(0xFFB471E6),
  );

  // The three presets below are NOT upstream colors — mixed for this port,
  // anchored on the two mint values upstream's README shows as a theming
  // example (body-mid #3cbe80, outline #2f9e6b).

  /// Mint jelly (hand-mixed; body/outline anchors from upstream's README).
  static const JellyBlobPalette mint = JellyBlobPalette(
    bodyTop: Color(0xFFC8F5DF),
    bodyMid: Color(0xFF3CBE80),
    bodyDeep: Color(0xFF2BA46C),
    bodyRim: Color(0xFF8FE6BD),
    outline: Color(0xFF2F9E6B),
    outlineLight: Color(0xFF5CC490),
    armLight: Color(0xFFA9ECC9),
    armMid: Color(0xFF46BD85),
    armDeep: Color(0xFF2F9E6B),
    cheekLight: Color(0xFFFFD3C9),
    cheek: Color(0xFFFF9D8A),
    cheekDeep: Color(0xFFF2836F),
    eyeLight: Color(0xFF1D3B2F),
    eye: Color(0xFF0C1F17),
    eyeDeep: Color(0xFF07130E),
    bellyGlow: Color(0xFFB5F3D2),
    eyeSparkle: Color(0xFF58CF96),
  );

  /// Coral jelly (hand-mixed).
  static const JellyBlobPalette coral = JellyBlobPalette(
    bodyTop: Color(0xFFFFD2C2),
    bodyMid: Color(0xFFFF8A70),
    bodyDeep: Color(0xFFF0654D),
    bodyRim: Color(0xFFFFAB93),
    outline: Color(0xFFE05540),
    outlineLight: Color(0xFFFF8A70),
    armLight: Color(0xFFFFC4B0),
    armMid: Color(0xFFFF8168),
    armDeep: Color(0xFFE8604A),
    cheekLight: Color(0xFFFFD9E6),
    cheek: Color(0xFFFF8FB7),
    cheekDeep: Color(0xFFF272A2),
    eyeLight: Color(0xFF46201B),
    eye: Color(0xFF24100D),
    eyeDeep: Color(0xFF140806),
    bellyGlow: Color(0xFFFFC7AE),
    eyeSparkle: Color(0xFFFF9D7E),
  );

  /// Gold jelly (hand-mixed).
  static const JellyBlobPalette gold = JellyBlobPalette(
    bodyTop: Color(0xFFFFE8B0),
    bodyMid: Color(0xFFF5B942),
    bodyDeep: Color(0xFFDC9A24),
    bodyRim: Color(0xFFFFD489),
    outline: Color(0xFFC98A1D),
    outlineLight: Color(0xFFECB64F),
    armLight: Color(0xFFFFDF9E),
    armMid: Color(0xFFF0B544),
    armDeep: Color(0xFFD0951F),
    cheekLight: Color(0xFFFFD4C4),
    cheek: Color(0xFFFF9E7E),
    cheekDeep: Color(0xFFF28866),
    eyeLight: Color(0xFF3C2A12),
    eye: Color(0xFF201507),
    eyeDeep: Color(0xFF120B03),
    bellyGlow: Color(0xFFFFDF9D),
    eyeSparkle: Color(0xFFE8A83C),
  );
}
