// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// date: 2018-04-16  
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Lake" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (40.,128., 1, 1)
		_BaseWaterColor ("_BaseWaterColor", COLOR) = (.025, .2, .125,0.)
		_LightWaterColor ("_LightWaterColor", COLOR) = (.025, .2, .125,0.)
		waterHeight ("waterHeight", float) =1.0
		lightDir ("lightDir", Vector) =(-0.8,0.4,-0.3,0.)
    }
    SubShader{ 
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LoopNum = float4(40.,128.,0.,0.);
			//#define USING_PERLIN_NOISE
#pragma vertex vert  
#pragma fragment frag  
#include "ShaderLibs/Framework3D.cginc" 
			
			float3 _BaseWaterColor;
			float3 _LightWaterColor;
			
			float waterHeight = 4.;

			float3 lightDir ;
			float _FBM( in float3 p ) {
				float f = 0.0;
				f += 0.5000*Noise( p ); p = mul(_m3,p)*2.02;
				f += 0.2500*Noise( p ); p = mul(_m3,p)*2.03;
				f += 0.1250*Noise( p ); p = mul(_m3,p)*2.01; 
				f += 0.0625*Noise( p );
				return f/0.9375;
			}
			float WaterMap( fixed3 pos ) {
				return _FBM( fixed3( pos.xz, ftime )) * 1;
			}

			float3 WaterNormal(float3 pos,float rz){
				float EPSILON = 0.001 * rz;
				float3 dx = float3( EPSILON, 0.,0. );
				float3 dz = float3( 0.,0., EPSILON );
					
				float3	normal = float3( 0., 1., 0. );
				float bumpfactor = 0.2 * (1. - smoothstep( 0., 1000, rz) );//根据距离所见Bump幅度
				
				normal.x = -bumpfactor * (WaterMap(pos + dx) - WaterMap(pos-dx) ) / (2. * EPSILON);
				normal.z = -bumpfactor * (WaterMap(pos + dz) - WaterMap(pos-dz) ) / (2. * EPSILON);
				return normalize( normal );	
			}


            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
				fixed3 col = Sky(ro,rd,lightDir);
				if(rd.y < -0.01 ) { 
					float rz = (-ro.y)/rd.y;
					float3 pos = ro + rd * rz; 
					float3 normal = WaterNormal(pos,rz);
					float ndotr = dot(normal,-rd);
					float fresnel = pow(1.0-abs(ndotr),6.);//计算 
					float3 reflectRd = reflect( rd, normal);
					float3 reflectCol = Sky( ro, reflectRd,lightDir);
  
					float3 diff = pow(dot(normal,lightDir) * 0.4 + 0.6,3.);
					float3 refractCol = _BaseWaterColor + diff * _LightWaterColor * 0.12; 
    
					col = lerp(refractCol,reflectCol,fresnel);
    
					float nrm = (60. + 8.0) / (PI * 8.0);
					float spec=  pow(max(dot(reflectRd,lightDir),0.0),128.) * nrm;
					col += float3(spec,spec,spec);
				}
				col = pow(col,float3(0.8,0.8,0.8));
				
                sceneCol.xyz = col;
                return sceneCol;
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



