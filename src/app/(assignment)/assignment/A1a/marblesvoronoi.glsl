// "Channeling Marbles" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

void HexVorInit ();
float HexVor (vec2 p);
mat3 QtToRMat (vec4 q);
float SmoothMin (float a, float b, float r);
vec2 Rot2D (vec2 q, float a);
vec3 HsvToRgb (vec3 c);
vec2 Hashv2v2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);
vec4 Loadv4 (int idVar);

const int nBall = 64;
vec3 vnObj, ltDir, vorSmth;
float tCur, dstFar, vorHt, vorAmp, vorScl;
int idBall;
const float pi = 3.14159, sqrt3 = 1.73205;

float SurfHt (vec2 p)
{
  return vorHt * smoothstep (vorSmth.x, vorSmth.y, HexVor (p));
}

float SurfRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  dHit = dstFar;
  if (rd.y < 0.) {
    s = - (ro.y - vorHt) / rd.y;
    sLo = s;
    for (int j = 0; j < 160; j ++) {
      p = ro + s * rd;
      h = p.y - SurfHt (p.xz);
      if (h < 0.) break;
      sLo = s;
      s += max (0.2, 0.4 * h);
      if (s > dstFar) break;
    }
    if (h < 0.) {
      sHi = s;
      for (int j = 0; j < 5; j ++) {
        s = 0.5 * (sLo + sHi);
        p = ro + s * rd;
        if (p.y > SurfHt (p.xz)) sLo = s;
        else sHi = s;
      }
      dHit = 0.5 * (sLo + sHi);
    }
  }
  return dHit;
}

vec3 SurfNf (vec3 p)
{
  const vec2 e = vec2 (0.01, 0.);
  return normalize (vec3 (SurfHt (p.xz) - vec2 (SurfHt (p.xz + e.xy), SurfHt (p.xz + e.yx)), e.x).xzy);
}

float BallHit (vec3 ro, vec3 rd)
{
  vec4 p;
  vec3 u;
  float b, d, w, dMin, rad;
  dMin = dstFar;
  for (int n = 0; n < nBall; n ++) {
    p = Loadv4 (4 * n);
    u = ro - p.xyz;
    rad = 0.45;
    b = dot (rd, u);
    w = b * b - dot (u, u) + rad * rad;
    if (w >= 0.) {
      d = - b - sqrt (w);
      if (d > 0. && d < dMin) {
        dMin = d;
        vnObj = (u + d * rd) / rad;
        idBall = n;
      }
    }
  }
  return dMin;
}

float BallHitSh (vec3 ro, vec3 rd, float rng)
{
  vec4 p;
  vec3 rs, u;
  float b, d, w, dMin, rad;
  dMin = dstFar;
  for (int n = 0; n < nBall; n ++) {
    p = Loadv4 (4 * n);
    u = ro - p.xyz;
    rad = 0.45;
    b = dot (rd, u);
    w = b * b - dot (u, u) + rad * rad;
    if (w >= 0.) {
      d = - b - sqrt (w);
      if (d > 0. && d < dMin) dMin = d;
    }
  }
  return smoothstep (0., rng, dMin);
}

float BallChqr (int idBall, vec3 vnBall)
{
  vec3 u;
  vec2 a;
  u = vnBall * QtToRMat (Loadv4 (4 * idBall + 2));
  a = mod (floor (8. * vec2 (atan (u.x, u.y), asin (u.z)) / pi), 2.) - 0.5;
  return 0.5 + 0.5 * step (0., sign (a.x) * sign (a.y));
}

vec3 BgCol (vec3 rd)
{
  return vec3 (0.5, 0.7, 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, bgCol;
  float dstObj, dstSurf, sh;
  HexVorInit ();
  bgCol = BgCol (rd);
  dstObj = BallHit (ro, rd);
  dstSurf = SurfRay (ro, rd);
  if (min (dstObj, dstSurf) < dstFar) {
    if (dstObj < dstSurf) {
      ro += dstObj * rd;
      vn = vnObj;
      col4 = vec4 (HsvToRgb (vec3 (float (idBall) / float (nBall), 0.8, BallChqr (idBall, vn))), 0.3);
    } else if (dstSurf < dstFar) {
      ro += dstSurf * rd;
      vn = SurfNf (ro);
      vn = VaryNf (4. * ro, vn, max (0.1, 2. - 2. * dstSurf / dstFar));
      col4 = vec4 (mix (vec3 (0.4, 0.3, 0.3), vec3 (0.8, 0.85, 0.8), smoothstep (0., 0.02, ro.y)), 0.);
    }
    sh = BallHitSh (ro + 0.01 * ltDir, ltDir, 10.);
    col = col4.rgb * (0.2 + 0.1 * max (- dot (vn.xz, normalize (ltDir.xz)), 0.) + 
       0.1 * max (vn.y, 0.) + 0.8 * sh * max (dot (vn, ltDir), 0.)) +
       col4.a * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    col = mix (col, bgCol, 1. - min (1., exp2 (8. * (1. - 1.2 * min (dstObj, dstSurf) / dstFar))));
    
  } else col = bgCol;
  return clamp (col, 0., 1.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 stDat, mPtr;
  vec3 col, rd, ro, vd, bMid;
  vec2 canvas, uv, ut;
  float az, el, asp, zmFac, s, mb;
  int fBall;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  asp = canvas.x / canvas.y;
  stDat = Loadv4 (4 * nBall + 0);
  vorSmth = stDat.xyz;
  stDat = Loadv4 (4 * nBall + 1);
  vorAmp = stDat.x;
  vorHt = stDat.y;
  vorScl = stDat.z;
  stDat = Loadv4 (4 * nBall + 2);
  mPtr.xyz = stDat.xyz;
  fBall = int (stDat.w);
  az = 0.;
  el = 0.;
  ut = vec2 (mPtr.x, abs (mPtr.y)) + 0.05 * vec2 (1. / asp, 1.) - 0.5;
  mb = min (ut.x, ut.y);
  if (mPtr.z > 0. && mb < 0.) {
    az = 2. * pi * mPtr.x;
    el = 0.5 * pi * (mPtr.y + 0.25);
  } else {
    if (fBall < 0) {
      az += 0.03 * pi * tCur;
      el += pi * (0.17 + 0.1 * sin (0.041 * pi * tCur));
    }
  }
  if (fBall >= 0) {
    ro = Loadv4 (4 * fBall + 0).xyz;
    ro.y += 0.7;
    vd = Loadv4 (4 * fBall + 1).xyz;
    vd = normalize (vec3 (vd.x, 0., vd.z));
    vd.xz = Rot2D (vd.xz,  - az);
    ro.xz -= 0.7 * vd.xz;
    vuMat = mat3 (vec3 (vd.z, 0., - vd.x), vec3 (0., 1., 0.), vd);
    zmFac = 2.;
  } else {
    el = clamp (el, 0.02 * pi, 0.4 * pi);
    bMid.xz = vec2 (0.);
    for (int n = 0; n < nBall; n ++) bMid.xz += Loadv4 (4 * n).xz;
    bMid.xz /= float (nBall);
    bMid.y = vorHt;
    ro = bMid + 60. * vec3 (cos (el) * sin (az + vec2 (0.5 * pi, 0.)), 2. * sin (el)).xzy;
    vd = normalize (bMid - ro);
    s = sqrt (max (1. - vd.y * vd.y, 1e-6));
    vuMat = mat3 (vec3 (vd.z, 0., - vd.x) / s, vec3 (- vd.y * vd.x, 1. - vd.y * vd.y,
       - vd.y * vd.z) / s, vd);
    zmFac = 4.;
  }
  rd = vuMat * normalize (vec3 (uv, zmFac));
  dstFar = 200.;
  ltDir = normalize (vec3 (1., 2., -1.));
  col = ShowScene (ro, rd);
  if (mPtr.z > 0. && min (uv.x - asp, abs (uv.y) - 1.) > -0.1)
     col = mix (col, vec3 (1., 0.3, 0.), 0.3);
  fragColor = vec4 (col, 1.);
}

vec2 PixToHex (vec2 p)
{
  vec3 c, r, dr;
  c.xz = vec2 ((1./sqrt3) * p.x - (1./3.) * p.y, (2./3.) * p.y);
  c.y = - c.x - c.z;
  r = floor (c + 0.5);
  dr = abs (r - c);
  r -= step (dr.yzx, dr) * step (dr.zxy, dr) * dot (r, vec3 (1.));
  return r.xz;
}

vec2 HexToPix (vec2 h)
{
  return vec2 (sqrt3 * (h.x + 0.5 * h.y), (3./2.) * h.y);
}

vec2 gVec[7], hVec[7];

void HexVorInit ()
{
  vec3 e = vec3 (1., 0., -1.);
  gVec[0] = e.yy;
  gVec[1] = e.xy;
  gVec[2] = e.yx;
  gVec[3] = e.xz;
  gVec[4] = e.zy;
  gVec[5] = e.yz;
  gVec[6] = e.zx;
  for (int k = 0; k < 7; k ++) hVec[k] = HexToPix (gVec[k]);
}

float HexVor (vec2 p)
{
  vec4 sd;
  vec2 ip, fp, d, u;
  float a;
  p *= vorScl;
  ip = PixToHex (p);
  fp = p - HexToPix (ip);
  sd = vec4 (4.);
  for (int k = 0; k < 7; k ++) {
    u = Hashv2v2 (ip + gVec[k]);
    a = 2. * pi * (u.y - 0.5);
    d = hVec[k] + vorAmp * (0.4 + 0.6 * u.x) * sin (a + vec2 (0.5 * pi, 0.)) - fp;
    sd.w = dot (d, d);
    if (sd.w < sd.x) sd = sd.wxyw;
    else sd = (sd.w < sd.y) ? sd.xwyw : ((sd.w < sd.z) ? sd.xyww : sd);
  }
  sd.xyz = sqrt (sd.xyz);
  return SmoothMin (sd.y, sd.z, vorSmth.z) - sd.x;
}

mat3 QtToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  q = normalize (q);
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1., 0., 1.), c.y);
}

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec2 t, ip, fp;
  ip = floor (p);  
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = mix (Hashv2v2 (ip), Hashv2v2 (ip + vec2 (0., 1.)), fp.y);
  return mix (t.x, t.y, fp.x);
}

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  vec2 e;
  e = vec2 (0.1, 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float txRow = 128.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize);
}
