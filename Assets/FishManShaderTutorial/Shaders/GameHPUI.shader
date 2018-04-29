// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-13  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/GameHPUI" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (314.,1., 1, 1)
		
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
			#include "ShaderLibs/Math.cginc"
			 
			#define  SIZE  0.5
			#define WATER_DEEP 0.6
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
			
			float Rand(float x)
			{
				return frac(sin(x*866353.13)*613.73);
			}

			float2x2 Rotate2D(float deg){
				deg = deg * Deg2Radius;
				return float2x2(cos(deg),sin(deg),-sin(deg),cos(deg));
			}
			float2 Within(float2 uv, float4 rect) {
				return (uv-rect.xy)/(rect.zw-rect.xy);
			}
			float Circle(float2 uv,float2 center,float size,float blur){
				uv = uv - center;
				uv /= size;
				float len = length(uv);
				return smoothstep(1.,1.-blur,len);
			}

			float PureCircle(float2 uv,float2 center,float size,float blur,float powVal){
				uv = uv - center;
				uv /= size;
				float len = 1.-length(uv);
				float val = clamp(Remap(0.,blur,0.,1.,len),0.,1.);
				return pow(val,powVal);//* pow(1.+len * 3.,0.1);
			}
			float Ellipse(float2 uv,float2 center,float2 size,float blur){
				uv = uv - center;
				uv /= size;
				float len = length(uv);
				return smoothstep(1.,1.-blur,len);
			}


			float3 Draw3DFrame(float2 uv){
				//cameraPos  
				float3 camPos = float3(0.,0.,-3);
				//Torus 
				float3 frameCol = float3(0.9,0.75,0.6);
				float frameMask = Circle(uv,float2(0.,0.),SIZE*1.1,0.01) - 
					Circle(uv,float2(0.,0.),SIZE,0.01);
				return float3(0.,0.,0.);
    
			}
			float Torus2D(float2 uv,float2 center,float2 size,float blur){
				uv = uv - center;
				float len = length(uv);
				if(len<size.y || len >size.x)
					return 0.;
				float radio = (len-size.y)/(size.x-size.y);
				float val = 1.-abs((radio-0.5)*2.);
				return pow(val,blur);
			}

			float3 DrawFrame(float2 uv){
				float3 frameCol = float3(0.9,0.75,0.6);
				float frameMask = Circle(uv,float2(0.,0.),SIZE*1.1,0.01) - 
					Circle(uv,float2(0.,0.),SIZE,0.01);
				//return frameCol * frameMask;
				return Torus2D(uv,float2(0.,0.),float2(SIZE * 1.1,SIZE),0.2) *frameCol;
			}
			float3 DrawHightLight(float2 uv){
				//up
				float3 hlCol = float3(0.95,0.95,0.95);
				float upMask = Ellipse(uv,float2(0.,0.8)*SIZE,float2(0.9,0.7)*SIZE,0.6)*0.9;
				upMask = upMask * Circle(uv,float2(0.,0.)*SIZE,SIZE*0.95,0.02) ;
				upMask = upMask * Circle(uv,float2(0.,-0.9)*SIZE,SIZE*1.1,-0.8) ;
				//bottom
				uv =mul(Rotate2D(30.),uv) ;
				float btMask =1.;
				btMask *=  Circle(uv,float2(0.,0.)*SIZE,SIZE*0.95,0.02);
				float scale = 0.9;
				btMask *= 1.- Circle(uv,float2(0.,-0.17+scale)*SIZE,SIZE*(1.+scale),0.2) ;
				return  (upMask + btMask) * hlCol;
    
			}


			float GetWaveHeight(float2 uv){
				uv =mul(Rotate2D(-30.),uv) ;
				float wave =  0.12*sin(-2.*uv.x+_Time.y*4.); 
				uv =mul(Rotate2D(-50.),uv) ;
				wave +=  0.05*sin(-2.*uv.x+_Time.y*4.); 
				return wave;
			}

			float RayMarchWater(float3 camera, float3 dir,float startT,float maxT){
				float3 pos = camera + dir * startT;
				float t = startT;
				for(int i=0;i<150;i++){
					if(t > maxT){
        				return -1.;
					}
					float h = GetWaveHeight(pos.xz) * WATER_DEEP;
					if(h + 0.01 > pos.y ) {//+ 0.01 acc intersect speed
						// get the intersect point
						return t;
					}
					t += pos.y - h; 
					pos = camera + dir * t;
				}
				return -1.0;
			}

			float4 SimpleWave3D(float2 uv,float3 col){
				float3 camPos =float3(0.23,0.13,-2.28);
				float3 targetPos = float3(0.,0.,0.);
    
				float3 f = normalize(targetPos-camPos);
				float3 r = cross(normalize(float3(0.01, 1., 0.)), f);
				float3 u = cross(f, r);
    
				float3 ray = normalize(uv.x*r+uv.y*u+1.0*f);
    
				float startT = 0.1;
				float maxT = 20.;
				float dist = RayMarchWater(camPos, ray,startT,maxT);
				float3 pos = camPos + ray * dist;
				//only need a small circle
				float circleSize = 2.;
				if(dist < 0.){
    				return float4(0.,0.,0.,0.);
				}
				float2 offsetPos = pos.xz;
				if(length(offsetPos)>circleSize){
    				return float4(0.,0.,0.,0.);
				}
				float colVal = 1.-((pos.z+0.)/circleSize +1.0) *.5;//0~1
				return float4(col*smoothstep(0.,1.4,colVal),1.);
			}
			float SmoothCircle(float2 uv,float2 offset,float size){
				uv -= offset;
				uv/=size;
				float temp = clamp(1.-length(uv),0.,1.);
				return smoothstep(0.,1.,temp);
			}
			float DrawBubble(float2 uv,float2 offset,float size){
				uv = (uv - offset)/size;
				float val = 0.;
				val = length(uv);
				val = smoothstep(0.5,2.,val)*step(val,1.);
    
				val +=SmoothCircle(uv,float2(-0.2,0.3),0.6)*0.4;
				val +=SmoothCircle(uv,float2(0.4,-0.5),0.2)*0.2;
				return val; 
			}
			float DrawBubbles(float2 uv){
				uv = Within(uv, float4(-SIZE,-SIZE,SIZE,SIZE));
				uv.x-=0.5;
				float val = 0.;
				const float count = 2.;// bubble num per second
				const float maxVY = 0.1;
				const float ay = -.3;
				const  float ax = -.5;
				const  float maxDeg = 80.;
				const float loopT = maxVY/ay + (1.- 0.5*maxVY*maxVY/ay)/maxVY;
				const  float num = loopT*count;
				for(float i=1.;i<num;i++){
    				float size = 0.02*Rand(i*451.31)+0.02;
					float t = fmod(_Time.y + Rand(i)*loopT,loopT);
					float deg = (Rand(i*1354.54)*maxDeg +(90.-maxDeg*0.5))*Deg2Radius;
					float2 vel = float2(cos(deg),sin(deg));
					float ty = max((vel.y*0.3 - maxVY),0.)/ay;
					float yt = clamp(t,0.,ty);
					float y = max(0.,abs(vel.y)*yt + 0.5*ay*yt*yt) + max(0.,t-ty)*maxVY;// 加点加速度
        
					float tx = abs(vel.x/ax);
					t = min(tx,t);
					float xOffset = abs(vel.x)*t+0.5*ax*t*t + sin(_Time.y*(0.5+Rand(i)*2.)+Rand(i)*2.*PI)*0.03;
					float x = sign(vel.x)*xOffset;
					float2 offset = float2(x,y);
    				val += DrawBubble(uv,offset,size*0.5);
				}
				return val;
			}


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
		
            float4 frag (v2f i) : SV_Target
            {
				float hpPer = sin(_Time.y*0.2)*0.4+0.5;
				float3 waterCol = 0.5+0.5*cos(2.*PI*(float3(1.,1.,1.)*_Time.y*0.2+float3(0.,0.33,0.67)));
    
				float2 uv = (i.uv/1 - 0.5)*1/1*2.;
				float3 col = float3(0.,0.,0.);//final color 
				//draw 3D frame
				col += DrawFrame(uv);
    
				//draw base water
				float hpPerMask = step(0.,(hpPer *2. -1.)*SIZE - uv.y);
  				float bgMask = 0.;
				bgMask += PureCircle(uv,float2(0.,0.),SIZE*1.1,.9,0.9);
 				bgMask += Circle(uv,float2(0.,0.),SIZE,.6)*0.2;
				col += bgMask * waterCol *hpPerMask ;
    
				//draw wave
				float waterMask = step(length(uv),SIZE);
				float offset = hpPer -0.5+0.01;
				float wavePicSize = 0.8*SIZE;
				float2 remapUV = Within(uv,float4(0.,offset,wavePicSize,offset+wavePicSize-0.2));
				float4 wave = SimpleWave3D(remapUV,waterCol);
				col = lerp(col,wave.xyz*bgMask,wave.w*waterMask);
	
				//draw bubbles
				float bubbleMask = smoothstep(0.,0.1,(hpPer *2. -1.2)*SIZE - uv.y);
				col+= DrawBubbles(uv)*float3(1.,1.,1.)* bubbleMask*waterMask;
				//draw hight light
				col += DrawHightLight(uv*1.);
                return float4(col,1.); 
            }			
            ENDCG
        }
    }
    FallBack Off
}



