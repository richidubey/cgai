/////////////////////////////////////////////////////
//// CS 8803/4803 CGAI: Computer Graphics in AI Era
//// Assignment 1B: Neural SDF
/////////////////////////////////////////////////////

precision highp float;              //// set default precision of float variables to high precision

varying vec2 vUv;                   //// screen uv coordinates (varying, from vertex shader)
uniform vec2 iResolution;           //// screen resolution (uniform, from CPU)
uniform float iTime;                //// time elapsed (uniform, from CPU)

#define PI 3.1415925359
const float MAX_DIST = 100.0; //We use this to indicate the max distance that our ray will goto


const vec3 CAM_POS = vec3(0, 1, 0);

vec3 rotate(vec3 p, vec3 ax, float ro)
{
    return mix(dot(p, ax) * ax, p, cos(ro)) + sin(ro) * cross(ax, p);
}

/////////////////////////////////////////////////////
//// sdf functions
/////////////////////////////////////////////////////

float sdfPlane(vec3 p, float h)
{
    return p.y - h;
}

float sdfBunny(vec3 p)
{
    p = rotate(p, vec3(1., 0., 0.), PI / 2.);
    p = rotate(p, vec3(0., 0., 1.), PI / 2. + PI / 1.);

    // sdf is undefined outside the unit sphere, uncomment to witness the abominations
    if(length(p) > 1.0)
    {
        return length(p) - 0.9;
    }

    //// neural network weights for the bunny 

    vec4 f0_0=sin(p.y*vec4(1.74,-2.67,1.91,-1.93)+p.z*vec4(2.15,-3.05,.50,-1.32)+p.x*vec4(2.47,.30,-2.00,-2.75)+vec4(1.31,6.89,-8.25,.15));
    vec4 f0_1=sin(p.y*vec4(-.72,-3.13,4.36,-3.50)+p.z*vec4(3.39,3.58,-4.52,-1.10)+p.x*vec4(-1.02,-2.90,2.23,-.62)+vec4(1.61,-.84,-2.00,-.47));
    vec4 f0_2=sin(p.y*vec4(-1.47,.32,-.70,-1.51)+p.z*vec4(.17,.75,3.59,4.05)+p.x*vec4(-3.10,1.40,4.72,2.90)+vec4(-6.76,-6.43,2.41,-.66));
    vec4 f0_3=sin(p.y*vec4(-2.75,1.59,3.43,-3.39)+p.z*vec4(4.09,4.09,-2.34,1.23)+p.x*vec4(1.07,.65,-.18,-3.46)+vec4(-5.09,.73,3.06,3.35));
    vec4 f1_0=sin(mat4(.47,.12,-.23,-.04,.48,.06,-.24,.19,.12,.72,-.08,.39,.37,-.14,-.01,.06)*f0_0+
        mat4(-.62,-.40,-.81,-.30,-.34,.08,.26,.37,-.16,.38,-.09,.36,.02,-.50,.34,-.38)*f0_1+
        mat4(-.26,-.51,-.32,.32,-.67,.35,-.43,.93,.12,.34,.07,-.01,.67,.27,.43,-.02)*f0_2+
        mat4(.02,-.18,-.15,-.10,.47,-.07,.82,-.46,.18,.44,.39,-.94,-.20,-.28,-.20,.29)*f0_3+
        vec4(-.09,-3.49,2.17,-1.45))/1.0+f0_0;
    vec4 f1_1=sin(mat4(-.46,-.33,-.85,-.57,.41,.87,.25,.58,-.47,.16,-.14,-.06,-.70,-.82,-.20,.47)*f0_0+
        mat4(-.15,-.73,-.46,-.58,-.54,-.34,-.02,.12,.55,.32,.22,-.87,-.57,-.28,-.51,.10)*f0_1+
        mat4(.75,1.06,-.08,-.17,-.43,.69,1.07,.23,.46,-.02,.10,-.11,.21,-.70,-.08,-.48)*f0_2+
        mat4(.04,-.09,-.51,-.06,1.12,-.21,-.35,-.17,-.95,.49,.22,.99,.62,-.25,.06,-.20)*f0_3+
        vec4(-.61,2.91,-.17,.71))/1.0+f0_1;
    vec4 f1_2=sin(mat4(.01,-.86,-.07,.46,.73,-.28,.83,.12,.16,.33,.28,-.55,-.21,-.02,.53,-.15)*f0_0+
        mat4(-.28,-.32,.19,-.28,.24,-.23,-.61,-.39,.26,.40,.18,.41,.21,.57,-.91,-.29)*f0_1+
        mat4(.23,-.40,-1.34,-.50,.08,-.04,-1.67,-.16,-.65,-.09,.38,-.22,-.14,-.34,.37,.05)*f0_2+
        mat4(-.47,-.23,-.57,-.05,.51,.04,.00,.27,.80,.29,-.09,-.53,-.20,-.41,-.64,-.12)*f0_3+
        vec4(1.08,4.00,-2.54,2.18))/1.0+f0_2;
    vec4 f1_3=sin(mat4(-.30,.38,.39,.53,.73,.73,-.06,.01,.54,-.07,-.19,.68,.59,.40,.04,.07)*f0_0+
        mat4(-.17,.44,-.61,.43,-.84,-.12,.65,-.50,.33,-.31,-.28,.13,.18,-.42,.14,.08)*f0_1+
        mat4(-.78,.06,-.18,.37,-.99,.49,.71,.15,.27,-.48,-.17,.25,.05,.10,-.40,-.21)*f0_2+
        mat4(-.17,-.27,.40,.18,-.24,.23,.03,-.83,-.30,-.38,.07,.21,-.45,-.24,.78,.50)*f0_3+
        vec4(2.14,-3.48,3.81,-1.43))/1.0+f0_3;
    vec4 f2_0=sin(mat4(.83,.15,-.49,-.80,-.83,.16,1.24,.75,-.27,.18,-.13,1.05,.70,-.15,.30,.79)*f1_0+
        mat4(-.38,-.17,.34,.67,-.39,.09,.48,-.93,.19,.60,-.20,-.22,-.76,-.62,-.40,.01)*f1_1+
        mat4(.10,.22,.08,.13,-.42,-.11,.71,-.63,.02,.46,-.07,-.46,-.37,.07,.15,.14)*f1_2+
        mat4(.09,-.48,-.38,.40,-.57,-.88,-.14,-.25,.20,.95,.86,-1.08,.46,.04,.53,-.82)*f1_3+
        vec4(3.47,-3.66,3.06,.84))/1.4+f1_0;
    vec4 f2_1=sin(mat4(1.03,.03,-.76,-.03,.84,.66,-.49,.74,-.09,-.85,-.55,.17,.07,.85,-.55,-.20)*f1_0+
        mat4(-.55,1.13,.41,-.21,-.55,.19,.49,.67,.40,1.80,-.82,-.83,-1.02,.78,-.42,-.51)*f1_1+
        mat4(.77,-.88,.64,1.10,-.49,1.05,-.43,-.38,.66,-.63,.02,.11,-.24,-.23,.49,-.65)*f1_2+
        mat4(-.66,1.90,.02,-.48,.22,-.62,-.68,-.44,.52,-.57,.16,-.61,-.03,-.02,-.88,-.23)*f1_3+
        vec4(.58,-3.00,-2.53,.14))/1.4+f1_1;
    vec4 f2_2=sin(mat4(-.44,-.06,.30,-.37,.27,-.23,-.56,.15,.03,-.14,-.08,.72,.76,-.58,.55,.29)*f1_0+
        mat4(.31,.23,.42,-.17,.37,-.05,.39,.46,-1.14,.32,.06,-.28,.28,-.21,-.58,.62)*f1_1+
        mat4(.92,-.16,.86,-.09,-.12,.33,-.49,-.24,.29,-.19,.95,-.40,-.87,.08,.08,-.71)*f1_2+
        mat4(-.45,.67,1.07,-.14,-.56,.06,-.81,-.15,-.57,-.24,-1.09,.69,-.44,-.32,-.00,-.07)*f1_3+
        vec4(-4.43,-1.86,-2.87,1.45))/1.4+f1_2;
    vec4 f2_3=sin(mat4(.58,.25,.01,-.54,.34,.56,.61,-.79,-.01,.05,-.57,-1.31,.74,.78,-.10,-.11)*f1_0+
        mat4(-.03,-.48,-.24,.01,.10,.23,.22,-.05,.76,.29,-.37,.02,.54,-.07,.27,.38)*f1_1+
        mat4(.31,-1.03,.24,.95,.80,.29,.43,.61,-.04,-.22,-.06,-.52,-.46,.35,.07,-.07)*f1_2+
        mat4(.47,-.12,-.62,.06,.47,-.41,.53,-2.14,-.59,.16,.74,-.58,.32,.66,-.30,-.18)*f1_3+
        vec4(-2.86,-3.27,-.55,2.87))/1.4+f1_3;
    return dot(f2_0,vec4(-.08,.03,.07,-.03))+
        dot(f2_1,vec4(-.03,-.02,-.06,-.07))+
        dot(f2_2,vec4(.05,-.09,.03,.11))+
        dot(f2_3,vec4(.03,.06,-.06,-.03))+
        -0.014;
}

/////////////////////////////////////////////////////
//// Step 1: training a neural SDF model
//// You are asked to train your own neural SDF model on Colab. 
//// Your implementation should take place in neural_sdf.ipynb.
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 2: copy neural SDF weights to GLSL
//// In this step, you are asked to the network weights you have trained from the text file to the function sdfCow().
//// You should replace the default implementation (a sphere) with your own network weights. 
/////////////////////////////////////////////////////

float sdfCow(vec3 p)
{
    p = rotate(p, vec3(1., 0., 0.), PI / 2.);
    p = rotate(p, vec3(0., 0., 1.), PI / 3. + PI/3.0);

    // sdf is undefined outside the unit sphere, uncomment to witness the abominations
    if(length(p) > 1.)
    {
        return length(p) - 0.9;
    }

    //// your implementation starts
    vec4 f0_0=sin(p.y*vec4(3.09,-1.93,-.59,.40)+p.z*vec4(-2.53,-3.29,-.91,2.36)+p.x*vec4(-2.02,-.79,-.02,-3.71)+vec4(.16,-.74,5.03,-1.71));
    vec4 f0_1=sin(p.y*vec4(-2.27,-2.76,-3.76,2.41)+p.z*vec4(-.88,.83,-4.39,-1.39)+p.x*vec4(-3.53,5.07,-3.23,.57)+vec4(-7.00,-.48,-1.35,-6.56));
    vec4 f0_2=sin(p.y*vec4(2.76,.40,-.08,2.60)+p.z*vec4(-.21,4.61,2.54,-.12)+p.x*vec4(.74,-3.67,2.18,2.83)+vec4(-7.57,7.26,8.54,7.10));
    vec4 f0_3=sin(p.y*vec4(-2.51,-2.72,-.22,.13)+p.z*vec4(2.30,-2.35,-.81,3.30)+p.x*vec4(1.99,-.08,3.93,-.02)+vec4(-7.37,-5.28,-2.61,1.75));
    vec4 f1_0=sin(mat4(.02,.24,.37,-.26,-.26,.22,-.09,-.17,-.18,.31,.29,-.18,.00,-.38,-.73,-.12)*f0_0+
        mat4(-.03,-.41,.30,.12,.22,.06,.06,-.33,.30,.12,-.17,-.49,.35,-.86,.37,.92)*f0_1+
        mat4(.23,.55,-.62,-.55,-.34,-.50,-.06,.22,-.00,-.54,.78,.51,-.30,.36,.54,-.17)*f0_2+
        mat4(.73,-.47,.14,.00,.90,.06,.12,.49,-.15,-.93,.55,-.11,-.71,-.57,.24,.39)*f0_3+
        vec4(.34,-.97,-1.28,1.04))/1.0+f0_0;
    vec4 f1_1=sin(mat4(.02,.61,-.69,-.29,.21,.37,-.46,.68,-.08,.55,.07,.57,.22,-.64,-.55,-.26)*f0_0+
        mat4(.68,.17,.52,.17,.09,.85,.33,.09,.27,.10,-.47,.40,-.99,-.06,-.72,-.11)*f0_1+
        mat4(-.70,.17,-.04,-.34,.39,-.28,-.13,-.10,-.95,.09,.15,.10,.38,.41,-.19,.95)*f0_2+
        mat4(.09,-.93,-.05,-.90,.16,.13,.18,-.32,-.59,-.22,.77,-.34,-.03,1.28,.21,.55)*f0_3+
        vec4(-1.08,.74,.41,-.35))/1.0+f0_1;
    vec4 f1_2=sin(mat4(-.21,.37,-.19,-.69,.28,.66,-.02,-.56,.16,.37,-.01,.10,-.02,.20,.38,-.62)*f0_0+
        mat4(-.29,-.76,-.06,-.15,-.10,-.21,-.22,-.18,-.11,.06,-.19,.40,.22,.33,-.14,-.18)*f0_1+
        mat4(-.44,.30,.57,-.21,-.35,-.10,.45,.33,.07,-.09,.33,.28,-.14,.14,-.63,.09)*f0_2+
        mat4(-.57,.95,-.07,.47,-.06,.20,-.11,.03,.33,.22,.91,.57,-.10,.09,-.26,.23)*f0_3+
        vec4(1.97,.68,-.30,2.32))/1.0+f0_2;
    vec4 f1_3=sin(mat4(-.62,-.11,-.25,-.54,-.17,-.06,.83,-.30,.36,.43,-.37,-.02,-.53,-.05,-.34,-.14)*f0_0+
        mat4(.06,.09,-.31,-.10,-.15,-.06,-.52,-.32,.20,.03,.65,-.29,-.54,.67,.21,-.03)*f0_1+
        mat4(.49,.14,-.21,-.54,-.15,-.19,.15,.62,-.75,.31,.41,1.06,.24,.54,-.36,-.82)*f0_2+
        mat4(.30,-.17,.41,-.17,.40,.54,-.04,1.16,-.01,-.51,-.52,.06,.46,.40,-.34,-.46)*f0_3+
        vec4(1.24,-.64,-2.07,2.09))/1.0+f0_3;
    vec4 f2_0=sin(mat4(.17,-.15,.11,.18,.38,.34,-.23,.26,.68,.56,.36,-.25,-.17,.10,.21,-.28)*f1_0+
        mat4(.09,-.13,.22,-.42,.34,-.12,-.20,.28,.09,.19,-.41,-.05,-.35,-.61,.65,.22)*f1_1+
        mat4(.60,.72,-.95,-1.73,.05,-.90,.20,.16,.51,.54,.11,.32,-.15,-.49,-.23,.73)*f1_2+
        mat4(.08,-.60,-.81,-.47,.46,.25,.53,-.74,.70,-.52,.03,-.10,-.20,.52,.22,.28)*f1_3+
        vec4(2.97,-1.51,.80,3.40))/1.4+f1_0;
    vec4 f2_1=sin(mat4(-.57,-.75,.26,-.84,-.61,-.55,.41,-.43,-.07,-.94,.34,1.02,.10,-1.20,1.56,.04)*f1_0+
        mat4(-.69,.09,-.31,-.11,-.21,.21,.64,.07,.54,.09,1.49,.78,-.13,.06,-.24,-.34)*f1_1+
        mat4(.53,-.07,.17,-.26,-.40,.11,.69,.19,.34,-.19,.27,-.01,.61,.14,-.20,.51)*f1_2+
        mat4(.28,-.29,.17,-.92,.25,-.51,.35,1.05,-.31,.72,-1.17,-.55,.05,-.03,-1.54,.14)*f1_3+
        vec4(-3.50,3.05,2.47,3.23))/1.4+f1_1;
    vec4 f2_2=sin(mat4(-.42,-.44,.32,-.03,-.34,-.18,-.06,-.04,-.57,.08,-.60,-.18,.63,.31,.33,.77)*f1_0+
        mat4(.45,-.21,-.14,.24,.29,-.06,-.98,-.15,-.55,.49,.22,.16,.07,.30,.59,-.81)*f1_1+
        mat4(-.66,-.36,.22,-.63,-.24,.07,-.21,-.32,.11,-.67,.11,-.23,.03,.79,-.29,.83)*f1_2+
        mat4(-.21,-.76,-.91,.51,.08,.21,-.04,-.23,-.37,-.34,-1.12,.37,.19,.98,1.23,.24)*f1_3+
        vec4(2.12,-1.74,-3.61,1.92))/1.4+f1_2;
    vec4 f2_3=sin(mat4(-.11,.31,.81,-.13,-.20,.16,-.29,-.77,.25,.54,-.65,.58,-.09,.00,-.40,-.27)*f1_0+
        mat4(-.02,.68,.15,-.16,-.17,-.52,-.01,.39,-.50,-.08,-.19,-.42,.45,.05,.11,-.02)*f1_1+
        mat4(-.51,-.54,.99,.22,-.78,-.49,.97,.32,-.14,.21,-.02,-.19,-.28,-.22,-.16,.38)*f1_2+
        mat4(-.89,.19,-.75,.43,1.61,.40,.14,.04,.02,-.01,.53,-.11,-.03,.84,.16,.58)*f1_3+
        vec4(-1.05,.83,-4.03,.49))/1.4+f1_3;
    return dot(f2_0,vec4(.04,.04,-.04,.03))+
        dot(f2_1,vec4(.05,-.03,-.01,-.06))+
        dot(f2_2,vec4(.11,.02,.02,.04))+
        dot(f2_3,vec4(.02,-.09,-.04,.04))+
        0.060;
    //// your implementation ends
}

float sdfUnion(float d1, float d2)
{
    return min(d1, d2);
}

/////////////////////////////////////////////////////
//// Step 3: scene sdf
//// You are asked to use the sdf boolean operations to draw the bunny and the cow in the scene.
//// The bunny is located in the ceter of vec3(-1.0, 1., 4.), and the cow is located in the center of vec3(1.0, 1., 4.).
/////////////////////////////////////////////////////

//// sdf: p - query point
float sdf(vec3 p)
{
    float s = 0.;

    float plane_h = -0.1;

    //// calculate the sdf based on all objects in the scene

    //// your implementation starts
    // return sdfBunny(p - vec3(-1.0, 1., 4.));
    s = sdfUnion(sdfPlane(p, plane_h), sdfBunny(p - vec3(-1.0, 1., 4.)));
    s = sdfUnion(s, sdfCow(p - vec3(1.0, 1., 4.))); 
    //// your implementation ends

    return s;
}

/////////////////////////////////////////////////////
//// ray marching
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 4: ray marching
//// You are asked to implement the ray marching algorithm within the following for-loop.
//// You are allowed to reuse your previous implementation in A1a for this function.
/////////////////////////////////////////////////////

//// ray marching: origin - ray origin; dir - ray direction 
float rayMarching(vec3 origin, vec3 dir)
{
    float s = 0.0;
    vec3 p;
    float v;

    for(int i = 0; i < 100; i++)
    {
        
        p = origin + s*dir;
        v = sdf(p);
        s += v*0.9; //Advance the ray, prevent overstepping
        if(v < .0001)
            break;
        
        if(s>MAX_DIST)
            break;
    }
    
    return s;
}

/////////////////////////////////////////////////////
//// normal calculation
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 5: normal calculation
//// You are asked to calculate the sdf normal based on finite difference.
//// You are allowed to reuse your previous implementation in A1a for this function.
/////////////////////////////////////////////////////

//// normal: p - query point
vec3 normal(vec3 p)
{
    float s = sdf(p);          //// sdf value in p
    float dx = 0.01;           //// step size for finite difference

    //// your implementation starts

    float sx = sdf(p + vec3(dx, 0.0, 0.0)) - sdf(p - vec3(dx,0.0, 0.0));
    float sy = sdf(p + vec3(0.0, dx, 0.0)) - sdf(p - vec3(0.0, dx, 0.0));
    float sz = sdf(p + vec3(0.0, 0.0, dx)) - sdf(p - vec3(0.0, 0.0, dx));
    return normalize(vec3(sx,sy,sz)/(2.0*dx));

    //// your implementation ends
}

/////////////////////////////////////////////////////
//// Phong shading
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 6: lighting and coloring
//// You are asked to specify the color for the two neural SDF objects in the scene.
//// Each object must have a separate color without mixing.
//// Notice that we have implemented the default Phong shading model for you.
/////////////////////////////////////////////////////

vec3 phong_shading(vec3 p, vec3 n)
{
    //// background
    if(p.z > 20.0)
    {
        vec3 color = vec3(0.04, 0.16, 0.33);
        // vec3 color = vec3(1, 1, 1);
        return color;
    }

    //// phong shading
    vec3 lightPos = vec3(4. * sin(iTime), 4., 4. * cos(iTime));
    vec3 l = normalize(lightPos - p);
    float amb = 0.1;
    float dif = max(dot(n, l), 0.) * 0.7;
    vec3 eye = CAM_POS;
    float spec = pow(max(dot(reflect(-l, n), normalize(eye - p)), 0.0), 128.0) * 0.9;

    vec3 sunDir = normalize(vec3(0, 1, -1)); //// parallel light direction
    float sunDif = max(dot(n, sunDir), 0.) * 0.2;

    //// shadow
    float s = rayMarching(p + n * 0.02, l);
    if(s < length(lightPos - p))
        dif *= .2;

    vec3 color = vec3(1.0);

    //// your implementation start

    if(p.y < 0.01)
    color = vec3(0.9961, 0.9961, 0.0);
    else if(p.x < 0.0)
    color = vec3(1, 0, 0);
    else 
    color = vec3(0,1,0);
    //// your implementation ends

    return (amb + dif + spec + sunDif) * color;
}

/////////////////////////////////////////////////////
//// main function
/////////////////////////////////////////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy - .5 * iResolution.xy) / iResolution.y;         //// screen uv
    vec3 origin = CAM_POS;                                                  //// camera position 
    vec3 dir = normalize(vec3(uv.x, uv.y, 1));                              //// camera direction
    float s = rayMarching(origin, dir);                                     //// ray marching
    vec3 p = origin + dir * s;                                              //// ray-sdf intersection
    vec3 n = normal(p);                                                     //// sdf normal
    vec3 color = phong_shading(p, n);                                       //// phong shading
    fragColor = vec4(color, 1.);                                            //// fragment color
}

void main()
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}