// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-13  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/HighlandLake" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (40.,128., 1, 1)
		_BaseWaterColor ("_BaseWaterColor", COLOR) = (.025, .2, .125,0.)
		_LightWaterColor ("_LightWaterColor", COLOR) = (.025, .2, .125,0.)
		waterHeight ("waterHeight", float) =1.0
		SC ("SC", float) =15
		waterTranDeep ("waterTranDeep", float) =5
    }
    SubShader{ 
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LoopNum = float4(40.,128.,0.,0.);
#pragma vertex vert  
#pragma fragment frag  
#include "ShaderLibs/Framework3D_Terrain.cginc" 
			
			float3 _BaseWaterColor;
			float3 _LightWaterColor;
			
			float waterTranDeep = 5;
			
			float waterHeight = 4.;
			float SC = 15;

			float WaterMap( fixed3 pos ) {
				return FBM( fixed3( pos.xz, ftime )) * 1;
			}

			float3 WaterNormal(float3 pos,float rz){
				float EPSILON = 0.003*rz*rz;
				float3 dx = float3( EPSILON, 0.,0. );
				float3 dz = float3( 0.,0., EPSILON );
					
				float3	normal = float3( 0., 1., 0. );
				float bumpfactor = 0.4 * pow(1.-clamp((rz)/1000.,0.,1.),6.);//根据距离所见Bump幅度
				
				normal.x = -bumpfactor * (WaterMap(pos + dx) - WaterMap(pos-dx) ) / (2. * EPSILON);
				normal.z = -bumpfactor * (WaterMap(pos + dz) - WaterMap(pos-dz) ) / (2. * EPSILON);
				return normalize( normal );	
			}

			#define Terrain(pos,NUM)\
                float2  p = pos.xz*0.003/SC;\
                float a = 0.0;\
                float b = 1.0;\
                float2  d = float2(0.0,0.0);\
                for( int i=0; i<NUM; i++ ){\
                    float n = Noised(p).x;\
                    a += b*n;\
                    b *= 0.5;\
                    p = p*2.0;\
                }\
				return float2(pos.y - SC*120.0*a,1.);

            float2 TerrainL(float3 pos){ 
                Terrain(pos,9.);
            } 
            float2 TerrainM(float3 pos){
                Terrain(pos,9.);
            } 
            float2 TerrainH(float3 pos){
                Terrain(pos,9.);
            }  


			
			float3 RenderMountain(float3 ro,float3 rd,float rz){
				float3 col = float3(0.,0.,0.);
				float3 pos = ro + rz * rd;
				float3 nor = NormalTerrian(pos,rz);

                float3 ref = reflect( rd, nor );
                float fre = clamp( 1.0+dot(rd,nor), 0.0, 1.0 );
                float3 hal = normalize(_LightDir-rd);
        
                // rock
                float r = tex2D( _NoiseTex, (7.0/SC)*pos.xz/256.0 ).x;
                col = (r*0.25+0.75)*0.9*lerp( float3(0.08,0.05,0.03), float3(0.10,0.09,0.08), tex2D(_NoiseTex,0.00007*float2(pos.x,pos.y*48.0)/SC).x );
                col = lerp( col, 0.20*float3(0.45,.30,0.15)*(0.50+0.50*r),smoothstep(0.70,0.9,nor.y) );
                col = lerp( col, 0.15*float3(0.30,.30,0.10)*(0.25+0.75*r),smoothstep(0.95,1.0,nor.y) );

                // lighting     
                float amb = clamp(0.5+0.5*nor.y,0.0,1.0);
                float dif = clamp( dot( _LightDir, nor ), 0.0, 1.0 );
                float bac = clamp( 0.2 + 0.8*dot( normalize( float3(-_LightDir.x, 0.0, _LightDir.z ) ), nor ), 0.0, 1.0 );

				//shadow
                float sh = .0; 
                if( dif>=0.0001 ) sh = SoftShadow(pos+_LightDir*SC*0.05,_LightDir,SC*200.0);
        
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
				float sundot = clamp(dot(rd,_LightDir),0.0,1.0);
				float rz = RaycastTerrain(ro,rd);
				float firstInsertRZ = min(rz,waterT);
				float fresnel = 0;
				float3 refractCol = float3(0.,0.,0.);
				bool reflected = false;
				// hit the water
				if(rz >= waterT && rd.y < -0.01){
					float3 waterPos = ro + rd * waterT; 
					float3 nor = WaterNormal(waterPos,waterT);
					float ndotr = dot(nor,-rd);
					fresnel = pow(1.0-abs(ndotr),6.);//计算  
					float3 diff = pow(dot(nor,_LightDir) * 0.4 + 0.6,3.);
					// get the water col 
					float3 waterCol = _BaseWaterColor + diff * _LightWaterColor * 0.12; 
					float transPer = pow(1.0-clamp( rz - waterT,0,waterTranDeep)/waterTranDeep,3.);
					// get refract bg col
					float3 bgCol = RenderMountain(ro,rd + nor* clamp(1.-dot(rd,-nor),0.,1.),rz);
					refractCol = lerp(waterCol,bgCol,transPer);

					ro = waterPos;
					rd = reflect( rd, nor);
					rz = RaycastTerrain(ro,rd);
					reflected = true;
					col = refractCol; 
				}
				if(rz >= maxT){
					col = Sky( ro, rd,_LightDir);
				}else{
					col = RenderMountain(ro,rd,rz);
				}
				if( reflected == true ) {
					col = lerp(refractCol,col,fresnel);
					float spec=  pow(max(dot(rd,_LightDir),0.0),128.) * 3.;
					col += float3(spec,spec,spec);
				}
				
				MergeUnityIntoRayMarching(firstInsertRZ,col,sceneDep,sceneCol); 
                sceneCol.xyz = col;

                return sceneCol;
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



