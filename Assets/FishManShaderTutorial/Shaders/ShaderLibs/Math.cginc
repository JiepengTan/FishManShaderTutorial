// Merge by JiepengTan@gmail.com
#ifndef FMST_MATH
#define FMST_MATH

#define PI 3.1415927
#define Deg2Radius PI/180.

fixed3x3 rot_x(fixed a){fixed sa = sin(a); fixed ca = cos(a); return fixed3x3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
fixed3x3 rot_y(fixed a){fixed sa = sin(a); fixed ca = cos(a); return fixed3x3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
fixed3x3 rot_z(fixed a){fixed sa = sin(a); fixed ca = cos(a); return fixed3x3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.);}


float circle(){

}

float rectangle(){

}


#endif // FMST_MATH