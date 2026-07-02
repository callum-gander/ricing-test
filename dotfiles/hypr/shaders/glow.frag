#version 300 es
// ~/.config/hypr/shaders/glow.frag — vibrance + real bloom/halation (still strong for testing).
// The bloom gathers bright light from NEIGHBOURING pixels, so it spreads a halo around bright
// things (that's the halation). Dial SPREAD/GLOW/VIBRANCE down once you're happy.
precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float VIBRANCE  = 1.5;      // colour punch (subtle ~1.12)
const float THRESHOLD = 0.5;      // only pixels brighter than this bloom
const float SPREAD    = 0.010;    // how far the halo reaches (fraction of screen)
const float GLOW      = 2.0;      // halo intensity

void main() {
    vec4 color = texture(tex, v_texcoord);

    // vibrance
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(lum), color.rgb, VIBRANCE);

    // bloom / halation: gather bright light from a 5x5 neighbourhood
    vec3 bloom = vec3(0.0);
    float total = 0.0;
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 off = vec2(float(x), float(y)) * SPREAD;
            vec3 s = texture(tex, v_texcoord + off).rgb;
            vec3 b = max(s - THRESHOLD, 0.0);   // the bright part only
            float w = 1.0 / (1.0 + float(x * x + y * y));
            bloom += b * w;
            total += w;
        }
    }
    color.rgb += (bloom / total) * GLOW;

    fragColor = color;
}
