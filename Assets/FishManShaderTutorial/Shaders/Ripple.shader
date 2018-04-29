// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// all right reserve
Shader "FishManShaderTutorial/Ripple"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color ("color", Color) = (.34, .85, .92, 1) // color
        crossGridNum ("crossGridNum", float) = 1.//Maximum number of cells a ripple can cross.
        period ("period", float) = 1.//peroid
        spreadSpd ("spreadSpd", float) = 2.//wave move speed
        waveNum ("waveNum", float) = 1.//wave num in a grid
        waveInterval ("waveInterval", float) = 0.05//single wave 's width
        decaySpd ("decaySpd", float) = 5.//wave amptitude decrese speed 
        waveHei ("waveHei", float) = .3// wave height
        tileNum ("tileNum", float) = 10.// grid tile num
        ttime ("ttime", float) = 10.// grid tile num

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
            
            int crossGridNum ; // Maximum number of cells a ripple can cross.
            float period ;//peroid
            float spreadSpd;//wave move speed
            float waveNum ;//wave num in a grid
            float waveInterval;//single wave 's width
            float decaySpd;//wave amptitude decrese speed 
            float waveHei;// wave height
            float tileNum;// wave height
			float4 _Color;
            float ttime;// wave height
			
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
			float Hash12(float2 co){
				return frac(sin(co.x*157.1147 + co.y*13.713) * 43751.1353);
			}
			fixed2 Hash22(fixed2 co){
				fixed x = frac(sin(dot(co.xy ,fixed2(1232.9898,7183.233))) * 43758.5453);
				fixed y = frac(sin(dot(co.xy ,fixed2(4577.6537,5337.2793))) * 37573.5913);
				return fixed2(x,y);
			}
			float2 Hash21(float co){
				fixed x = frac(sin(co*57.2793) * 438.5453);
				fixed y = frac(sin(co*47.6537) * 373.5453);
				return fixed2(x,y);
			}


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float waveWidth = -waveNum * .5 * waveInterval;
                float halfWaveWid = waveWidth * 0.5;
                float freq = waveNum * 2.*3.14159/waveInterval/(float(crossGridNum) + 1.);
                float totalCellNum =  float((crossGridNum*2+1)*(crossGridNum*2+1));
                float radius = (float(crossGridNum) + 1.);
                float mP  = min(period,radius/spreadSpd);
    
    
                float2 uv = i.uv*tileNum;
                float2 p0 = floor(uv);
				float iTime = ttime;
                float2 circles = float2(0.,0.);

			
                for (float j = -crossGridNum; j <= crossGridNum; ++j)
                {
                    for (float i = -crossGridNum; i <= crossGridNum; ++i)
                    {
                        float2 pi = p0 + float2(i, j);
                        float2 hsh = Hash22(pi);
                        float pd = period*(Hash12(hsh) + 1.);
                        float time = iTime+pd*Hash12(pi);
                        float t = modf(time,pd);
                        float2 p = pi + Hash22(hsh + Hash21(floor(time/pd)));
            
                        float lifeTime = (Hash12(Hash22(hsh)) * 0.8+ 0.2)* mP;
                        float decay =pow(max(0.,lifeTime - t)/lifeTime,decaySpd);
                        float amp = (lifeTime / period) * waveHei;
            
                        float2 v = p - uv;
                        float d = (length(v) - spreadSpd*t)/radius;
            
                        float h = 1e-3;
                        float d1 = d - h;
                        float d2 = d + h;
                        float p1 = amp*sin(freq*d1) *  smoothstep(waveWidth, halfWaveWid, d1) *  smoothstep(0., halfWaveWid, d1);
                        float p2 = amp*sin(freq*d2) * smoothstep(waveWidth, halfWaveWid, d2) *  smoothstep(0., halfWaveWid, d2);
                        circles += 0.5 * normalize(v) * ((p2 - p1) / (2. * h) * decay);
                    }
                }
                circles /= totalCellNum;
                float3 n = float3(circles, sqrt(1. - dot(circles, circles)));

                float3 col = tex2D(_MainTex, i.uv - n.xy).rgb
					+5.*pow(clamp(dot(n, normalize(float3(1., 0.7, 0.5))), 0., 1.), 6.);
                
                return float4(col,1.0);
					/**/
            }
            ENDCG
        }
    }
}
