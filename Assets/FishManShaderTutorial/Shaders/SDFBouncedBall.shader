// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/SDFBouncedBall" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM

#pragma vertex vert   
#pragma fragment frag  

#define DEFAULT_MAT_COL
#define DEFAULT_PROCESS_FRAG
#define DEFAULT_RENDER
#include "ShaderLibs/Framework3D_DefaultRender.cginc"

			float SdBounceBalls(float3 pos){
                float SIZE = 2.;
                float2 gridSize = float2(SIZE,SIZE);
                float rv = Hash12( floor((pos.xz) / gridSize));
                pos.xz = OpRep(pos.xz,gridSize);
                float bollSize = 0.1;
                float bounceH = .5;
                return SdSphere(pos- float3(0.,(bollSize+bounceH+sin(_Time.y*3.14 + rv*6.24)*bounceH),0.),bollSize);
            }

            float2 Map( in float3 pos )
            {
                float2 res = float2( SdPlane(     pos), 1.0 )  ;
                res = OpU( res, float2( SdBounceBalls( pos),1.) );
                return res;
            }

            ENDCG
        }//end pass
    }//end SubShader
    FallBack Off
}



