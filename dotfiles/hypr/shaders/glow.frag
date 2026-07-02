#version 300 es
// ~/.config/hypr/shaders/glow.frag — TEST MODE: cranked up so you can SEE it working.
// If the screen goes heavily saturated + warm-tinted + glowy, the shader is applying.
// Once confirmed, dial VIBRANCE→1.12, GLOW→0.30, and remove the TINT line for a subtle look.
precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float VIBRANCE = 2.5;    // subtle = 1.12
const float GLOW      = 2.0;    // subtle = 0.30

void main() {
    vec4 color = texture(tex, v_texcoord);

    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(lum), color.rgb, VIBRANCE);

    vec3 bright = max(color.rgb - 0.4, 0.0);
    color.rgb += bright * bright * GLOW;

    color.rgb *= vec3(1.15, 1.0, 0.82);   // obvious warm tint (remove for subtle)

    fragColor = color;
}
