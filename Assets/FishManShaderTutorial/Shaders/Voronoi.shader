// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-12  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Voronoi"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TileNum ("TileNum", float) = 5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
			#include "ShaderLibs/Noise.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
			
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _TileNum ; 

			#define HASHSCALE3 float3(.1031, .1030, .0973)

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
		
            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv = _TileNum * i.uv;
				float time = _Time.y;
				float val = WNoise(uv,time);
				
                return float4(val,val,val,1.0);
            }			
            ENDCG
        }
    }
}
