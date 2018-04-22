// create by JiepengTan  email: jiepengtan@gmail.com
// 2018-04-13



Shader "FishManShaderTutorial/Sea2" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
        _NoiseTex("_NoiseTex", 2D) = "white" {}
		//_LooPNUMS ("_LooPNUMS", Vector) = (3.,5.,8., 1)
		SEA_HEIGHT ("SEA_HEIGHT", float) = 0.6// color
		SEA_CHOPPY ("SEA_CHOPPY", float) = 4.0 // color
		SEA_SPEED ("SEA_SPEED", float) = 0.8 // color
		SEA_FREQ ("SEA_FREQ", float) = 0.16 // color
		SEA_BASE ("_SeaBaseColor", Color) = (0.1,0.19,0.22, 1) // color
		SEA_WATER_COLOR ("_SeaWaterColor", Color) = (0.8,0.9,0.6) // color

		MAP_LOOP_NUM ("MAP_LOOP_NUM", float) = 3 // color
		MAPH_LOOP_NUM ("MAPH_LOOP_NUM", float) = 5 // color
		RAY_MARCH_LOOP_NUM ("RAY_MARCH_LOOP_NUM", float) = 30 // color

    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LooPNUMS = float4(3.,5.,25., 1);
// 是否使用Noise 贴图来加速
//#define USING_TEXLOD_NOISE 

#pragma vertex vert  
#pragma fragment frag  
#include "ShaderLibs/Framework3D.cginc"

			const int NUM_STEPS = 8;
			const float EPSILON = 1e-3;

			float SEA_HEIGHT = 0.6;
			float SEA_CHOPPY = 4.0;
			float SEA_SPEED = 0.8;
			float SEA_FREQ = 0.16;
			float3 SEA_BASE = float3(0.1,0.19,0.22);
			float3 SEA_WATER_COLOR = float3(0.8,0.9,0.6);
#define EPSILON_NRM (0.1 / _ScreenParams.x)
#define SEA_TIME (1.0 + _Time.y * SEA_SPEED)

			float MAP_LOOP_NUM = 3;
			float MAPH_LOOP_NUM = 5;
			float RAY_MARCH_LOOP_NUM = 30;

			// lighting
			float diffuse(float3 n,float3 l,float p) {
				return pow(dot(n,l) * 0.4 + 0.6,p);
			}
			float specular(float3 n,float3 l,float3 e,float s) {    
				float nrm = (s + 8.0) / (PI * 8.0);
				return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
			}

			// sky
			float3 getSkyColor(float3 e) {
				e.y = max(e.y,0.0);
				return float3(pow(1.0-e.y,2.0), 1.0-e.y, 0.6+(1.0-e.y)*0.4);
			}

			// sea
			float sea_octave(float2 uv, float choppy) {
				uv += Noise(uv);        
				float2 wv = 1.0-abs(sin(uv));
				float2 swv = abs(cos(uv));    
				wv = lerp(wv,swv,wv);
				return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
			}

			float map(float3 p) {
				float2x2 octave_m = float2x2(1.6,1.2,-1.2,1.6);
				float freq = SEA_FREQ;
				float amp = SEA_HEIGHT;
				float choppy = SEA_CHOPPY; 
				float2 uv = p.xz; uv.x *= 0.75;
    
				float d, h = 0.0; 
				for(int i = 0; i < MAP_LOOP_NUM; i++) {        
					d = sea_octave((uv + SEA_TIME)*freq,choppy);
					d += sea_octave((uv - SEA_TIME)*freq,choppy);
					h += d * amp;        
					uv = mul(octave_m,uv); freq *= 1.9; amp *= 0.22;
					choppy = lerp(choppy,1.0,0.2);
				}
				return p.y - h;
			}

			float map_detailed(float3 p) {
				float2x2 octave_m = float2x2(1.6,1.2,-1.2,1.6);
				float freq = SEA_FREQ;
				float amp = SEA_HEIGHT;
				float choppy = SEA_CHOPPY;
				float2 uv = p.xz; uv.x *= 0.75;
    
				float d, h = 0.0;   
				for(int i = 0; i < MAPH_LOOP_NUM; i++) {        
					d = sea_octave((uv+SEA_TIME)*freq,choppy);
					d += sea_octave((uv-SEA_TIME)*freq,choppy);
					h += d * amp;        
					uv = mul(octave_m,uv); freq *= 1.9; amp *= 0.22;
					choppy = lerp(choppy,1.0,0.2);
				}
				return p.y - h;
			}

			float3 getSeaColor(float3 p, float3 n, float3 l, float3 eye, float3 dist) {  
				float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
				fresnel = pow(fresnel,3.0) * 0.65;
        
				float3 reflected = getSkyColor(reflect(eye,n));    
				float3 refracted = SEA_BASE + diffuse(n,l,80.0) * SEA_WATER_COLOR * 0.12; 
    
				float3 color = lerp(refracted,reflected,fresnel);
    
				float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
				color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;
				float val = specular(n,l,eye,60.0);
				color += float3(val,val,val);
    
				return color;
			}

			// tracing
			float3 getNormal(float3 p, float eps) {
				float3 n;
				n.y = map_detailed(p);    
				n.x = map_detailed(float3(p.x+eps,p.y,p.z)) - n.y;
				n.z = map_detailed(float3(p.x,p.y,p.z+eps)) - n.y;
				n.y = eps;
				return normalize(n);
			}

			float heightMapTracing(float3 ro, float3 rd) {  
				float tmin = 0.1;
				float tmax = 1000;
				float t = tmin;
				float hx = map(ro + rd * tmax);
				if(hx > 0.0) return tmax;  
				for( int i=0; i< RAY_MARCH_LOOP_NUM; i++ )
				{
					float3 p = ro + t*rd;
					float h = map(p);
					if( h<0.002 || t>tmax ) break;
					t += 0.8*h;
				}
				return t;
			}

            float4 ProcessRayMarch(float2 uv,float3 ori,float3 dir,inout float sceneDep,float4 sceneCol){ 
				  // tracing
				float t = heightMapTracing(ori,dir);
				float3 p = ori + dir * t;
				float3 dist = p - ori;
				float3 n = getNormal(p, dot(dist,dist) * 0.1 / _ScreenParams.x);
				
				float3 light = normalize(float3(0.0,1.0,0.8)); 
             
				// color
				float3 col = lerp(
					getSkyColor(dir),
					getSeaColor(p,n,light,dir,dist),
					pow(smoothstep(0.0,-0.05,dir.y),0.3));
                sceneCol.xyz = col;
				//sceneCol.xyz = n;
                return sceneCol; 
            }
            ENDCG
        }//end pass  
    }//end SubShader 
    FallBack Off
}



