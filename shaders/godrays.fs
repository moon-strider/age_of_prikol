#version 330

in vec2 fragTexCoord;
out vec4 finalColor;

uniform sampler2D texture0;
uniform vec2 lightPos;
uniform float exposure;
uniform float decay;
uniform float density;

float noise(vec2 uv) {
    return fract(52.9829189 * fract(dot(uv, vec2(0.06711056, 0.00583715))));
}

void main() {
    const int SAMPLES = 48;
    
    vec2 texCoord = fragTexCoord;
    vec2 delta = (texCoord - lightPos) * density / float(SAMPLES);
    
    texCoord -= delta * noise(gl_FragCoord.xy);
    
    vec3 color = vec3(0.0);
    float illumination = 1.0;
    
    for (int i = 0; i < SAMPLES; i++) {
        vec3 s = texture(texture0, texCoord).rgb;
        color += s * illumination * 0.02;
        illumination *= decay;
        texCoord -= delta;
    }
    
    finalColor = vec4(color * exposure, 1.0);
}
