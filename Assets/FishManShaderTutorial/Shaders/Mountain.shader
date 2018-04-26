Shader "FishManShaderTutorial/Mountain" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
        _LoopNum ("_LoopNum", Vector) = (314.,1., 1, 1)
        _MaxTerrianH ("_MaxTerrianH", float) = 500. // color
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM

#pragma vertex vert  
#pragma fragment frag  
#define DEFAULT_RENDER_SKY
#include "ShaderLibs/Framework3D_Terrain.cginc"

            float _MaxTerrianH;

            #define Terrain(uv,NUM)\
                float2  p = uv*.9/_MaxTerrianH;\
                float a = 0.0;\
                float b = 0.5;\
                for( int i=0; i<NUM; i++ ){\
                    float n = VNoise(p);\
                    a += b*n;\
                    b *= 0.497;\
                    p = p*2.01;\
                }\
                return _MaxTerrianH * a;

            float TerrainL(float2 uv){ 
                Terrain(uv,5.);
            }
            float TerrainM(float2 uv){
                Terrain(uv,9.);
            }
            float TerrainH(float2 uv){
                Terrain(uv,15.);
            }

            float SoftShadow(in float3 ro, in float3 rd ){    
                float res = 1.0;
                float t = 0.001;
                for( int i=0; i<180; i++ ){
                    float3  p = ro + t*rd;
                    float h = p.y - TerrainM( p.xz );
                    res = min( res, 16.0*h/t );
                    t += h;
                    if( res<0.001 ||p.y> _MaxTerrianH ) break;
                }
                return clamp( res, 0.0, 1.0 );
            }

            float3 RenderMountain(float3 pos, float3 rd,float rz, float3 nor, float3 lightDir) {  
                float3 col = float3(0.,0.,0.);
                /**/
                //rock
                float r =0.5;// tex2D( _NoiseTex, (600./_MaxTerrianH)*pos.xz/256.0 ).x;
                col = (r*0.25+0.75)*0.9*float3(0.10,0.09,0.08);//lerp( float3(0.08,0.05,0.03), float3(0.10,0.09,0.08), tex2D(_NoiseTex,0.03*float2(pos.x,pos.y*48.0)/_MaxTerrianH).x );
                col = lerp( col, 0.20*float3(0.45,.30,0.15)*(0.50+0.50*r),smoothstep(0.70,0.9,nor.y) );
                col = lerp( col, 0.15*float3(0.30,.30,0.10)*(0.25+0.75*r),smoothstep(0.95,1.0,nor.y) );
				col = float3(0.7,0.3,0.1);
                //lighting     
                float amb = clamp(0.5+0.5*nor.y,0.0,1.0);
                float dif = clamp( dot( lightDir, nor ), 0.0, 1.0 );
                float bac = clamp( 0.2 + 0.8*dot( normalize( float3(-lightDir.x, 0.0, lightDir.z ) ), nor ), 0.0, 1.0 );
                
                //shadow
                float sh =1.;sh = SoftShadow(pos+lightDir*0.01,lightDir);
        
                //brdf
                float3 lin  = float3(0.0,0.0,0.0);
                lin += dif*float3(7.00,5.00,3.00)*1.3*float3( sh, sh*sh*0.5+0.5*sh, sh*sh*0.8+0.2*sh );
                //lin += amb*float3(0.40,0.60,1.00)*1.2;
                //lin += bac*float3(0.40,0.50,0.60);
                //col *= lin;
                col = float3(sh,sh,sh);
                col = float3(dif,dif,dif);
                // fog
                float fo = 1.0-exp(-pow(0.1*rz/_MaxTerrianH,1.5));
                float3 fco = 0.65*float3(0.4,0.65,1.0);
                col = lerp( col, fco, fo );
                return col;
            }
            
            float3 CalcTerrianNormal( in float3 pos, float t )
            {
                float2  eps = float2( 0.002*t, 0.0 );
                return normalize( float3( TerrainH(pos.xz-eps.xy) - TerrainH(pos.xz+eps.xy),
                                        2.0*eps.x,
                                        TerrainH(pos.xz-eps.yx) - TerrainH(pos.xz+eps.yx) ) );
            }
            

            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
                float tmax = 3000.;
                float rz = RaycastTerrain(ro,rd); 
                float3 pos = ro + rd *rz;
                float3 nor = CalcTerrianNormal(pos,rz);
                // color
                float3 col = float3(0.,0.,0.);
                if(rz >tmax ){
                    col= RenderSky(pos,rd,_LightDir);
                }else{
                    col = RenderMountain(pos,rd,rz,nor,_LightDir);
                }
                // sun scatter
                float sundot = clamp(dot(rd,_LightDir),0.0,1.0);
                //col += 0.3*float3(1.0,0.7,0.3)*pow( sundot, 8.0 );
                //gamma
                col = pow( col, float3(0.4545,0.4545,0.4545) );
                sceneCol.xyz = col; 
                return sceneCol; 
            }
            ENDCG
        }//end pass  
    }//end SubShader 
    FallBack Off
}

