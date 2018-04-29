// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// date: 2018-03-27  
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/BaseMath"{
	Properties{
	    _MainTex ("MainTex", 2D) = "white" {}
	}

	SubShader
	{
	    Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }

	    Pass
	    {
	        ZWrite Off
	        Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

	        CGPROGRAM
	        #pragma vertex vert
	        #pragma fragment frag
			#define USING_PERLIN_NOISE 1
			#include "ShaderLibs/Framework2D.cginc"
	
			#define DrawInGrid(uv,DRAW_FUNC)\
				{\
					float2 pFloor = floor(uv);\
					if(length(pFloor-float2(j,i))<0.1){\
						col = DRAW_FUNC(frac(uv)-0.5);\
					}\
					num = num + 1.000;\
					i=floor(num / gridSize); j=fmod(num,gridSize);\
				}\

				
			float3 DrawSmoothstep(float2 uv){
				uv+=0.5;
				float val = smoothstep(0.0,1.0,uv.x);
				val = step(abs(val-uv.y),0.01); 
				return float3(val,val,val);
			}
			float3 DrawCircle(float2 uv){
				float val = clamp((1.0-length(uv)*2),0.,1.);
				return float3(val,val,val);
			}
			float3 DrawFlower(float2 uv){
				float deg = atan2(uv.y,uv.x) + _Time.y * -0.1;
				float len = length(uv)*3.0;
				float offs = abs(sin(deg*3.))*0.35;
				return smoothstep(1.+offs,1.+offs-0.05,len);
			}
			float3 DrawWeakCircle(float2 uv){
				float val = clamp((1.0-length(uv)*2),0.,1.);
				val = pow(val,2.0);
				return float3(val,val,val);
			}
			float3 DrawStrongCircle(float2 uv){
				float val = clamp((1.0-length(uv)*2),0.,1.);
				val = pow(val,0.5);
				return float3(val,val,val);
			}
			float3 DrawBounceBall(float2 uv){
				uv*=4.;
				uv.y+=sin(ftime*PI);
				float val = clamp((1.0-length(uv)),0.,1.);
				val = smoothstep(0.,0.05,val);
				return float3(val,val,val);
			}
			float3 DrawRandomColor(float2 uv){
				uv+=0.5;
				uv*=4.;
				return Hash32(floor(uv));
			}
			float3 DrawNoise(float2 uv){
				uv*=4.;
				float val =(PNoise(uv)+1.0)*0.5;
				return float3(val,val,val);
			}
			float3 DrawFBM(float2 uv){
				uv*=4.;
				float val = (FBM(uv)+1.0)*0.5;
				return float3(val,val,val);
			}
			//绘制格子线
			float3 DrawGridLine(float2 uv){
				float2 _uv = uv-floor(uv);
				float val = 0.;
				const float eps = 0.01;
				if(_uv.x<eps||_uv.y<eps){
					val = 1.;
				}
				return float3(val,val,val);
			}

			float3 ProcessFrag(float2 uv)  {
			    float3 col = float3(0.0,0.0,0.0);
			    float num = 0.;
				float gridSize = 3.;
				float i =0.,j=0.;
				uv*=gridSize;
				DrawInGrid(uv,DrawSmoothstep);
				DrawInGrid(uv,DrawCircle);
				DrawInGrid(uv,DrawFlower);
				DrawInGrid(uv,DrawWeakCircle);
				DrawInGrid(uv,DrawStrongCircle);
				DrawInGrid(uv,DrawBounceBall);
				DrawInGrid(uv,DrawRandomColor);
				DrawInGrid(uv,DrawNoise);
				DrawInGrid(uv,DrawFBM);

				col +=DrawGridLine(uv);
				return col;			
			}
	    ENDCG
	}//end pass
  }//end SubShader
}//end Shader

