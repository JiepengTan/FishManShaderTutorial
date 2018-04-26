// Create  by JiepengTan@gmail.com
// 2018-04-24
#ifndef FRAMEWORK_3D_DEFAULT_SCENE
#define FRAMEWORK_3D_DEFAULT_SCENE

#include "SDF.cginc"
#include "Framework3D.cginc"

//DEFAULT_RENDER                default render function
//DEFAULT_MAT_COL               defualt material color function
//DEFAULT_PROCESS_FRAG          default process frag function

float3 MatCol(float matID,float3 pos,float3 nor);
float2 Map( in float3 pos );
float3 Render( in float3 ro, in float3 rd );

float2 RayCast( in float3 ro, in float3 rd )
{
    float tmin = 1.0;
    float tmax = 20.0;
             
    float t = tmin;
    float m = -1.0;
    for( int i=0; i<128; i++ )
    {
        float precis = 0.0005*t;
        float2 res = Map( ro+rd*t );
        if( res.x<precis || t>tmax ) break;
        t += res.x;
        m = res.y;
    } 

    if( t>tmax ) m=-1.0;
    return float2( t, m );
}


float SoftShadow( in float3 ro, in float3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<80; i++ )
    {
        float h = Map( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float3 CalcNormal( in float3 pos )
{
    float2 e = float2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*Map( pos + e.xyy ).x + 
            			e.yyx*Map( pos + e.yyx ).x + 
            			e.yxy*Map( pos + e.yxy ).x + 
            			e.xxx*Map( pos + e.xxx ).x );
}

float CalcAO( in float3 pos, in float3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        float3 aopos =  nor * hr + pos;
        float dd = Map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}
#ifdef DEFAULT_RENDER
float3 Render( in float3 ro, in float3 rd )
{ 
    float3 col = float3(0.7, 0.9, 1.0) +rd.y*0.8;
    float2 res = RayCast(ro,rd);
    float t = res.x;
    float m = res.y;
    if( m>-0.5 )
    {
        float3 pos = ro + t*rd;
        float3 nor = CalcNormal( pos );
        float3 ref = reflect( rd, nor );
		col = MatCol(m,pos,nor);

        // lighitng        
        float occ = CalcAO( pos, nor );
        float3  lig = normalize( float3(-0.4, 0.7, -0.6) );
        float3  hal = normalize( lig-rd );
        float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(float3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.1, 0.1, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
                    
        dif *= SoftShadow( pos, lig, 0.02, 2.5 );
        dom *= SoftShadow( pos, ref, 0.02, 2.5 );

        float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0)*
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 ));

        float3 lin = float3(0.0,0.0,0.0);
        lin += 1.30*dif*float3(1.00,0.80,0.55);
        lin += 0.40*amb*float3(0.40,0.60,1.00)*occ;
        lin += 0.50*dom*float3(0.40,0.60,1.00)*occ;
        lin += 0.50*bac*float3(0.25,0.25,0.25)*occ;
        lin += 0.25*fre*float3(1.00,1.00,1.00)*occ;
        col = col*lin;
        col += 10.00*spe*float3(1.00,0.90,0.70);

        col = lerp( col, float3(0.8,0.9,1.0), 1.0-exp( -0.0002*t*t*t ) );
    }

    return float3( clamp(col,0.0,1.0) );
}
#endif

#ifdef DEFAULT_MAT_COL
float3 MatCol(float matID,float3 pos,float3 nor)
{ 
	// material        
	float3 col = 0.45 + 0.35*sin( float3(0.05,0.08,0.10)*(matID-1.0) );
	if( matID<1.5 )
	{       
		float f = CheckersGradBox( 5.0*pos.xz );
		col = 0.3 + f*float3(0.1,0.1,0.1);
	}
	return col;
}
#endif

#ifdef DEFAULT_PROCESS_FRAG
float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol)  {
		// render	
	float3 col = Render( ro, rd );
	// gamma
	col = pow( col, float3(0.4545,0.4545,0.4545) );
	sceneCol.xyz = col;  
	return sceneCol;
} 
#endif


#endif // FRAMEWORK_3D_DEFAULT_SCENE