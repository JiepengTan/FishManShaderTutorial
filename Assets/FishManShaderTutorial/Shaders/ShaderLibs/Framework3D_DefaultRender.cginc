// Create  by JiepengTan@gmail.com
// 2018-04-24
#ifndef FRAMEWORK_3D_DEFAULT_SCENE
#define FRAMEWORK_3D_DEFAULT_SCENE

#include "SDF.cginc"
#include "Framework3D.cginc"


fixed3 MatCol(float matID,float3 pos,float3 nor);
fixed2 Map( in fixed3 pos );
fixed3 Render( in fixed3 ro, in fixed3 rd );

fixed2 RayCast( in fixed3 ro, in fixed3 rd )
{
    fixed tmin = 1.0;
    fixed tmax = 20.0;
             
    fixed t = tmin;
    fixed m = -1.0;
    for( int i=0; i<128; i++ )
    {
        fixed precis = 0.0005*t;
        fixed2 res = Map( ro+rd*t );
        if( res.x<precis || t>tmax ) break;
        t += res.x;
        m = res.y;
    } 

    if( t>tmax ) m=-1.0;
    return fixed2( t, m );
}


fixed SoftShadow( in fixed3 ro, in fixed3 rd, in fixed mint, in fixed tmax )
{
    fixed res = 1.0;
    fixed t = mint;
    for( int i=0; i<80; i++ )
    {
        fixed h = Map( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

fixed3 CalcNormal( in fixed3 pos )
{
    fixed2 e = fixed2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*Map( pos + e.xyy ).x + 
            			e.yyx*Map( pos + e.yyx ).x + 
            			e.yxy*Map( pos + e.yxy ).x + 
            			e.xxx*Map( pos + e.xxx ).x );
}

fixed CalcAO( in fixed3 pos, in fixed3 nor )
{
    fixed occ = 0.0;
    fixed sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        fixed hr = 0.01 + 0.12*fixed(i)/4.0;
        fixed3 aopos =  nor * hr + pos;
        fixed dd = Map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}
#ifdef DEFAULT_RENDER
fixed3 Render( in fixed3 ro, in fixed3 rd )
{ 
    fixed3 col = fixed3(0.7, 0.9, 1.0) +rd.y*0.8;
    fixed2 res = RayCast(ro,rd);
    fixed t = res.x;
    fixed m = res.y;
    if( m>-0.5 )
    {
        fixed3 pos = ro + t*rd;
        fixed3 nor = CalcNormal( pos );
        fixed3 ref = reflect( rd, nor );
		col = MatCol(m,pos,nor);

        // lighitng        
        fixed occ = CalcAO( pos, nor );
        fixed3  lig = normalize( fixed3(-0.4, 0.7, -0.6) );
        fixed3  hal = normalize( lig-rd );
        fixed amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        fixed dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        fixed bac = clamp( dot( nor, normalize(fixed3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        fixed dom = smoothstep( -0.1, 0.1, ref.y );
        fixed fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
                    
        dif *= SoftShadow( pos, lig, 0.02, 2.5 );
        dom *= SoftShadow( pos, ref, 0.02, 2.5 );

        fixed spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0)*
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 ));

        fixed3 lin = fixed3(0.0,0.0,0.0);
        lin += 1.30*dif*fixed3(1.00,0.80,0.55);
        lin += 0.40*amb*fixed3(0.40,0.60,1.00)*occ;
        lin += 0.50*dom*fixed3(0.40,0.60,1.00)*occ;
        lin += 0.50*bac*fixed3(0.25,0.25,0.25)*occ;
        lin += 0.25*fre*fixed3(1.00,1.00,1.00)*occ;
        col = col*lin;
        col += 10.00*spe*fixed3(1.00,0.90,0.70);

        col = lerp( col, fixed3(0.8,0.9,1.0), 1.0-exp( -0.0002*t*t*t ) );
    }

    return fixed3( clamp(col,0.0,1.0) );
}
#endif

#ifdef DEFAULT_MAT_COL
fixed3 MatCol(float matID,float3 pos,float3 nor)
{ 
	// material        
	fixed3 col = 0.45 + 0.35*sin( fixed3(0.05,0.08,0.10)*(matID-1.0) );
	if( matID<1.5 )
	{       
		fixed f = CheckersGradBox( 5.0*pos.xz );
		col = 0.3 + f*fixed3(0.1,0.1,0.1);
	}
	return col;
}
#endif

#ifdef DEFAULT_PROCESS_FRAG
float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol)  {
		// render	
	fixed3 col = Render( ro, rd );
	// gamma
	col = pow( col, float3(0.4545,0.4545,0.4545) );
	sceneCol.xyz = col;  
	return sceneCol;
} 
#endif


#endif // FRAMEWORK_3D_DEFAULT_SCENE