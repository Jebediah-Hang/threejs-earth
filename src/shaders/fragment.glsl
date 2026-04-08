// // reference from https://youtu.be/vM8M4QloVL0?si=CKD5ELVrRm3GjDnN
// varying vec3 vNormal;
// varying vec3 eyeVector;
// varying vec3 vWorldPosition;

// uniform float atmOpacity;
// uniform float atmPowFactor;
// uniform float atmMultiplier;
// uniform float atmNightFade;
// uniform vec3 sunDirection;

// void main() {
//     // Starting from the atmosphere edge, dotP would increase from 0 to 1
//     float dotP = dot( vNormal, eyeVector );
//     // This factor is to create the effect of a realistic thickening of the atmosphere coloring
//     float factor = pow(dotP, atmPowFactor) * atmMultiplier * 50.0;
//     // Adding in a bit of dotP to the color to make it whiter while thickening
//     vec3 atmColor = vec3(0.35 + dotP/4.5, 0.35 + dotP/4.5, 1.0);

//     vec3 toVertex = normalize(vWorldPosition);
//     float sunIntensity = max(dot(toVertex, sunDirection), 0.0);
//     float nightFactor = mix(atmNightFade, 1.0, sunIntensity);

//     // use atmOpacity to control the overall intensity of the atmospheric color
//     // gl_FragColor = vec4(atmColor, atmOpacity) * factor;
//     gl_FragColor = vec4(atmColor, atmOpacity) * factor * nightFactor;

//     // (optional) colorSpace conversion for output
//     // gl_FragColor = linearToOutputTexel( gl_FragColor );
// }

precision highp float;

uniform vec3 sunDirection;
uniform float planetRadius;
uniform float atmosphereRadius;
uniform float atmOpacity;
uniform float atmPowFactor;
uniform float atmMultiplier;
uniform float atmNightFade;
uniform float blendFactor;

varying vec3 vNormal;
varying vec3 eyeVector;
varying vec3 vWorldPosition;

const int STEPS = 16;
const float ATM_HEIGHT_FALLBACK = 4.0;
const float MIE_POWER = 8.0;
const float SCATTER_STRENGTH = 1.5;
const vec3 RAYLEIGH_COLOR = vec3(0.3, 0.6, 1.0);
const vec3 MIE_COLOR = vec3(1.0, 0.5, 0.2);

vec2 raySphere(vec3 ro, vec3 rd, float r2) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - r2;
    float h = b*b - c;
    if (h < 0.0) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b - h, -b + h);
}

vec3 volumeScattering(vec3 ro, vec3 rd, vec3 lightDir) {
    float atmRadiusSq = atmosphereRadius * atmosphereRadius;
    float planetRadiusSq = planetRadius * planetRadius;

    vec2 hit = raySphere(ro, rd, atmRadiusSq);
    if (hit.x < 0.0) return vec3(0.0);

    float t0 = max(hit.x, 0.0);
    float t1 = hit.y;
    float stepSize = (t1 - t0) / float(STEPS);

    vec3 sum = vec3(0.0);

    for (int i = 0; i < STEPS; i++) {
        float t = t0 + stepSize * (float(i) + 0.5);
        vec3 pos = ro + rd * t;
        float height = length(pos) - planetRadius;

        float density = exp2(-height * 5.77078);

        vec2 lightHit = raySphere(pos, lightDir, planetRadiusSq);
        float inShadow = lightHit.x > 0.0 ? 0.0 : 1.0;

        vec3 rayleigh = RAYLEIGH_COLOR * density;

        float mu = dot(rd, lightDir);
        float mie = pow(max(mu, 0.0), MIE_POWER);
        vec3 mieColor = MIE_COLOR * mie * density;

        vec3 scatter = (rayleigh + mieColor) * inShadow;
        sum += scatter * stepSize;
    }

    return 1.0 - exp(-sum * SCATTER_STRENGTH);
}

vec3 viewBasedGlow(vec3 normal, vec3 eyeVec, vec3 worldPos, vec3 sunDir) {
    float dotP = dot(normal, eyeVec);
    float factor = pow(dotP, atmPowFactor) * atmMultiplier;
    vec3 atmColor = vec3(0.35 + dotP/4.5, 0.35 + dotP/4.5, 1.0);

    vec3 toVertex = normalize(worldPos);
    float sunIntensity = max(dot(toVertex, sunDir), 0.0);
    float nightFactor = mix(atmNightFade, 1.0, sunIntensity);

    return atmColor * factor * nightFactor;
}

void main() {
    vec3 ro = cameraPosition;
    vec3 rd = normalize(vWorldPosition - ro);

    vec3 volScatter = volumeScattering(ro, rd, sunDirection);

    vec3 viewGlow = viewBasedGlow(vNormal, eyeVector, vWorldPosition, sunDirection);

    vec3 finalColor = mix(volScatter, viewGlow, blendFactor);
    float finalAlpha = mix(1.0, atmOpacity, blendFactor);

    gl_FragColor = vec4(finalColor, finalAlpha);
}