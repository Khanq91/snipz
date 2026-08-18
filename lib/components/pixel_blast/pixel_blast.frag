// PixelBlast — faithful port of react-bits Backgrounds/PixelBlast
// (Bayer-dithered FBM pixel pattern + tap ripples). Changes vs the WebGL
// original:
//   - fwidth() is unavailable in Flutter runtime effects -> the shape masks
//     use a constant AA width derived from uPixelSize instead.
//   - int/bool/array uniforms -> floats and ten discrete vec4 click slots
//     (xy = position px, z = click time, x < 0 = empty slot).
//   - the liquid touch-trail post-process is NOT ported (needs a dynamic
//     touch texture + render-to-texture pass); the film-noise post-process
//     is folded into this shader (uNoiseAmount).
//   - the final linear->sRGB conversion is dropped: uColor arrives as sRGB.
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec3 uColor;
uniform float uPixelSize;
uniform float uScale;
uniform float uDensity;
uniform float uPixelJitter;
uniform float uEnableRipples;
uniform float uRippleSpeed;
uniform float uRippleThickness;
uniform float uRippleIntensity;
uniform float uEdgeFade;
uniform float uShapeType; // 0 square, 1 circle, 2 triangle, 3 diamond
uniform float uNoiseAmount;
uniform float uTransparent; // 1 = premultiplied alpha out, 0 = over black
uniform vec4 uClick0;
uniform vec4 uClick1;
uniform vec4 uClick2;
uniform vec4 uClick3;
uniform vec4 uClick4;
uniform vec4 uClick5;
uniform vec4 uClick6;
uniform vec4 uClick7;
uniform vec4 uClick8;
uniform vec4 uClick9;

out vec4 fragColor;

const float FBM_LACUNARITY = 1.25;
const float FBM_GAIN = 1.0;

float Bayer2(vec2 a) {
  a = floor(a);
  return fract(a.x / 2.0 + a.y * a.y * 0.75);
}

float Bayer4(vec2 a) {
  return Bayer2(0.5 * a) * 0.25 + Bayer2(a);
}

// Faithful to the original macro chain (Bayer4 of the half-res grid plus
// Bayer2 of the full grid).
float Bayer8(vec2 a) {
  return Bayer4(0.5 * a) * 0.25 + Bayer2(a);
}

float hash11(float n) {
  return fract(sin(n) * 43758.5453);
}

float vnoise(vec3 p) {
  vec3 ip = floor(p);
  vec3 fp = fract(p);
  float n000 = hash11(dot(ip + vec3(0.0, 0.0, 0.0), vec3(1.0, 57.0, 113.0)));
  float n100 = hash11(dot(ip + vec3(1.0, 0.0, 0.0), vec3(1.0, 57.0, 113.0)));
  float n010 = hash11(dot(ip + vec3(0.0, 1.0, 0.0), vec3(1.0, 57.0, 113.0)));
  float n110 = hash11(dot(ip + vec3(1.0, 1.0, 0.0), vec3(1.0, 57.0, 113.0)));
  float n001 = hash11(dot(ip + vec3(0.0, 0.0, 1.0), vec3(1.0, 57.0, 113.0)));
  float n101 = hash11(dot(ip + vec3(1.0, 0.0, 1.0), vec3(1.0, 57.0, 113.0)));
  float n011 = hash11(dot(ip + vec3(0.0, 1.0, 1.0), vec3(1.0, 57.0, 113.0)));
  float n111 = hash11(dot(ip + vec3(1.0, 1.0, 1.0), vec3(1.0, 57.0, 113.0)));
  vec3 w = fp * fp * fp * (fp * (fp * 6.0 - 15.0) + 10.0);
  float x00 = mix(n000, n100, w.x);
  float x10 = mix(n010, n110, w.x);
  float x01 = mix(n001, n101, w.x);
  float x11 = mix(n011, n111, w.x);
  float y0 = mix(x00, x10, w.y);
  float y1 = mix(x01, x11, w.y);
  return mix(y0, y1, w.z) * 2.0 - 1.0;
}

float fbm2(vec2 uv, float t) {
  vec3 p = vec3(uv * uScale, t);
  float amp = 1.0;
  float freq = 1.0;
  float sum = 1.0;
  for (int i = 0; i < 5; ++i) {
    sum += amp * vnoise(p * freq);
    freq *= FBM_LACUNARITY;
    amp *= FBM_GAIN;
  }
  return sum * 0.5 + 0.5;
}

float maskCircle(vec2 p, float cov) {
  float r = sqrt(cov) * 0.25;
  float d = length(p - 0.5) - r;
  float aa = 1.5 / uPixelSize; // constant AA (no fwidth in runtime effects)
  return cov * (1.0 - smoothstep(-aa, aa, d * 2.0));
}

float maskTriangle(vec2 p, vec2 id, float cov) {
  if (mod(id.x + id.y, 2.0) > 0.5) {
    p.x = 1.0 - p.x;
  }
  float r = sqrt(cov);
  float d = p.y - r * (1.0 - p.x);
  float aa = 2.0 / uPixelSize; // constant AA (no fwidth in runtime effects)
  return cov * clamp(0.5 - d / aa, 0.0, 1.0);
}

float maskDiamond(vec2 p, float cov) {
  float r = sqrt(cov) * 0.564;
  return step(abs(p.x - 0.49) + abs(p.y - 0.49), r);
}

float rippleContrib(vec4 click, vec2 uv, float aspect, float cellPixelSize) {
  if (click.x < 0.0) {
    return 0.0;
  }
  vec2 cuv = ((click.xy - uResolution * 0.5 - cellPixelSize * 0.5) / uResolution) * vec2(aspect, 1.0);
  float t = max(uTime - click.z, 0.0);
  float r = distance(uv, cuv);
  float waveR = uRippleSpeed * t;
  float ring = exp(-pow((r - waveR) / uRippleThickness, 2.0));
  float atten = exp(-1.0 * t) * exp(-10.0 * r);
  return ring * atten * uRippleIntensity;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy - uResolution * 0.5;
  float aspectRatio = uResolution.x / uResolution.y;

  vec2 pixelId = floor(fragCoord / uPixelSize);
  vec2 pixelUV = fract(fragCoord / uPixelSize);

  float cellPixelSize = 8.0 * uPixelSize;
  vec2 cellId = floor(fragCoord / cellPixelSize);
  vec2 cellCoord = cellId * cellPixelSize;
  vec2 uv = cellCoord / uResolution * vec2(aspectRatio, 1.0);

  float base = fbm2(uv, uTime * 0.05);
  base = base * 0.5 - 0.65;

  float feed = base + (uDensity - 0.5) * 0.3;

  if (uEnableRipples > 0.5) {
    feed = max(feed, rippleContrib(uClick0, uv, aspectRatio, cellPixelSize));
    feed = max(feed, rippleContrib(uClick1, uv, aspectRatio, cellPixelSize));
    feed = max(feed, rippleContrib(uClick2, uv, aspectRatio, cellPixelSize));
    feed = max(feed, rippleContrib(uClick3, uv, aspectRatio, cellPixelSize));
    feed = max(feed, rippleContrib(uClick4, uv, aspectRatio, cellPixelSize));
    feed = max(feed, rippleContrib(uClick5, uv, aspectRatio, cellPixelSize));
    feed = max(feed, rippleContrib(uClick6, uv, aspectRatio, cellPixelSize));
    feed = max(feed, rippleContrib(uClick7, uv, aspectRatio, cellPixelSize));
    feed = max(feed, rippleContrib(uClick8, uv, aspectRatio, cellPixelSize));
    feed = max(feed, rippleContrib(uClick9, uv, aspectRatio, cellPixelSize));
  }

  float bayer = Bayer8(fragCoord / uPixelSize) - 0.5;
  float bw = step(0.5, feed + bayer);

  float h = fract(sin(dot(floor(fragCoord / uPixelSize), vec2(127.1, 311.7))) * 43758.5453);
  float jitterScale = 1.0 + (h - 0.5) * uPixelJitter;
  float coverage = bw * jitterScale;

  float M;
  if (uShapeType > 2.5) {
    M = maskDiamond(pixelUV, coverage);
  } else if (uShapeType > 1.5) {
    M = maskTriangle(pixelUV, pixelId, coverage);
  } else if (uShapeType > 0.5) {
    M = maskCircle(pixelUV, coverage);
  } else {
    M = coverage;
  }

  if (uEdgeFade > 0.0) {
    vec2 norm = FlutterFragCoord().xy / uResolution;
    float edge = min(min(norm.x, norm.y), min(1.0 - norm.x, 1.0 - norm.y));
    M *= smoothstep(0.0, uEdgeFade, edge);
  }

  vec3 color = uColor * M;
  if (uNoiseAmount > 0.0) {
    vec2 norm = FlutterFragCoord().xy / uResolution;
    float n = fract(sin(dot(floor(norm * vec2(1920.0, 1080.0)) + floor(uTime * 60.0), vec2(127.1, 311.7))) * 43758.5453);
    color += (n - 0.5) * uNoiseAmount;
  }

  float alpha = mix(1.0, M, uTransparent);
  fragColor = vec4(color, alpha);
}
