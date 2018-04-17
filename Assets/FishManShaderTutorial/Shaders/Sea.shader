Shader "FishManShaderTutorial/Sea" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (314.,1., 1, 1)
		_SeaBaseColor ("_SeaBaseColor", Color) = (0.1,0.19,0.22, 1) // color
		_SeaWaterColor ("_SeaWaterColor", Color) = (0.8,0.9,0.6) // color
		_SeaHeight ("_SeaHeight", float) = 5. // color
		
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM


#pragma vertex VertMergeRayMarch  
#pragma fragment FragMergeRayMarch  
#include "ShaderLibs/MergeRayMarch.cginc"

			float3 _SeaBaseColor;
			float3 _SeaWaterColor;
            float4 _LoopNum;
			float _SeaHeight;
			#define lightDir _WorldSpaceLightPos0 
			

			float wave(float2 uv, float2 emitter, float speed, float phase){
				float dst = distance(uv, emitter);
				return pow((0.5 + 0.5 * sin(dst * phase - time * speed)), 5.0);
			}
			float getwaves(float2 uv){
				float w = 0.0;
				float sw = 0.0;
				float iter = 0.0;
				float ww = 1.0;
				uv += time * 0.5;
				// it seems its absolutely fastest way for water height function that looks real
				for(int i=0;i<5;i++){
					w += ww * wave(uv * 0.06 , float2(sin(iter), cos(iter)) * 10.0, 2.0 + iter * 0.08, 2.0 + iter * 3.0);
					sw += ww;
					ww = lerp(ww, 0.0115, 0.4);
					iter += 2.39996;
				}
				return w / sw;
			}
			float getwavesH(float2 uv){
				float w = 0.0;
				float sw = 0.0;
				float iter = 0.0;
				float ww = 1.0;
				uv += time * 0.5;
				// it seems its absolutely fastest way for water height function that looks real
				for(int i=0;i<24;i++){
					w += ww * wave(uv * 0.06 , float2(sin(iter), cos(iter)) * 10.0, 2.0 + iter * 0.08, 2.0 + iter * 3.0);
					sw += ww;
					ww = lerp(ww, 0.0115, 0.4);
					iter += 2.39996;
				}
				return w / sw;
			}
	
			float heightMapTracing(float3 ro, float3 rd) {  
				float tmin = 0.1;
				float tmax = 1000;
				float t = tmin;
				for( int i=0; i< 314; i++ )
				{
					float3 p = ro + t*rd;
					float h = p.y - getwaves(p.xz)*_SeaHeight;
					if( h<0.002 || t>tmax ) break;
					t += 0.8*h;
				}
				return t;
			}
			
			// sky
			float3 getSkyColor(float3 e,float3 lightDir) {
				e.y = max(e.y,0.0);
				float3 col =  float3(pow(1.0-e.y,2.0), 1.0-e.y, 0.6+(1.0-e.y)*0.4);
				float val = pow(max(dot(e,lightDir),0.0),200.0);
				col += float3(val,val,val);
				return col;
			}
        
			float3 getSeaColor(float3 p, float3 n, float3 l, float3 eye, float3 dist) {  
				float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
				fresnel = pow(fresnel,3.0) * 0.65;
        
				float3 reflected = getSkyColor(reflect(eye,n),l);    
				float3 diff = pow(dot(n,l) * 0.4 + 0.6,3.);
				float3 refracted = _SeaBaseColor + diff * _SeaWaterColor * 0.12; 
    
				float3 col = lerp(refracted,reflected,fresnel);
    
				float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
				//col += _SeaWaterColor * (p.y - _SeaHeight) * 0.18 * atten;

				float nrm = (60. + 8.0) / (PI * 8.0);
				float spec=  pow(max(dot(reflect(eye,n),l),0.0),60.) * nrm;
				col += float3(spec,spec,spec);
    
				return col;
			}
			float3 calcnormal(float2 pos, float e){
				float2 ex = float2(e, 0);
				float H = getwavesH(pos.xy) * _SeaHeight;
				float3 a = float3(pos.x, H, pos.y);
				return normalize(cross(normalize(a-float3(pos.x - e, getwavesH(pos.xy - ex.xy) * _SeaHeight, pos.y)), 
									   normalize(a-float3(pos.x, getwavesH(pos.xy + ex.yx) * _SeaHeight, pos.y + e))));
			}

            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
				float3 t = heightMapTracing(ro,rd);
				float3 p = ro + t * rd;
				float3 dist = p - ro;
				float3 n = calcnormal(p.xz,0.0005);
             
				// color
				float3 col = lerp(
					getSkyColor(rd,lightDir),
					getSeaColor(p,n,lightDir,rd,dist),
    				pow(smoothstep(0.0,-0.05,rd.y),0.3));
				float val = p.y;
                sceneCol.xyz = float3(val,val,val);
				sceneCol.xyz = col;
                return sceneCol; 
            }
            ENDCG
        }//end pass  
    }//end SubShader 
    FallBack Off
}



