#version 120

// GLSL 120 port of hand_trail_mask.fsh: turns the hand silhouette into the single-channel mask the
// rest of the smoke chain reads.

uniform sampler2D Sampler0;

varying vec2 texCoord;

void main() {
    float isHand = smoothstep(0.08, 0.6, texture2D(Sampler0, texCoord).a);

    float topDistance = 1.0 - texCoord.y;
    isHand *= smoothstep(0.012, 0.075, topDistance);

    gl_FragColor = vec4(isHand, isHand, isHand, isHand);
}
