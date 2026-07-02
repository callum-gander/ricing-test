#version 300 es
// ~/.config/hypr/shaders/glow.frag
// PER-PIXEL colour grade: vibrance + gentle contrast + highlight self-glow + vignette.
//
// Deliberately samples ONLY the current pixel — NO neighbour taps. Neighbour-
// sampling screen shaders fight Hyprland's damage tracking (it redraws only the
// changed parts of the screen, so stale shaded pixels persist as ghost/mesh
// artefacts), and a single screen shader can't do a real multi-pass bloom anyway.
// So the "glow" here is: already-bright pixels get lifted (self-bloom), and the
// compositor's window blur does the spatial light-spread. Smooth + cheap — fine
// even on the VM's soft GL. Tune the constants to taste (this file hot-reloads:
// edit → `hyprctl reload`).
precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float VIBRANCE = 1.22;   // colour saturation punch (1.0 = untouched)
const float CONTRAST = 1.08;   // gentle S-curve around mid-grey
const float LIFT     = 0.35;   // how hard bright pixels "glow" (self-bloom)
const float VIGNETTE = 0.25;   // corner darkening (0 = off) — focuses the eye

void main() {
    vec3 c = texture(tex, v_texcoord).rgb;

    // vibrance — push colour away from its own luminance
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(lum), c, VIBRANCE);

    // gentle contrast around 0.5
    c = (c - 0.5) * CONTRAST + 0.5;

    // highlight self-glow — only pixels that are already bright bloom their own
    // colour brighter (smoothstep gate so mid-tones/darks are untouched → no mesh)
    float hi = smoothstep(0.6, 1.0, lum);
    c += c * hi * LIFT;

    // vignette — per-pixel, distance from screen centre
    vec2 d = v_texcoord - 0.5;
    c *= 1.0 - dot(d, d) * VIGNETTE * 2.0;

    fragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}
