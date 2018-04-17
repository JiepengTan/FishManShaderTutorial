// Merge by JiepengTan@gmail.com
#ifndef FMST_COMMOM
#define FMST_COMMOM

#include "UnityCG.cginc"


#include "Noise.cginc"


#define ftime _Time.y

fixed3x3 rot_x(fixed a){fixed sa = sin(a); fixed ca = cos(a); return fixed3x3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
fixed3x3 rot_y(fixed a){fixed sa = sin(a); fixed ca = cos(a); return fixed3x3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
fixed3x3 rot_z(fixed a){fixed sa = sin(a); fixed ca = cos(a); return fixed3x3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.);}


#endif // FMST_COMMOM