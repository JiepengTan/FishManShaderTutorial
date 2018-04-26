// Create  by JiepengTan@gmail.com
// 2018-04-24
#ifndef FRAMEWORK_3D_DEFAULT_SCENE
#define FRAMEWORK_3D_DEFAULT_SCENE

#include "SDF.cginc"
#include "Framework3D.cginc"

//DEFAULT_RENDER_SKY            default sky box 

float TerrainL(float2 uv);
float TerrainH(float2 uv);


float3 NormalTerrian( in float2 pos, float rz )
{
    float2  eps = float2( 0.002*rz, 0.0 );
    return normalize( float3( TerrainH(pos-eps.xy) - TerrainH(pos+eps.xy),
                            2.0*eps.x,
                            TerrainH(pos-eps.yx) - TerrainH(pos+eps.yx) ) );
}
            

float RaycastTerrain(float3 ro, float3 rd) {  
	const float tmin = 0.1;
	const float tmax = 10000;
	float t = tmin;
	for( int i=0; i< 314; i++ )
	{
		float3 p = ro + t*rd;
		float h = p.y - TerrainL(p.xz);
		if( h<0.002 || t>tmax ) break;
		t += 0.8*h;
	}
	return t;
}

#define _MACRO_SOFT_SHADOW(ro, rd, maxH,MAP_FUNC) \
    float res = 1.0;\
    float t = 0.001;\
    for( int i=0; i<80; i++ ){\
        float3  p = ro + t*rd;\
        float h = p.y - MAP_FUNC( p.xz );\
        res = min( res, 16.0*h/t );\
        t += h;\
        if( res<0.001 ||p.y> maxH ) break;\
    }\
    return clamp( res, 0.0, 1.0 );


#ifdef DEFAULT_RENDER_SKY
float3 RenderSky(float3 ro ,float3 rd,float3 lightDir){
	fixed3 col = fixed3(0.0,0.0,0.0);  
	float sundot = clamp(dot(rd,lightDir),0.0,1.0);
   
     // sky      
    col = float3(0.2,0.5,0.85)*1.1 - rd.y*rd.y*0.5;
    col = lerp( col, 0.85*float3(0.7,0.75,0.85), pow( 1.0-max(rd.y,0.0), 4.0 ) );
    // sun
    col += 0.25*float3(1.0,0.7,0.4)*pow( sundot,5.0 );
    col += 0.25*float3(1.0,0.8,0.6)*pow( sundot,64.0 );
    col += 0.4*float3(1.0,0.8,0.6)*pow( sundot,512.0 );
    // clouds
	col = Cloud(col,ro,rd,float3(1.0,0.95,1.0),1,1);
    // .
    col = lerp( col, 0.68*float3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
	return col;
}
#endif

#endif // FRAMEWORK_3D_DEFAULT_SCENE