// create by JiepengTan 
// date: 2018-03-27  
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/2DFireParticle"{
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
		 
			float3 ProcessFrag(float2 uv){
				fixed3 acc = fixed3(0.0,0.0,0.0);
				fixed time = _Time.y;

				fixed3 fireCol = fixed3(1.0,0.3,0.0);
				fixed sparkGridSize = 30.0;//»®·Ö¸ñ×Ó
				fixed rotateSpd = 3.*time;//¿ØÖÆÐý×ªËÙ¶È
				fixed yOffset = 4.*time;//¿ØÖÆÁ£×ÓÉÏÉýËÙ¶È

				fixed2 coord = uv*sparkGridSize - fixed2(0.,yOffset);
				if (abs(fmod(coord.y,2.0))<1.0) //Æ«ÒÆ°ë¸ö¸ñ×Ó
					coord.x += 0.5;
				fixed2 sparkGridIndex = fixed2(floor(coord));
				fixed sparkRandom = Hash12(sparkGridIndex);//¶¨ÒåÁ£×ÓµÄ´óÐ¡
				fixed sparkLife = min(10.0*(1.0-min((sparkGridIndex.y + yOffset)/(24.0-20.0*sparkRandom),1.0)),1.0);//Ë³Ó¦YÖáÍùÏÂÒÆ¶¯µÄÍ¬Ê±  ²»¶ÏµÄÉ¾¼õÁÁ¶È
				//acc = fixed3(sparkRandom,sparkRandom,sparkRandom);
				if (sparkLife>0.0 ) {
					fixed size = 0.08*sparkRandom;//¶¨ÒåÁ£×ÓµÄ´óÐ¡
					fixed deg = 999.0*sparkRandom*2.0*PI + rotateSpd*(0.5+0.5*sparkRandom);//³õÊ¼»¯Ðý×ª³õ½Ç¶È
					fixed2 rotate = fixed2(sin(deg),cos(deg));
					fixed radius =  0.5-size*0.2;
					fixed2 cirOffset = radius*rotate;//¸ù¾ÝÁ£×ÓµÄ´óÐ¡¾ö¶¨ÆäÐý×ª°ë¾¶
					fixed2 part = frac(coord-cirOffset) - 0.5 ;
					float len = length(part);
					fixed sparksGray = max(0.0,1.0 -len/size);//ÈÃÔ²±äÐ¡µã
					fixed sinval = sin(PI*1.*(0.3+0.7*sparkRandom)*time+sparkRandom*10.);
					fixed period = pow(sinval,5.);
					period = clamp(pow(period,5.),0.,1.);
					fixed blink =(0.8+0.8*abs(period));
					acc = sparkLife*sparksGray*fireCol*blink;
				}
				return acc;
			}
	    ENDCG
	}//end pass
  }//end SubShader
}//end Shader

