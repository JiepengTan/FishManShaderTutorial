Shader "FishManShaderTutorial/Cloud2" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
        _LoopNum ("_LoopNum", Vector) = (17.,128., 1, 1)
        _NoiseTex("_NoiseTex", 2D) = "white" {}
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            //#define USING_TEXLOD_NOISE 0
#pragma vertex VertMergeRayMarch  
#pragma fragment FragMergeRayMarch  
#include "ShaderLibs/MergeRayMarch.cginc"

            float4 _LoopNum ;


			fixed map5( in fixed3 p )
			{
				fixed3 q = p;// - fixed3(0.0,0.1,1.0)*_Time.y;
				fixed f;
				f  = 0.50000*noise( q ); q = q*2.02;
				f += 0.25000*noise( q ); q = q*2.03;
				f += 0.12500*noise( q ); q = q*2.01;
				f += 0.06250*noise( q ); q = q*2.02;
				f += 0.03125*noise( q );
				return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
			}

			fixed map4( in fixed3 p )
			{
				fixed3 q = p;// - fixed3(0.0,0.1,1.0)*_Time.y;
				fixed f;
				f  = 0.50000*noise( q ); q = q*2.02;
				f += 0.25000*noise( q ); q = q*2.03;
				f += 0.12500*noise( q ); q = q*2.01;
				f += 0.06250*noise( q );
				return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
			}
			fixed map3( in fixed3 p )
			{
				fixed3 q = p ;//- fixed3(0.0,0.1,1.0)*_Time.y;
				fixed f;
				f  = 0.50000*noise( q ); q = q*2.02;
				f += 0.25000*noise( q ); q = q*2.03;
				f += 0.12500*noise( q );
				return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
			}
			fixed map2( in fixed3 p )
			{
				fixed3 q = p;// - fixed3(0.0,0.1,1.0)*_Time.y;
				fixed f;
				f  = 0.50000*noise( q ); q = q*2.02;
				f += 0.25000*noise( q );;
				return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
			}

			fixed3 sundir = normalize( fixed3(1.0,1.0,1.0) );

			fixed4 integrate( in fixed4 sum, in fixed dif, 
						   in fixed den, in fixed3 bgcol, in fixed t )
			{
				// lighting
				//模拟密度变化 面朝阳光方向的方向的
				//密度的增加对于阳光的穿透效应
				fixed3 lin = fixed3(0.65,0.7,0.75)*1.4 + fixed3(1.0, 0.6, 0.3)*dif;
				fixed4 col = fixed4( lerp( fixed3(1.0,0.95,0.8), 
									 fixed3(0.25,0.3,0.35), den ), den );//浓度也高颜色越深
				col.xyz *= lin;
				col.xyz = lerp( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );//越远的地方 越多的背景色
				// front to back blending    
				col.a *= 0.4;
				col.rgb *= col.a;
				return sum + col*(1.0-sum.a);//当层透明效果一层层 的叠加上去 
			}
			#define MARCH(STEPS,MAPLOD) \
			for(int i=0; i<STEPS; i++) \
			{ fixed3  pos = ro + t*rd; \
				if( pos.y<-3.0 || pos.y>2.0 || sum.a > 0.99 ) break;\
				 fixed den = MAPLOD( pos ); if( den>0.01 ) \
				{ \
				fixed dif =  clamp((den - MAPLOD(pos+0.3*sundir))/0.6, 0.0, 1.0 );\
					sum = integrate( sum, dif, den, bgcol, t ); \
				} \
				t += max(0.05,0.02*t); \
			}\

			fixed4 raymarch( in fixed3 ro, in fixed3 rd, in fixed3 bgcol )
			{
				fixed4 sum = fixed4(0.0,0.0,0.0,0.0);

				fixed t = 0.0;//0.05*tex2D( _MainTex, px&255, 0 ).x;

				MARCH(_LoopNum.x,map5);
				MARCH(_LoopNum.x,map5); 
				MARCH(_LoopNum.x,map5);
				MARCH(_LoopNum.x,map5);

				return clamp( sum, 0.0, 1.0 );
			}

		
			fixed4 render( in fixed3 ro, in fixed3 rd )
			{
				// background sky     
				fixed sun = clamp( dot(sundir,rd), 0.0, 1.0 );
				fixed3 col = fixed3(0.6,0.71,0.75) 
					//- rd.y*0.2*fixed3(1.0,0.5,1.0) 
					+ 0.15*0.5;
				col += 0.2*fixed3(1.0,.6,0.1)*pow( sun, 8.0 );

				// clouds    
				fixed4 res = raymarch( ro, rd, col );
				col = col*(1.0-res.w) + res.xyz;//在函数里面已经乘了alpha
    
				// sun glare    
				col += 0.2*fixed3(1.0,0.4,0.2)*pow( sun, 3.0 );

				return fixed4( col, 1.0 );
			}



//-------------------------------------------------


            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
                //col *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.12 ); //Vign
                sceneCol.xyz = render( ro, rd );
                return sceneCol; 
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



