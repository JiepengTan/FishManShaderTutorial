// create by JiepengTan 2018-04-16  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/HighlandLake" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (40.,128., 1, 1)
		_BaseWaterColor ("_BaseWaterColor", COLOR) = (.025, .2, .125,0.)
		_LightWaterColor ("_LightWaterColor", COLOR) = (.025, .2, .125,0.)
		_TerrialHeigMap("_TerrialHeigMap", 2D) = "white" {}
		waterHeight ("waterHeight", float) =1.0
		//lightDir ("lightDir", Vector) =(-0.8,0.4,-0.3,0.)
		SC ("SC", float) =15
		waterTranDeep ("waterTranDeep", float) =5
    }
    SubShader{ 
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LoopNum = float4(40.,128.,0.,0.);
#pragma vertex VertMergeRayMarch  
#pragma fragment FragMergeRayMarch  
#include "ShaderLibs/MergeRayMarch.cginc" 
			
			float3 _BaseWaterColor;
			float3 _LightWaterColor;
			sampler2D _TerrialHeigMap;
			
			float waterTranDeep = 5;
			
			float waterHeight = 4.;
			#define lightDir (_WorldSpaceLightPos0.xyz)
			float SC = 15;
			const float2x2 m2 = float2x2( 0.60, -0.80, 0.80, 0.60 );
			const float3x3 m3 = float3x3( 0.00,  0.80,  0.60,
										 -0.80,  0.36, -0.48,
										 -0.60, -0.48,  0.64 );

			float FBM( in float3 p ) {
				float f = 0.0;
				f += 0.5000*noise( p ); p = mul(m3,p)*2.02;
				f += 0.2500*noise( p ); p = mul(m3,p)*2.03;
				f += 0.1250*noise( p ); p = mul(m3,p)*2.01; 
				f += 0.0625*noise( p );
				return f/0.9375;
			}

			float FBM( in float2 p ) {
				float f = 0.0;
				f += 0.5000*noise( p ); p = mul(m2,p)*2.02;
				f += 0.2500*noise( p ); p = mul(m2,p)*2.03;
				f += 0.1250*noise( p ); p = mul(m2,p)*2.01; 
				f += 0.0625*noise( p );
				return f/0.9375;
			}

			float WaterMap( fixed3 pos ) {
				return fbm( fixed3( pos.xz, ftime )) * 1;
			}

			float3 WaterNormal(float3 pos,float rz){
				float EPSILON = 0.01;
				float3 dx = float3( EPSILON, 0.,0. );
				float3 dz = float3( 0.,0., EPSILON );
					
				float3	normal = float3( 0., 1., 0. );
				float bumpfactor = 0.3 * pow(1.-clamp((rz)/100.,0.,1.),6.);//根据距离所见Bump幅度
				
				normal.x = -bumpfactor * (WaterMap(pos + dx) - WaterMap(pos-dx) ) / (2. * EPSILON);
				normal.z = -bumpfactor * (WaterMap(pos + dz) - WaterMap(pos-dz) ) / (2. * EPSILON);
				return normalize( normal );	
			}

			float3 RayMarchCloud(float3 ro,float3 rd){
				fixed3 col = fixed3(0.0,0.0,0.0);  
				float sundot = clamp(dot(rd,lightDir),0.0,1.0);
               
                 // sky      
                col = float3(0.2,0.5,0.85)*1.1 - rd.y*rd.y*0.5;
                col = lerp( col, 0.85*float3(0.7,0.75,0.85), pow( 1.0-max(rd.y,0.0), 4.0 ) );
                // sun
                col += 0.25*float3(1.0,0.7,0.4)*pow( sundot,5.0 );
                col += 0.25*float3(1.0,0.8,0.6)*pow( sundot,64.0 );
                col += 0.4*float3(1.0,0.8,0.6)*pow( sundot,512.0 );
                // clouds
				col = Cloud(col,ro,rd,float3(1.0,0.95,1.0),1,1);
                // .
                col = lerp( col, 0.68*float3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
				return col;
			}
			float TerrainHigh( in float2 x ) {
				float2  p = x*0.003/SC;
                float a = 0.0;
                float b = 1.0;
                float2  d = float2(0.0,0.0);
                for( int i=0; i<9; i++ )
                {
                    float3 n = noised(p);
                    d += n.yz;
                    a += b*n.x;
                    b *= 0.5;
                    p = p*2.0;
                }

                return SC*120.0*a;
			}


			float InteresctTerrial( in float3 ro, in float3 rd, in float tmin, in float tmax )
            {
                float t = tmin;
                for( int i=0; i<218; i++ ) 
                {
                    float3 p = ro + t*rd;
                    float h = p.y - TerrainHigh( p.xz );
                    if( h<(0.002*t) || t>tmax ) break;
                    t += 0.5*h;
                }
                return t; 
            }
			float SoftShadow(in float3 ro, in float3 rd )
            {
                float res = 1.0;
                float t = 0.001;
                for( int i=0; i<80; i++ )
                {
                    float3  p = ro + t*rd;
                    float h = p.y - TerrainHigh( p.xz );
                    res = min( res, 16.0*h/t );
                    t += h;
                    if( res<0.001 ||p.y>(SC*200.0) ) break;
                }
                return clamp( res, 0.0, 1.0 );
            }



            float3 CalcTerrianNormal( in float3 pos, float t )
            {
                float2  eps = float2( 0.002*t, 0.0 );
                return normalize( float3( TerrainHigh(pos.xz-eps.xy) - TerrainHigh(pos.xz+eps.xy),
                                        2.0*eps.x,
                                        TerrainHigh(pos.xz-eps.yx) - TerrainHigh(pos.xz+eps.yx) ) );
            }
			
			float3 RayMarchTerrial(float3 ro,float3 rd,float rz){
				float3 col = float3(0.,0.,0.);
				float3 pos = ro + rz * rd;
				float3 nor = CalcTerrianNormal(pos,rz);

                float3 ref = reflect( rd, nor );
                float fre = clamp( 1.0+dot(rd,nor), 0.0, 1.0 );
                float3 hal = normalize(lightDir-rd);
        
                // rock
                float r = tex2D( _NoiseTex, (7.0/SC)*pos.xz/256.0 ).x;
                col = (r*0.25+0.75)*0.9*lerp( float3(0.08,0.05,0.03), float3(0.10,0.09,0.08), tex2D(_NoiseTex,0.00007*float2(pos.x,pos.y*48.0)/SC).x );
                col = lerp( col, 0.20*float3(0.45,.30,0.15)*(0.50+0.50*r),smoothstep(0.70,0.9,nor.y) );
                col = lerp( col, 0.15*float3(0.30,.30,0.10)*(0.25+0.75*r),smoothstep(0.95,1.0,nor.y) );

                // lighting     
                float amb = clamp(0.5+0.5*nor.y,0.0,1.0);
                float dif = clamp( dot( lightDir, nor ), 0.0, 1.0 );
                float bac = clamp( 0.2 + 0.8*dot( normalize( float3(-lightDir.x, 0.0, lightDir.z ) ), nor ), 0.0, 1.0 );

				//shadow
                float sh = .0; 
                if( dif>=0.0001 ) sh = SoftShadow(pos+lightDir*SC*0.05,lightDir);
        
				// 
                float3 lin  = float3(0.0,0.0,0.0);
                lin += dif*float3(7.00,5.00,3.00)*1.3*float3( sh, sh*sh*0.5+0.5*sh, sh*sh*0.8+0.2*sh );
                lin += amb*float3(0.40,0.60,1.00)*1.2;
                lin += bac*float3(0.40,0.50,0.60);
                col *= lin;
        
                // fog
                float fo = 1.0-exp(-pow(0.001*rz/SC,1.5));
                float3 fco = 0.65*float3(0.4,0.65,1.0);// + 0.1*float3(1.0,0.8,0.5)*pow( sundot, 4.0 );
				col = lerp( col, fco, fo );
				return col;
			}
            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){  
				float maxT = 10000;
				float minT = 0.1;
				float3 col  = float3 (0.,0.,0.);
				float waterT = maxT;
				if(rd.y <-0.01){
					float t = -(ro.y - waterHeight)/rd.y;
					waterT = min(waterT,t);
				}
				float sundot = clamp(dot(rd,lightDir),0.0,1.0);

				float rz = InteresctTerrial(ro,rd,minT,maxT);
				float fresnel = 0;
				float3 refractCol = float3(0.,0.,0.);
				bool reflected = false;
				// hit the water
				if(rz >= waterT && rd.y < -0.01){
					float3 waterPos = ro + rd * waterT; 
					float3 nor = WaterNormal(waterPos,waterT);
					float ndotr = dot(nor,-rd);
					fresnel = pow(1.0-abs(ndotr),6.);//计算 
					float3 diff = pow(dot(nor,lightDir) * 0.4 + 0.6,3.);
					// get the water col 
					float3 waterCol = _BaseWaterColor + diff * _LightWaterColor * 0.12; 
					float transPer = pow(1.0-clamp( rz - waterT,0,waterTranDeep)/waterTranDeep,3.);
					float3 bgCol = RayMarchTerrial(ro,rd + nor* clamp(1.-dot(rd,-nor),0.,1.),rz);
					refractCol = lerp(waterCol,bgCol,transPer);

					ro = waterPos;
					rd = reflect( rd, nor);
					rz = InteresctTerrial(ro,rd,minT,maxT);
					reflected = true;
					col = refractCol;
				}
				if(rz >= maxT){
					col = RayMarchCloud( ro, rd);
				}else{
					col = RayMarchTerrial(ro,rd,rz);
				}
				if( reflected == true ) {
					col = lerp(refractCol,col,fresnel);
					float nrm = (60. + 8.0) / (PI * 8.0);
					float spec=  pow(max(dot(rd,lightDir),0.0),128.) * nrm;
					col += float3(spec,spec,spec);
				}
				
				/**/
				// sun scatter
                //col += 0.3*float3(1.0,0.7,0.3)*pow( sundot, 8.0 );
                // gamma
                //col = sqrt(col);
                sceneCol.xyz = col;

                return sceneCol;
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



