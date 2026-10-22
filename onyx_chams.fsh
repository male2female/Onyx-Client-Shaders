#version 120

// GLSL 120 port of onyx_chams.fsh.
//
// Two things differ from the Fabric original. There is no overlay texture in 1.8.9 — the hurt and
// charge flashes are a plain GL colour there, not a sampler — so the untouched-model blend has no
// overlay term. And fog comes from the fixed-function `gl_Fog` state rather than Minecraft's own
// fog uniforms.

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;

uniform vec4 uTint;
uniform vec4 uStyle;
uniform float uFogEnabled;

varying vec2 texCoord0;
varying vec2 lightCoord;
varying vec3 cameraRelative;
varying vec3 surfaceNormal;

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec4 skin = texture2D(Sampler0, texCoord0);

    // Taken before the discard, while every fragment of the quad is still alive: a derivative
    // that reads a killed neighbour is undefined, and this one has to survive skin edges.
    float creases = clamp(fwidth(luminance(skin.rgb)) * 7.0, 0.0, 1.0);

    if (skin.a < 0.1) {
        discard;
    }

    vec3 tint = uTint.rgb;
    float opacity = uTint.a;

    float paramA = uStyle.x;
    float modelAmount = uStyle.w;

    vec3 normal = normalize(surfaceNormal);
    vec3 view = normalize(-cameraRelative);
    float facing = clamp(abs(dot(normal, view)), 0.0, 1.0);

    // The untouched model, kept around because two things want it: the keep-model blend below,
    // and strength itself, which fades the whole grade back to this rather than to a grey skin.
    vec3 model = skin.rgb * texture2D(Sampler1, lightCoord).rgb;

    // Everything comes off the skin itself: its own value drives a crushed, desaturated grade
    // towards the tint, and its own contrast marks the creases that grade sinks into.
    float value = luminance(skin.rgb);
    vec3 graded = mix(vec3(value), skin.rgb, 0.25);

    graded = mix(graded, tint * (0.2 + 0.8 * value * value), paramA);
    graded *= 1.0 - creases * paramA * 0.5;

    vec3 styled = graded * mix(0.32, 1.0, facing);

    // Strength gates the entire stylisation, not just the tint. At 0 the desaturation and the
    // facing falloff go with it, so the skin comes out exactly as the game drew it and chams is
    // left doing nothing but the through-walls pass.
    vec3 color = mix(model, styled, paramA);
    float alpha = opacity;

    if (modelAmount > 0.0) {
        color = mix(color, model, modelAmount);
        alpha = mix(alpha, opacity, modelAmount);
    }

    if (uFogEnabled > 0.5) {
        float fogAmount = clamp((gl_Fog.end - gl_FogFragCoord) * gl_Fog.scale, 0.0, 1.0);
        color = mix(gl_Fog.color.rgb, color, fogAmount);
    }

    gl_FragColor = vec4(color, alpha);
}
