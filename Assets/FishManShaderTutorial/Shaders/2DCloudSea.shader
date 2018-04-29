// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// date: 2018-03-27  
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/2DCloudSea"{
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

	        CGPROGRAM
	        #pragma vertex vert
	        #pragma fragment frag
			#include "ShaderLibs/Framework2D.cginc"
	
			#define LAYER 22.0
			fixed Wave(float layer,fixed2 uv,fixed val){
				float amplitude =  layer*layer*0.00004;
				float frequency = val*200*uv.x/layer;
				float phase = 9.*layer+ _Time.z/val;
				return amplitude*sin(frequency+phase); 
			}
			float Circle(fixed2 uv,fixed2 center,float size,float blur){
				uv = uv - center;
				uv /= size;
				float len = length(uv);
				return smoothstep(1.,1.-blur,len);
			}
			float AngleCircle(fixed2 uv,fixed2 center,float size,float blur){
				uv = uv - center;
				uv /= size;
				float deg = atan2(uv.y,uv.x) + _Time.y * -0.1;
				float len = length(uv);
				float offs =( sin(deg*9)*3.+sin(deg*11+sin(_Time.y*6)*.5))*0.05;
				return smoothstep(1.+offs,1.-blur+offs,len);
			}

			float DrawCloud(fixed2 uv,fixed2 center,float size){
				uv = uv - center;
				uv /= size;
				float col = Circle(uv,fixed2(0.,0.),0.2,0.05);
				col =col *  smoothstep(-0.1,-0.1+0.01,uv.y);
				col += Circle(uv,fixed2(0.15,-0.05),0.1,0.05);
				col += Circle(uv,fixed2(0.,-0.1),0.11,0.05);
				col += Circle(uv,fixed2(-0.15,-0.1),0.1,0.05);
				col += Circle(uv,fixed2(-0.3,-0.08),0.1,0.05);
				col += Circle(uv,fixed2(-0.2,0.),0.15,0.05);
				return col;
			}
			float DrawClouds(fixed2 uv){
				uv.x += 0.03*_Time.y;
				uv.x = frac(uv.x+0.5) - 0.5;
				float col = DrawCloud( uv,fixed2(-0.4,0.3),0.2);
				col += DrawCloud( uv,fixed2(-0.2,0.42),0.2);
				col += DrawCloud( uv,fixed2(0.0,0.4),0.2);
				col += DrawCloud( uv,fixed2(0.15,0.3),0.2);
				col += DrawCloud( uv,fixed2(0.45,0.45),0.2);
				return col;
			}
			float3 ProcessFrag(float2 uv)  {
			    float3 col = float3(0.0,0.0,0.0);
			    float num = 0.;
			    for (float i=1.; i < LAYER; i++) {
			    	float wave = 2.*Wave(i,uv,1.)+Wave(i,uv,1.8)+.5*Wave(i,uv,3.);
			    	float layerVal = 0.7-0.03*i + wave;
			        if(uv.y >layerVal){
			            break;
			        }
					num = i;//计算所在层的ID
			    }
			    col = num*fixed3(0,.03,1);//计算每一层的基本颜色
			    col += (LAYER - num) * fixed3(.04,.04,.04);//颜色叠亮
				if(num ==0){
					//添加海平面泛光
					float ry = Remap(0.7,1.0,1.0,0.0,uv.y);
					col = lerp(fixed3(0.1,0.6,0.9),fixed3(0.1,0.7,0.9),ry);
					col += pow(ry,10.)*fixed3(0.9,0.2,0.1)*0.2;
				}
				//调整UV为(-0.5,-0.5,0.5,0.5)方便绘图
				uv = uv - fixed2(0.5,0.5);
				//添加太阳
				fixed2 sunPos = fixed2(0.3,0.35);
				fixed sun = Circle(uv,sunPos,0.06,0.05);
				fixed sunCircle = AngleCircle(uv,sunPos,0.08,0.05);
				col = lerp( col ,fixed3(0.9,0.6,0.15),sunCircle);
				col = lerp( col ,fixed3(0.98,0.9,0.1),sun);
				//云
				col += DrawClouds(uv);
				return col;
			}
	    ENDCG
	}//end pass
  }//end SubShader
}//end Shader

