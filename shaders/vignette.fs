#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform float intensity;
uniform float smoothness;

out vec4 finalColor;

void main() {
    vec4 color = texture(texture0, fragTexCoord);
    
    vec2 uv = fragTexCoord;
    uv *= 1.0 - uv.yx;
    float vignette = uv.x * uv.y * 15.0;
    vignette = pow(vignette, intensity * smoothness);
    
    color.rgb *= vignette;
    
    finalColor = color;
}

