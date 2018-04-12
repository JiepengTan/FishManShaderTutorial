Shader "ShaderToy/MergeUnityWithShadertoySimpleSphere" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}
	SubShader{
		Pass {
			ZTest Always Cull Off ZWrite Off
			CGPROGRAM

#pragma vertex VertMergeRayMarch  
#pragma fragment FragMergeRayMarch  
#include "../ShaderLibs/MergeRayMarch.cginc"
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
			fixed4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol)  {
				fixed4 sph = fixed4(0.0,0.0,0.0, 0.5);
				fixed3 col = fixed3(0.0,0.0,0.0); 
				fixed t = sphIntersect(ro + float3(0.,tnoise(_Time.xy*10.,_Time.y,1.),0.), rd, sph);   
				if (t > 0.0 && t < sceneDep)  
				{    
					float3 pos = ro + t * rd;
					float3 nor = normalize(pos - sph.xyz);
					fixed3 col = fixed3(1.2,1.2,1.2);
					col *= 0.6 + 0.4*nor.y;
					sceneCol.xyz = col;
				}
				return sceneCol;
			} 
			ENDCG
		}//end pass
	}//end SubShader
	FallBack Off
}



