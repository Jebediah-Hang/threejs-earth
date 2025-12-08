// reference from https://youtu.be/vM8M4QloVL0?si=CKD5ELVrRm3GjDnN
varying vec3 vNormal;
varying vec3 eyeVector;
varying vec3 vWorldPosition;

uniform float atmOpacity;
uniform float atmPowFactor;
uniform float atmMultiplier;
uniform float atmNightFade;
uniform vec3 sunDirection;

void main() {
    // Starting from the atmosphere edge, dotP would increase from 0 to 1
    float dotP = dot( vNormal, eyeVector );
    // This factor is to create the effect of a realistic thickening of the atmosphere coloring
    float factor = pow(dotP, atmPowFactor) * atmMultiplier;
    // Adding in a bit of dotP to the color to make it whiter while thickening
    vec3 atmColor = vec3(0.35 + dotP/4.5, 0.35 + dotP/4.5, 1.0);

    vec3 toVertex = normalize(vWorldPosition);
    float sunIntensity = max(dot(toVertex, sunDirection), 0.0);
    float nightFactor = mix(atmNightFade, 1.0, sunIntensity);

    // use atmOpacity to control the overall intensity of the atmospheric color
    // gl_FragColor = vec4(atmColor, atmOpacity) * factor;
    gl_FragColor = vec4(atmColor, atmOpacity) * factor * nightFactor;

    // (optional) colorSpace conversion for output
    // gl_FragColor = linearToOutputTexel( gl_FragColor );
}