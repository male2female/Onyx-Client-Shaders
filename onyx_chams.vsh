#version 120

// GLSL 120 port of the Fabric chams vertex stage. 1.8.9 feeds entity models through the fixed
// function pipeline, so position, normal and texture coordinates come off the built-in attributes
// rather than named ins, and the lightmap rides on texture unit 1 like vanilla puts it there.

varying vec2 texCoord0;
varying vec2 lightCoord;
varying vec3 cameraRelative;
varying vec3 surfaceNormal;

void main() {
    vec4 viewPosition = gl_ModelViewMatrix * gl_Vertex;

    gl_Position = gl_ProjectionMatrix * viewPosition;

    texCoord0 = gl_MultiTexCoord0.xy;
    lightCoord = gl_MultiTexCoord1.xy;
    cameraRelative = viewPosition.xyz;
    surfaceNormal = gl_NormalMatrix * gl_Normal;

    gl_FogFragCoord = length(viewPosition.xyz);
}
