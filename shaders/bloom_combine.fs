#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform sampler2D bloomTexture;
uniform float bloomIntensity;

out vec4 finalColor;

void main() {
    vec3 scene = texture(texture0, fragTexCoord).rgb;
    vec3 bloom = texture(bloomTexture, fragTexCoord).rgb;
    
    vec3 result = scene + bloom * bloomIntensity;
    
    result = vec3(1.0) - exp(-result * 1.0);
    
    finalColor = vec4(result, 1.0);
}

