// create by JiepengTan 
// https://github.com/JiepengTan/FishManShaderTutorial
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/SDF" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
			
#define DEFAULT_MAT_COL
#define DEFAULT_PROCESS_FRAG
#define DEFAULT_RENDER

#pragma vertex vert   
#pragma fragment frag  
#include "ShaderLibs/Framework3D_DefaultRender.cginc"



            float3 rX(const in float3 v, const in float cs, const in float sn) {return mul(v,float3x3(1.0,0.0,0.0,0.0,cs,sn,0.0,-sn,cs));}
            float3 rY(const in float3 v, const in float cs, const in float sn) {return mul(v,float3x3(cs,0.0,-sn,0.0,1.0,0.0,sn,0.0,cs));}
            float3 rZ(const in float3 v, const in float cs, const in float sn) {return mul(v,float3x3(cs,sn,0.0,-sn,cs,0.0,0.0,0.0,1.0));}


            // implicitly specifies shading rules
            #define WOOD_MAT 0.   
            #define STRAW_MAT 1.
            #define VILLAGE_MAT 2. 
 
            #define BridgeL 40. 
            #define BridgeW 2.  
            #define BridgeH 4.

            #define BridgeL1 50. 


            #define LegGap (BridgeW*0.45)
            #define LegWid 0.1
            #define LegLenGap LegGap * 4.

            #define BoardLen  0.2

            float SdCappedCone( in float3 p, in float3 c ) // c=float3(bottom radius, angle , height)
            {
                float2 q = float2( length(p.xz), p.y );
                float2 v = float2( c.z*c.y/c.x, -c.z );
                float2 w = v - q;
                float2 vv = float2( dot(v,v), v.x*v.x );
                float2 qv = float2( dot(v,w), v.x*w.x );
                float2 d = max(qv,0.0)*qv/vv;
                return sqrt( dot(w,w) - max(d.x,d.y) )* sign(max(q.y*v.x-q.x*v.y,w.y));
            }

  
            float SdBoatHull( float3 vPos )
            { 
                vPos.y-=0.4; 
                float3 vBoatDomain = vPos;
                vBoatDomain.x = abs(vBoatDomain.x);
                
                float boatDist = length( vBoatDomain.xyz - float3(-3.9,3.2,0.)) - 5.6;
            	
                float bs = 14.5;
                float gap = 0.3;
                float2 offset=float2(0.3,bs+gap);
                float cylinder= length(vBoatDomain.xy-offset)-bs;
                boatDist=OpS(boatDist,cylinder);
                float sSize = 15.0;
                float sOff = 0.05;
                float sphere = length( vBoatDomain.xyz - float3(0,sSize+sOff,0)) - sSize;
                boatDist=OpS(boatDist,sphere);
                
                float bx = vPos.y+0.4;
                boatDist=OpS(boatDist,bx);
                
                return boatDist;
            }


            float SdHalfCylinder(float3 pos , float3 h){
                float cy=OpS(
                    SdCylinder(pos.yzx,h.xy + float2(0.03,-0.03)),
                    SdCylinder(pos.yzx,h.xy)
                );
                float bx = SdBox(pos-float3(0.,-h.x*h.z*2.,0.),float3(h.x+0.3,h.x,h.y+0.3));
                return OpS(cy,bx);
            }



            float SdQuant(float3 pos){
                pos -= float3(-0.,.3,0.);
                float barLen = 0.3;
                float quantLen = 0.2;
            	float cy = SdCylinder(pos-float3(0.,0.,0.),float2(0.008,barLen));
                float bx = SdRoundBox(pos-float3(0.,barLen+quantLen,0.),float3(0.025,quantLen,0.002),0.003);
                return min(cy,bx);
            }
             
            float SdBoat(float3 pos){
                float ret = 10000.;
                //body
                float vb = SdBoatHull(pos);
                pos.y -=0.07;
                float vs = SdBoatHull(pos);
                float boatBody =  OpS(vb,vs); 
                
                ret = min(ret , boatBody);
                //quant
                float3 quantPos = pos ;
                quantPos.x = abs(pos.x);
                quantPos = quantPos- float3(0.05,.72,1.5);
                
                float degZ= PI*-0.15;
                quantPos = rZ(quantPos,sin(degZ),cos(degZ));
                float degX= PI*0.65;
                quantPos = rX(quantPos,sin(degX),cos(degX));
                float quant = SdQuant(quantPos*0.5);
                ret = min(ret , quant);
                
                //quant Ring
                
                float3 ringPos = pos ;
                ringPos.x = abs(pos.x);
                ringPos = ringPos- float3(0.44,.49,1.72);
                
                degZ= PI*-0.05;
                ringPos = rZ(ringPos,sin(degZ),cos(degZ));
                degZ= PI*-0.45;
                ringPos = rX(ringPos,sin(degZ),cos(degZ));
                float ringd = SdTorus(ringPos,float2(0.05,0.005));
                ret = min(ret , ringd);
                //bar
                float3 bpos = pos;
                bpos.z = abs(bpos.z);
                float bar1 = SdRoundBox(bpos-float3(0.,0.4,1.5),float3(.46,0.01,0.04),0.01);
                ret = min(ret , bar1);
                
                // roof
               	float3 q1=pos-float3(0.,0.65,0.);
                float3 roofSize = float3(0.65,1.0,0.7);
                float roof = SdHalfCylinder(q1,roofSize);
                ret = min(ret , roof);
                
                //pos.x= abs(pos.x);//!! it is strange that i cann't use pos.x= abs(pos.x) to simplify the code
                float3 padPos = pos;
                //padPos.x = abs(pos.x);
                float paddingT = SdClipCylinder( padPos - float3(-0.65,0.42,0.),float3(8,0.02,0.003));
                ret = min(ret , paddingT);
                padPos.x = -pos.x;
                paddingT = SdClipCylinder( padPos - float3(-0.65,0.42,0.),float3(8,0.02,0.003));
                ret = min(ret , paddingT);
                
                return ret;
            }


            float BridgeSeg1(float mindist,in float3 pos){
                float dis= 0.;
            	
                // bridge leg
                float3 legPos = pos;
                legPos.z -= LegLenGap * 0.5;
                if( legPos.z < BridgeL-LegLenGap && legPos.z >0.){
                	legPos.z = fmod(legPos.z,LegLenGap) - LegLenGap * 0.5;
                }
                
               	dis = SdCylinder( float3(abs(legPos.x),legPos.yz)-float3(LegGap,0.,0.0), float2(LegWid,BridgeH) );
                mindist = min( dis, mindist );
                
                dis = SdBox( legPos-float3(0.,BridgeH*0.8,0.0), float3(LegGap*0.95,LegWid*0.7,LegWid*0.7) );
                mindist = min( dis, mindist );
                
                // bridge face
                float3 facePos = pos;
                dis = SdBox( facePos-float3(0.,BridgeH,BridgeL*0.5 ), float3(BridgeW,LegWid*0.7,BridgeL*0.5) );
                mindist = min( dis, mindist );
                
                float3 boardPos = pos;
                if( boardPos.z < BridgeL && boardPos.z >0.){
                	boardPos.z = fmod(boardPos.z,BoardLen)- BoardLen * 0.5;
                }
                dis = SdBox( boardPos-float3(0.,BridgeH + .1,0.), float3(BridgeW,0.1,BoardLen*0.3));
                //dis = SdSphere( boardPos-float3(0.,BridgeH + 4.,BridgeL*0.5),float4(0.,0.,0.,0.5));
                //dis = SdSphere( boardPos, float4(0.,BridgeH,0.,0.5) );
                mindist = min( dis, mindist );
               
                return mindist;  
            }

            float BridgeSeg2(float mindist,in float3 pos){
                float dis= 0.;
            	pos.z -= BridgeL;
                pos.xz = pos.zx;
                pos.z = -pos.z;
                pos.z += BridgeW;
                
                return BridgeSeg1(mindist,pos);
            }
            float SdBridge( in float3 pos )
            {
                pos*=3.;
            	float mindist = 10000000.0;
            	
                float f = 0.5;//-0.5*cos(3.14159*pos.z/20.0);
            	mindist = BridgeSeg1(mindist,pos);
              	mindist = BridgeSeg2(mindist,pos);
            	return 0.25*mindist;
            }

			float SdBounceBalls(float3 pos){
                float SIZE = 2.;
                float2 gridSize = float2(SIZE,SIZE);
                float rv = Hash12( floor((pos.xz) / gridSize));
                pos.xz = OpRep(pos.xz,gridSize);
                float bollSize = 0.1;
                float bounceH = .5;
                return SdSphere(pos- float3(0.,(bollSize+bounceH+sin(_Time.y*3.14 + rv*6.24)*bounceH),0.),bollSize);
            }

            float2 Map( in float3 pos )
            {
                float2 res = float2( SdPlane(     pos), 1.0 )  ;
                res = OpU( res, float2( SdBounceBalls( pos),1.) );
                res = OpU( res, float2( SdBridge( pos),1.) );
                
            	pos -=float3(-1,0.,-.5);
                float deg = 1.*3.14159/180.;
                pos = rY(pos,sin(deg),cos(deg));
                res = OpU( res, float2( SdBoat( pos),1.) );
              
                return res;
            }
            ENDCG
        }//end pass
    }//end SubShader
    FallBack Off
}



