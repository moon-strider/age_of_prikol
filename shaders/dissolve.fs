#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform float dissolveAmount;
uniform vec3 edgeColor;
uniform float edgeWidth;

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

void main() {
    vec4 color = texture(texture0, fragTexCoord) * fragColor;
    
    float noiseVal = noise(fragTexCoord * 20.0);
    noiseVal += noise(fragTexCoord * 40.0) * 0.5;
    noiseVal /= 1.5;
    
    float edge = smoothstep(dissolveAmount - edgeWidth, dissolveAmount, noiseVal);
    float alpha = smoothstep(dissolveAmount, dissolveAmount + 0.01, noiseVal);
    
    vec3 finalCol = mix(edgeColor, color.rgb, edge);
    
    finalColor = vec4(finalCol, color.a * alpha);
}

