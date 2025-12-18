#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform float time;
uniform vec2 resolution;
uniform vec2 lightPos;
uniform float lightIntensity;

out vec4 finalColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

void main() {
    vec2 uv = fragTexCoord;
    vec2 worldUV = uv * vec2(resolution.x / resolution.y, 1.0);
    
    float cloudNoise = fbm(worldUV * 3.0 + vec2(time * 0.02, 0.0));
    cloudNoise += fbm(worldUV * 6.0 + vec2(time * 0.03, time * 0.01)) * 0.5;
    
    float cloudMask = smoothstep(0.3, 0.7, cloudNoise);
    
    vec2 toLightDir = normalize(lightPos - uv);
    float distToLight = length(lightPos - uv);
    float lightFalloff = 1.0 / (1.0 + distToLight * 2.0);
    
    vec3 cloudColor = vec3(0.9, 0.92, 0.95);
    vec3 shadowColor = vec3(0.5, 0.55, 0.65);
    vec3 litColor = vec3(1.0, 0.95, 0.85);
    
    float lightAmount = smoothstep(0.0, 1.0, dot(vec2(0.0, -1.0), toLightDir) * 0.5 + 0.5);
    lightAmount *= lightFalloff * lightIntensity;
    
    vec3 color = mix(shadowColor, cloudColor, lightAmount);
    color = mix(color, litColor, lightAmount * 0.5);
    
    float alpha = cloudMask * 0.6;
    
    finalColor = vec4(color, alpha);
}

