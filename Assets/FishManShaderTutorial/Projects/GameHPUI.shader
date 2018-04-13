
Shader "FishManShaderTutorial/GameHPUI"{
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
	        #include "UnityCG.cginc"

            struct v2f {
		        fixed4 pos : SV_POSITION;
		        fixed2 uv : TEXCOORD0;
		        fixed2 uv_depth : TEXCOORD1;
		        fixed4 interpolatedRay : TEXCOORD2;
	        };

		    fixed4x4 _FrustumCornersRay;
	        fixed4 _MainTex_TexelSize;
	        sampler2D _CameraDepthTexture;
	        //Variables
float4 _iMouse;
sampler2D _MainTex;
float4 _LoopNum;


	        v2f vert(appdata_img v) {
		        v2f o;
		        o.pos = UnityObjectToClipPos(v.vertex);

		        o.uv = v.texcoord;
		        o.uv_depth = v.texcoord;

        #if UNITY_UV_STARTS_AT_TOP
		        if (_MainTex_TexelSize.y < 0)
			        o.uv_depth.y = 1 - o.uv_depth.y;
        #endif

		        int index = 0;
		        if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
			        index = 0;
		        }
		        else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
			        index = 1;
		        }
		        else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
			        index = 2;
		        }
		        else {
			        index = 3;
		        }

        #if UNITY_UV_STARTS_AT_TOP
		        if (_MainTex_TexelSize.y < 0)
			        index = 3 - index;
        #endif
		        o.interpolatedRay = _FrustumCornersRay[index];
                //VertexFactory
		        return o;
	        }//end fixedt

            fixed4 ProcessFrag(v2f i);


	        fixed4 frag(v2f i) : SV_Target
	        {
                fixed linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
		        fixed3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
		        //get Unity world pos
		        fixed4 finalColor = tex2D(_MainTex, i.uv);

		        fixed4 processCol = ProcessFrag(i);
		        if(processCol.w < linearDepth){
			        finalColor = processCol;
			        finalColor.w =1.0;
		        }

		        return finalColor;
	        }//end frag

//-----------------------------------------------------
	        //afl_ext 2017 

#define mouse (_iMouse.xy / 1)
#define WATER_DEEP 0.6
#define GOLDEN_ANGLE_RADIAN 2.39996
#define PI 3.1415927

#define PI 3.1415927
#define Deg2Radius PI/180.

fixed Wave(fixed layer,fixed2 uv,fixed val){
	fixed amplitude =  layer*layer*0.00004;
	fixed frequency = val*200.*uv.x/layer;
	fixed phase = 9.*layer+ _Time.y/val;
	return amplitude*sin(frequency+phase); 
}

// its from here https://github.com/achlubek/venginenative/blob/master/shaders/include/WaterHeight.glsl 
fixed wave(fixed2 uv, fixed2 emitter, fixed speed, fixed phase){
	fixed dst = distance(uv, emitter);
	return pow((0.5 + 0.5 * sin(dst * phase - _Time.y * speed)), 5.0);
}

fixed getwaves(fixed2 uv){
	fixed w = 0.0;
	fixed sw = 0.0;
	fixed iter = 0.0;
	fixed ww = 1.0;
    uv += _Time.y * 0.5;
	// it seems its absolutely fastest way for water height function that looks real
	[unroll(100)]
	for(int i=0;i<6;i++){
		w += ww * wave(uv * 0.06 , fixed2(sin(iter), cos(iter)) * 10.0, 2.0 + iter * 0.08, 2.0 + iter * 3.0);
		sw += ww;
		ww = lerp(ww, 0.0115, 0.4);
		iter += GOLDEN_ANGLE_RADIAN;
	}
	
	return w / sw;
}


fixed2x2 Rotate2D(float deg){
    deg = deg * Deg2Radius;
	return fixed2x2(cos(deg),sin(deg),-sin(deg),cos(deg));
}


fixed getNewWaves(fixed2 uv){
	//uv = mul(Rotate2D(-30.),uv);
	float wave =  0.12*sin(-2.*uv.x+_Time.y*4.); 
	uv = mul(Rotate2D(-50.),uv);
	wave +=  0.05*sin(-2.*uv.x+_Time.y*4.); 
	return wave;
}

fixed H = 0.0;
fixed3 normal(fixed2 pos, fixed e, fixed depth){
    fixed2 ex = fixed2(e, 0);
    H = getwaves(pos.xy) * depth;
    fixed3 a = fixed3(pos.x, H, pos.y);
    return normalize(cross(normalize(a-fixed3(pos.x - e, getwaves(pos.xy - ex.xy) * depth, pos.y)), 
                           normalize(a-fixed3(pos.x, getwaves(pos.xy + ex.yx) * depth, pos.y + e))));
}
fixed3x3 rotmat(fixed3 axis, fixed angle)
{
	axis = normalize(axis);
	fixed s = sin(angle);
	fixed c = cos(angle);
	fixed oc = 1.0 - c;
	
	return fixed3x3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 
	oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s, 
	oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}
fixed Remap(fixed a,fixed b,fixed c,fixed d,fixed val){
	return (val - a /b -a)*(d-c);
}

fixed raymarchwater(fixed3 camera, fixed3 dir,fixed startT,fixed maxT){
    fixed3 pos = camera + dir * startT;
    fixed t = startT;
	for(int i=0;i<_LoopNum.x;i++){
        if(t > maxT){
        	return -1.;
        }
        fixed h = getNewWaves(pos.xz) * WATER_DEEP;
        if(h + 0.01 > pos.y ) {//+ 0.01 acc intersect speed
            // get the intersect point
            return t;
        }
        t += pos.y - h; 
        pos = camera + dir * t;
    }
    return -1.0;
}


fixed sun(fixed3 ray){
 	fixed3 sd = normalize(fixed3(1.0,1.0,1.0));   
    return pow(max(0.0, dot(ray, sd)), 528.0) * 110.0;
}



//-----------------------------------------------------
	
            fixed4 ProcessFrag(v2f i)  {
                 
	fixed2 uv = i.uv / 1;
 	uv = (uv * 2.0 - 1.0)* fixed2(1 / 1, 1.0);
	
    fixed yRot = (mouse.x * 2.0 - 1.0)*PI;
    fixed xRot = (mouse.y*2.0-1.0)*PI;
    fixed radius = 10.;
    radius = Remap(-1.,1.,3.,9.,xRot);
    
    fixed3 camPos =fixed3(0.,0.5,0.);
    camPos.xz = fixed2(cos(yRot),sin(yRot))*radius;
    fixed3 targetPos = fixed3(0.,0.,0.);
    
    fixed3 f = normalize(targetPos-camPos);
    fixed3 r = cross(fixed3(0., 1., 0.), f);
    fixed3 u = cross(f, r);
    
    fixed3 ray = normalize(uv.x*r+uv.y*u+1.0*f);
    //camPos = fixed3(0.0, 2., 0.0);
    
	//ray= normalize(fixed3(uv.x, uv.y, 1.0));
    //fixed3 proj = normalize(fixed3(uv.x, uv.y, 1.0));	
    //ray = rotmat(fixed3(0.0, -1.0, 0.0), mouse.x * 2.0 - 1.0) * rotmat(fixed3(1.0, 0.0, 0.0), 1.5 * (mouse.y * 2.0 - 1.0)) * proj;
 
    
	camPos = _WorldSpaceCameraPos;
	ray = normalize(i.interpolatedRay.xyz);

	fixed startT = 0.1;
    fixed maxT = 20.;
	fixed dist = raymarchwater(camPos, ray,startT,maxT);
    fixed3 pos = camPos + ray * dist;
	//裁剪为一个圆面
    fixed circleSize = 2.;
    //return fixed4(0.,0.,0.,0.);
    if(dist < 0.)
    {
    	return  fixed4(0.,0.,0.,0.);
	}
	fixed2 offsetPos = pos.xz;
    if(length(offsetPos)>circleSize){
        return fixed4(0.,0.,0.,0.);
    }
	fixed3 WaveColor =fixed3(0.95,0.2,0.95);
    float colVal = 1.-(offsetPos.y/circleSize +1.0) *.5;
	return fixed4(WaveColor*colVal,1.);
	} 
//-----------------------------------------------------
	    ENDCG
	    }//end pass
    }//end SubShader
}//end Shader

