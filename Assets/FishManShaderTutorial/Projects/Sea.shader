Shader "FishManShaderTutorial/Sea" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		//_LooPNUMS ("_LooPNUMS", Vector) = (3.,5.,8., 1)
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
			const float PI	 	= 3.141592;
			const float EPSILON	= 1e-3;
			#define EPSILON_NRM (0.1 / _ScreenParams.x)

			// sea
			const int ITER_GEOMETRY = 3;
			const int ITER_FRAGMENT = 5;
			const float SEA_HEIGHT = 0.6;
			const float SEA_CHOPPY = 4.0;
			const float SEA_SPEED = 0.8;
			const float SEA_FREQ = 0.16;
			const float3 SEA_BASE = float3(0.1,0.19,0.22);
			const float3 SEA_WATER_COLOR = float3(0.8,0.9,0.6);
			#define SEA_TIME _Time.y
			//;//(1.0 + _Time.y * SEA_SPEED)
			const float2x2 octave_m = float2x2(1.6,1.2,-1.2,1.6);


            float4 _LooPNUMS = float4(3.,5.,314., 1);
#pragma vertex VertMergeRayMarch  
#pragma fragment FragMergeRayMarch  
#include "ShaderLibs/MergeRayMarch.cginc"
            // value noise, and its analytical derivatives
    	        
			// lighting
			float lightDiff(float3 n,float3 l,float p) {
				return pow(dot(n,l) * 0.4 + 0.6,p);
			}
			float lightSpec(float3 n,float3 l,float3 e,float s) {    
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
				uv += noise(uv);        
				float2 wv = 1.0-abs(sin(uv));
				float2 swv = abs(cos(uv));    
				wv = lerp(wv,swv,wv);
				return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
			}


			float wave(float2 uv, float2 emitter, float speed, float phase){
				float dst = distance(uv, emitter);
				return pow((0.5 + 0.5 * sin(dst * phase - SEA_TIME * speed)), 5.0);
			}

			float map(float3 p){
				float uv = p.xz;
				float w = 0.0;
				float sw = 0.0;
				float iter = 0.0;
				float ww = 1.0;
				uv += SEA_TIME * 0.5;
				// it seems its absolutely fastest way for water height function that looks real
				for(int i=0;i<6;i++){
					w += ww * wave(uv * 0.06 , float2(sin(iter), cos(iter)) * 10.0, 2.0 + iter * 0.08, 2.0 + iter * 3.0);
					sw += ww;
					ww = lerp(ww, 0.0115, 0.4);
					iter += 2.39996;
				}
				//return p.y - w / sw;
				return p.y - sin(length(uv)+SEA_TIME);
			}
	
			float map_detailed(float3 p){
				return map(p);
			}
			float3 getSeaColor(float3 p, float3 n, float3 l, float3 eye, float3 dist) {  
				float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
				fresnel = pow(fresnel,3.0) * 0.65;
        
				float3 reflected = getSkyColor(reflect(eye,n));    
				float3 refracted = SEA_BASE + lightDiff(n,l,80.0) * SEA_WATER_COLOR * 0.12; 
    
				float3 color = lerp(refracted,reflected,fresnel);
    
				float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
				color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;
				float spec = lightSpec(n,l,eye,60.0);
				color += float3(spec,spec,spec);
    
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
				for( int i=0; i< 80 ; i++ )
				{
					float3 p = ro + t*rd;
					float h =  p.y - sin(length(p.xz)+SEA_TIME);
					if( h<(0.002*t) || t>tmax ) break;
					t += 0.5*h;
				}
				return t;
			}


        
            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
				float3 t = heightMapTracing(ro,rd);
				float3 p = ro + t * rd;
				float3 dist = p - ro;
				float3 n = getNormal(p, dot(dist,dist) * EPSILON_NRM);
				float3 light = normalize(float3(0.0,1.0,0.8)); 
             
				// color
				float3 col = lerp(
					getSkyColor(rd),
					getSeaColor(p,n,light,rd,dist),
    				pow(smoothstep(0.0,-0.05,rd.y),0.3));
				float val = t/10.;
                sceneCol.xyz = float3(val,val,val);
				//sceneCol.xyz = col;
                return sceneCol; 
            }
            ENDCG
        }//end pass  
    }//end SubShader 
    FallBack Off
}



