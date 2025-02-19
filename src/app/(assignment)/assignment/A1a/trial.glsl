

// -----------------------------------
// Tunable parameters
// -----------------------------------
const int   MAX_STEPS   = 100;   // Max iterations for ray-marching
const float EPSILON     = 0.001; // When we consider the ray "close enough" to the surface
const float MAX_DIST    = 100.0; // Far-plane cutoff for ray distance
const float SPHERE_RADIUS = 1.0; // Radius of our sphere
const vec3  SPHERE_COLOR = vec3(0.0, 1.0, 0.0); // Green

// -----------------------------------
// SDF function for a sphere at origin
// -----------------------------------
float sphereSDF(vec3 p, float r)
{
    // Distance from p to origin minus radius
    return length(p) - r;
}

// -----------------------------------
// "Scene" SDF: for now, only one sphere
// -----------------------------------
float sceneSDF(vec3 p)
{
    return sphereSDF(p, SPHERE_RADIUS);
}

// -----------------------------------
// Estimate normal at point p on SDF
// -----------------------------------
vec3 estimateNormal(vec3 p)
{
    const float d = 0.0001;
    // Gradient approximation
    float dx = sceneSDF(p + vec3(d, 0.0, 0.0)) - sceneSDF(p - vec3(d, 0.0, 0.0));
    float dy = sceneSDF(p + vec3(0.0, d, 0.0)) - sceneSDF(p - vec3(0.0, d, 0.0));
    float dz = sceneSDF(p + vec3(0.0, 0.0, d)) - sceneSDF(p - vec3(0.0, 0.0, d));
    return normalize(vec3(dx, dy, dz));
}

// -----------------------------------
// Main ray-marching routine
// Returns distance along ray to the first hit, or -1 if none
// -----------------------------------
float raymarch(vec3 ro, vec3 rd)
{
    float distTravelled = 0.0;
    for (int i = 0; i < MAX_STEPS; i++)
    {
        vec3 currentPos = ro + rd * distTravelled;
        float dS = sceneSDF(currentPos);

        // If we're close enough to the surface, report a hit
        if (dS < EPSILON)
        {
            return distTravelled;
        }

        distTravelled += dS;

        // If we've gone too far, assume no hit
        if (distTravelled > MAX_DIST)
        {
            break;
        }
    }
    return -1.0;
}

void main()
{
    // Map vUV into a typical NDC range. 
    // Assuming vUV is [-1..1] x [-1..1], you can skip this if already in that range.
   

in vec2 vUV;           // Full-screen quad UV, range typically [-1, 1] or [0, 1]
out vec4 fragColor;

    vec2 uv = vUV;
    // Camera setup
    vec3 ro = vec3(0.0, 0.0, 3.0);       // Ray origin (camera position)
    vec3 rd = normalize(vec3(uv, -1.0)); // Ray direction (looking towards negative Z)
    
    // Perform the ray-marching
    float t = raymarch(ro, rd);
    
    if (t > 0.0)
    {
        // We hit something. Compute position and normal.
        vec3 p = ro + rd * t;
        vec3 n = estimateNormal(p);

        // Basic Lambertian lighting with a single directional light
        vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
        float diff    = max(dot(n, lightDir), 0.0);

        // Output color (green sphere)
        fragColor = vec4(SPHERE_COLOR * diff, 1.0);
    }
    else
    {
        // No hit: draw a background color (black)
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
}
