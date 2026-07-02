#version 300 es
// ~/.config/hypr/shaders/bloom.frag
// REAL halation / bloom — for METAL (a proper GPU), NOT the VM.
//
// Unlike glow.frag (which is per-pixel), this GATHERS threshold-passed brightness
// from a dense Gaussian neighbourhood, so bright things get a soft glowing halo
// (true halation). That means it:
//   1) samples 169 texels per pixel — cheap on a real GPU, will crawl on the VM's
//      software GL, and
//   2) MUST be paired with `debug:damage_tracking = 0` in hyprland.conf. Otherwise
//      Hyprland only redraws the changed parts of the screen and the neighbour
//      taps leave stale mesh artefacts (the exact jank glow.frag was rewritten to
//      avoid).
//
// TO SWITCH TO THIS ON REAL HARDWARE (all in hyprland.conf, then `hyprctl reload`):
//   - decoration: screen_shader = ~/.config/hypr/shaders/bloom.frag
//   - uncomment the `debug { damage_tracking = 0 }` block at the bottom of the file
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float VIBRANCE  = 1.22;   // colour grade — matches glow.frag
const float CONTRAST  = 1.08;
const float VIGNETTE  = 0.25;

const float THRESHOLD = 0.55;   // only pixels brighter than this feed the halo
const float GLOW      = 0.75;   // halo intensity
const float RADIUS    = 0.010;  // halo reach (texcoord units ≈ 2% of screen)
const int   STEPS     = 6;      // taps per side → (2*STEPS+1)^2 = 13x13 = 169 samples

void main() {
    vec3 c = texture(tex, v_texcoord).rgb;

    // --- vibrance + contrast (same grade as glow.frag) ---
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(lum), c, VIBRANCE);
    c = (c - 0.5) * CONTRAST + 0.5;

    // --- Gaussian bloom: soft halo gathered from bright neighbours ---
    float stepSize = RADIUS / float(STEPS);
    float sigma    = RADIUS * 0.5;
    vec3  bloom    = vec3(0.0);
    float total    = 0.0;
    for (int x = -STEPS; x <= STEPS; x++) {
        for (int y = -STEPS; y <= STEPS; y++) {
            vec2  off = vec2(float(x), float(y)) * stepSize;
            float w   = exp(-dot(off, off) / (2.0 * sigma * sigma));   // Gaussian weight
            vec3  s   = texture(tex, v_texcoord + off).rgb;
            bloom += max(s - THRESHOLD, 0.0) * w;                       // bright part only
            total += w;
        }
    }
    c += (bloom / total) * GLOW;

    // --- vignette ---
    vec2 d = v_texcoord - 0.5;
    c *= 1.0 - dot(d, d) * VIGNETTE * 2.0;

    fragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}
