// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// date: 2018-04-16  
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Rain" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (40.,128., 1, 1)
		_BaseWaterColor ("_BaseWaterColor", COLOR) = (.025, .2, .125,0.)
		_LightWaterColor ("_LightWaterColor", COLOR) = (.025, .2, .125,0.)
		waterHeight ("waterHeight", float) =1.0


        period ("period", float) = 1.//peroid
        spreadSpd ("spreadSpd", float) = 1.//wave move speed
        waveGap ("waveGap", float) = 0.2//single wave 's width
        waveHei ("waveHei", float) = 0.3// wave height
        Rain_Slop ("Rain_Slop", float) = 0.03// wave height
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


            float period ;//peroid
            float spreadSpd;//wave move speed
            float waveGap;//single wave 's width
            float waveHei;// wave height
            float Rain_Slop;

			float WaterMap( fixed3 pos ) {
				float h = FBMR( fixed3( pos.xz, ftime*0.6 )) * 0.5 + Ripples(pos.xz,7.,2.,period,spreadSpd,waveGap)* waveHei;
				return h;
			}

			float3 WaterNormal(float3 pos,float rz){
				float EPSILON = 0.001 *rz;
				float3 dx = float3( EPSILON, 0.,0. );
				float3 dz = float3( 0.,0., EPSILON );
					
				float3	normal = float3( 0., 1., 0. );
				float bumpfactor = 0.2 * (1. - smoothstep( 0., 1000, rz) );//根据距离所见Bump幅度
				
				normal.x = -bumpfactor * (WaterMap(pos + dx) - WaterMap(pos-dx) ) / (2. * EPSILON);
				normal.z = -bumpfactor * (WaterMap(pos + dz) - WaterMap(pos-dz) ) / (2. * EPSILON);
				return normalize( normal );	
			}



            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
				fixed3 col = Sky(ro,rd,_LightDir);
				if(rd.y < -0.01 ) { 
					float rz = (-ro.y)/rd.y;
					float3 pos = ro + rd * rz; 
					float3 normal = WaterNormal(pos,rz);
					//add ripples


					float ndotr = dot(normal,-rd);
					float fresnel = pow(1.0-abs(ndotr),6.);//计算 
					float3 reflectRd = reflect( rd, normal);
					float3 reflectCol = Sky( ro, reflectRd,_LightDir);
  
					float3 diff = pow(dot(normal,_LightDir) * 0.4 + 0.6,3.);
					float3 refractCol = _BaseWaterColor + diff * _LightWaterColor * 0.12; 
    
					col = lerp(refractCol,reflectCol,fresnel);
    
					float spec=  pow(max(dot(reflectRd,_LightDir),0.0),128.) * 1.;
					col += float3(spec,spec,spec);
				}
				//vec2 st =  uv * vec2(.5+(xy.y+1.0)*.3, .02)+vec2(gTime*.5+xy.y*.2, gTime*.2);
				// Rain & Lightning together... 
				float2 ruv = uv / float2(_ScreenParams.x/_ScreenParams.y,1.0);
				uv = (ruv * 2.0 - 1.0) *  float2(_ScreenParams.x/_ScreenParams.y,1.0);
				float2 st =  uv * float2(.5+(ruv.y+1.0)*0.5, .03)+float2(ftime*.2-ruv.y*.1, ftime*.2);
				// I'm adding two parts of the texture to stop repetition...
				float f = tex2D(_NoiseTex, st).y * tex2D(_NoiseTex, st*.773).x * 1.55;
				f = clamp(pow(abs(f), 23.0) * 13.0, 0.0, (ruv.y-.2)*.14);
				col += float3(f,f,f); 

				col = pow(col,float3(0.8,0.8,0.8));
				
                sceneCol.xyz = col;
                return sceneCol;
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



