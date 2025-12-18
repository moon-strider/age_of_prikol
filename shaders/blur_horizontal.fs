#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec2 resolution;

out vec4 finalColor;

const float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

void main() {
    vec2 texOffset = 1.0 / resolution;
    vec3 result = texture(texture0, fragTexCoord).rgb * weights[0];
    
    for (int i = 1; i < 5; i++) {
        result += texture(texture0, fragTexCoord + vec2(texOffset.x * float(i), 0.0)).rgb * weights[i];
        result += texture(texture0, fragTexCoord - vec2(texOffset.x * float(i), 0.0)).rgb * weights[i];
    }
    
    finalColor = vec4(result, 1.0);
}

