// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-13  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Stars" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM

#pragma vertex vert  
#pragma fragment frag  
#include "ShaderLibs/Feature.cginc"
#include "ShaderLibs/Framework3D.cginc"

            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol)  {
                sceneCol.xyz =  Stars(rd,3.,50.);
                return sceneCol;
            } 
            ENDCG
        }//end pass
    }//end SubShader
    FallBack Off
}



