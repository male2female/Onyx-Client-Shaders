#version 120

uniform sampler2D Sampler0;

uniform vec4 uLightColorAndStrength;
uniform vec4 uGradeParams;
uniform float uTime;

varying vec2 texCoord;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec3 grade(vec2 uv, vec3 color) {
    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(luminance), color, uGradeParams.x);
    color = (color - 0.5) * uGradeParams.y + 0.5;

    vec2 centered = uv * 2.0 - 1.0;
    float vignette = smoothstep(0.25, 1.35, dot(centered, centered));
    color *= 1.0 - vignette * uGradeParams.z;

    float grain = hash21(gl_FragCoord.xy + floor(uTime * 60.0)) - 0.5;
    color += grain * uGradeParams.w;
    return color;
}

void main() {
    vec3 color = texture2D(Sampler0, texCoord).rgb;
    color *= mix(vec3(1.0), uLightColorAndStrength.rgb * 1.12, uLightColorAndStrength.a);
    color = grade(texCoord, color);

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
