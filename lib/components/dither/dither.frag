// DitherWaves — port of react-bits Backgrounds/Dither. The original renders
// in two passes (wave shader -> Bayer-dither postprocess reading inputBuffer);
// since the wave is fully procedural, both passes are folded into this single
// fragment: the wave is evaluated at the pixelated UV (exactly what sampling
// the pixelated inputBuffer did), then quantized with the same 8x8 Bayer
// threshold. Changes vs the WebGL original:
//   - FlutterFragCoord() is y-down -> uv.y flipped once so the pattern keeps
//     the original's orientation.
//   - const float[64] Bayer table -> procedural per-bit computation (runtime
//     effects and const arrays don't mix reliably; the closed form is exact).
//   - mouse hover interaction dropped (no hover on Android).
//   - uScale added (§9.1): multiplies the noise domain so small carriers keep
//     pattern detail.
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform float uWaveSpeed;
uniform float uWaveFrequency;
uniform float uWaveAmplitude;
uniform float uScale;
uniform float uColorNum;
uniform float uPixelSize;
uniform vec3 uWaveColor;

out vec4 fragColor;

#define OCTAVES 4

// --- classic 2D Perlin noise (webgl-noise, as embedded in the original) ---
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x * 34.0) + 1.0) * x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }
vec2 fade(vec2 t) { return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); }

float cnoise(vec2 P) {
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod289(Pi);
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute(permute(ix) + iy);
  vec4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0;
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x, gy.x);
  vec2 g10 = vec2(gx.y, gy.y);
  vec2 g01 = vec2(gx.z, gy.z);
  vec2 g11 = vec2(gx.w, gy.w);
  vec4 norm = taylorInvSqrt(vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  return 2.3 * mix(n_x.x, n_x.y, fade_xy.y);
}

float fbm(vec2 p) {
  float value = 0.0;
  float amp = 1.0;
  float freq = uWaveFrequency;
  for (int i = 0; i < OCTAVES; i++) {
    value += amp * abs(cnoise(p));
    p *= freq;
    amp *= uWaveAmplitude;
  }
  return value;
}

float wavePattern(vec2 p) {
  vec2 p2 = p - uTime * uWaveSpeed;
  return fbm(p + fbm(p2));
}

// Bayer 8x8 threshold, exact closed form of the original's float[64] table:
// M8(x,y) = 16*f(x0,y0) + 4*f(x1,y1) + f(x2,y2), f(a,b) = 2*(a xor b) + a.
float bayerCell(float a, float b) { return 2.0 * mod(a + b, 2.0) + a; }

float bayer8(vec2 c) {
  float x = mod(c.x, 8.0);
  float y = mod(c.y, 8.0);
  float x0 = mod(x, 2.0);
  float y0 = mod(y, 2.0);
  float x1 = mod(floor(x * 0.5), 2.0);
  float y1 = mod(floor(y * 0.5), 2.0);
  float x2 = floor(x * 0.25);
  float y2 = floor(y * 0.25);
  return (16.0 * bayerCell(x0, y0) + 4.0 * bayerCell(x1, y1) + bayerCell(x2, y2)) / 64.0;
}

vec3 dither(vec2 uv, vec3 color) {
  vec2 scaledCoord = floor(uv * uResolution / uPixelSize);
  float threshold = bayer8(scaledCoord) - 0.25;
  float quantStep = 1.0 / (uColorNum - 1.0);
  color += threshold * quantStep;
  float bias = 0.2;
  color = clamp(color - bias, 0.0, 1.0);
  return floor(color * (uColorNum - 1.0) + 0.5) / (uColorNum - 1.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  uv.y = 1.0 - uv.y; // GL orientation of the original

  // Pixelation from the original postprocess: evaluate the wave at the
  // block-floored uv instead of sampling a pixelated buffer.
  vec2 normalizedPixelSize = uPixelSize / uResolution;
  vec2 uvPixel = normalizedPixelSize * floor(uv / normalizedPixelSize);

  vec2 p = uvPixel - 0.5;
  p.x *= uResolution.x / uResolution.y;
  float f = wavePattern(p * uScale);

  vec3 col = mix(vec3(0.0), uWaveColor, f);
  col = dither(uv, col);
  fragColor = vec4(col, 1.0);
}
