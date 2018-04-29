// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// 2018-04-13  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Mountain" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM

#pragma vertex vert   
#pragma fragment frag  
#include "ShaderLibs/Framework3D.cginc"

			
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
                // clouds
				col = Cloud(col,ro,rd,float3(1.0,0.95,1.0),1,1);
                // .
                col = lerp( col, 0.68*float3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
                sceneCol.xyz = col;
                return sceneCol;
            } 
            ENDCG
        }//end pass
    }//end SubShader
    FallBack Off
}



