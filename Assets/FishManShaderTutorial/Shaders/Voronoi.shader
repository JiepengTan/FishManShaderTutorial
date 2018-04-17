// create by JiepengTan 2018-04-12  email: jiepengtan@gmail.com
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
			float2 hash22(float2 p)
			{
				float3 p3 = frac(float3(p.xyx) * HASHSCALE3);
				p3 += dot(p3, p3.yzx+19.19);
				return frac((p3.xx+p3.yz)*p3.zy);

			}
			float wnoise(float2 p,float time) {
				float2 n = floor(p);
				float2 f = frac(p);
				float md = 5.0;
				float2 m = float2(0.,0.);
				for (int i = -1;i<=1;i++) {
					for (int j = -1;j<=1;j++) {
						float2 g = float2(i, j);
						float2 o = hash22(n+g);
						o = 0.5+0.5*sin(time+6.28*o);
						float2 r = g + o - f;
						float d = dot(r, r);
						if (d<md) {
							md = d;
							m = n+g+o;
						} 
					}
				}
				return md;
			}
            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv = _TileNum * i.uv;
				float time = _Time.y;
				float val = wnoise(uv,time);
				
                return float4(val,val,val,1.0);
            }			
            ENDCG
        }
    }
}
