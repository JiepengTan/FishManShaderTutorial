Shader "FishManShaderTutorial/Sea" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (314.,1., 1, 1)
		_SeaBaseColor ("_SeaBaseColor", Color) = (0.1,0.19,0.22, 1) // color
		_SeaWaterColor ("_SeaWaterColor", Color) = (0.8,0.9,0.6) // color
		_SeaWaveHeight ("_SeaWaveHeight", float) = 5. // color
		
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM

#pragma vertex vert  
#pragma fragment frag  
#include "ShaderLibs/Framework3D_Terrain.cginc"

			float3 _SeaBaseColor;
			float3 _SeaWaterColor;
            float4 _LoopNum;
			float _SeaWaveHeight;

			#define	Waves(pos,NUM)\
				float2 uv = pos.xz;\
				float w = 0.0,sw = 0.0;\
				float iter = 0.0, ww = 1.0;\
				uv += ftime * 0.5;\
				for(int i=0;i<NUM;i++){\
					w += ww * Wave(uv * 0.06 , float2(sin(iter), cos(iter)) * 10.0, 2.0 + iter * 0.08, 2.0 + iter * 3.0);\
					sw += ww;\
					ww = lerp(ww, 0.0115, 0.4);\
					iter += 2.39996;\
				}\
				return float2(pos.y- w / sw*_SeaWaveHeight,1.);\

				
			float Wave(float2 uv, float2 emitter, float speed, float phase){ 
				//uv += Noise(uv);
				float dst = distance(uv, emitter);
				return pow((0.5 + 0.5 * sin(dst * phase - ftime * speed)), 5.0);
			}


            float2 TerrainL(float3 pos){ 
                Waves(pos,5.);
            } 
            float2 TerrainM(float3 pos){
                Waves(pos,9.);
            } 
            float2 TerrainH(float3 pos){
                Waves(pos,24.);
            } 

			float3 RenderSea(float3 pos, float3 rd,float rz, float3 nor, float3 lightDir) {  
				float fresnel = clamp(1.0 - dot(nor,-rd), 0.0, 1.0);
				fresnel = pow(fresnel,3.0) * 0.65;
        
				float3 reflected = Sky(pos,reflect(rd,nor),lightDir);    
				float3 diff = pow(dot(nor,lightDir) * 0.4 + 0.6,3.);
				float3 refracted = _SeaBaseColor + diff * _SeaWaterColor * 0.12;
				float3 col = lerp(refracted,reflected,fresnel);
    
				float atten = max(1.0 - dot(rz,rz) * 0.001, 0.0);
				//col += _SeaWaterColor * (p.y - _SeaHeight) * 0.18 * atten;
				float spec=  pow(max(dot(reflect(rd,nor),lightDir),0.0),60.) * 3.;
				col += float3(spec,spec,spec);
    
				return col;
			}
            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
				float rz = RaycastTerrain(ro,rd).x; 
				float3 pos = ro + rd *rz;
				float3 nor = NormalTerrian(pos,rz);
                 
				// color
				float3 skyCol = Sky(pos,rd,_LightDir);
				float3 seaCol = RenderSea(pos,rd,rz,nor,_LightDir);
				float3 col = lerp(skyCol,seaCol,pow(smoothstep(0.0,-0.05,rd.y),0.3));
				col = pow( col, float3(0.4545,0.4545,0.4545) );
				sceneCol.xyz = col;
                return sceneCol; 
            }
            ENDCG
        }//end pass  
    }//end SubShader 
    FallBack Off
}

