#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform float time;
uniform vec2 lightPos;
uniform float fogDensity;
uniform vec3 fogColor;
uniform vec3 lightColor;
uniform float lightIntensity;

out vec4 finalColor;

void main() {
    vec4 sceneColor = texture(texture0, fragTexCoord);
    vec2 uv = fragTexCoord;
    
    float depth = 1.0 - uv.y;
    float fogAmount = 1.0 - exp(-fogDensity * depth * depth);
    
    vec2 toLightDir = lightPos - uv;
    float distToLight = length(toLightDir);
    float lightFalloff = exp(-distToLight * 1.5);
    
    vec3 atmosphereColor = mix(fogColor, lightColor, lightFalloff * lightIntensity);
    
    float scatter = max(0.0, dot(normalize(toLightDir), vec2(0.0, -1.0)));
    scatter = pow(scatter, 2.0) * lightIntensity;
    atmosphereColor += lightColor * scatter * 0.3;
    
    vec3 result = mix(sceneColor.rgb, atmosphereColor, fogAmount * 0.4);
    
    result += lightColor * lightFalloff * lightIntensity * 0.1;
    
    finalColor = vec4(result, sceneColor.a);
}

