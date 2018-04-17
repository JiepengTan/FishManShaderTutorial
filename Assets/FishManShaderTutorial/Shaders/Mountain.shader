Shader "FishManShaderTutorial/Mountain" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
        //x:MapL y:MapH z:Shadow w:Intersect
        _LoopNum ("_LoopNum", Vector) = (5.,8., 50, 128)
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LoopNum;
#pragma vertex VertMergeRayMarch  
#pragma fragment FragMergeRayMarch  
#include "ShaderLibs/MergeRayMarch.cginc"

            #define InteresctMap TerrialM
            #define NormalMap TerrialH
            #define TerrialHeight 100
            #define SC (TerrialHeight/120.)
            #define MaxShadowHeight TerrialHeight*2.0

            const float2x2 m2 = float2x2(0.8,-0.6,0.6,0.8);
            inline fixed _Terrial(fixed3 pos,float loopNum)
            {
                fixed2 p = pos.xz / (TerrialHeight *2.);
                fixed a = 0.0; 
                fixed b = 1.0;
                fixed2  d = fixed2(0.0,0.0);
                for( int i=0; i<loopNum; i++ )
                {
                    fixed3 n = noised(p);
                    d += n.yz;
                    a += b*n.x/(1.0+dot(d,d));
                    b *= 0.5;
                    p =mul(m2,p)*2.0;
					//p *=2.0;
                }
                return a* TerrialHeight;
            }
            fixed TerrialL( in fixed3 x )
            {
               return _Terrial(x,_LoopNum.x);
            }
            fixed TerrialH( in fixed3 x )
            {
               return _Terrial(x,_LoopNum.y);
            }
            fixed TerrialM( in fixed3 x )
            {
               return _Terrial(x,(_LoopNum.y + _LoopNum.x)*0.5);
            }
            

			float ShadowDistToScene( float3 p )
            {
                return p.y - TerrialL(p) ;
            }
            float IntersectDistToScene( float3 p )
            {
                return p.y - TerrialL(p);
            }

            float SoftShadow(in float3 ro, in float3 rd )
            {
                // real shadows 
                float res = 1.0;
                float t = 0.001;
                for( int i=0; i<_LoopNum.z; i++ )
                {
                    float3  p = ro + t*rd;
                    float h = ShadowDistToScene( p );
                    res = min( res, 16.0*h/t );
                    t += h;
                    if( res<0.01 ||p.y>(MaxShadowHeight) ) break;
                }
                return clamp( res, 0.0, 1.0 );
            }


            float Interesct( in float3 ro, in float3 rd, in float tmin, in float tmax )
            {
                float t = tmin;
                for( int i=0; i<_LoopNum.w; i++ )
                {
                    float3 p = ro + t*rd;
                    float h = IntersectDistToScene(p);
                    if( h<(0.002*t) || t>tmax ) break;
                    t += 0.5*h;
                }
                return t;
            }

            float3 CalcNormal( in float3 pos, float t )
            {
                float3  eps = float3( 0.002*t, 0.0 ,0.);
                return normalize( float3( NormalMap(pos.xyz-eps.xyz) - NormalMap(pos.xyz+eps.xyz),
                                        2.0*eps.x,
                                        NormalMap(pos.xyz-eps.yxz) - NormalMap(pos.xyz+eps.yxz) ) );
            }
        
            float3 Render( in float3 ro, in float3 rd,float tmax)
            {   
                float3 lightDir = normalize( float3(-0.8,0.3,-0.3) );

                float tmin = 0.01;

				fixed3 light1 = normalize( fixed3(-0.8,0.4,-0.3) );
				// bounding plane

				fixed maxh = 300.0*SC;
				fixed sundot = clamp(dot(rd,light1),0.0,1.0);
				fixed3 col = fixed3(0.0,0.0,0.0);
				fixed t = Interesct( ro, rd, tmin, tmax );
				col = fixed3(t/tmax,t/tmax,t/tmax);  
				
                if(t>tmax){
                    float3 sky0 = float3(0.8,0.7,0.5) * 1.2;
                    float3 sky1 = float3(0.4,0.6,0.8) * 1.2;
                    col = lerp(sky0,sky1,pow(max(rd.y + 0.15,0.0),0.5));
                    float val = pow(max(dot(rd,light1),0.0),200.0);
                    col += float3(val,val,val);
					//col = float3(0.,0.,0.);
                }
                else{
                 				// mountains		
					fixed3 pos = ro + t*rd;
					fixed3 nor = CalcNormal( pos, t );

					fixed3 ref = reflect( rd, nor );
					fixed fre = clamp( 1.0+dot(rd,nor), 0.0, 1.0 );
					fixed3 hal = normalize(light1-rd);
        
					// rock
					fixed r = tex2D( _NoiseTex, (7.0/SC)*pos.xz/256.0 ).x;
					col = (r*0.25+0.75)*0.9*lerp( fixed3(0.08,0.05,0.03), fixed3(0.10,0.09,0.08), 
												 tex2D(_NoiseTex,0.00007*fixed2(pos.x,pos.y*48.0)/SC).x );
					col = lerp( col, 0.20*fixed3(0.45,.30,0.15)*(0.50+0.50*r),smoothstep(0.70,0.9,nor.y) );
					col = lerp( col, 0.15*fixed3(0.30,.30,0.10)*(0.25+0.75*r),smoothstep(0.95,1.0,nor.y) );

					// snow
					fixed h = smoothstep(55.0,80.0,pos.y/SC + 25.0*fbm(0.01*pos.xz/SC) );
					fixed e = smoothstep(1.0-0.5*h,1.0-0.1*h,nor.y);
					fixed o = 0.3 + 0.7*smoothstep(0.0,0.1,nor.x+h*h);
					fixed s = h*e*o;
					col = lerp( col, 0.29*fixed3(0.62,0.65,0.7), smoothstep( 0.1, 0.9, s ) );
		
					// lighting		
					fixed amb = clamp(0.5+0.5*nor.y,0.0,1.0);
					fixed dif = clamp( dot( light1, nor ), 0.0, 1.0 );
					fixed bac = clamp( 0.2 + 0.8*dot( normalize( fixed3(-light1.x, 0.0, light1.z ) ), nor ), 0.0, 1.0 );
					fixed sh = 1.0; 
                    if( dif>=0.0001 ) sh = SoftShadow(pos+light1*SC*0.05,light1);
		
					fixed3 lin  = fixed3(0.0,0.0,0.0);
					lin += dif*fixed3(7.00,5.00,3.00)*1.3*fixed3( sh, sh*sh*0.5+0.5*sh, sh*sh*0.8+0.2*sh );
					lin += amb*fixed3(0.40,0.60,1.00)*1.2;
					lin += bac*fixed3(0.40,0.50,0.60);
					col *= lin;
        
					col += s*0.1*pow(fre,4.0)*fixed3(7.0,5.0,3.0)*sh * pow( clamp(dot(nor,hal), 0.0, 1.0),16.0);
					col += s*
						   (0.04+0.96*pow(clamp(1.0+dot(hal,rd),0.0,1.0),5.0))*
						   fixed3(7.0,5.0,3.0)*dif*sh*
						   pow( clamp(dot(nor,hal), 0.0, 1.0),16.0);
        
        
					col += s*0.1*pow(fre,4.0)*fixed3(0.4,0.5,0.6)*smoothstep(0.0,0.6,ref.y);

					// fog
					fixed fo = 1.0-exp(-pow(0.001*t/SC,1.5) );
					fixed3 fco = 0.65*fixed3(0.4,0.65,1.0);// + 0.1*fixed3(1.0,0.8,0.5)*pow( sundot, 4.0 );
					col = lerp( col, fco, fo );
                }
                return col;
            }
        

            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
                float tmax = 500;
                sceneCol.xyz = Render(ro,rd,tmax);
                return sceneCol; 
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



