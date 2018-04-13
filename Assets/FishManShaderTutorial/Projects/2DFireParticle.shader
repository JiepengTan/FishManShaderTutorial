
Shader "FishManShaderTutorial/FireParticle"{
	Properties{
	    _MainTex ("MainTex", 2D) = "white" {}
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
			#define PI 3.14159
		 
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
		        return o;
	        }
			
			fixed4 ProcessFrag(v2f input);

			fixed4 frag(v2f i) : SV_Target{
				fixed4 finalColor =fixed4(0.,0.,0.,0.);
				fixed4 processCol = ProcessFrag(i);
                finalColor = processCol;
                finalColor.w =1.0;
				return finalColor;
			}
			
			fixed3 mod289(fixed3 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			fixed4 mod289(fixed4 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			fixed4 permute(fixed4 x) {
					 return mod289(((x*34.0)+1.0)*x);
			}

			fixed4 taylorInvSqrt(fixed4 r)
			{
				return 1.79284291400159 - 0.85373472095314 * r;
			}

			float snoise(fixed3 v)
				{ 
				const fixed2	C = fixed2(1.0/6.0, 1.0/3.0) ;
				const fixed4	D = fixed4(0.0, 0.5, 1.0, 2.0);

			// First corner
				fixed3 i	= floor(v + dot(v, C.yyy) );
				fixed3 x0 =	 v - i + dot(i, C.xxx) ;

			// Other corners
				fixed3 g = step(x0.yzx, x0.xyz);
				fixed3 l = 1.0 - g;
				fixed3 i1 = min( g.xyz, l.zxy );
				fixed3 i2 = max( g.xyz, l.zxy );

				//	 x0 = x0 - 0.0 + 0.0 * C.xxx;
				//	 x1 = x0 - i1	+ 1.0 * C.xxx;
				//	 x2 = x0 - i2	+ 2.0 * C.xxx;
				//	 x3 = x0 - 1.0 + 3.0 * C.xxx;
				fixed3 x1 = x0 - i1 + C.xxx;
				fixed3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
				fixed3 x3 = x0 - D.yyy;			// -1.0+3.0*C.x = -0.5 = -D.y

			// Permutations
				i = mod289(i); 
				fixed4 p = permute( permute( permute( 
									 i.z + fixed4(0.0, i1.z, i2.z, 1.0 ))
								 + i.y + fixed4(0.0, i1.y, i2.y, 1.0 )) 
								 + i.x + fixed4(0.0, i1.x, i2.x, 1.0 ));

			// Gradients: 7x7 points over a square, mapped onto an octahedron.
			// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
				float n_ = 0.142857142857; // 1.0/7.0
				fixed3	ns = n_ * D.wyz - D.xzx;

				fixed4 j = p - 49.0 * floor(p * ns.z * ns.z);	//	mod(p,7*7)

				fixed4 x_ = floor(j * ns.z);
				fixed4 y_ = floor(j - 7.0 * x_ );		// mod(j,N)

				fixed4 x = x_ *ns.x + ns.yyyy;
				fixed4 y = y_ *ns.x + ns.yyyy;
				fixed4 h = 1.0 - abs(x) - abs(y);

				fixed4 b0 = fixed4( x.xy, y.xy );
				fixed4 b1 = fixed4( x.zw, y.zw );

				//fixed4 s0 = fixed4(lessThan(b0,0.0))*2.0 - 1.0;
				//fixed4 s1 = fixed4(lessThan(b1,0.0))*2.0 - 1.0;
				fixed4 s0 = floor(b0)*2.0 + 1.0;
				fixed4 s1 = floor(b1)*2.0 + 1.0;
				fixed4 sh = -step(h, fixed4(0.,0.,0.,0.));

				fixed4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
				fixed4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

				fixed3 p0 = fixed3(a0.xy,h.x);
				fixed3 p1 = fixed3(a0.zw,h.y);
				fixed3 p2 = fixed3(a1.xy,h.z);
				fixed3 p3 = fixed3(a1.zw,h.w);

			//Normalise gradients
				fixed4 norm = taylorInvSqrt(fixed4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
				//fixed4 norm = inversesqrt(fixed4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
				p0 *= norm.x;
				p1 *= norm.y;
				p2 *= norm.z;
				p3 *= norm.w;

			// Mix final noise value
				fixed4 m = max(0.6 - fixed4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
				m = m * m;
				return 42.0 * dot( m*m, fixed4( dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3) ) );
			}

			float prng(in fixed2 seed) {
				seed = frac (seed * fixed2 (5.3983, 5.4427));
				seed += dot (seed.yx, seed.xy + fixed2 (21.5351, 14.3137));
				return frac (seed.x * seed.y * 95.4337);
			}

			float noiseStack(fixed3 pos,int octaves,float falloff){
				float noise = snoise(fixed3(pos));
				float off = 1.0;
				if (octaves>1) {
					pos *= 2.0;
					off *= falloff;
					noise = (1.0-off)*noise + off*snoise(fixed3(pos));
				}
				if (octaves>2) {
					pos *= 2.0;
					off *= falloff;
					noise = (1.0-off)*noise + off*snoise(fixed3(pos));
				}
				if (octaves>3) {
					pos *= 2.0;
					off *= falloff;
					noise = (1.0-off)*noise + off*snoise(fixed3(pos));
				}
				return (1.0+noise)/2.0;
			}

			fixed2 noiseStackUV(fixed3 pos,int octaves,float falloff,float diff){
				float displaceA = noiseStack(pos,octaves,falloff);
				float displaceB = noiseStack(pos+fixed3(3984.293,423.21,5235.19),octaves,falloff);
				return fixed2(displaceA,displaceB);
			}
			fixed4 ProcessFrag(v2f i)  {
				fixed3 acc = fixed3(0.0,0.0,0.0);
				fixed time = _Time.y;

				fixed3 fireCol = fixed3(1.0,0.3,0.0);
				fixed sparkGridSize = 30.0;//»®·Ö¸ñ×Ó
				fixed rotateSpd = 3.*time;//¿ØÖÆÐý×ªËÙ¶È
				fixed yOffset = 4.*time;//¿ØÖÆÁ£×ÓÉÏÉýËÙ¶È

				fixed2 coord = i.uv*sparkGridSize - fixed2(0.,yOffset);
				//coord -= .8*noiseStackUV(0.01*fixed3(coord*30.,30.0*time),1,0.4,0.1);
				if (abs(fmod(coord.y,2.0))<1.0) //Æ«ÒÆ°ë¸ö¸ñ×Ó
					coord.x += 0.5;
				fixed2 sparkGridIndex = fixed2(floor(coord));
				fixed sparkRandom = prng(sparkGridIndex);//¶¨ÒåÁ£×ÓµÄ´óÐ¡
				fixed sparkLife = min(10.0*(1.0-min((sparkGridIndex.y + yOffset)/(24.0-20.0*sparkRandom),1.0)),1.0);//Ë³Ó¦YÖáÍùÏÂÒÆ¶¯µÄÍ¬Ê±  ²»¶ÏµÄÉ¾¼õÁÁ¶È
				//acc = fixed3(sparkRandom,sparkRandom,sparkRandom);
				if (sparkLife>0.0 ) {
					fixed size = 0.08*sparkRandom;//¶¨ÒåÁ£×ÓµÄ´óÐ¡
					fixed deg = 999.0*sparkRandom*2.0*PI + rotateSpd*(0.5+0.5*sparkRandom);//³õÊ¼»¯Ðý×ª³õ½Ç¶È
					fixed2 rotate = fixed2(sin(deg),cos(deg));
					fixed radius =  0.5-size*0.2;
					fixed2 cirOffset = radius*rotate;//¸ù¾ÝÁ£×ÓµÄ´óÐ¡¾ö¶¨ÆäÐý×ª°ë¾¶
					fixed2 part = frac(coord-cirOffset) - 0.5 ;
					float len = length(part);
					fixed sparksGray = max(0.0,1.0 -len/size);//ÈÃÔ²±äÐ¡µã
					fixed sinval = sin(PI*1.*(0.3+0.7*sparkRandom)*time+sparkRandom*10.);
					fixed period = pow(sinval,5.);
					period = clamp(pow(period,5.),0.,1.);
					fixed blink =(0.8+0.8*abs(period));
					acc = sparkLife*sparksGray*fireCol*blink;
				}
				return fixed4(acc, 1.0);
			}
	    ENDCG
	}//end pass
  }//end SubShader
}//end Shader

