#version 120

// GLSL 120 port of hand_trail_down.fsh: dual-Kawase downsample.

uniform sampler2D Sampler0;
uniform vec2 uSourceSize;
uniform float uBlur;

varying vec2 texCoord;

void main() {
    vec2 halfPixel = (0.5 / max(uSourceSize, vec2(1.0))) * uBlur;

    vec4 sum = texture2D(Sampler0, texCoord) * 4.0;
    sum += texture2D(Sampler0, texCoord - halfPixel);
    sum += texture2D(Sampler0, texCoord + halfPixel);
    sum += texture2D(Sampler0, texCoord + vec2(halfPixel.x, -halfPixel.y));
    sum += texture2D(Sampler0, texCoord - vec2(halfPixel.x, -halfPixel.y));

    gl_FragColor = sum / 8.0;
}
