// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-13  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Cloud" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
			//#define USING_VALUE_NOISE 1
#pragma vertex vert   
#pragma fragment frag  
#include "ShaderLibs/Framework3D.cginc"
 
            float4 MapCloud(float3 pos){
                float d = 1.0-0.3*abs(3.8 - pos.y);
                d -= 1.6 * FBM( pos*0.3 );
                d = clamp( d, 0.0, 1.0 );
                float4 res = float4(d,d,d,d);
                res.xyz = lerp( 0.8*float3(1.0,0.95,0.9), 0.2*float3(0.6,0.6,0.6), res.x );
                res.xyz *= 0.65;
                return res; 
            }

            float3 RenderCloud(float3 bgCol,float3 ro,float3 rd,float tmax){
                float4 sum = float4(0., 0., 0., 0.);
                float dif = clamp( dot(rd,_LightDir), 0.0, 1.0 );
                float t = 0.1;
                for(int i=0; i<64.; i++) {
                    if( sum.w > 0.99 || t > tmax ) break;
                    float3 pos = ro + t*rd;
                    float4 col = MapCloud( pos );
                    col.xyz *= float3(0.4,0.52,0.6);
                    col.xyz += float3(1.0,0.7,0.4)*0.3*pow( dif, 6.0 )*(1.0-col.w);
                    col.xyz = lerp( col.xyz, bgCol, 1.0-exp(-0.0018*t*t) );
                    col.a *= 0.5;
                    col.rgb *= col.a;
                    sum = sum + col*(1.0 - sum.a);  
                    t += max(0.1,0.05*t);
                }
                sum =  clamp( sum, 0.0, 1.0 );
                return bgCol*(1.0-sum.w) + sum.xyz;
            }
            
            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol)  {
                fixed3 col = fixed3(0.0,0.0,0.0);  
                float3 light1 = normalize( float3(-0.8,0.4,-0.3) );
                float sundot = clamp(dot(rd,light1),0.0,1.0);
               
                 // sky      
                col = float3(0.2,0.5,0.85)*1.1 - rd.y*rd.y*0.5;
                col = lerp( col, 0.85*float3(0.7,0.75,0.85), pow( 1.0-max(rd.y,0.0), 4.0 ) );
                // sun
                col += 0.25*float3(1.0,0.7,0.4)*pow( sundot,5.0 );
                col += 0.25*float3(1.0,0.8,0.6)*pow( sundot,64.0 );
                col += 0.2*float3(1.0,0.8,0.6)*pow( sundot,512.0 );
                // .
                col = RenderCloud(col,ro,rd,200.);
                //col = lerp( col, 0.68*float3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
                // clouds
                //float val  = VNoise(float3(uv*10.,0.));
                //col.xyz = float3(val,val,val);
                sceneCol.xyz = col;
                return sceneCol;
            } 
            ENDCG
        }//end pass
    }//end SubShader
    FallBack Off
}



