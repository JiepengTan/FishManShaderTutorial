// Create  by JiepengTan@gmail.com
// 2018-03-27
#ifndef FRAMEWORK_3D
#define FRAMEWORK_3D

#include "FBM.cginc"
#include "Feature.cginc"
sampler2D _MainTex;
float2 _MainTex_TexelSize;
float4x4 _FrustumCornersRay;
sampler2D _CameraDepthTexture;

struct v2f {
    float4 pos : SV_POSITION;
    half2 uv : TEXCOORD0;
    half2 uv_depth : TEXCOORD1;
    float4 interpolatedRay : TEXCOORD2;
};

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
    return o;
}

//RayMarching is the main world, ignore unity sky box
void MergeUnityIntoRayMarching(inout float rz,inout float3 rCol, float unityDep,float4 unityCol){
    if(rz>unityDep && unityDep<_ProjectionParams.z-1.){// unity camera far plane 
        rCol = unityCol.xyz;
        rz = unityDep;
    }
}
//Unity scene is the main world, ignore RayMarching sky box
void MergeRayMarchingIntoUnity(inout float rz,inout float3 rCol, float unityDep,float4 unityCol){
    if(rz>unityDep ){
        rCol = unityCol.xyz;
        rz = unityDep;
    }
}           

float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol);

float4 frag(v2f i) : SV_Target{
    float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
    depth *= length(i.interpolatedRay.xyz);
    fixed4 sceneCol = tex2D(_MainTex, i.uv);
    float2 uv = i.uv * float2(_ScreenParams.x/_ScreenParams.y,1.0);
    fixed3 ro = _WorldSpaceCameraPos;
    fixed3 rd = normalize(i.interpolatedRay.xyz);
    return ProcessRayMarch(uv,ro,rd,depth,sceneCol);
}

#endif