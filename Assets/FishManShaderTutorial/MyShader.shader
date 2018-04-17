
Shader "FishManShaderTutorial/MyShader"{
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
sampler2D _MainTex;


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
	        // a sunny day of sea - by JiepengTan - 2018
// jiepengtan@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


#define  SIZE  0.5
#define WATER_DEEP 0.6
#define PI 3.1415927
#define Deg2Radius PI/180.

fixed Rand(fixed x)
{
    return frac(sin(x*866353.13)*613.73);
}

fixed2x2 Rotate2D(fixed deg){
    deg = deg * Deg2Radius;
	return fixed2x2(cos(deg),sin(deg),-sin(deg),cos(deg));
}
fixed2 Within(fixed2 uv, fixed4 rect) {
	return (uv-rect.xy)/(rect.zw-rect.xy);
}
fixed Remap(fixed a,fixed b,fixed c,fixed d,fixed val){
	return (val-a)/(b-a) * (d-c) + c;
}

fixed Circle(fixed2 uv,fixed2 center,fixed size,fixed blur){
	uv = uv - center;
	uv /= size;
	fixed len = length(uv);
	return smoothstep(1.,1.-blur,len);
}

fixed PureCircle(fixed2 uv,fixed2 center,fixed size,fixed blur,fixed powVal){
	uv = uv - center;
	uv /= size;
	fixed len = 1.-length(uv);
    fixed val = clamp(Remap(0.,blur,0.,1.,len),0.,1.);
    return pow(val,powVal);//* pow(1.+len * 3.,0.1);
}
fixed Ellipse(fixed2 uv,fixed2 center,fixed2 size,fixed blur){
	uv = uv - center;
	uv /= size;
	fixed len = length(uv);
	return smoothstep(1.,1.-blur,len);
}


fixed3 Draw3DFrame(fixed2 uv){
    //cameraPos  
    fixed3 camPos = fixed3(0.,0.,-3);
    //Torus 
	fixed3 frameCol = fixed3(0.9,0.75,0.6);
    fixed frameMask = Circle(uv,fixed2(0.,0.),SIZE*1.1,0.01) - 
        Circle(uv,fixed2(0.,0.),SIZE,0.01);
    return fixed3(0.,0.,0.);
    
}
fixed Torus2D(fixed2 uv,fixed2 center,fixed2 size,fixed blur){
	uv = uv - center;
	fixed len = length(uv);
    if(len<size.y || len >size.x)
        return 0.;
    fixed radio = (len-size.y)/(size.x-size.y);
    fixed val = 1.-abs((radio-0.5)*2.);
	return pow(val,blur);
}

fixed3 DrawFrame(fixed2 uv){
    fixed3 frameCol = fixed3(0.9,0.75,0.6);
    fixed frameMask = Circle(uv,fixed2(0.,0.),SIZE*1.1,0.01) - 
        Circle(uv,fixed2(0.,0.),SIZE,0.01);
    //return frameCol * frameMask;
    return Torus2D(uv,fixed2(0.,0.),fixed2(SIZE * 1.1,SIZE),0.2) *frameCol;
}
fixed3 DrawHightLight(fixed2 uv){
    //up
    fixed3 hlCol = fixed3(0.95,0.95,0.95);
    fixed upMask = Ellipse(uv,fixed2(0.,0.8)*SIZE,fixed2(0.9,0.7)*SIZE,0.6)*0.9;
    upMask = upMask * Circle(uv,fixed2(0.,0.)*SIZE,SIZE*0.95,0.02) ;
    upMask = upMask * Circle(uv,fixed2(0.,-0.9)*SIZE,SIZE*1.1,-0.8) ;
    //bottom
    uv *= Rotate2D(30.);
    fixed btMask =1.;
    btMask *=  Circle(uv,fixed2(0.,0.)*SIZE,SIZE*0.95,0.02);
    fixed scale = 0.9;
    btMask *= 1.- Circle(uv,fixed2(0.,-0.17+scale)*SIZE,SIZE*(1.+scale),0.2) ;
    return  (upMask + btMask) * hlCol;
    
}


fixed GetWaveHeight(fixed2 uv){
    uv = Rotate2D(-30.)*uv;
	fixed wave =  0.12*sin(-2.*uv.x+_Time.y*4.); 
	uv = Rotate2D(-50.)*uv;
	wave +=  0.05*sin(-2.*uv.x+_Time.y*4.); 
	return wave;
}

fixed RayMarchWater(fixed3 camera, fixed3 dir,fixed startT,fixed maxT){
    fixed3 pos = camera + dir * startT;
    fixed t = startT;
    [unroll(100)]
for(int i=0;i<200;i++){
        if(t > maxT){
        	return -1.;
        }
        fixed h = GetWaveHeight(pos.xz) * WATER_DEEP;
        if(h + 0.01 > pos.y ) {//+ 0.01 acc intersect speed
            // get the intersect point
            return t;
        }
        t += pos.y - h; 
        pos = camera + dir * t;
    }
    return -1.0;
}

fixed4 SimpleWave3D(fixed2 uv,fixed3 col){
	fixed3 camPos =fixed3(0.23,0.115,-2.28);
    fixed3 targetPos = fixed3(0.,0.,0.);
    
    fixed3 f = normalize(targetPos-camPos);
    fixed3 r = cross(fixed3(0., 1., 0.), f);
    fixed3 u = cross(f, r);
    
    fixed3 ray = normalize(uv.x*r+uv.y*u+1.0*f);
    
	fixed startT = 0.1;
    fixed maxT = 20.;
	fixed dist = RayMarchWater(camPos, ray,startT,maxT);
    fixed3 pos = camPos + ray * dist;
	//only need a small circle
    fixed circleSize = 2.;
    if(dist < 0.){
    	return fixed4(0.,0.,0.,0.);
    }
    fixed2 offsetPos = pos.xz;
    if(length(offsetPos)>circleSize){
    	return fixed4(0.,0.,0.,0.);
    }
    fixed colVal = 1.-((pos.z+0.)/circleSize +1.0) *.5;//0~1
	return fixed4(col*smoothstep(0.,1.4,colVal),1.);
}
fixed SmoothCircle(fixed2 uv,fixed2 offset,fixed size){
    uv -= offset;
    uv/=size;
    fixed temp = clamp(1.-length(uv),0.,1.);
    return smoothstep(0.,1.,temp);
}
fixed DrawBubble(fixed2 uv,fixed2 offset,fixed size){
    uv = (uv - offset)/size;
    fixed val = 0.;
    val = length(uv);
    val = smoothstep(0.5,2.,val)*step(val,1.);
    
    val +=SmoothCircle(uv,fixed2(-0.2,0.3),0.6)*0.4;
    val +=SmoothCircle(uv,fixed2(0.4,-0.5),0.2)*0.2;
	return val; 
}
fixed DrawBubbles(fixed2 uv){
	uv = Within(uv, fixed4(-SIZE,-SIZE,SIZE,SIZE));
    uv.x-=0.5;
    fixed val = 0.;
    const fixed count = 2.;// bubble num per second
    const fixed maxVY = 0.1;
    const fixed ay = -.3;
    const  fixed ax = -.5;
    const  fixed maxDeg = 80.;
    const fixed loopT = maxVY/ay + (1.- 0.5*maxVY*maxVY/ay)/maxVY;
    const  fixed num = loopT*count;
	for(fixed i=1.;i<num;i++){
    	fixed size = 0.02*Rand(i*451.31)+0.02;
        fixed t = fmod(_Time.y + Rand(i)*loopT,loopT);
        fixed deg = (Rand(i*1354.54)*maxDeg +(90.-maxDeg*0.5))*Deg2Radius;
        fixed2 vel = fixed2(cos(deg),sin(deg));
        fixed ty = max((vel.y*0.3 - maxVY),0.)/ay;
        fixed yt = clamp(t,0.,ty);
		fixed y = max(0.,abs(vel.y)*yt + 0.5*ay*yt*yt) + max(0.,t-ty)*maxVY;
        
        fixed tx = abs(vel.x/ax);
        t = min(tx,t);
        fixed xOffset = abs(vel.x)*t+0.5*ax*t*t + sin(_Time.y*(0.5+Rand(i)*2.)+Rand(i)*2.*PI)*0.03;
        fixed x = sign(vel.x)*xOffset;
        fixed2 offset = fixed2(x,y);
    	val += DrawBubble(uv,offset,size*0.5);
    }
	return val;
}




//-----------------------------------------------------
	
            fixed4 ProcessFrag(v2f i)  {
                 
    fixed hpPer = sin(_Time.y*0.2)*0.2+0.5;
    fixed3 waterCol = fixed3(0.5,0.5,0.5)+fixed3(0.5,0.5,0.5)*cos(2.*PI*(fixed3(1.,0.5)+fixed3(0.5,0.5,0.5)*cos(2.*PI*(fixed3(1.,0.5)+fixed3(0.5,0.5,0.5)*cos(2.*PI*(fixed3(1.,1.,1.)*_Time.y*0.1+fixed3(0.,0.33,0.67)));
    
	fixed2 uv = (i.uv/1 - 0.5)*1/1*2.;
    fixed3 col = fixed3(0.,0.,0.);//final color 
	//draw 3D frame
    col += DrawFrame(uv);
    
    //draw base water
    fixed hpPerMask = step(0.,(hpPer *2. -1.)*SIZE - uv.y);
  	fixed bgMask = 0.;
    bgMask += PureCircle(uv,fixed2(0.,0.),SIZE*1.1,.9,0.9);
 	bgMask += Circle(uv,fixed2(0.,0.),SIZE,.6)*0.2;
    col += bgMask * waterCol *hpPerMask ;
    
    //draw wave
    fixed waterMask = step(length(uv),SIZE);
    fixed offset = hpPer -0.5+0.01;
    fixed wavePicSize = 0.8*SIZE;
    fixed2 remapUV = Within(uv,fixed4(0.,offset,wavePicSize,offset+wavePicSize-0.2));
    fixed4 wave = SimpleWave3D(remapUV,waterCol);
    col = lerp(col,wave.xyz*bgMask,wave.w*waterMask);
	
    //draw bubbles
    fixed bubbleMask = smoothstep(0.,0.1,(hpPer *2. -1.2)*SIZE - uv.y);
    col+= DrawBubbles(uv)*fixed3(1.,1.,1.)* bubbleMask*waterMask;
    //draw hight light
    col += DrawHightLight(uv*1.);
    
    return fixed4(col,1.0);
    

        
                return fixed4(col, 1.0);
            }

//-----------------------------------------------------
	    ENDCG
	    }//end pass
    }//end SubShader
}//end Shader

