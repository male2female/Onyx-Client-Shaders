#version 120

// GLSL 120 port of hand_trail_near.fsh.
//
// A tiny map of where the trail could possibly reach, dilated by the radius the gather searches.
// One texel of this answers, for a whole block of the screen, whether the expensive pass has any
// reason to run at all.

uniform sampler2D Sampler0;
uniform vec2 uSourceSize;
uniform vec2 uOutSize;

varying vec2 texCoord;

void main() {
    vec2 texel = 1.0 / max(uSourceSize, vec2(1.0));
    vec2 span = uSourceSize / max(uOutSize, vec2(1.0)) * 0.5;
    float widest = 0.0;

    for (int y = -3; y <= 3; y++) {
        for (int x = -3; x <= 3; x++) {
            widest = max(widest, texture2D(Sampler0, texCoord + vec2(float(x), float(y)) * span * texel).r);
        }
    }

    gl_FragColor = vec4(widest);
}
