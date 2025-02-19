/////////////////////////////////////////////////////
//// CS 8803/4803 CGAI: Computer Graphics in AI Era
//// Assignment 1A: SDF and Ray Marching
/////////////////////////////////////////////////////

precision highp float;              //// set default precision of float variables to high precision

varying vec2 vUv;                   //// screen uv coordinates (varying, from vertex shader)
uniform vec2 iResolution;           //// screen resolution (uniform, from CPU)
uniform float iTime;                //// time elapsed (uniform, from CPU)

const vec3 CAM_POS = vec3(-0.35, 1.0, -3.0);

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 color = vec3(0.1686, 0.7922, 0.502);

    fragColor = vec4(color, 1.);                                            //// fragment color
}


void main() 
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
