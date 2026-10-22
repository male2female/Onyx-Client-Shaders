#version 120

// GLSL 120 port of hand_trail_smoke.fsh: lays the simulated smoke back over the scene.

uniform sampler2D SceneSampler;
uniform sampler2D SmokeSampler;
uniform sampler2D MaskSampler;

uniform vec2 uMaskSize;
uniform vec4 uSmokeParams;
uniform vec4 uSmokeExtra;

varying vec2 texCoord;

float sampleMask(vec2 uv) {
    return texture2D(MaskSampler, clamp(uv, vec2(0.0), vec2(1.0))).r;
}

float edgeMask(vec2 uv, vec2 texelSize) {
    float c = sampleMask(uv);
    float e = 0.0;
    e += abs(c - sampleMask(uv + vec2( texelSize.x, 0.0)));
    e += abs(c - sampleMask(uv + vec2(-texelSize.x, 0.0)));
    e += abs(c - sampleMask(uv + vec2(0.0,  texelSize.y)));
    e += abs(c - sampleMask(uv + vec2(0.0, -texelSize.y)));
    return clamp(e * 0.9, 0.0, 1.0);
}

void main() {
    float intensity = uSmokeParams.x;
    float handSoftness = uSmokeParams.y;
    float handBlur = uSmokeParams.z;
    float smoke = uSmokeParams.w;
    float activity = uSmokeExtra.x;

    // The mask is simulated at a fraction of the output, so the edge taps have to step by its
    // texel and not by the screen's, or neighbouring pixels land on the same texel and the rim
    // breaks up into a grid.
    vec2 texelSize = 1.0 / max(uMaskSize, vec2(1.0));

    float topDistance = 1.0 - texCoord.y;
    float topEdgeFade = smoothstep(0.012, 0.085, topDistance);
    vec4 scene = texture2D(SceneSampler, texCoord);
    vec4 smokeTex = texture2D(SmokeSampler, texCoord);

    float intensityC = clamp(intensity, 0.0, 1.5);
    float softness = clamp(handSoftness, 0.4, 2.5);
    float blurSetting = clamp(handBlur, 0.2, 3.0);
    float smokeSetting = clamp(smoke, 0.0, 0.8);
    float mask = sampleMask(texCoord);
    float edge = edgeMask(texCoord, texelSize);

    float activityC = clamp(activity, 0.0, 1.0);
    float trail = clamp(smokeTex.a, 0.0, 1.0);
    float softMix = clamp((softness - 0.4) / 2.1, 0.0, 1.0);
    float blurMix = clamp((blurSetting - 0.2) / 2.8, 0.0, 1.0);
    float bloom = pow(trail, mix(0.78, 0.48, softMix));
    float aura = smoothstep(0.012, mix(0.24, 0.38, blurMix), trail);
    float smokeAlpha = clamp(max(bloom * 0.62, aura * 0.38), 0.0, 0.76);
    smokeAlpha *= (0.84 + intensityC * 0.46 + smokeSetting * 0.35 + activityC * 0.12 + softMix * 0.14);
    smokeAlpha = clamp(smokeAlpha, 0.0, 0.86);
    smokeAlpha = smokeAlpha < 0.005 ? 0.0 : smokeAlpha;
    smokeAlpha *= 1.0 - mask * 0.18;
    smokeAlpha *= topEdgeFade;

    vec3 smokeColor = clamp(smokeTex.rgb * (1.18 + smokeSetting * 0.24), 0.0, 1.0);
    vec3 outColor = scene.rgb;
    outColor += smokeColor * smokeAlpha;
    outColor += smokeColor * edge * bloom * (0.11 + intensityC * 0.10) * (1.0 - softMix * 0.28) * topEdgeFade;

    gl_FragColor = vec4(clamp(outColor, 0.0, 1.0), scene.a);
}
