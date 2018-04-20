// Merge by JiepengTan@gmail.com
#ifndef FMST_MATH
#define FMST_MATH

#define PI 3.14159265359
#define PI2 6.28318530718
#define Deg2Radius PI/180.
#define Radius2Deg 180./PI


float3x3 Rotx(fixed a){a*= Radius2Deg; fixed sa = sin(a); fixed ca = cos(a); return float3x3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
float3x3 Roty(fixed a){a*= Radius2Deg; fixed sa = sin(a); fixed ca = cos(a); return float3x3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
float3x3 Rotz(fixed a){a*= Radius2Deg; fixed sa = sin(a); fixed ca = cos(a); return float3x3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.); }

float3x3 RotEuler(float3 ang) {
	ang = ang*Radius2Deg;
    float2 a1 = float2(sin(ang.x),cos(ang.x));
    float2 a2 = float2(sin(ang.y),cos(ang.y));
    float2 a3 = float2(sin(ang.z),cos(ang.z));
    float3x3 m;
    m[0] = float3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
    m[1] = float3(-a2.y*a1.x,a1.y*a2.y,a2.x);
    m[2] = float3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
    return m;
}

#endif // FMST_MATH