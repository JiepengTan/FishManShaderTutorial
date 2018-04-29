// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-13  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Desert" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (40.,128., 1, 1)
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LoopNum = float4(40.,128.,0.,0.);
#pragma vertex vert  
#pragma fragment frag  
#include "ShaderLibs/Framework3D.cginc"
			float terrainH( in float2 p)
			{
				//middle
				float valM = PNoise(p * 0.26) + 0.5;//0~1
				valM = 1.0 - abs(valM - 0.5) * 2.0;
				valM = pow(valM,2.0);
    
				//big
				float valB = smoothstep(0.0,1.0,PNoise(p * 0.2) + 0.5);//0~1
				float val =  valB * 0.8 +valM * 0.19*pow(valB,2.0) ;
				return val * _LoopNum.z;
			}

			float softShadow(in float3 ro, in float3 rd )
			{
				// real shadows 
				float res = 1.0;
				float t = 0.001;
				for( int i=0; i<_LoopNum.x; i++ )
				{
					float3  p = ro + t*rd;
					float h = p.y - terrainH( p.xz );
					res = min( res, 16.0*h/t );
					t += h;
					if( res<0.01 ||p.y>(200.0) ) break;
				}
				return clamp( res, 0.0, 1.0 );
			}


			float interesct( in float3 ro, in float3 rd, in float tmin, in float tmax )
			{
				float t = tmin;
				for( int i=0; i<_LoopNum.y; i++ )
				{
					float3 pos = ro + t*rd;
					float h = pos.y - terrainH( pos.xz );
					if( h<(0.002*t) || t>tmax ) break;
					t += 0.5*h;
				}
				return t;
			}


			float3 calcNormal( in float3 pos, float t )
			{
				float2  eps = float2( 0.002*t, 0.0 );
				return normalize( float3( terrainH(pos.xz-eps.xy) - terrainH(pos.xz+eps.xy),
										2.0*eps.x,
										terrainH(pos.xz-eps.yx) - terrainH(pos.xz+eps.yx) ) );
			}
		
			float3 render( in float3 ro, in float3 rd )
			{   
				float3 lightDir = normalize( float3(-0.8,0.3,-0.3) );
				float3 lightColor = float3(1.0,1.0,1.0);
				float3 sandColor = float3(0.9,0.70,0.4);
				float3 ambientColor = float3(0.5,0.5,0.5);

				float tmin = 0.1;
				float tmax = 30.0;
				float t = interesct(ro,rd,tmin,tmax);

				float3 col;
				if(t>tmax){
					float3 sky0 = float3(0.8,0.7,0.5) * 1.2;
					float3 sky1 = float3(0.4,0.6,0.8) * 1.2;
					col = lerp(sky0,sky1,pow(max(rd.y + 0.15,0.0),0.5));
					float val = pow(max(dot(rd,lightDir),0.0),200.0);
					col += float3(val,val,val);
				}
				else{
					float3 pos = ro + t*rd;
        
					float shadow = softShadow(pos + lightDir *0.01,lightDir);
        
					float3 normal = calcNormal( pos, t );
					normal = normalize(normal + float3(sin(pos.x * 100.0 + sin(pos.z * 31.0) + sin(pos.y) * 200.0) * 0.02,0,0));
					float3 viewDir = -rd;

					float lambertian = max(dot(lightDir,normal), 0.0);

					float shininess =  20.0;
					float3 fixedDir = normalize(lightDir + viewDir);
					float specAngle = max(dot(fixedDir, normal), 0.0);
					float specular1 = pow(specAngle, shininess);
					float specular2 = pow(specAngle, shininess / 2.0) * pow(tex2D(_MainTex,pos.xz * 10.0).x,3.0);

					float3 diff = sandColor * lambertian * lightColor;
					float3 spec = (specular1 *0.3 + specular2 * 0.2) * lightColor;
					float3 ambient = ambientColor * sandColor;
					col = shadow * (diff + spec) + ambient;
				}
				return col;
			}
		

            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
                sceneCol.xyz = render(ro,rd);
                return sceneCol; 
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



