
Shader "FishManShaderTutorial/Shadertoy_Elevated"{
    Properties{
        _MainTex ("MainTex", 2D) = "white" {}
        _NoiseTex ("_NoiseTex", 2D) = "white" {}
        _LoopNum ("_LoopNum", Vector) = (1, 1, 1, 1)
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
            #pragma exclude_renderers d3d11_9x
            #include "UnityCG.cginc"

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv_depth : TEXCOORD1;
                float4 interpolatedRay : TEXCOORD2;
                //VertexOutput
            };

            float4x4 _FrustumCornersRay;
            float4 _MainTex_TexelSize;
            sampler2D _CameraDepthTexture;
            //Variables
            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float4 _LoopNum;
            
            #define AA 1   // make this 2 or even 3 if you have a really powerful GPU

            #define SC (250.0)
            #define kMaxT (5000.0*SC)
            #define m2 (float2x2(0.8,-0.6,0.6,0.8))
            

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv_depth : TEXCOORD1;
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
                //VertexFactory
                return o;
            }



            // value Noise, and its analytical derivatives
            float3 Noised( in float2 x )
            {
                float2 f = frac(x);
                float2 u = f*f*(3.0-2.0*f);

                float2 p = floor(x);
                float st = 1.0/255.0;
                float a = tex2Dlod( _NoiseTex, float4((p+float2(0.5,0.5))*st ,0.0,0.0)).x;
                float b = tex2Dlod( _NoiseTex, float4((p+float2(1.5,0.5))*st ,0.0,0.0)).x;//tex2D( _NoiseTex, (p+float2(1.0,0.0))*st ).x;
                float c = tex2Dlod( _NoiseTex, float4((p+float2(0.5,1.5))*st ,0.0,0.0)).x;//tex2D( _NoiseTex, (p+float2(0.0,1.0))*st ).x;
                float d = tex2Dlod( _NoiseTex, float4((p+float2(1.5,1.5))*st ,0.0,0.0)).x;//tex2D( _NoiseTex, (p+float2(1.0,1.0))*st ).x;

    
                return float3(a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y,
                            6.0*f*(1.0-f)*(float2(b-a,c-a)+(a-b-c+d)*u.yx));
            }

            
   

            float terrainH( in float2 x )
            {
                float2  p = x*0.003/SC;
                float a = 0.0;
                float b = 1.0;
                float2  d = float2(0.0,0.0);
                //[unroll(100)]
                for( int i=0; i<_LoopNum.x; i++ )
                {
                    float3 n = Noised(p);
                    d += n.yz;
                    a += b*n.x;///(1.0+dot(d,d));
                    b *= 0.5;
                    p = p*2.0;//mul(m2,p)*2.0;
                }

                return SC*120.0*a;
            }

            float terrainM( in float2 x )
            {
                float2  p = x*0.003/SC;
                float a = 0.0;
                float b = 1.0;
                float2  d = float2(0.0,0.0);
                //[unroll(100)]
                for( int i=0; i<_LoopNum.y ; i++ )
                {
                    float3 n = Noised(p);
                    d += n.yz;
                    a += b*n.x/(1.0+dot(d,d));
                    b *= 0.5;
                    p =mul(m2,p)*2.0;
                }
                return SC*120.0*a;
            }

            float terrainL( in float2 x )
            {
                float2  p = x*0.003/SC;
                float a = 0.0;
                float b = 1.0;
                float2  d = float2(0.0,0.0);
                //[unroll(100)] 
                for( int i=0; i<_LoopNum.z; i++ )
                {
                    float3 n = Noised(p);
                    d += n.yz;
                    a += b*n.x/(1.0+dot(d,d));
                    b *= 0.5;
                    p =mul(m2,p)*2.0;
                }

                return SC*120.0*a;
            }

            float interesct( in float3 ro, in float3 rd, in float tmin, in float tmax )
            {
                float t = tmin;
                //[unroll(100)]
                for( int i=0; i<_LoopNum.w; i++ ) 
                {
                    float3 pos = ro + t*rd;
                    float h = pos.y - terrainM( pos.xz );
                    if( h<(0.002*t) || t>tmax ) break;
                    t += 0.5*h;
                }

                return t; 
            }

            float softShadow(in float3 ro, in float3 rd )
            {
                float res = 1.0;
                float t = 0.001;
                //[unroll(100)]
                for( int i=0; i<80; i++ )
                {
                    float3  p = ro + t*rd;
                    float h = p.y - terrainM( p.xz );
                    res = min( res, 16.0*h/t );
                    t += h;
                    if( res<0.001 ||p.y>(SC*200.0) ) break;
                }
                return clamp( res, 0.0, 1.0 );
            }

            float3 calcNormal( in float3 pos, float t )
            {
                float2  eps = float2( 0.002*t, 0.0 );
                return normalize( float3( terrainH(pos.xz-eps.xy) - terrainH(pos.xz+eps.xy),
                                        2.0*eps.x,
                                        terrainH(pos.xz-eps.yx) - terrainH(pos.xz+eps.yx) ) );
            }

            float fbm( float2 p )
            {
                float2 f = 0.0;
				p += _Time.y * 0.5;
                f += 0.5000*tex2D(_NoiseTex, p/256).x; p = mul(m2,p)*2.02;
				p += _Time.y * 0.25;
                f += 0.2500*tex2D(_NoiseTex, p/256).x; p = mul(m2,p)*2.03;
				p += _Time.y * 1;
                f += 0.1250*tex2D(_NoiseTex, p/256).x; p = mul(m2,p)*2.01;
				p += _Time.y * 2;
                f += 0.0625*tex2D(_NoiseTex, p/256).x;
                return f/0.9375;				  
            }
			
            float fbmCloud( float2 p,float t )
            {
                float2 f = 0.0;
				float s = 0.5;
				float sum =0;
				for(int i=0;i<4;i++){
					p += t;
					f += s*tex2D(_NoiseTex, p/256).x; p = mul(m2,p)*2.02;
					t *=1.5;
					sum+= s;
					s*=0.6;
				}
                return f/sum;	
            }

            float4 render( in float3 ro, in float3 rd )
            {
                float3 light1 = normalize( float3(-0.8,0.4,-0.3) );
                // bounding plane
                float tmin = 1.0;
                float tmax = kMaxT;// kMaxT;
            #if 1
                float maxh = 300.0*SC;
                float tp = (maxh-ro.y)/rd.y;
                //if( tp>0.0 )
                //{
                //  if( ro.y>maxh ) tmin = max( tmin, tp );
                //  else            tmax = min( tmax, tp );
                //}
            #endif
                float sundot = clamp(dot(rd,light1),0.0,1.0);
                float3 col = float3(0.0,0.0,0.0);
                float t = interesct( ro, rd, tmin, tmax );
                col = float3(t/tmax,t/tmax,t/tmax);  
                
                if( t>tmax)
                {
                    // sky      
                    col = float3(0.2,0.5,0.85)*1.1 - rd.y*rd.y*0.5;
                    col = lerp( col, 0.85*float3(0.7,0.75,0.85), pow( 1.0-max(rd.y,0.0), 4.0 ) );
                    // sun
                    col += 0.25*float3(1.0,0.7,0.4)*pow( sundot,5.0 );
                    col += 0.25*float3(1.0,0.8,0.6)*pow( sundot,64.0 );
                    col += 0.2*float3(1.0,0.8,0.6)*pow( sundot,512.0 );
                    // clouds
					float time = _Time.y*0.05;
					for(int i=0;i<1;i++){
						float2 sc = ro.xz + rd.xz*((i+3)*SC*800.0-ro.y)/rd.y;//pow(rd.y,0.4);
						col = lerp( col, float3(1.0,0.95,1.0), 0.5*smoothstep(0.5,0.8,fbmCloud(0.0005*sc/SC,time*(i+3))) );
					}
                    // horizon
                    col = lerp( col, 0.68*float3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
                    t = -1.0;
                }
                else
                {
                    // mountains        
                    float3 pos = ro + t*rd;
                    float3 nor = calcNormal( pos, t );

                    float3 ref = reflect( rd, nor );
                    float fre = clamp( 1.0+dot(rd,nor), 0.0, 1.0 );
                    float3 hal = normalize(light1-rd);
        
                    // rock
                    float r = tex2D( _NoiseTex, (7.0/SC)*pos.xz/256.0 ).x;
                    col = (r*0.25+0.75)*0.9*lerp( float3(0.08,0.05,0.03), float3(0.10,0.09,0.08), 
                                                 tex2D(_NoiseTex,0.00007*float2(pos.x,pos.y*48.0)/SC).x );
                    col = lerp( col, 0.20*float3(0.45,.30,0.15)*(0.50+0.50*r),smoothstep(0.70,0.9,nor.y) );
                    col = lerp( col, 0.15*float3(0.30,.30,0.10)*(0.25+0.75*r),smoothstep(0.95,1.0,nor.y) );

                    // snow
                    float h = smoothstep(55.0,80.0,pos.y/SC + 25.0*fbm(0.01*pos.xz/SC) );
                    float e = smoothstep(1.0-0.5*h,1.0-0.1*h,nor.y);
                    float o = 0.3 + 0.7*smoothstep(0.0,0.1,nor.x+h*h);
                    float s = h*e*o;
                    col = lerp( col, 0.29*float3(0.62,0.65,0.7), smoothstep( 0.1, 0.9, s ) );
        
                    // lighting     
                    float amb = clamp(0.5+0.5*nor.y,0.0,1.0);
                    float dif = clamp( dot( light1, nor ), 0.0, 1.0 );
                    float bac = clamp( 0.2 + 0.8*dot( normalize( float3(-light1.x, 0.0, light1.z ) ), nor ), 0.0, 1.0 );
                    float sh = 1.0; 
                    if( dif>=0.0001 ) sh = softShadow(pos+light1*SC*0.05,light1);
        
                    float3 lin  = float3(0.0,0.0,0.0);
                    lin += dif*float3(7.00,5.00,3.00)*1.3*float3( sh, sh*sh*0.5+0.5*sh, sh*sh*0.8+0.2*sh );
                    lin += amb*float3(0.40,0.60,1.00)*1.2;
                    lin += bac*float3(0.40,0.50,0.60);
                    col *= lin;
        
                    col += s*0.1*pow(fre,4.0)*float3(7.0,5.0,3.0)*sh * pow( clamp(dot(nor,hal), 0.0, 1.0),16.0);
                    col += s*
                           (0.04+0.96*pow(clamp(1.0+dot(hal,rd),0.0,1.0),5.0))*
                           float3(7.0,5.0,3.0)*dif*sh*
                           pow( clamp(dot(nor,hal), 0.0, 1.0),16.0);
        
        
                    col += s*0.1*pow(fre,4.0)*float3(0.4,0.5,0.6)*smoothstep(0.0,0.6,ref.y);

                    // fog
                    float fo = 1.0-exp(-pow(0.001*t/SC,1.5) );
                    float3 fco = 0.65*float3(0.4,0.65,1.0);// + 0.1*float3(1.0,0.8,0.5)*pow( sundot, 4.0 );
                    //col = lerp( col, fco, fo );

                }
                
                // sun scatter
                col += 0.3*float3(1.0,0.7,0.3)*pow( sundot, 8.0 );
 
                // gamma
                col = sqrt(col);
    
                return float4( col, t );
            }
                
    
    
            float3 camPath( float time )
            {
                return SC*1100.0*float3( cos(0.0+0.23*time), 0.0, cos(1.5+0.21*time) );
            }

            float3x3 setCamera( in float3 ro, in float3 ta, in float cr )
            {
                float3 cw = normalize(ta-ro);
                float3 cp = float3(sin(cr), cos(cr),0.0);
                float3 cu = normalize( cross(cw,cp) );
                float3 cv = normalize( cross(cu,cw) );
                return float3x3( cu, cv, cw );
            }

            void moveCamera( float time, out float3 oRo, out float3 oTa, out float oCr, out float oFl )
            {
                float3 ro = camPath( time );
                float3 ta = camPath( time + 3.0 );
                ro.y = terrainL( ro.xz ) + 19.0*SC;
                ta.y = ro.y - 20.0*SC;
                float cr = 0.2*cos(0.1*time);
                oRo = ro;
                oTa = ta;
                oCr = cr;
                oFl = 3.0;
            }

    

            float4 ProcessFrag(v2f i) : SV_Target
            {
                float3 ro, rd;
                float3  ta; float cr, fl;
                //// pixel
                //float2 p = (i.uv*2.0-1.0 )* float2(1.77,1.0);
    //            float time =0.1;// _Time.y*0.1;
                //  // camera position
                //moveCamera( time, ro, ta, cr, fl );
                //// camera2world transform    
                //float3x3 cam = setCamera( ro, ta, cr );
                //// camera ray    
                //rd = mul(cam ,normalize(float3(p,fl))) ;
                  
                moveCamera( 0.1, ro, ta, cr, fl );
                ro = _WorldSpaceCameraPos;
                rd = normalize(i.interpolatedRay.xyz);
                
                float4 res = render( ro, rd );
                float3 val = float3(0.0,0.0,0.0);
                //val = Noised(p);
                //val = float3(fbm(p),fbm(p),fbm(p));
                //val = length(p);
                val = res.xyz;
                //val = rd;
                return float4(val,1.0);

            }



            float4 frag(v2f i) : SV_Target{
                float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
                float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
                //get Unity world pos
                float4 finalColor = tex2D(_MainTex, i.uv);

                float4 processCol = ProcessFrag(i);
                if(processCol.w < linearDepth){
                    finalColor = processCol;
                    finalColor.w =1.0;
                }
                finalColor = processCol;
                finalColor.w =1.0;
                return finalColor;
            }




        ENDCG
    }//end pass
  }//end SubShader
}//end Shader

