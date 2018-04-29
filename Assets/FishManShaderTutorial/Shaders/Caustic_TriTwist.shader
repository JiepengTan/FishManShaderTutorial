// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// date: 2018-04-11 
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Caustic_TriTwist"{
	Properties{
        _MainTex ("Texture", 2D) = "white" {}
        _TileNum ("TileNum", float) = 1
    }
	SubShader
	{
        Tags { "RenderType"="Opaque" }
	    Pass
	    {
	        ZWrite Off
	        Blend SrcAlpha OneMinusSrcAlpha

	        CGPROGRAM
	        #pragma vertex vert
	        #pragma fragment frag
			#include "ShaderLibs/Framework2D.cginc"
            float _TileNum ; 
		 
			float3 ProcessFrag(float2 _uv){
				float2 uv = _TileNum * _uv;
				float time = _Time.y;
				float val = CausticTriTwist(uv,time); 
                return float3(val,val,val);
            }
            ENDCG
        }
    }
}
