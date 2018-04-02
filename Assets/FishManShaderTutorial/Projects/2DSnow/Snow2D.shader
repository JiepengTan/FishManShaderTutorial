
Shader "FishManShaderTutorial/Snow2D"{
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



#define LIGHT_SNOW // Comment this out for a blizzard

#ifdef LIGHT_SNOW
	#define LAYERS 20
	#define DEPTH .5
	#define WIDTH .5
	#define SPEED .6
#else // BLIZZARD
	#define LAYERS 200
	#define DEPTH .1
	#define WIDTH .8
	#define SPEED 1.5
#endif
			fixed2 rand(fixed2 co){
				fixed x = frac(sin(dot(co.xy ,fixed2(12.9898,78.233))) * 43758.5453);
				fixed y = frac(sin(dot(co.xy ,fixed2(47.6537,37.2793))) * 37573.5913);
				return fixed2(x,y);
			}

			fixed4 ProcessFrag(v2f input)  {
				fixed2 uv = input.uv;
				fixed3 acc = fixed3(0.0,0.0,0.0);
				fixed dof = 5.*sin(_Time.y*.1);//让雪花的大小变化
				//不同的layer  生成不同的雪花
				for (fixed i=0.;i<LAYERS;i++) {
					fixed fi = fixed(i); 
					fixed2 q = uv*(1.+fi*DEPTH);//划分不同的格子
					q += fixed2(q.y*(WIDTH*frac(fi*9.27373)-WIDTH*.5),//添加左右偏移
					SPEED*_Time.y/(1.+fi*DEPTH*.03));//添加随着时间向下漂移的效果
					// 随机值生成
					fixed2 r = rand(floor(q)+(31.1759*fi));
    				//acc = r;
					fixed2 s = abs(frac(q)-.5+.9*r.xy-.45);//-0.5~0.5  + -0.5~0  -1~0.5
					//s += .01*abs(2.*frac(10.*q.yx)-1.); 
					fixed d = length(s);// .6*max(s.x-s.y,s.x+s.y)+max(s.x,s.y)-.01;
					//acc += fixed3(d,d,d);
					fixed edge = .005+.05*min(.5*abs(fi-5.-dof),1.);//随机边距 生成不同的圆
					fixed value = r.x/(1.+.02*fi*DEPTH);  //.02*fi*DEPTH  随着距离增加变暗
					fixed finVal = smoothstep(edge,-edge,d)* value;
					acc += fixed3(finVal,finVal,finVal);
				}
                return fixed4(acc, 1.0);
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

