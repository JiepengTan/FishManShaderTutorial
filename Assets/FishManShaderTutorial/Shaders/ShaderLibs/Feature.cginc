// Merge by JiepengTan@gmail.com
#ifndef FMST_FEATURE
#define FMST_FEATURE

#include "Noise.cginc"

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
#define Caustic CausticRotateMin

#endif // FMST_NOISE