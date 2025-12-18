#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform float amount;
uniform vec2 center;

out vec4 finalColor;

void main() {
    vec2 uv = fragTexCoord;
    vec2 dir = uv - center;
    float dist = length(dir);
    
    vec2 offset = dir * dist * amount;
    
    float r = texture(texture0, uv + offset).r;
    float g = texture(texture0, uv).g;
    float b = texture(texture0, uv - offset).b;
    
    finalColor = vec4(r, g, b, 1.0);
}

