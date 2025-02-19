// A dirty old 2d sphere trick that just projects a texture in 2d. Obviously this can't withstand
// closer scrutiny. Textures with distinct features give it away instantly. Also the glow can't
// represent what's underneath the marble.
// This is close to something we got away with in a game. Although we were targeting GLES1
// and did this with texture coordinates and additional tricks with the geometry.

#define PI 3.1415926536
#define HPI (PI / 2.0)
#define TAU (2.0 * PI)
#define TSCALE 1.25
#define MARBLES 9

// returns normalized distance along sphere surface given 2d radius
float surface(float d)
{
    return asin(clamp(d, 0.0, 1.0)) / HPI * TSCALE;
}

// returns normalized distance along sphere surface given 2d distance on background plane
float glow(float d, float sr)
{
    return atan(d / sr) / HPI * TSCALE;
}

struct Marble
{
    vec2 pos;
    vec2 v;
    vec2 nv;
    float d;
   	float r;
    vec2 tpos;
};

Marble m[MARBLES];

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float time = iTime * 0.28;
	vec2 uv = fragCoord.xy / iResolution.y;
    vec2 size = vec2(iResolution.x/iResolution.y, 1.0);

    // background
    vec3 color = vec3(0.025, 0.05, 0.15);

    // set up marbles and accumulate glows
    float p = 0.0;
    float pinc = TAU / float(MARBLES);
    for (int i = 0; i < MARBLES; i++)
    {
        // position and distance vecs
        vec2 off = vec2(cos(time + p), sin(time + p));
        m[i].pos = 0.5 * size + 0.33 * size * off + sin((time + p) * 6.0) * off.yx * 0.12;

        m[i].v = uv - m[i].pos;
        m[i].d = length(m[i].v);
        m[i].nv = m[i].v / m[i].d;

        // marble radius and texture position
        m[i].r = 0.1 + sin(p * 5.0) * 0.025;
        m[i].tpos = 0.5 + 0.1 * p - m[i].pos / HPI * TSCALE;

        // background glow
        float g = glow(m[i].d, m[i].r);
        vec2 guv = 0.5 + m[i].tpos - m[i].nv * g * m[i].r;
        vec3 gc = texture(iChannel0, guv).rbg;
        gc = smoothstep(0.5, 0.9, gc) * vec3(0.4, 0.3, 0.1);
        // attenuation
        float gd = sqrt(m[i].d * m[i].d + m[i].r * m[i].r) - m[i].r;
        gc /= (0.5 + 1000.0 * gd * gd);
        color += gc;
        
        p += pinc;
    }
    
    // draw marbles on top
    for (int i = 0; i < MARBLES; i++)
    {
        // marble surface
        float md = m[i].d / m[i].r;
        if (md > 1.0)
            continue;
        float ms = surface(md);
        vec2 muv = m[i].tpos + m[i].nv * ms * m[i].r;
        vec3 mc = texture(iChannel0, muv).rgb;
        // glow
        vec3 mg = smoothstep(0.55, 0.9, mc.rbg) * 0.5;
        // base falloff
        mc *= (1.0 - clamp(md * 1.1, 0.0, 0.8));
        // glow with additional falloff
        mc += mg * (1.0 - 0.5 * md);
        // rim, hides the problem at rotational poles a bit
        mc = mix(mc, vec3(0.15, 0.1, 0.2), smoothstep(0.25, 1.0, md * md) * 0.9);
        // highlight
        mc += smoothstep(0.18, 0.04, md) * vec3(0.15, 0.15, 0.2);
        // aa
        float alpha = 1.0 - smoothstep(m[i].r - 0.002, m[i].r, m[i].d);
        color = mix(color, mc, alpha);
    }
    
    fragColor = vec4(color, 1.0);
}
