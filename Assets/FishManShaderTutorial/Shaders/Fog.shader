// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-13  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Fog" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (40.,128., 1, 1)
		_FogSpd ("_FogSpd", Vector) = (1.,0.,0.,0.5)
		_FogHighRange ("_FogHighRange", Vector) = (-5,10,0.,0.5)
		_FogCol ("_FogCol", COLOR) = (.025, .2, .125,0.)
		
    }
    SubShader{ 
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LoopNum = float4(40.,128.,0.,0.);
            float3 _FogSpd ;
			float2 _FogHighRange;
			fixed3 _FogCol;
			 
#pragma vertex vert  
#pragma fragment frag  
#include "ShaderLibs/Framework3D.cginc" 
			#define ITR 100 
			#define FAR 50.
			

			fixed3 Normal(in fixed3 p)
			{  
				return float3(0.,1.0,0.);
			}

			fixed RayCast(in fixed3 ro, in fixed3 rd)
			{
				if (rd.y>=0.0) {
					return 100000;
				}
				float d = -(ro.y - 0.)/rd.y;
				d = min(100000.0, d);
				return d;
			}
            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
				fixed3 ligt = normalize( fixed3(.5, .05, -.2) );
				fixed3 ligt2 = normalize( fixed3(.5, -.1, -.2) );
    
				fixed rz = RayCast(ro,rd);
	
				fixed3 fogb = lerp(fixed3(.7,.8,.8	)*0.3, fixed3(1.,1.,.77)*.95, pow(dot(rd,ligt2)+1.2, 2.5)*.25);
				fogb *= clamp(rd.y*.5+.6, 0., 1.);
				fixed3 col = fogb;
				
				if ( rz < FAR )
				{
					fixed3 pos = ro+rz*rd;
					fixed3 nor= Normal( pos );
					fixed dif = clamp( dot( nor, ligt ), 0.0, 1.0 );
					fixed spe = pow(clamp( dot( reflect(rd,nor), ligt ), 0.0, 1.0 ),50.);
					col = lerp(fixed3(0.1,0.2,1),fixed3(.3,.5,1),pos.y*.5)*0.2+.1;
					col = col*dif + col*spe*.5 ;
				}
				 
				MergeRayMarchingIntoUnity(rz,col,sceneDep,sceneCol);  
			
				col = lerp(col, fogb, smoothstep(FAR-7.,FAR,rz)); 
				//then volumetric fog 
				col = Fog(col, ro, rd, rz,_FogCol,_FogSpd,_FogHighRange);
				//post
				col = pow(col,float3(0.8,0.8,0.8));
                sceneCol.xyz = col;
                return sceneCol; 
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



