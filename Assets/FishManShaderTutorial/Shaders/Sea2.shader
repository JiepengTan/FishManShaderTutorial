// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial 
// email: jiepengtan@gmail.com
// 2018-04-13



Shader "FishManShaderTutorial/Sea2" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
        _NoiseTex("_NoiseTex", 2D) = "white" {}
		//_LooPNUMS ("_LooPNUMS", Vector) = (3.,5.,8., 1)
		_SeaWaveHeight ("_SeaWaveHeight", float) = 0.6// color
		_SeaChoppy ("_SeaChoppy", float) = 4.0 // color
		_SeaSpeed ("_SeaSpeed", float) = 0.8 // color
		_SeaFreq ("_SeaFreq", float) = 0.16 // color
		_SeaBaseColor ("_SeaBaseColor", Color) = (0.1,0.19,0.22, 1) // color
		_SeaWaterColor ("_SeaWaterColor", Color) = (0.8,0.9,0.6) // color

		MAP_LOOP_NUM ("MAP_LOOP_NUM", float) = 3 // color
		MAPH_LOOP_NUM ("MAPH_LOOP_NUM", float) = 5 // color

    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LooPNUMS = float4(3.,5.,25., 1);
// 是否使用Noise 贴图来加速
#define USING_VALUE_NOISE 

#pragma vertex vert  
#pragma fragment frag  
#include "ShaderLibs/Framework3D_Terrain.cginc"


			float _SeaWaveHeight = 0.6;
			float _SeaChoppy = 4.0;
			float _SeaSpeed = 0.8;
			float _SeaFreq = 0.16;
			float3 _SeaBaseColor = float3(0.1,0.19,0.22);
			float3 _SeaWaterColor = float3(0.8,0.9,0.6);
			float MAP_LOOP_NUM = 3;
			float MAPH_LOOP_NUM = 5;
#define SEA_TIME (1.0 + _Time.y * _SeaSpeed)


			
			#define	Waves(pos,_LOOP_NUM)\
				float2 uv = pos.xz;\
				float2x2 octave_m = float2x2(1.6,1.2,-1.2,1.6);\
				float freq = _SeaFreq;\
				float amp = _SeaWaveHeight;\
				float choppy = _SeaChoppy;\
				uv.x *= 0.75;\
				float d, h = 0.0;   \
				for(int i = 0; i < _LOOP_NUM; i++) {        \
					d = Wave((uv+SEA_TIME)*freq,choppy);\
					d += Wave((uv-SEA_TIME)*freq,choppy);\
					h += d * amp;  \
					uv = mul(octave_m,uv); freq *= 1.9; amp *= 0.22;\
					choppy = lerp(choppy,1.0,0.2);\
				}\
				return float2(pos.y - h,1.0);

				
			// sea
			float Wave(float2 uv, float choppy) {
				uv += Noise(uv);   //与sea1 不同的主要地方加了一个noise     
				float2 wv = 1.0-abs(sin(uv));
				float2 swv = abs(cos(uv));    
				wv = lerp(wv,swv,wv);
				return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
			}


            float2 TerrainL(float3 pos){ 
                Waves(pos,MAP_LOOP_NUM);
            } 
            float2 TerrainM(float3 pos){
                Waves(pos,MAP_LOOP_NUM);
            } 
            float2 TerrainH(float3 pos){
                Waves(pos,MAPH_LOOP_NUM);
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
				float3 skyCol = Sky(ro,rd,_LightDir );
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



