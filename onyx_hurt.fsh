#version 120

// Damage wash. Draws a soft ring of colour in from the edge of the screen over the scene copy,
// leaving the middle untouched so it reads as feedback rather than as a filter over the game.

varying vec2 texCoord;

uniform sampler2D Sampler0;
uniform vec2 uResolution;
uniform vec3 uTint;
uniform float uStrength;
uniform float uReach;
// Yaw of the incoming hit, in degrees, and whether it should be used at all. A yaw is a
// perfectly ordinary negative number, so the flag has to be its own uniform rather than a
// sentinel value hidden in the angle.
uniform float uBias;
uniform float uDirectional;

void main() {
    vec4 scene = texture2D(Sampler0, texCoord);

    if (uStrength <= 0.0) {
        gl_FragColor = scene;
        return;
    }

    // Work in a square space so the vignette stays circular on a wide screen instead of
    // stretching into an ellipse that hugs the left and right edges only.
    vec2 centered = texCoord * 2.0 - 1.0;
    centered.x *= uResolution.x / max(uResolution.y, 1.0);

    float aspect = uResolution.x / max(uResolution.y, 1.0);
    float radius = length(centered) / length(vec2(aspect, 1.0));

    // uReach is how far in the wash comes: at 0 it clings to the very corner, at 1 it reaches
    // the middle. smoothstep gives the soft falloff, and the square makes the edge gentler still.
    float inner = mix(1.0, 0.0, clamp(uReach, 0.0, 1.0));
    float vignette = smoothstep(inner, 1.0, radius);
    vignette *= vignette;

    if (uDirectional > 0.5) {
        // attackedAtYaw is measured clockwise from straight ahead, so 0 is in front of you and
        // that has to land at the bottom of the screen, which is where the hit reads from.
        float angle = radians(uBias);
        vec2 direction = vec2(-sin(angle), cos(angle));
        float alignment = dot(normalize(centered + vec2(1e-5)), direction) * 0.5 + 0.5;

        vignette *= mix(0.35, 1.0, alignment);
    }

    float amount = clamp(vignette * uStrength, 0.0, 1.0);

    // Screen-blend the tint in rather than mixing towards it, so the wash lightens the edge
    // without flattening whatever detail was already there.
    vec3 washed = scene.rgb + uTint * amount * (1.0 - scene.rgb);

    gl_FragColor = vec4(mix(scene.rgb, washed, 1.0), scene.a);
}
