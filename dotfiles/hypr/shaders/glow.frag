// ~/.config/hypr/shaders/glow.frag — subtle vibrance + soft bloom
// Hyprland screen shader (GLES2). Portable. GPU-heavy: may be limited in the VM,
// shines on real hardware. Tweak the two constants to taste.
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

const float VIBRANCE = 1.12;   // 1.0 = off; higher = punchier colours
const float GLOW      = 0.30;  // strength of the soft glow on bright areas

void main() {
    vec4 color = texture2D(tex, v_texcoord);

    // vibrance: push colours a little away from their grey luminance
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(lum), color.rgb, VIBRANCE);

    // soft glow: add back a fraction of the brightest regions
    vec3 bright = max(color.rgb - 0.6, 0.0);
    color.rgb += bright * bright * GLOW;

    gl_FragColor = color;
}
