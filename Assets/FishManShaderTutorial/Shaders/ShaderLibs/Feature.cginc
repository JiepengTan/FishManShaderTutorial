// Merge by JiepengTan@gmail.com
#ifndef FMST_FEATURE
#define FMST_FEATURE

#include "Common.cginc"

float CausticRotateMin(float2 uv, float time){
	float3x3 mat = float3x3(2,1,-2, 3,-2,1, 1,2,2);
	float3 vec1 = mul(mat*0.5,float3(uv,time));
	float3 vec2 = mul(mat*0.4,vec1);
	float3 vec3 = mul(mat*0.3,vec2);
	float val = min(length(frac(vec1)-0.5),length(frac(vec2)-0.5));
	val = min(val,length(frac(vec3)-0.5));
	val = pow(val,7.0)*25.;
	return val;
}

float3 CausticTriTwist(float2 uv,float time )
{
	const int MAX_ITER = 5;
	float2 p = fmod(uv*PI2,PI2 )-250.0;

	float2 i = float2(p);
	float c = 1.0;
	float inten = .005;

	for (int n = 0; n < MAX_ITER; n++) 
	{
		float t = time * (1.0 - (3.5 / float(n+1)));
		i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
		c += 1.0/length(float2(p.x / (sin(i.x+t)/inten),p.y / (cos(i.y+t)/inten)));
	}
    
	c /= float(MAX_ITER);
	c = 1.17-pow(c, 1.4);
	float val = pow(abs(c), 8.0);
	return val;
}

float CausticVoronoi(float2 p,float time) {
	float v = 0.0;
	float a = 0.4;
	for (int i = 0;i<3;i++) {
		v+= wnoise(p,time)*a;
		p*=2.0;
		a*=0.5;
	}
	v = pow(v,2.)*5.;
	return v;
}

// 通过rd 来进行空间划分 这样在根据相机进行改变
float3 Stars(in float3 rd,float den,float tileNum)
{
    float3 c = float3(0.,0.,0.);
    float3 p = rd;
	float SIZE = 0.5;
    //分多层
    for (float i=0.;i<3.;i++)
    {
        float3 q = frac(p*tileNum)-0.5;
        float3 id = floor(p*tileNum);
        float2 rn = hash33(id).xy;

		float size = (hash13(id)*0.2+0.8)*SIZE; 
		float demp = pow(1.-size/SIZE,.8)*0.45;
		float val = (sin(_Time.y*31.*size)*demp+1.-demp) * size;
        float c2 = 1.-smoothstep(0.,val,length(q));//画圆
        c2 *= step(rn.x,(.0005+i*i*0.001)*den);//随机显示 随着深度的层数的增加添加更多的星星 增加每个grid 出现星星的概率
        c += c2*(lerp(float3(1.0,0.49,0.1),float3(0.75,0.9,1.),rn.y)*0.25+0.75);//不同的亮度
        p *= 1.4;//增加grid密度
    }
    return c*c*.7;
}


float TimeFBM( float2 p,float t )
{
    float2 f = 0.0;
	float s = 0.5;
	float sum =0;
	for(int i=0;i<5;i++){
		p += t;t *=1.5;
		f += s*tex2D(_NoiseTex, p/256).x; p = mul(float2x2(0.8,-0.6,0.6,0.8),p)*2.02;
		sum+= s;s*=0.6;
	}
    return f/sum;	 
}

float3 Cloud(float3 bgCol,float3 ro,float3 rd,float3 cloudCol,float spd, float layer)
{
	float3 col = bgCol;
    float time = _Time.y*0.05*spd;
	for(int i=0; i<layer; i++){
		float2 sc = ro.xz + rd.xz*((i+3)*40000.0-ro.y)/rd.y;
		col = lerp( col, cloudCol, 0.5*smoothstep(0.5,0.8,TimeFBM(0.00002*sc,time*(i+3))) );
	}
	return col;
}

fixed3 Fog(in fixed3 bgCol, in fixed3 ro, in fixed3 rd, in fixed maxT,
				float3 fogCol,float3 spd,float2 heightRange)
{
	fixed d = .4;
	float3 col = bgCol;
	for(int i=0; i<7; i++)
	{
		fixed3  p = ro + rd*d;
		// add some movement at some dir
		p += spd * ftime;
		p.z += sin(p.x*.5);
		// get height desity 
		float hDen = (1.-smoothstep(heightRange.x,heightRange.y,p.y));
		// get final  density
		fixed den = tnoise(p*2.2/(d+20.),ftime, 0.2)* hDen;
		fixed3 col2 = fogCol *( den *0.5+0.5);
		col = lerp(col,col2,clamp(den*smoothstep(d-0.4,d+2.+d*.75,maxT),0.,1.) );
		d *= 1.5+0.3; 
		if (d>maxT)break;
	}
	return col;
}


#define Caustic CausticRotateMin

#endif // FMST_NOISE