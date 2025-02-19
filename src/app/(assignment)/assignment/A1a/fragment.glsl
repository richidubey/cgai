/////////////////////////////////////////////////////
//// CS 8803/4803 CGAI: Computer Graphics in AI Era
//// Assignment 1A: SDF and Ray Marching
/////////////////////////////////////////////////////

precision highp float;              //// set default precision of float variables to high precision

varying vec2 vUv;                   //// screen uv coordinates (varying, from vertex shader)
uniform vec2 iResolution;           //// screen resolution (uniform, from CPU)
uniform float iTime;                //// time elapsed (uniform, from CPU)

const vec3 CAM_POS = vec3(-0.35, 1.0, -3.0);
const float MAX_DIST = 100.0; //We use this to indicate the max distance that our ray will goto

/////////////////////////////////////////////////////
//// sdf functions
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 1: sdf primitives
//// You are asked to implement sdf primitive functions for sphere, plane, and box.
//// In each function, you will calculate the sdf value based on the function arguments.
/////////////////////////////////////////////////////

//// sphere: p - query point; c - sphere center; r - sphere radius
float sdfSphere(vec3 p, vec3 c, float r)
{
    //// your implementation starts
    
    return length(p-c) - r;
    
    //// your implementation ends
}

//// plane: p - query point; h - height
float sdfPlane(vec3 p, float h)
{
    //// your implementation starts
    
    return length(p.y-h);
    
    //// your implementation ends
}

//// box: p - query point; c - box center; b - box half size (i.e., the box size is (2*b.x, 2*b.y, 2*b.z))
float sdfBox(vec3 p, vec3 c, vec3 b)
{
    //// your implementation starts
    
    vec3 d = abs(p - c) - b; //Absolute to shift in first quadrant
    float ret = length(max(vec3(0.0), d)); //For points outside the box

    ret += min(0.0, max(max(d.x, d.y), d.z));

    return ret;
    
    //// your implementation ends
}

/////////////////////////////////////////////////////
//// boolean operations
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 2: sdf boolean operations
//// You are asked to implement sdf boolean operations for intersection, union, and subtraction.
/////////////////////////////////////////////////////

float sdfIntersection(float s1, float s2)
{
    //// your implementation starts
    
    return max(s1, s2);

    //// your implementation ends
}

float sdfUnion(float s1, float s2)
{
    //// your implementation starts
    
    return min(s1, s2);

    //// your implementation ends
}

float sdfSubtraction(float s1, float s2)
{
    //// your implementation starts
    
    return max(s1, -s2);

    //// your implementation ends
}

/////////////////////////////////////////////////////
//// sdf calculation
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 3: scene sdf
//// You are asked to use the implemented sdf boolean operations to draw the following objects in the scene by calculating their CSG operations.
/////////////////////////////////////////////////////


#define NUM_MARBLES 3
#define NUM_TRACKS 4
#define PI 3.1415926536

struct marble{
    vec3 center;
    float radius;
    vec3 color;
};

marble m[NUM_MARBLES*NUM_TRACKS];

// Returns a pseudo-random value in [0.0, 1.0) based on input 'co'.
float rand(vec2 co)
{
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}


//// sdf: p - query point
float sdf(vec3 p)
{
    float s = 0.;

    //// 1st object: plane
    float plane1_h = -0.1;
    
    //// 2nd object: sphere
    vec3 sphere1_c = vec3(-2.0, 1.0, 0.0);
    float sphere1_r = 0.25;

    //// 3rd object: box
    vec3 box1_c = vec3(-1.0, 1.0, 0.0);
    vec3 box1_b = vec3(0.2, 0.2, 0.2);

    //// 4th object: box-sphere subtraction
    vec3 box2_c = vec3(0.0, 1.0, 0.0);
    vec3 box2_b = vec3(0.3, 0.3, 0.3);

    vec3 sphere2_c = vec3(0.0, 1.0, 0.0);
    float sphere2_r = 0.4;

    //// 5th object: sphere-sphere intersection
    vec3 sphere3_c = vec3(1.0, 1.0, 0.0);
    float sphere3_r = 0.4;

    vec3 sphere4_c = vec3(1.3, 1.0, 0.0);
    float sphere4_r = 0.3;

    //// calculate the sdf based on all objects in the scene
    
    //// your implementation starts
    s = sdfUnion( sdfPlane(p,plane1_h), sdfSphere(p, sphere1_c, sphere1_r));
    s = sdfUnion(s, sdfBox(p, box1_c, box1_b));
    s = sdfUnion(s, sdfSubtraction(sdfBox(p, box2_c, box2_b), sdfSphere(p, sphere2_c, sphere2_r)));
    s = sdfUnion(s, sdfIntersection(sdfSphere(p, sphere3_c, sphere3_r), sdfSphere(p, sphere4_c, sphere4_r)));
    //// your implementation ends

    return s;
}

/////////////////////////////////////////////////////
//// ray marching
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 4: ray marching
//// You are asked to implement the ray marching algorithm within the following for-loop.
/////////////////////////////////////////////////////

//// ray marching: origin - ray origin; dir - ray direction 
float rayMarching(vec3 origin, vec3 dir)
{
    float s = 0.0;
    vec3 p;
    float v;
    for(int i = 0; i < 100; i++)
    {
        //// your implementation starts
        p = origin + s*dir;
        v = sdf(p);
        s += v*0.9; //Advance the ray, prevent overstepping
        if(v < .0001)
            break;
        
        if(s>MAX_DIST)
            break;

        //// your implementation ends
    }
    
    return s;
}

/////////////////////////////////////////////////////
//// normal calculation
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 5: normal calculation
//// You are asked to calculate the sdf normal based on finite difference.
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
//// You are asked to specify the color for each object in the scene.
//// Each object must have a separate color without mixing.
//// Notice that we have implemented the default Phong shading model for you.
/////////////////////////////////////////////////////

vec3 phong_shading(vec3 p, vec3 n)
{
    //// background
    if(p.z > 10.0){
        return vec3(0.9, 0.6, 0.2);
    }

    //// phong shading
    vec3 lightPos = vec3(4.*sin(iTime), 4., 4.*cos(iTime));  
    vec3 l = normalize(lightPos - p);               
    float amb = 0.1;
    float dif = max(dot(n, l), 0.) * 0.7;
    vec3 eye = CAM_POS;
    float spec = pow(max(dot(reflect(-l, n), normalize(eye - p)), 0.0), 128.0) * 0.9;

    vec3 sunDir = vec3(0, 1, -1);
    float sunDif = max(dot(n, sunDir), 0.) * 0.2;

    //// shadow
    float s = rayMarching(p + n * 0.02, l);
    if(s < length(lightPos - p)) dif *= .2;

    vec3 color = vec3(1.0, 1.0, 1.0);

    //// your implementation for coloring starts
    if(p.y<0.0)
        color = vec3(0.9961, 0.9961, 0.0);
    else {
        if(p.x < - 1.5) 
            color = vec3(1.0, 1.0, 1.0);
        else if(p.x < -0.5)
            color = vec3(0.7176, 0.1961, 0.1961);
        else if (p.x < 1.0)
            color = vec3(0.4157, 0.7647, 0.0941);
        else 
            color = vec3(0.0275, 0.9216, 0.7412);
    }


    //// your implementation for coloring ends
    
    //color = 0.5 + 0.5*cos(iTime+vec3(0,2,4));
    
   
    // Alternate coloring for creative expression
    // for(int j=0;j<NUM_TRACKS;j++) {
    //     for(int i=0;i<NUM_MARBLES;i++){
    //         if( length(p - m[j*NUM_TRACKS+i].center) <= (m[j*NUM_TRACKS+i].radius + 0.5)){
    //             return (amb + dif + spec + sunDif) * m[j*NUM_TRACKS+i].color;
    //             //return vec3(1.0,0.0,0.0);
    //         }
    //     }
    // }
    

    return (amb + dif + spec + sunDif) * color;
}

/////////////////////////////////////////////////////
//// Step 7: creative expression
//// You will create your customized sdf scene with new primitives and CSG operations in the sdf2 function.
//// Call sdf2 in your ray marching function to render your customized scene.
/////////////////////////////////////////////////////


//// sdf2: p - query point
float sdf2(vec3 p)
{
    float s = 1e20;
    float time = iTime;

    float rad = 0.1; //Marble radius
    float angle_step = 2.0 * PI/(float(NUM_MARBLES));

    float base_radius = 0.2;
    vec3 offset;
    vec3 screenCenter =  vec3(0.0, 1.0, 0.0);

    int index;

    for(int j=0;j<NUM_TRACKS;j++){
        float track_radius = base_radius + float(j) * 0.3; // Increasing track radius

        for(int i=0;i<NUM_MARBLES;i++){
            index = j*NUM_TRACKS + i;
            float angle = time + float(i) * angle_step;
            angle += float(j)*0.3; // Track shifting

            if (j%2 == 0){
                angle = -1.0*angle;
            }
            
            vec3 offset = vec3(sin(angle) + cos(iTime), cos(angle) + sin(iTime), sin(iTime) + cos(2.0*iTime) *float(i+j)*1.5);

            m[index].center =  screenCenter + track_radius * offset; // Final marble position
            m[index].radius = rad;
            float rr = rand(vec2(float(index), 1.0));
            float gg = rand(vec2(float(index), 2.0));
            float bb = rand(vec2(float(index), 3.0));
             m[index].color = vec3(rr,gg,bb);
            // m[index].color = vec3(
            //             (float(index)* 0.21),
            //             (float(index)* 0.37),
            //             (float(index)* 0.53));

            //m[index].color = vec3(1.0, 0.0, 0.0);

            s = sdfUnion(s, sdfSphere(p, m[index].center, m[index].radius));
            
        }
    }

    return s;
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
