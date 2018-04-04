
Shader "FishManShaderTutorial/2DRain"{
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

			float Rand11(float x){
				return frac(sin(x*157.1147) * 43751.1353);
			}
		
			fixed2 Rand22(fixed2 co){
				fixed x = frac(sin(dot(co.xy ,fixed2(1232.9898,7183.233))) * 43758.5453);
				fixed y = frac(sin(dot(co.xy ,fixed2(4577.6537,5337.2793))) * 37573.5913);
				return fixed2(x,y);
			}
 
		
			#define PI2 6.28318
			fixed2 Rains(fixed2 uv, fixed seed, fixed m) {
				float time = _Time.y;
				float period = 5;//雨滴在格子中循环的周期
				float2 retVal  = float2(0.0,0.0);
				float aspectRatio = 4.0;//雨滴的宽高比
				float tileNum = 5;//平铺数量
				float ySpd = 0.1;
				uv.y += time * 0.0618;//加点y轴移动 =PI2 /period *0.45*0.55 / tileNum
				uv *= fixed2(tileNum * aspectRatio,tileNum);//栅格化uv
				//加点基于格子的随机值
				fixed2 idRand = Rand22(floor(uv));
				uv = frac(uv); 
				float2 gridUV = uv;
				uv -=0.5;//(-0.5,0.5)
				//此处uv值范围为(-0.5,0.5)
				//*0.45的原因 是让水滴在格子内游走刚好让上下两个格子之间游走，
				//从而在视觉上格子之间的水滴是可以碰撞的，从而克服格子的空间的分割感
				float t = time * PI2 /period;
				t += idRand.x * PI2;//添加Y随机值
				
				uv.y += sin(t+sin(t+sin(t)*0.55))*0.45;
				uv.y *= aspectRatio;
				//添加x轴随机偏移
				uv.x += (idRand.x-.5)*.6;

				float r = length(uv);
				r = smoothstep(0.2,0.1,r);
		
				//添加尾迹
				float tailTileNum = 3.0;
				float2 tailUV =uv *  float2(1.0,tailTileNum);
				tailUV.y = frac(tailUV.y) - 0.5;
				tailUV.x *= tailTileNum;
				//在雨滴上面总共有
				float rtail = length(tailUV);
				//尾迹塑形
				rtail *= uv.y * 1.5;
				rtail = smoothstep(0.2,0.1,rtail);
				//切除掉大雨滴下面的部分
				rtail *= smoothstep(0.3,0.5,uv.y);
				retVal = float2(rtail*tailUV+r*uv);
				return retVal;
			}
			fixed4 ProcessFrag(v2f input)  {
				float baseOffset = 0.1;
				float2 uv = input.uv;
				uv *= float2(_ScreenParams.x/_ScreenParams.y,1.0);
				float x = (sin(_Time.y*.1)*.5+.5)*.3;
				x =x*x;
				x+= baseOffset;
				float s = sin(x);
				float c = cos(x);
				float2x2 rot = float2x2(c, -s, s, c);
				uv = mul(rot,uv);
				float moveSpd = 0.1;
				float2 rainUV = float2(0.,0.);
				rainUV += Rains(uv,152.12,moveSpd);
				rainUV += Rains(uv*2.32, 25.23, moveSpd);
				fixed4 finalColor = tex2D(_MainTex, input.uv + rainUV*2.);
				return finalColor;
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

