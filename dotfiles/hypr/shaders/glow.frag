#version 300 es
// ~/.config/hypr/shaders/glow.frag — subtle vibrance + soft bloom
// Hyprland screen shader (GLES3 — must match Hyprland's shader version). Portable.
// Tweak the two constants to taste.
precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float VIBRANCE = 1.12;   // 1.0 = off; higher = punchier colours
const float GLOW      = 0.30;  // strength of the soft glow on bright areas

void main() {
    vec4 color = texture(tex, v_texcoord);

    // vibrance: nudge colours away from their grey luminance
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(lum), color.rgb, VIBRANCE);

    // soft glow: add back a fraction of the brightest regions
    vec3 bright = max(color.rgb - 0.6, 0.0);
    color.rgb += bright * bright * GLOW;

    fragColor = color;
}
