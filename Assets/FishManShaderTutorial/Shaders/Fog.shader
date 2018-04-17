// create by JiepengTan 2018-04-13  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Fog" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (40.,128., 1, 1)
		_FogSpd ("_FogSpd", Vector) = (1.,0.,0.,0.5)
		_FogHighRange ("_FogHighRange", Vector) = (-5,10,0.,0.5)
		_FogCol ("_FogCol", COLOR) = (.025, .2, .125,0.)
		
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LoopNum = float4(40.,128.,0.,0.);
            float4 _FogSpd ;
			float4 _FogHighRange;
			fixed3 _FogCol;
			
#pragma vertex VertMergeRayMarch  
#pragma fragment FragMergeRayMarch  
#include "ShaderLibs/MergeRayMarch.cginc"
            // value noise, and its analytical derivatives
    				/*	*/
			#define ITR 100
			#define FAR 30.
			#define time _Time.y
			

			fixed fogmap(in fixed3 p, in fixed d)
			{
				p += _FogSpd.xyz * time;
				p.z += sin(p.x*.5);
				return tnoise(p*2.2/(d+20.),time, 0.2)*(1.-smoothstep(_FogHighRange.x,_FogHighRange.y,p.y));
			}
		
			fixed3 fog(in fixed3 col, in fixed3 ro, in fixed3 rd, in fixed mt)
			{
				fixed d = .4;
				for(int i=0; i<7; i++)
				{
					fixed3  pos = ro + rd*d;
					fixed rz = fogmap(pos, d);
					fixed3 col2 = _FogCol *( rz *0.5+0.5);
					col = lerp(col,col2,clamp(rz*smoothstep(d-0.4,d+2.+d*.75,mt),0.,1.) );
					d *= 1.5+0.3;
					if (d>mt)break;
				}
				return col;
			}
			

			fixed3 normal(in fixed3 p)
			{  
				return float3(0.,1.0,0.);
			}

			fixed march(in fixed3 ro, in fixed3 rd)
			{
				if (rd.y>=0.0) {
					return 100000;
				}
				float d = -(ro.y - 0.)/rd.y;
				d = min(100000.0, d);
				return d;
			}
            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
				fixed3 ligt = normalize( fixed3(.5, .05, -.2) );
				fixed3 ligt2 = normalize( fixed3(.5, -.1, -.2) );
    
				fixed rz = march(ro,rd);
	
				fixed3 fogb = lerp(fixed3(.7,.8,.8	)*0.3, fixed3(1.,1.,.77)*.95, pow(dot(rd,ligt2)+1.2, 2.5)*.25);
				fogb *= clamp(rd.y*.5+.6, 0., 1.);
				fixed3 col = fogb;
				
				if ( rz < FAR )
				{
					fixed3 pos = ro+rz*rd;
					fixed3 nor= normal( pos );
					fixed dif = clamp( dot( nor, ligt ), 0.0, 1.0 );
					fixed spe = pow(clamp( dot( reflect(rd,nor), ligt ), 0.0, 1.0 ),50.);
					col = lerp(fixed3(0.1,0.2,1),fixed3(.3,.5,1),pos.y*.5)*0.2+.1;
					col = col*dif + col*spe*.5 ;
				}
				//ordinary distance fog first
				if(rz>sceneDep){
					col = sceneCol;
					rz = sceneDep;
				}
				col = lerp(col, fogb, smoothstep(FAR-7.,FAR,rz));
				//then volumetric fog
				col = fog(col, ro, rd, rz);
				//post
				col = pow(col,float3(0.8,0.8,0.8));
                sceneCol.xyz = col;
                return sceneCol; 
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



