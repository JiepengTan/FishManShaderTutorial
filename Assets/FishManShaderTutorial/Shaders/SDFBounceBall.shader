// create by JiepengTan 2018-04-14 
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/SDFBounceBall" {
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

			fixed SdBounceBalls(fixed3 pos){
                fixed SIZE = 2.;
                fixed2 gridSize = fixed2(SIZE,SIZE);
                fixed rv = Hash12( floor((pos.xz) / gridSize));
                pos.xz = OpRep(pos.xz,gridSize);
                fixed bollSize = 0.1;
                fixed bounceH = .5;
                return SdSphere(pos- fixed3(0.,(bollSize+bounceH+sin(_Time.y*3.14 + rv*6.24)*bounceH),0.),bollSize);
            }

            fixed2 Map( in fixed3 pos )
            {
                fixed2 res = fixed2( SdPlane(     pos), 1.0 )  ;
                res = OpU( res, fixed2( SdBounceBalls( pos),1.) );
                return res;
            }

            ENDCG
        }//end pass
    }//end SubShader
    FallBack Off
}



