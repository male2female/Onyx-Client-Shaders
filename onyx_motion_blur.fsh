#version 120

// Blends the frame that was just drawn with the one before it. uAmount is how much of the old
// frame survives, so it is also the decay rate of the trail: 0.5 halves every frame, 0.9 keeps a
// long smear.

varying vec2 texCoord;

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;
uniform float uAmount;

void main() {
    vec4 current = texture2D(Sampler0, texCoord);
    vec4 history = texture2D(Sampler1, texCoord);

    gl_FragColor = vec4(mix(current.rgb, history.rgb, clamp(uAmount, 0.0, 0.95)), current.a);
}
