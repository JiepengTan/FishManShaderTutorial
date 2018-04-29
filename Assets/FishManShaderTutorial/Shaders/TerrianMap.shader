// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-12  email: jiepengtan@gmail.com
// all right reserve
Shader "FishManShaderTutorial/Ripple"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color ("color", Color) = (.34, .85, .92, 1) // color
        crossGridNum ("crossGridNum", float) = 1.//Maximum number of cells a ripple can cross.
        _Precision ("_Precision", float) = 1.//peroid
        _High ("_High", float) = 2.//wave move speed

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
            //#include "ShaderLibs/Noise.cginc"
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
			float _Precision;
			float _High;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv = i.uv * float2(_ScreenParams.x/_ScreenParams.y,1.0);
                // sample the texture
				float3 col = float3(0.,0.,0.);
                return float4(col,1.0);
					/**/
            }
            ENDCG
        }
    }
}
