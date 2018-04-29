// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-13  email: jiepengtan@gmail.com
Shader "Unity Shaders Book/Chapter 13/Fog With Depth Texture" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_SrcCenterPos("_SrcCenterPos", Vector) = (1, 1, 1, 1)
		_InnerRange("_InnerRange", float) = 10
		_RingWidth("_RingWidth", float) = 10
		_RingIntensity("_RingIntensity", float) = 10

		_TileTex("_TileTex", 2D) = "white" {}
		_TileSize("_TileSize", float) = 10
		_TileIntensity("_TileIntensity", float) = 0.8
		_TileColor("_TileColor", Color) = (1, 1, 1, 1)

		_NoiseTex("_NoiseTex", 2D) = "white" {}
		_NoiseCellSize("_NoiseCellSize", float) = 0.8
		_NoiseCellColor("_NoiseCellColor", Color) = (1, 1, 1, 1)

		_EdgeColor("_EdgeColor", Color) = (1, 1, 1, 1)
	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		float4x4 _FrustumCornersRay;

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;//存储纹理大小

		sampler2D _CameraDepthTexture;

	    float4 _SrcCenterPos;
		float _InnerRange;
		float _RingWidth;
		float _RingIntensity;

		sampler2D _TileTex;
		float _TileSize;
		float _TileIntensity;
		float4 _TileColor;
		

		sampler2D _NoiseTex;
		float _NoiseCellSize;
		float4 _NoiseCellColor;

		float4 _EdgeColor;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 mainUV : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;
			float4 posWorld : TEXCOORD3;
			half2 edgeUV[9]: TEXCOORD4;
		};
		

		fixed luminance(fixed4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
		}

		half ComputeEdgeValue(v2f i)
		{
			const half Gx[9] = { -1,  0,  1,
				-2,  0,  2,
				-1,  0,  1 };
			const half Gy[9] = { -1, -2, -1,
				0,  0,  0,
				1,  2,  1 };

			half texColor;
			half edgeX = 0;
			half edgeY = 0;
			for (int it = 0; it < 9; it++) {
				texColor = luminance(tex2D(_MainTex, i.edgeUV[it]));
				edgeX += texColor * Gx[it];
				edgeY += texColor * Gy[it];
			}

			half edge = abs(edgeX) + abs(edgeY);
			return edge;
		}
		float4 GpuGetCell3D(float3 pos)
		{
			float u = (pos.x*23.335 + pos.y * 31.361) / 255.451;
			float v = (pos.z*83.112 - pos.x * 71.214) / 157.7324;
			return(tex2D(_NoiseTex, float2(u, v)));
		}

		v2f vert(appdata_img v) {
			v2f o = (v2f)0;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.mainUV = v.texcoord;
			o.uv_depth = v.texcoord;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
			
			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			} else {
				index = 3;
			}

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif
			
			o.interpolatedRay = _FrustumCornersRay[index];
			
			//Comp edge sample uv
			half2 mainUV = v.texcoord;
			o.edgeUV[0] = mainUV + _MainTex_TexelSize.xy * half2(-1, -1); 
			o.edgeUV[1] = mainUV + _MainTex_TexelSize.xy * half2(0, -1);
			o.edgeUV[2] = mainUV + _MainTex_TexelSize.xy * half2(1, -1);
			o.edgeUV[3] = mainUV + _MainTex_TexelSize.xy * half2(-1, 0);
			o.edgeUV[4] = mainUV + _MainTex_TexelSize.xy * half2(0, 0);
			o.edgeUV[5] = mainUV + _MainTex_TexelSize.xy * half2(1, 0);
			o.edgeUV[6] = mainUV + _MainTex_TexelSize.xy * half2(-1, 1);
			o.edgeUV[7] = mainUV + _MainTex_TexelSize.xy * half2(0, 1);
			o.edgeUV[8] = mainUV + _MainTex_TexelSize.xy * half2(1, 1);

			return o;
		}



		fixed4 frag(v2f i) : SV_Target {
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
			float3 rawWorldPos = worldPos;
			   worldPos = floor( worldPos / _NoiseCellSize)*_NoiseCellSize;//晶格化

			//Ring
			float dist = distance(worldPos, _SrcCenterPos.xyz);
			float distFactor = saturate(1 - abs((dist - _InnerRange)) / _RingWidth);
			distFactor = smoothstep(0, 1,distFactor);
			//tileTex
			float2 tileUV = rawWorldPos.xz / _TileSize;
			fixed4 tileIntensity = (tex2D(_TileTex, tileUV) * _TileIntensity).r;
			//edge 
			half edgeIntensity = ComputeEdgeValue(i);
			//晶格化
			//distFactor = step(0.1, distFactor);

			//cell Noise 
			float4 NoiseCellIntensity = GpuGetCell3D(worldPos).r;
			
			fixed4 finalColor = tex2D(_MainTex, i.mainUV);
			finalColor.rgb = finalColor.rgb 
				+ distFactor * (NoiseCellIntensity * _NoiseCellColor  + tileIntensity *_TileColor   + edgeIntensity * _EdgeColor) * _RingIntensity;
	
			//return _MainTex_TexelSize.y;
			return finalColor;
		}
		
		ENDCG
		
		Pass {
			ZTest Always Cull Off ZWrite Off
			     	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
	} 
	FallBack Off
}
