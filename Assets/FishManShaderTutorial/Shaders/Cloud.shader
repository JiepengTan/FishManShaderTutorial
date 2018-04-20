Shader "FishManShaderTutorial/Cloud" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
        _LoopNum ("_LoopNum", Vector) = (17.,128., 1, 1)
        _NoiseTex("_NoiseTex", 2D) = "white" {}
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #define USING_TEXLOD_NOISE 1
#pragma vertex VertMergeRayMarch  
#pragma fragment FragMergeRayMarch  
#include "ShaderLibs/MergeRayMarch.cginc"

            float4 _LoopNum ;
            float moy = 0.;

            float fbmss(in float3 x)
            {
                float rz = 0.;  
                float a = .35;
                for (int i = 0; i<2; i++)
                { 
                    rz += Noise(x)*a;  
                    a*=.35;
                    x*= 4.;
                }
                return rz;
            }

            float map(float3 p){
                return 
                    p.y*0.07 
                    + (fbmss(p*0.3)-0.1) 
                    +sin(p.x*0.24 + sin(p.z*.01)*7.)*0.22
                    +0.25
                    +sin(p.z*0.08)*0.05
                    ;
            }

            float march(in float3 ro, in float3 rd)
            {
                float precis = .3;
                float h= 1.;
                float d = 0.;
                for( int i=0; i<_LoopNum.x; i++ )
                {
                    if( abs(h)<precis || d>70. ) break;
                    d += h;
                    float3 pos = ro+rd*d;
                    pos.y += .5;
                    float res = map(pos)*7.;
                    h = res;
                }
                return d;
            }
            
            float mapV( float3 p ){ return clamp(-map(p), 0., 1.);}
            float4 marchV(in float3 ro, in float3 rd, in float t, in float3 bgc,float3 lgt)
            {
                float4 rz = float4( 0.0 , 0.0 , 0.0 , 0.0 );
    
                for( int i=0; i<_LoopNum.y; i++ )
                {
                    if(rz.a > 0.99 || t > 200.) break;
        
                    float3 pos = ro + t*rd;
                    float den = mapV(pos);
        
                    //直接作色 里面的云层颜色为黑色
                    float4 col = float4(lerp( float3(.8,.75,.85), float3(.0,.0,.0), den ),den);
                    //col.xyz *= lerp(bgc*bgc*2.5,
                    //               lerp(float3(0.1,0.2,0.55),float3(.8,.85,.9),moy*0.4),
                    //               clamp( -(den*40.+0.)*pos.y*.03-moy*0.5, 0., 1. ) );
                    //越上面的颜色月白
                    //col.rgb += clamp((1.-den*6.) +  pos.y*0.13 +.55, 0., 1.)
                    //    *0.35*lerp(bgc,float3(1,1,1),0.7); //Fringes
                    //col += clamp(den*pos.y*.15, -.02, .0); //Depth occlusion
                    col *= smoothstep(0.2+moy*0.05,.0,mapV(pos+1.*lgt))*.85+0.15; //Shadows
        
                    col.a *= .9;
                    col.rgb *= col.a;
                    rz = rz + col*(1.0 - rz.a);//一层层的颜色叠加  类是透明贴图的颜色混合

                    t += max(.4,(2.-den*30.)*t*0.011);
                }

                return clamp(rz, 0., 1.);
            }

            float pent(in float2 p){    
                float2 q = abs(p);
                return max(max(q.x*1.176-p.y*0.385, q.x*0.727+p.y), -p.y*1.237)*1.;
            }

            float3 flare(float2 p, float2 pos) //Inspired by mu6k's lens flare (https://www.shadertoy.com/view/4sX3Rs)
            {
                float2 q = p-pos;
                float2 pds = p*(length(p))*0.75;
                float a = atan2(q.y,q.x);
    
                float rz = .55*(pow(abs(frac(a*.8+.12)-0.5),3.)*(Hash11(a*15.)*0.9+.1)*exp2((-dot(q,q)*4.))); //Spokes
    
                rz += max(1.0/(1.0+32.0*pent(pds+0.8*pos)),.0)*00.2; //Projected ghost (main lens)
                float2 p2 = lerp(p,pds,-.5); //Reverse distort
                rz += max(0.01-pow(pent(p2 + 0.4*pos),2.2),.0)*3.0;
                rz += max(0.01-pow(pent(p2 + 0.2*pos),5.5),.0)*3.0; 
                rz += max(0.01-pow(pent(p2 - 0.1*pos),1.6),.0)*4.0;
                rz += max(0.01-pow(pent(-(p2 + 1.*pos)),2.5),.0)*5.0;
                rz += max(0.01-pow(pent(-(p2 - .5*pos)),2.),.0)*4.0;
                rz += max(0.01-pow(pent(-(p2 + .7*pos)),5.),.0)*3.0;
                float val = clamp(rz,0.,1.);
                return float3(val,val,val);
            }




            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
                float3 col = float3(0.,0.,0.);
                float3 lgt = normalize(float3(-0.3,0.1,1.));  
                float rdl = clamp(dot(rd, lgt),0.,1.);
  
                float3 hor = lerp( float3(.9,.6,.7)*0.35, float3(.5,0.05,0.05), rdl );
                col += lerp( float3(.2,.2,.6), hor, exp2(-(1.+ 3.*(1.-rdl))*max(abs(rd.y),0.)) )*.6;
                col += .8*float3(1.,.9,.9)*exp2(rdl*650.-650.);
                col += .3*float3(1.,1.,0.1)*exp2(rdl*100.-100.);
                col += .5*float3(1.,.7,0.)*exp2(rdl*50.-50.); 
                col += .4*float3(1.,0.,0.05)*exp2(rdl*10.-10.);  
                float3 bgc = col;
    
                float rz = march(ro,rd);
    
                if (rz < 70.){   
                    float4 res = marchV(ro, rd, rz-5., bgc,lgt);
                    col = col*(1.0-res.w) + res.xyz;
                }
                //float3 projected_flare = (-lgt*inv_rotation);
                //col += 1.4*float3(0.7,0.7,0.4)*max(flare(p,-projected_flare.xy/projected_flare.z*zoom)*projected_flare.z,0.);
    
                float g = 0.03;
                col = lerp(lerp(col,col.brg*float3(1,0.75,1),clamp(g*2.,0.0,1.0)), col.bgr, clamp((g-0.5)*2.,0.0,1.));
    
                col = clamp(col, 0., 1.);
                col = col*0.5 + 0.5*col*col*(3.0-2.0*col); //saturation
                col = pow(col, float3(0.416667,0.416667,0.416667))*1.055 - 0.055; //sRGB
                //col *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.12 ); //Vign
                sceneCol.xyz = col;
                return sceneCol; 
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



