// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// date: 2018-03-27  
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/2DLava"{
	Properties{
	    _MainTex ("MainTex", 2D) = "white" {}
	    _NoiseTex ("_NoiseTex", 2D) = "white" {}
	    _GridSize ("SparkGridSize", float) = 30
		
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
			float _GridSize;

			//float _Noise( in float2 x ){return tex2D(_NoiseTex, x*.003).x;}
			float _Noise( in float2 x ){ return VNoise(x*0.75);}

			float2 Gradn(float2 p)
			{
				float ep = .09;
				float gradx = _Noise(float2(p.x+ep,p.y))-_Noise(float2(p.x-ep,p.y));
				float grady = _Noise(float2(p.x,p.y+ep))-_Noise(float2(p.x,p.y-ep));
				return float2(gradx,grady);
			}
			// ...... Taken from https://www.shadertoy.com/view/MdBSRW
			float3 Blackbody(float t)
			{
				const float  TEMPERATURE  = 2200.0;
				t *= TEMPERATURE;
    
				float u = ( 0.860117757 + 1.54118254e-4 * t + 1.28641212e-7 * t*t ) 
						/ ( 1.0 + 8.42420235e-4 * t + 7.08145163e-7 * t*t );
    
				float v = ( 0.317398726 + 4.22806245e-5 * t + 4.20481691e-8 * t*t ) 
						/ ( 1.0 - 2.89741816e-5 * t + 1.61456053e-7 * t*t );

				float x = 3.0*u / (2.0*u - 8.0*v + 4.0);
				float y = 2.0*v / (2.0*u - 8.0*v + 4.0);
				float z = 1.0 - x - y;
    
				float Y = 1.0;
				float X = Y / y * x;
				float Z = Y / y * z; 

				float3x3 XYZtoRGB = float3x3(3.2404542, -1.5371385, -0.4985314,
									-0.9692660,  1.8760108,  0.0415560,
										0.0556434, -0.2040259,  1.0572252);

				return max(float3(0.0,0.,0.), mul(XYZtoRGB,float3(X,Y,Z)) * pow(t * 0.0004, 4.0));
			}

			float FlowFBM(in float2 p)
			{
				float z=2.;
				float rz = 0.;
				float2 bp = p;
				for (float i= 1.;i < 9.;i++ )
				{
					//让不同的层都添加不同的运动速度 形成一种明显的 层次感
					p += ftime*.0006;
					bp += ftime*0.00006;
					//获取梯度
					float2 gr = Gradn(i*p*1.54+ftime*.14)*4.;
					//添加旋转 让不同的图层拥有不同的旋转速度，形成整体有扭曲的感觉
					float2x2 rot = Rot2DRad(ftime*0.6-(0.05*p.x+0.07*p.y)*30.);
					gr = mul(rot,gr);
					p += gr*.5;
					//FBM实现
					rz+= (sin(_Noise(p)*7.)*0.5+0.5)/z;
					//插值调整每层之间效果
					p = lerp(bp,p,.77);
					//FBM 常规操作
					z *= 1.4;
					p *= 2.;
					bp *= 1.9;
				}
				return rz;	
			}


			float3 ProcessFrag(float2 uv)
			{
				uv*= _GridSize;
				float val = FlowFBM(uv);
				val = Remap(0.,1.,0.6,1.,val);
				float3 col = Blackbody(val);
				return col;
			}
	    ENDCG
	}//end pass
  }//end SubShader
}//end Shader

