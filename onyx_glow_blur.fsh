#version 120

uniform sampler2D DiffuseSampler;

uniform vec2 InSize;

uniform vec2 BlurDir;
uniform float Radius;

varying vec2 texCoord;

const int MAX_RADIUS = 24;
const float SPREAD = 1.6;

void main() {
    vec2 sampleStep = BlurDir / InSize * SPREAD;
    float sigma = max(Radius * 0.5, 0.75);
    float denominator = 2.0 * sigma * sigma;

    vec3 colorSum = vec3(0.0);
    float alphaSum = 0.0;
    float weightSum = 0.0;

    for (int offset = -MAX_RADIUS; offset <= MAX_RADIUS; offset++) {
        float d = float(offset);
        if (abs(d) > Radius) continue;

        float weight = exp(-(d * d) / denominator);
        vec4 sampleColor = texture2D(DiffuseSampler, texCoord + sampleStep * d);

        colorSum += sampleColor.rgb * sampleColor.a * weight;
        alphaSum += sampleColor.a * weight;
        weightSum += weight;
    }

    vec3 color = colorSum / max(alphaSum, 0.0001);
    gl_FragColor = vec4(color, alphaSum / max(weightSum, 0.0001));
}
