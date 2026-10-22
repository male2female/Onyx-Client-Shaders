#version 120

// GLSL 120 port of hand_trail_up.fsh: dual-Kawase upsample.

uniform sampler2D Sampler0;
uniform vec2 uSourceSize;
uniform float uBlur;

varying vec2 texCoord;

void main() {
    vec2 halfPixel = (0.5 / max(uSourceSize, vec2(1.0))) * uBlur;

    vec4 sum = texture2D(Sampler0, texCoord + vec2(-halfPixel.x * 2.0, 0.0));
    sum += texture2D(Sampler0, texCoord + vec2(-halfPixel.x, halfPixel.y)) * 2.0;
    sum += texture2D(Sampler0, texCoord + vec2(0.0, halfPixel.y * 2.0));
    sum += texture2D(Sampler0, texCoord + vec2(halfPixel.x, halfPixel.y)) * 2.0;
    sum += texture2D(Sampler0, texCoord + vec2(halfPixel.x * 2.0, 0.0));
    sum += texture2D(Sampler0, texCoord + vec2(halfPixel.x, -halfPixel.y)) * 2.0;
    sum += texture2D(Sampler0, texCoord + vec2(0.0, -halfPixel.y * 2.0));
    sum += texture2D(Sampler0, texCoord + vec2(-halfPixel.x, -halfPixel.y)) * 2.0;

    gl_FragColor = sum / 12.0;
}
