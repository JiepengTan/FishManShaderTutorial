Shader "Unlit/WaterCauster"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float2 uv = i.uv;
				//uv *= float2(_ScreenParams.x/_ScreenParams.y,1.0);
				float time = _Time.y;
				fixed4 col = _Time;
				col.w =0.;// _Time.w *0.1;
				// apply fog
				col.xy = uv*3.;//*(sin(time)+2.);
			    float3 val1 = float3(0.,0.0,0.0);
			    float3 val2 = float3(0.,0.0,0.0);
			    float3 val3 = float3(0.,0.0,0.0);
			    float3x3 mat = float3x3(-2,1,2, 3,-3,2, 1,2,2);
			    //8val1 = col.xyw;
			    col.xyw = mul(mat*.5,col.xyw);
			    val1 = col.xyw;   
			    //val2 = col.xyw;
			    col.xyw = mul(mat*.4,col.xyw);
			    val2 = col.xyw;
			    //val3 = col.xyw;
			    col.xyw = mul(mat*.3,col.xyw);
			    val3 = col.xyw;

			    col = pow(
			            min(
			                min(length(.5-frac(val1)),
			                    length(.5-frac(val2))
			                    ),
			                length(.5-frac(val3))
			                ),
			            1.)
			    +float4(0.,0.,0.,0.);
			    //float val = pow(length(.5-frac(val1)),3.)*25.;

			    col = float4(frac(val1).xxx,0.) +float4(0.,0.,0.,0.);
			    //col.xy = uv*3.;
			    //+ float4(0,.35,.5,1);
			    //return float4(uv,0.,0.);
				return col;
			}
			ENDCG
		}
	}
}
