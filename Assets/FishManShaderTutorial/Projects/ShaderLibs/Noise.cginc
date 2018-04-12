// Merge by JiepengTan@gmail.com

//https://www.shadertoy.com/view/4ssXRX   一些指定分布的Hash
//https://www.shadertoy.com/view/4djSRW  不实用三角函数实现的Hash
#define ITERATIONS 4
// *** Change these to suit your range of random numbers..
// *** Use this for integer stepped ranges, ie Value-Noise/Perlin noise functions.
#define HASHSCALE1 .1031
#define HASHSCALE3 float3(.1031, .1030, .0973)
#define HASHSCALE4 float4(.1031, .1030, .0973, .1099)
//----------------------------------------------------------------------------------------
//  1 out, 1 in...
float hash11(float p)
{
	float3 p3  = frac(p.xxx * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z); 
}

//----------------------------------------------------------------------------------------
//  1 out, 2 in...
float hash12(float2 p)
{
	float3 p3  = frac(float3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  1 out, 3 in...
float hash13(float3 p3)
{
	p3  = frac(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
float2 hash21(float p)
{
	float3 p3 = frac(p * HASHSCALE3);
	p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.xx+p3.yz)*p3.zy);

}

//----------------------------------------------------------------------------------------
///  2 out, 2 in...
float2 hash22(float2 p)
{
	float3 p3 = frac(float3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return frac((p3.xx+p3.yz)*p3.zy);

}

//----------------------------------------------------------------------------------------
///  2 out, 3 in...
float2 hash23(float3 p3)
{
	p3 = frac(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return frac((p3.xx+p3.yz)*p3.zy);
}

//----------------------------------------------------------------------------------------
//  3 out, 1 in...
float3 hash31(float p)
{
   float3 p3 = frac(p * HASHSCALE3); 
   p3 += dot(p3, p3.yzx+19.19);
   return frac((p3.xxy+p3.yzz)*p3.zyx); 
}


//----------------------------------------------------------------------------------------
///  3 out, 2 in...
float3 hash32(float2 p)
{
	float3 p3 = frac(float3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return frac((p3.xxy+p3.yzz)*p3.zyx); 
}

//----------------------------------------------------------------------------------------
///  3 out, 3 in...
float3 hash33(float3 p3)
{
	p3 = frac(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return frac((p3.xxy + p3.yxx)*p3.zyx);

}

//----------------------------------------------------------------------------------------
// 4 out, 1 in...
float4 hash41(float p)
{
	float4 p4 = frac(p * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return frac((p4.xxyz+p4.yzzw)*p4.zywx);
    
}

//----------------------------------------------------------------------------------------
// 4 out, 2 in...
float4 hash42(float2 p)
{
	float4 p4 = frac(float4(p.xyxy) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return frac((p4.xxyz+p4.yzzw)*p4.zywx);

}

//----------------------------------------------------------------------------------------
// 4 out, 3 in...
float4 hash43(float3 p)
{
	float4 p4 = frac(float4(p.xyzx)  * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return frac((p4.xxyz+p4.yzzw)*p4.zywx);
}

//----------------------------------------------------------------------------------------
// 4 out, 4 in...
float4 hash44(float4 p4)
{
	p4 = frac(p4  * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return frac((p4.xxyz+p4.yzzw)*p4.zywx);
}


// https://www.shadertoy.com/view/ldc3RB 
// https://www.shadertoy.com/view/4sc3z2
float noise(float2 p)
{
    float2 pi = floor(p);
    float2 pf = p - pi;
    
    float2 w = pf * pf * (3.0 - 2.0 * pf);
    
    return lerp(lerp(dot(hash22(pi + float2(0.0, 0.0)), pf - float2(0.0, 0.0)), 
                   dot(hash22(pi + float2(1.0, 0.0)), pf - float2(1.0, 0.0)), w.x), 
               lerp(dot(hash22(pi + float2(0.0, 1.0)), pf - float2(0.0, 1.0)), 
                   dot(hash22(pi + float2(1.0, 1.0)), pf - float2(1.0, 1.0)), w.x),
               w.y);
}

float noise(float3 p)
{
    float3 pi = floor(p);
    float3 pf = p - pi;
    
    float3 w = pf * pf * (3.0 - 2.0 * pf);
    
    return  lerp(
                lerp(
                    lerp(dot(pf - float3(0, 0, 0), hash33(pi + float3(0, 0, 0))), 
                        dot(pf - float3(1, 0, 0), hash33(pi + float3(1, 0, 0))),
                        w.x),
                    lerp(dot(pf - float3(0, 0, 1), hash33(pi + float3(0, 0, 1))), 
                        dot(pf - float3(1, 0, 1), hash33(pi + float3(1, 0, 1))),
                        w.x),
                    w.z),
                lerp(
                    lerp(dot(pf - float3(0, 1, 0), hash33(pi + float3(0, 1, 0))), 
                        dot(pf - float3(1, 1, 0), hash33(pi + float3(1, 1, 0))),
                        w.x),
                    lerp(dot(pf - float3(0, 1, 1), hash33(pi + float3(0, 1, 1))), 
                        dot(pf - float3(1, 1, 1), hash33(pi + float3(1, 1, 1))),
                        w.x),
                    w.z),
                w.y);
}


/*
//IQ fast noise3D https://www.shadertoy.com/view/ldScDh
float noise( in float3 x )
{
    float3 p = floor(x);
    float3 f = frac(x);
	f = f*f*(3.0-2.0*f);
	float2 uv = (p.xy+float2(37.0,17.0)*p.z) + f.xy;
	float2 rg = textureLod( iChannel1, (uv+0.5)/256.0, 0.0).yx;
	return mix( rg.x, rg.y, f.z );
}
*/
float vnoise(float2 p)
{
    float2 pi = floor(p);
    float2 pf = p - pi;
    
    float2 w = pf * pf * (3.0 - 2.0 * pf);
    
    return lerp(lerp(hash21(pi + float2(0.0, 0.0)), hash21(pi + float2(1.0, 0.0)), w.x),
               lerp(hash21(pi + float2(0.0, 1.0)), hash21(pi + float2(1.0, 1.0)), w.x),
               w.y);
}


float vnoise(float3 p)
{
    float3 pi = floor(p);
    float3 pf = p - pi;
    
    float3 w = pf * pf * (3.0 - 2.0 * pf);
    
    return  lerp(
                lerp(
                    lerp(hash31(pi + float3(0, 0, 0)), hash31(pi + float3(1, 0, 0)), w.x),
                    lerp(hash31(pi + float3(0, 0, 1)), hash31(pi + float3(1, 0, 1)), w.x), 
                    w.z),
                lerp(
                    lerp(hash31(pi + float3(0, 1, 0)), hash31(pi + float3(1, 1, 0)), w.x),
                    lerp(hash31(pi + float3(0, 1, 1)), hash31(pi + float3(1, 1, 1)), w.x), 
                    w.z),
                w.y);
}


float snoise(float2 p)
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;
    
    float2 i = floor(p + (p.x + p.y) * K1);
    
    float2 a = p - (i - (i.x + i.y) * K2);
    float2 o = (a.x < a.y) ? float2(0.0, 1.0) : float2(1.0, 0.0);
    float2 b = a - (o - K2);
    float2 c = a - (1.0 - 2.0 * K2);
    
    float3 h = max(0.5 - float3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    float3 n = h * h * h * h * float3(dot(a, hash22(i)), dot(b, hash22(i + o)), dot(c, hash22(i + 1.0)));
    
    return dot(float3(70.0, 70.0, 70.0), n);
}

float snoise(float3 p)
{
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;
    
    float3 i = floor(p + (p.x + p.y + p.z) * K1);
    float3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    
    // thx nikita: https://www.shadertoy.com/view/XsX3zB
    float3 e = step(float3(0.0,0.0,0.0), d0 - d0.yzx);
    float3 i1 = e * (1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy * (1.0 - e);
    
    float3 d1 = d0 - (i1 - 1.0 * K2);
    float3 d2 = d0 - (i2 - 2.0 * K2);
    float3 d3 = d0 - (1.0 - 3.0 * K2);
    
    float4 h = max(0.6 - float4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    float4 n = h * h * h * h * float4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));
    
    return dot(float4(31.316,31.316,31.316,31.316), n);
}

float tri(in float x){return abs(frac(x)-.5);}
float2 tri2(in float2 p){return float2(tri(p.x+tri(p.y*2.)), tri(p.y+tri(p.x*2.)));}
float3 tri3(in float3 p){return float3(tri(p.z+tri(p.y*1.)), tri(p.z+tri(p.x*1.)), tri(p.y+tri(p.x*1.)));}

float tnoise(float2 p,float time,float spd)
{
	const float2x2 _m2 = float2x2( 0.970,  0.242, -0.242,  0.970 );
    float z=1.5;
	float rz = 0.;
    float2 bp = p;
	for (float i=0.; i<=4.; i++ )
	{
        float2 dg = tri2(bp*2.)*.8;
        p += (dg+time)*spd;

        bp *= 1.6;
		z *= 1.8;
		p *= 1.2;
        p = mul(_m2,p);
        
        rz+= (tri(p.x+tri(p.y)))/z;
	}
	return rz;
}

//https://www.shadertoy.com/view/4ts3z2 
float tnoise(in float3 p, float time,float spd)
{
    float z=1.4;
	float rz = 0.;
    float3 bp = p;
	for (float i=0.; i<=3.; i++ )
	{
        float3 dg = tri3(bp*2.);
        p += (dg+time)*spd;

        bp *= 1.8;
		z *= 1.5;
		p *= 1.2;
        
        rz+= (tri(p.z+tri(p.x+tri(p.y))))/z;
        bp += 0.14;
	}
	return rz;
}

const float2x2 m2 = float2x2( 0.80,  0.60, -0.60,  0.80 );
float fbm( float2 p )
{
    float f = 0.0;

    f += 0.50000*noise( p ); p = mul(m2,p)*2.02;
    f += 0.25000*noise( p ); p = mul(m2,p)*2.03;
    f += 0.12500*noise( p ); p = mul(m2,p)*2.01;
    f += 0.06250*noise( p ); p = mul(m2,p)*2.04;
    f += 0.03125*noise( p );

    return f/0.984375;
}
float fbm( in float3 p )
{
    float n = 0.0;
    n += 0.50000*noise( p*1.0 );
    n += 0.25000*noise( p*2.0 );
    n += 0.12500*noise( p*4.0 );
    n += 0.06250*noise( p*8.0 );
    n += 0.03125*noise( p*16.0 );
    return n/0.984375;
}


float fbm4( in float3 p )
{
    float n = 0.0;
    n += 1.000*noise( p*1.0 );
    n += 0.500*noise( p*2.0 );
    n += 0.250*noise( p*4.0 );
    n += 0.125*noise( p*8.0 );
    return n;
}

float fbm6( in float3 p )
{
    float n = 0.0;
    n += 1.00000*noise( p*1.0 );
    n += 0.50000*noise( p*2.0 );
    n += 0.25000*noise( p*4.0 );
    n += 0.12500*noise( p*8.0 );
    n += 0.06250*noise( p*16.0 );
    n += 0.03125*noise( p*32.0 );
    return n;
}

float fbm4( in float2 p )
{
    float n = 0.0;
    n += 1.00000*noise( p*1.0 );
    n += 0.50000*noise( p*2.0 );
    n += 0.25000*noise( p*4.0 );
    n += 0.12500*noise( p*8.0 );
    return n;
}

float fbm6( in float2 p )
{
    float n = 0.0;
    n += 1.00000*noise( p*1.0 );
    n += 0.50000*noise( p*2.0 );
    n += 0.25000*noise( p*4.0 );
    n += 0.12500*noise( p*8.0 );
    n += 0.06250*noise( p*16.0 );
    n += 0.03125*noise( p*32.0 );
    return n;
}

/**/