// Create  by JiepengTan@gmail.com
// 2018-03-27
#ifndef FMST_SDF
#define FMST_SDF
#include "Math.cginc"

//------------------------------------------------------------------

fixed OpS( fixed d1, fixed d2 )
{
    return max(-d2,d1);
}

fixed OpU( fixed d1, fixed d2 )
{
    return min(d1,d2);
}
fixed2 OpU( fixed2 d1, fixed2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

fixed3 OpRep( fixed3 p, fixed3 c )
{
    return fmod(p,c)-0.5*c;
}

fixed2 OpRep( fixed2 p, fixed2 c )
{
    return fmod(p,c)-0.5*c;
}


fixed3 OpTwist( fixed3 p )
{
    fixed  c = cos(10.0*p.y+10.0);
    fixed  s = sin(10.0*p.y+10.0);
    fixed2x2   m = fixed2x2(c,-s,s,c);
    return fixed3(mul(m,p.xz),p.y);
}



fixed SdPlane( fixed3 p )
{
    return p.y;
}

fixed SdSphere( fixed3 p, fixed s )
{
    return length(p)-s;
}

fixed SdBox( fixed3 p, fixed3 b )
{
    fixed3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

fixed SdEllipsoid( in fixed3 p, in fixed3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

fixed SdRoundBox( fixed3 p, fixed3 b, fixed r )
{
    return length(max(abs(p)-b,0.0))-r;
}

fixed SdTorus( fixed3 p, fixed2 t )
{
    return length( fixed2(length(p.xz)-t.x,p.y) )-t.y;
}

fixed SdHexPrism( fixed3 p, fixed2 h )
{
    fixed3 q = abs(p);
#if 0
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
#else
    fixed d1 = q.z-h.y;
    fixed d2 = max((q.x*0.866025+q.y*0.5),q.y)-h.x;
    return length(max(fixed2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
}

fixed SdCapsule( fixed3 p, fixed3 a, fixed3 b, fixed r )
{
    fixed3 pa = p-a, ba = b-a;
    fixed h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

fixed SdEquilateralTriangle(  in fixed2 p )
{
    const fixed k = 1.73205;//sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x + k*p.y > 0.0 ) p = fixed2( p.x - k*p.y, -k*p.x - p.y )/2.0;
    p.x += 2.0 - 2.0*clamp( (p.x+2.0)/2.0, 0.0, 1.0 );
    return -length(p)*sign(p.y);
}

fixed SdTriPrism( fixed3 p, fixed2 h )
{
    fixed3 q = abs(p);
    fixed d1 = q.z-h.y;
#if 1
    // distance bound
    fixed d2 = max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5;
#else
    // correct distance
    h.x *= 0.866025;
    fixed d2 = SdEquilateralTriangle(p.xy/h.x)*h.x;
#endif
    return length(max(fixed2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}



fixed SdCylinder( fixed3 p, fixed2 h )
{
  fixed2 d = abs(fixed2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

fixed SdCone( in fixed3 p, in fixed3 c )
{
    fixed2 q = fixed2( length(p.xz), p.y );
    fixed d1 = -q.y-c.z;
    fixed d2 = max( dot(q,c.xy), q.y);
    return length(max(fixed2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

fixed SdConeSection( in fixed3 p, in fixed h, in fixed r1, in fixed r2 )
{
    fixed d1 = -p.y - h;
    fixed q = p.y - h;
    fixed si = 0.5*(r1-r2)/h;
    fixed d2 = max( sqrt( dot(p.xz,p.xz)*(1.0-si*si)) + q*si - r2, q );
    return length(max(fixed2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

fixed SdPryamid4(fixed3 p, fixed3 h ) // h = { cos a, sin a, height }
{
    // Tetrahedron = Octahedron - Cube
    fixed box = SdBox( p - fixed3(0,-2.0*h.z,0), fixed3(2.0*h.z,2.0*h.z,2.0*h.z) );
 
    fixed d = 0.0;
    d = max( d, abs( dot(p, fixed3( -h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, fixed3(  h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, fixed3(  0, h.y, h.x )) ));
    d = max( d, abs( dot(p, fixed3(  0, h.y,-h.x )) ));
    fixed octa = d - h.z;
    return max(-box,octa); // Subtraction
 }


fixed SdTorus82( fixed3 p, fixed2 t )
{
    fixed2 q = fixed2(length2(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

fixed SdTorus88( fixed3 p, fixed2 t )
{
    fixed2 q = fixed2(length8(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

fixed SdCylinder6( fixed3 p, fixed2 h )
{
    return max( length6(p.xz)-h.x, abs(p.y)-h.y );
}

//圆柱切片
fixed SdClipCylinder( fixed3 pos, fixed3 h)
{
   pos.x += h.x*h.z*2. - h.x;
   fixed cy = SdCylinder(pos,h.xy);
   fixed bx = SdBox(pos-fixed3(h.x*(1.+2.*h.z),0.,0.),fixed3(h.x*2.,h.y+0.3,h.x*2.));
   return OpS(cy,bx);
}

#endif // FMST_SDF