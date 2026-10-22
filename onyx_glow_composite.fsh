#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D HaloSampler;

uniform float Intensity;

varying vec2 texCoord;
varying vec2 oneTexel;

vec3 saturate(vec3 color, float amount) {
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    return mix(vec3(luma), color, amount);
}

float occupied(vec2 offset) {
    return step(0.001, texture2D(DiffuseSampler, texCoord + offset).a);
}

void main() {
    vec4 mask = texture2D(DiffuseSampler, texCoord);
    vec4 halo = texture2D(HaloSampler, texCoord);

    float inside = step(0.001, mask.a);

    // The former standalone sobel pass, folded in: a mask texel is part of the outline
    // core when any 4-neighbour occupancy differs. Same taps as before, minus a whole
    // full-resolution render pass, target and clear per frame.
    float coreAlpha = clamp(
        abs(inside - occupied(vec2(-oneTexel.x, 0.0)))
        + abs(inside - occupied(vec2(oneTexel.x, 0.0)))
        + abs(inside - occupied(vec2(0.0, -oneTexel.y)))
        + abs(inside - occupied(vec2(0.0, oneTexel.y))),
        0.0,
        1.0
    );

    // The blurred silhouette carries a low, normalized density. Shape it into a
    // bright rim that fades softly outward for a luminous bloom instead of a flat halo.
    float amplifiedHalo = 1.0 - exp(-halo.a * 7.0);
    float haloAlpha = amplifiedHalo * Intensity * (1.0 - inside);
    float alpha = 1.0 - (1.0 - coreAlpha) * (1.0 - haloAlpha);

    // The colour is per entity and travels in the mask, so each group glows its own colour
    // within one frame. Inside the silhouette the mask texel is exact; the outer half of the
    // core edge and the halo sit on empty mask, and take the colour from the blur instead -
    // it divides by its own alpha, so what comes back is the nearest ink's colour, not a
    // faded one. Push it toward a saturated, slightly overdriven tone so it reads as emitted
    // light rather than an overlay.
    vec3 tint = mix(halo.rgb, mask.rgb, inside);
    vec3 haloColor = clamp(saturate(tint, 1.35) * 1.18, 0.0, 1.0);
    vec3 color = mix(haloColor, tint, step(0.001, coreAlpha) * inside);
    gl_FragColor = vec4(color, clamp(alpha, 0.0, 1.0));
}
