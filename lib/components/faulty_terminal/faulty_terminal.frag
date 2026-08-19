// FaultyTerminal — port of react-bits Backgrounds/FaultyTerminal (OGL).
// A glitchy CRT terminal: a grid of pseudo-random "digit" cells lit by
// layered fbm noise, with scanline bars, line displacement/flicker glitches,
// barrel curvature, optional chromatic aberration and output dither.
// Changes vs the WebGL original:
//   - vUv came from the vertex shader (y-up); reconstructed here as
//     FlutterFragCoord()/uResolution with uv.y flipped once.
//   - The original assigns a mutable GLOBAL `float time;` in main() — SkSL
//     runtime effects forbid mutable globals, so time is threaded through
//     noise/fbm/pattern/digit/getColor as a parameter `t`. Math unchanged.
//   - Mouse interaction (uMouse/uMouseStrength/uUseMouse) dropped — no hover
//     on Android.
//   - uUsePageLoadAnimation flag folded away: at uPageLoadProgress >= 1.0 the
//     fade multiplier is 1.0 for every cell, so the branch is simply skipped;
//     pass 1.0 to disable the load animation.
//   - uScale is the original's own UV multiplier and doubles as the §9.1
//     detail-density scale.
#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;           // floats 0,1
uniform float uTime;                // 2 — already (elapsed+offset)*timeScale
uniform float uScale;               // 3
uniform vec2 uGridMul;              // 4,5
uniform float uDigitSize;           // 6
uniform float uScanlineIntensity;   // 7
uniform float uGlitchAmount;        // 8
uniform float uFlickerAmount;       // 9
uniform float uNoiseAmp;            // 10
uniform float uChromaticAberration; // 11
uniform float uDither;              // 12
uniform float uCurvature;           // 13
uniform vec3 uTint;                 // 14,15,16
uniform float uBrightness;          // 17
uniform float uPageLoadProgress;    // 18 — 1.0 = fully loaded / disabled

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * 234.56);
  p += dot(p, p + 34.56);
  return fract(p.x * p.y);
}

// `t` is the original's global `time` (= uTime / 3).
float noise(vec2 p, float t) {
  return sin(p.x * 10.0) * sin(p.y * (3.0 + sin(t * 0.090909))) + 0.2;
}

mat2 rotate(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat2(c, -s, s, c);
}

float fbm(vec2 p, float t) {
  p *= 1.1;
  float f = 0.0;
  float amp = 0.5 * uNoiseAmp;

  mat2 modify0 = rotate(t * 0.02);
  f += amp * noise(p, t);
  p = modify0 * p * 2.0;
  amp *= 0.454545;

  mat2 modify1 = rotate(t * 0.02);
  f += amp * noise(p, t);
  p = modify1 * p * 2.0;
  amp *= 0.454545;

  // The original builds a third rotation (rotate(time * 0.08)) but never
  // applies it — kept identical by not applying it here either.
  f += amp * noise(p, t);

  return f;
}

float pattern(vec2 p, float t) {
  // q/r were `out` params in the original but the caller never reads them.
  vec2 offset1 = vec2(1.0);
  mat2 rot01 = rotate(0.1 * t);
  mat2 rot1 = rotate(0.1);

  vec2 q = vec2(fbm(p + offset1, t), fbm(rot01 * p + offset1, t));
  vec2 r = vec2(fbm(rot1 * q, t), fbm(q, t));
  return fbm(p + r, t);
}

float digit(vec2 p, float t) {
  vec2 grid = uGridMul * 15.0;
  vec2 s = floor(p * grid) / grid;
  p = p * grid;
  float intensity = pattern(s * 0.1, t) * 1.3 - 0.03;

  // Page-load fade: cells pop in with a per-cell random delay. At
  // progress >= 1.0 every cell multiplier is 1.0, so skip the work.
  if (uPageLoadProgress < 1.0) {
    float cellRandom = fract(sin(dot(s, vec2(12.9898, 78.233))) * 43758.5453);
    float cellDelay = cellRandom * 0.8;
    float cellProgress = clamp((uPageLoadProgress - cellDelay) / 0.2, 0.0, 1.0);
    intensity *= smoothstep(0.0, 1.0, cellProgress);
  }

  p = fract(p);
  p *= uDigitSize;

  float px5 = p.x * 5.0;
  float py5 = (1.0 - p.y) * 5.0;
  float x = fract(px5);
  float y = fract(py5);

  float i = floor(py5) - 2.0;
  float j = floor(px5) - 2.0;
  float n = i * i + j * j;
  float f = n * 0.0625;

  float isOn = step(0.1, intensity - f);
  float brightness = isOn * (0.2 + y * 0.8) * (0.75 + x * 0.25);

  return step(0.0, p.x) * step(p.x, 1.0) * step(0.0, p.y) * step(p.y, 1.0) * brightness;
}

float onOff(float a, float b, float c) {
  return step(c, sin(uTime + a * cos(uTime * b))) * uFlickerAmount;
}

float displace(vec2 look) {
  float y = look.y - mod(uTime * 0.25, 1.0);
  float window = 1.0 / (1.0 + 50.0 * y * y);
  return sin(look.y * 20.0 + uTime) * 0.0125 * onOff(4.0, 2.0, 0.8) * (1.0 + cos(uTime * 60.0)) * window;
}

vec3 getColor(vec2 p, float t) {
  float bar = step(mod(p.y + t * 20.0, 1.0), 0.2) * 0.4 + 1.0;
  bar *= uScanlineIntensity;

  float displacement = displace(p);
  p.x += displacement;

  if (uGlitchAmount != 1.0) {
    p.x += displacement * (uGlitchAmount - 1.0);
  }

  float middle = digit(p, t);

  const float off = 0.002;
  float sum = digit(p + vec2(-off, -off), t) + digit(p + vec2(0.0, -off), t) + digit(p + vec2(off, -off), t) +
              digit(p + vec2(-off, 0.0), t) + digit(p + vec2(0.0, 0.0), t) + digit(p + vec2(off, 0.0), t) +
              digit(p + vec2(-off, off), t) + digit(p + vec2(0.0, off), t) + digit(p + vec2(off, off), t);

  return vec3(0.9) * middle + sum * 0.1 * vec3(1.0) * bar;
}

vec2 barrel(vec2 uv) {
  vec2 c = uv * 2.0 - 1.0;
  float r2 = dot(c, c);
  c *= 1.0 + uCurvature * r2;
  return c * 0.5 + 0.5;
}

void main() {
  float t = uTime * 0.333333; // the original's global `time`

  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / uResolution;
  uv.y = 1.0 - uv.y; // GL orientation of the original (vUv is y-up)

  if (uCurvature != 0.0) {
    uv = barrel(uv);
  }

  vec2 p = uv * uScale;
  vec3 col = getColor(p, t);

  if (uChromaticAberration != 0.0) {
    vec2 ca = vec2(uChromaticAberration) / uResolution;
    col.r = getColor(p + ca, t).r;
    col.b = getColor(p - ca, t).b;
  }

  col *= uTint;
  col *= uBrightness;

  if (uDither > 0.0) {
    float rnd = hash21(fragCoord);
    col += (rnd - 0.5) * (uDither * 0.003922);
  }

  fragColor = vec4(col, 1.0);
}
