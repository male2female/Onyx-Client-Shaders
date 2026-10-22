#version 120

uniform sampler2D DiffuseSampler;

uniform vec2 InSize;

uniform vec4 BaseColor;
uniform vec4 EffectData;

varying vec2 texCoord;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    local = local * local * (3.0 - 2.0 * local);

    return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), local.x),
               mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), local.x), local.y);
}

void main() {
    vec4 mask = texture2D(DiffuseSampler, texCoord);
    if (mask.a <= 0.001) {
        gl_FragColor = vec4(0.0);
        return;
    }

    float time = EffectData.x;
    vec2 aspectUv = vec2(texCoord.x * InSize.x / max(InSize.y, 1.0), texCoord.y);
    vec2 flowUv = aspectUv * 8.0 + vec2(time * 0.32, -time * 0.21);

    float flow = noise(flowUv) * 0.65 + noise(flowUv * 2.1 + 7.3) * 0.35;
    float wave = 0.5 + 0.5 * sin((aspectUv.y * 14.0 + aspectUv.x * 5.0 + flow * 3.0) - time * 2.2);
    float metal = smoothstep(0.18, 0.82, flow * 0.72 + wave * 0.45);
    float highlight = pow(smoothstep(0.62, 0.96, metal), 2.0);

    // The colour is per entity and rides in the mask, so two entities in different groups get
    // their own metal within one frame. BaseColor keeps only its alpha, the intensity.
    vec3 tint = mask.rgb;

    vec3 shadow = tint * 0.16;
    vec3 body = mix(tint * 0.42, tint * 1.18, metal);
    vec3 color = mix(shadow, body, 0.45 + flow * 0.55);
    color = mix(color, vec3(1.0), highlight * 0.78);

    vec2 texel = 1.0 / InSize;
    float edge = clamp(mask.a - min(min(texture2D(DiffuseSampler, texCoord + vec2(texel.x, 0.0)).a,
                                       texture2D(DiffuseSampler, texCoord - vec2(texel.x, 0.0)).a),
                                   min(texture2D(DiffuseSampler, texCoord + vec2(0.0, texel.y)).a,
                                       texture2D(DiffuseSampler, texCoord - vec2(0.0, texel.y)).a)), 0.0, 1.0);
    color += mix(tint, vec3(1.0), 0.65) * edge * 0.55;

    gl_FragColor = vec4(color, mask.a * BaseColor.a);
}
