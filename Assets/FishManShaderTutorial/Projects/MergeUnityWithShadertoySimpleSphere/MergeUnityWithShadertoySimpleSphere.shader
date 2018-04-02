Shader "ShaderToy/MergeUnityWithShadertoySimpleSphere" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_FogDensity("Fog Density", Float) = 1.0
		_FogColor("Fog Color", Color) = (1, 1, 1, 1)
		_FogStart("Fog Start", Float) = 0.0
		_FogEnd("Fog End", Float) = 1.0
	}
		SubShader{
		CGINCLUDE

#include "UnityCG.cginc"

		float4x4 _FrustumCornersRay;

	sampler2D _MainTex;
	half4 _MainTex_TexelSize;
	sampler2D _CameraDepthTexture;
	half _FogDensity;
	fixed4 _FogColor;
	float _FogStart;
	float _FogEnd;

	struct v2f {
		float4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
		half2 uv_depth : TEXCOORD1;
		float4 interpolatedRay : TEXCOORD2;
	};

	v2f vert(appdata_img v) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);

		o.uv = v.texcoord;
		o.uv_depth = v.texcoord;

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv_depth.y = 1 - o.uv_depth.y;
#endif

		int index = 0;
		if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
			index = 0;
		}
		else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
			index = 1;
		}
		else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
			index = 2;
		}
		else {
			index = 3;
		}

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			index = 3 - index;
#endif

		o.interpolatedRay = _FrustumCornersRay[index];

		return o;
	}


	//Variables
	float4 _iMouse;

	fixed sphIntersect(in fixed3 ro, in fixed3 rd, in fixed4 sph)
	{
		fixed3 oc = sph.xyz - ro;
		fixed b = dot(oc, rd);
		if(b<=0) return -1.0;
		fixed d2 = dot(oc,oc) - b*b;
		fixed r2 = sph.w * sph.w;
		if(d2>r2) return -1.0;
		return b - sqrt(r2 - d2);
	}


	fixed2 hash2(fixed n) {
		return frac(sin(fixed2(n,n + 1.0))*fixed2(43758.5453123,22578.1459123));
	}
	fixed4 ProcessFrag(v2f i,inout float3 pos)  {
		fixed2 p = (2.0*i.uv - 1) / 1;

		//fixed3 ro = fixed3(0.0, 0.0, 4.0);
		//fixed3 rd = normalize(fixed3(p,-2.0));
		fixed3 ro = _WorldSpaceCameraPos;
		fixed3 rd = normalize(i.interpolatedRay.xyz);


		// sphere animation
		fixed4 sph = fixed4(0.0,0.0,0.0, 0.5);

		fixed3 col = fixed3(0.0,0.0,0.0);

		fixed tmin = 1e10;

		fixed t2 = sphIntersect(ro, rd, sph);
		if (t2 > 0.0 && t2 < tmin)
		{
			tmin = t2;
			fixed t = t2;
			pos = ro + t * rd;
			fixed3 nor = normalize(pos - sph.xyz);
			col = fixed3(1.2,1.2,1.2);
			col *= 0.6 + 0.4*nor.y;
		}
		// output: pixel color

		return fixed4(col, tmin);
	}
	fixed4 frag(v2f i) : SV_Target{
		float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
		float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
		//get Unity world pos
		fixed4 finalColor = tex2D(_MainTex, i.uv);


		float3 pos = float3(-1000,-1000,-1000);
		fixed4 processCol = ProcessFrag(i,pos);
		float4 clipPos = mul(unity_MatrixVP,pos);
		float zVal  = clipPos.z/clipPos.w;
		float zNDC = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
		if(zVal < zNDC){
			finalColor = processCol;
			finalColor.w =1.0;
		}
		
		if(processCol.w < linearDepth){
			finalColor = processCol;
			finalColor.w =1.0;
		}
	
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



