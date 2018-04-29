//// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
//// date:2018-04-12 
//// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/RaymarchMergeExample" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM

#pragma vertex vert   
#pragma fragment frag  
#include "ShaderLibs/Framework3D.cginc"

            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol)  {
				float3 col = float3(0.,0.,0.);
				float3 n = float3(0.,1.0,0.);
				float t = sceneDep + 10;
				float occ = 0.;
				float3 sc =  float3(0.,1.0+0.5*sin(ftime*PI2),0.);
				float3 sr = 0.5;
				float3 ce = sc - ro;
				float b = dot( rd, ce );
				float tt = sr*sr - (dot( ce, ce )- b*b );
				if( tt > 0.0 ){
					t = b - sqrt(tt);
					float3 p = ro+t*rd;
					col = 0.5+0.5*cos(2.*PI*(float3(1.,1.,1.)*p.y*0.2+float3(0.,0.33,0.67)));
				}
				MergeRayMarchingIntoUnity(t,col, sceneDep,sceneCol);
                return float4(col,1.0);
            } 
			ENDCG
        }//end pass
    }//end SubShader
    FallBack Off
}



