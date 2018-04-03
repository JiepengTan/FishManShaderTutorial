
Shader "FishManShaderTutorial/Snow2D - tutourial"{
	Properties{
	    _MainTex ("MainTex", 2D) = "white" {}
        _NoiseTex ("_NoiseTex", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (1, 1, 1, 1)
	}

	SubShader
	{
	    Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }

	    Pass
	    {
	        ZWrite Off
	        Blend SrcAlpha OneMinusSrcAlpha

	        CGPROGRAM
	        #pragma vertex vert
	        #pragma fragment frag
			#pragma exclude_renderers d3d11_9x
	        #include "UnityCG.cginc"

	        struct VertexOutput {
	           	fixed4 pos : SV_POSITION;
		        fixed2 uv : TEXCOORD0;
		        fixed2 uv_depth : TEXCOORD1;
		        fixed4 interpolatedRay : TEXCOORD2;
	            //VertexOutput
	        };

		    fixed4x4 _FrustumCornersRay;
	        fixed4 _MainTex_TexelSize;
	        sampler2D _CameraDepthTexture;
	        //Variables
            sampler2D _MainTex;
            sampler2D _NoiseTex;
			float4 _LoopNum;
			
			#define AA 1   // make this 2 or even 3 if you have a really powerful GPU

			#define SC (250.0)
			#define kMaxT (5000.0*SC)
            #define m2 (fixed2x2(0.8,-0.6,0.6,0.8))
			

            struct v2f {
		        fixed4 pos : SV_POSITION;
		        fixed2 uv : TEXCOORD0;
		        fixed2 uv_depth : TEXCOORD1;
		        fixed4 interpolatedRay : TEXCOORD2;
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
                //VertexFactory
		        return o;
	        }




			#define SIZE_RATE 0.1
			#define YSPEED 0.5
			#define XSPEED 0.2
			#define LAYERS 10
			float Rand11(float x){
				return frac(sin(x*157.1147) * 43751.1353);
			}
			fixed2 Rand22(fixed2 co){
				fixed x = frac(sin(dot(co.xy ,fixed2(1232.9898,7183.233))) * 43758.5453);
				fixed y = frac(sin(dot(co.xy ,fixed2(4577.6537,5337.2793))) * 37573.5913);
				return fixed2(x,y);
			}
			float3 SnowSingleLayer(float2 uv,float layer){
				float time = _Time.y;
				fixed3 acc = fixed3(0.0,0.0,0.0);//让雪花的大小变化
				uv = uv * (2.0+layer);//透视视野变大效果
			    float xOffset = uv.y * (((Rand11(layer)*2-1.)*0.5+1.)*XSPEED);//增加x轴移动
			    float yOffset = (YSPEED*time);//y轴下落过程
				uv += fixed2(xOffset,yOffset);
				float2 rgrid = Rand22(floor(uv)+(31.1759*layer));
				uv = frac(uv);
				uv -= (rgrid*2-1.0) * 0.35;
				uv -=0.5;
				float r = length(uv);
				float circleSize = 0.05*(1.0+0.3*sin(time*SIZE_RATE));//让大小变化点
				float val = smoothstep(circleSize,-circleSize,r);
				float3 col = float3(val,val,val)* rgrid.x ;
				return col;
			}
			float3 Snow(float2 uv){
				float3 acc = float3(0,0,0);
				for (fixed i=0.;i<LAYERS;i++) {
					acc += SnowSingleLayer(uv,i); 
				}
				return acc;
			}
			fixed4 ProcessFrag(v2f input)  {
				return float4(Snow(input.uv),1.0);
            }

			fixed4 frag(v2f i) : SV_Target{
				float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
				float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
				//get Unity world pos
				fixed4 finalColor = tex2D(_MainTex, i.uv);

				fixed4 processCol = ProcessFrag(i);
				if(processCol.w < linearDepth){
					finalColor = processCol;
					finalColor.w =1.0;
				}
                finalColor = processCol;
                finalColor.w =1.0;
				return finalColor;
			}




	    ENDCG
	}//end pass
  }//end SubShader
}//end Shader

