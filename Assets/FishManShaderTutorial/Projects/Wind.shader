Shader "FishManShaderTutorial/Wind" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (40.,128., 1, 1)
		_DirSpd ("_DirSpd", Vector) = (1.,0.,0.,0.5)
		_WindHighRange ("_WindHighRange", Vector) = (-5,10,0.,0.5)
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LoopNum = float4(40.,128.,0.,0.);
            float4 _DirSpd ;
			float4 _WindHighRange;
			
#pragma vertex VertMergeRayMarch  
#pragma fragment FragMergeRayMarch  
#include "ShaderLibs/MergeRayMarch.cginc"
            // value noise, and its analytical derivatives
    				/*	*/
			#define ITR 100
			#define FAR 30.
			#define time _Time.y
			fixed2x2 mm2(in fixed a){fixed c = cos(a), s = sin(a);return fixed2x2(c,s,-s,c);}
			 
			fixed height(in fixed2 p)
			{
				p *= 0.2;
				return sin(p.y)*0.4 + sin(p.x)*0.4;
			}

			//smooth min form iq
			fixed smin( fixed a, fixed b)
			{
				const fixed k = 0.7;
				fixed h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
				return lerp( b, a, h ) - k*h*(1.0-h);
			}

			//form Dave
			fixed2 hash22(fixed2 p)
			{
				p  = frac(p * fixed2(5.3983, 5.4427));
				p += dot(p.yx, p.xy +  fixed2(21.5351, 14.3137));
				return frac(fixed2(p.x * p.y * 95.4337, p.x * p.y * 97.597));
			}

		

			fixed tri(in fixed x){return abs(frac(x)-.5);}
			fixed3 tri3(in fixed3 p){return fixed3( tri(p.z+tri(p.y*1.)), tri(p.z+tri(p.x*1.)), tri(p.y+tri(p.x*1.)));}
                                 
			fixed2x2 m2 = fixed2x2(0.970,  0.242, -0.242,  0.970);

			fixed triNoise3d(in fixed3 p, in fixed spd)
			{
				fixed z=1.4; 
				fixed rz = 0.;
				fixed3 bp = p;
				for (fixed i=0.; i<=3.; i++ )
				{
					fixed3 dg = tri3(bp*2.);
					p += dg + spd * time;

					bp *= 1.8;
					z *= 1.5;
					p *= 1.2;
					//p.xz*= m2;
        
					rz+= (tri(p.z+tri(p.x+tri(p.y))))/z;
					bp += 0.14;
				}
				return rz;
			}

			fixed fogmap(in fixed3 p, in fixed d)
			{
				p += _DirSpd.xyz *_DirSpd.w* time;
				p.z += sin(p.x*.5);
				return triNoise3d(p*2.2/(d+20.), 0.2)*(1.-smoothstep(_WindHighRange.x,_WindHighRange.y,p.y));
			}

			fixed3 fog(in fixed3 col, in fixed3 ro, in fixed3 rd, in fixed mt)
			{
				fixed d = .4;
				for(int i=0; i<7; i++)
				{
					fixed3  pos = ro + rd*d;
					fixed rz = fogmap(pos, d);
					fixed grd =  clamp((rz - fogmap(pos+.8-fixed(i)*0.1,d))*3., 0.1, 1. );
					fixed3 col2 = (fixed3(.1,0.8,.5)*.5 + .5*fixed3(.5, .8, 1.)*(1.7-grd))*0.55;
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
				//col *= 1.-smoothstep(0.1,2.,length(p));
                sceneCol.xyz = col;
                return sceneCol; 
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



