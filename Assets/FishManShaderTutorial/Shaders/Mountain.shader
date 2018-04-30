// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-13  email: jiepengtan@gmail.com
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

#define USING_VALUE_NOISE 1
#pragma vertex vert  
#pragma fragment frag  
#include "ShaderLibs/Framework3D_Terrain.cginc"
            float _MaxTerrianH;

            #define Terrain(pos,NUM)\
                float2 p = pos.xz*.9/_MaxTerrianH;\
                float a = 0.0;\
                float b = 0.491;\
				float2  d = float2(0.0,0.);\
                for( int i=0; i<NUM; i++ ){\
                    float n = VNoise(p);\
                    a += b*n;\
                    b *= 0.49;\
                    p = p*2.01;\
                }\
				return float2(pos.y - _MaxTerrianH*a,1.);

            float2 TerrainL(float3 pos){ 
                Terrain(pos,5.);
            } 
            float2 TerrainM(float3 pos){
                Terrain(pos,9.);
            } 
            float2 TerrainH(float3 pos){
                Terrain(pos,15.);
            }  

 
            float3 RenderMountain(float3 pos, float3 rd,float rz, float3 nor, float3 lightDir) {  
                float3 col = float3(0.,0.,0.);
                /**/
                //base color 
                col = float3(0.10,0.09,0.08);
    
                //lighting     
                float amb = clamp(0.5+0.5*nor.y,0.0,1.0);
                float dif = clamp( dot( lightDir, nor ), 0.0, 1.0 );
                float bac = clamp( 0.2 + 0.8*dot( normalize( float3(-lightDir.x, 0.0, lightDir.z ) ), nor ), 0.0, 1.0 );
                
                //shadow
                float sh = SoftShadow(pos+lightDir*_MaxTerrianH*0.08,lightDir,_MaxTerrianH*1.2);
        
                //brdf 
                float3 lin  = float3(0.0,0.0,0.0);
                lin += dif*float3(7.00,5.00,3.00)*float3( sh, sh*sh*0.5+0.5*sh, sh*sh*0.8+0.2*sh );
                lin += amb*float3(0.40,0.60,1.00)*1.2;
                lin += bac*float3(0.40,0.50,0.60);
                col *= lin;
                // fog
                float fo = 1.0-exp(-pow(0.1*rz/_MaxTerrianH,1.5));
                float3 fco = 0.65*float3(0.4,0.65,1.0);
                col = lerp( col, fco, fo );
                return col;
            }

            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
                float tmax = 3000.;
                float rz = RaycastTerrain(ro,rd).x; 
                float3 pos = ro + rd *rz;
                float3 nor = NormalTerrian(pos,rz);
                // color 
                float3 col = float3(0.,0.,0.);
                if(rz >tmax ){ 
                    col= Sky(pos,rd,_LightDir);
                }else{
                    col = RenderMountain(pos,rd,rz,nor,_LightDir);
                } 
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

