// Merge by JiepengTan@gmail.com
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
	const float TAU = 6.28318530718;
	const int MAX_ITER = 5;
	float2 p = fmod(uv*TAU,TAU )-250.0;

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

#define Caustic CausticRotateMin