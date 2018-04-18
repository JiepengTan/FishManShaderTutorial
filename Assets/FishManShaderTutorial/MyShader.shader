
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
float4 _iMouse;
sampler2D _SecondTex;
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
	        // Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// on the derivatives based noise: http://iquilezles.org/www/articles/morenoise/morenoise.htm
// on the soft shadow technique: http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
// on the fog calculations: http://iquilezles.org/www/articles/fog/fog.htm
// on the lighting: http://iquilezles.org/www/articles/outdoorslighting/outdoorslighting.htm
// on the raymarching: http://iquilezles.org/www/articles/terrainmarching/terrainmarching.htm


#define AA 1   // make this 2 or even 3 if you have a really powerful GPU


#define SC (250.0)

// value noise, and its analytical derivatives
fixed3 noised( in fixed2 x )
{
    fixed2 f = frac(x);
    fixed2 u = f*f*(3.0-2.0*f);

#if 1
    // texel fetch version
    int2 p = int2(floor(x));
    fixed a = tex2D( _MainTex, (p+int2(0,0))&255, 0 ).x;
	fixed b = tex2D( _MainTex, (p+int2(1,0))&255, 0 ).x;
	fixed c = tex2D( _MainTex, (p+int2(0,1))&255, 0 ).x;
	fixed d = tex2D( _MainTex, (p+int2(1,1))&255, 0 ).x;
#else    
    // tex2D version    
    fixed2 p = floor(x);
	fixed a = tex2Dlod( _MainTex,float4( (p+fixed2(0.5,0.5))/256.0, 0.0 ,0)).x;
	fixed b = tex2Dlod( _MainTex,float4( (p+fixed2(1.5,0.5))/256.0, 0.0 ,0)).x;
	fixed c = tex2Dlod( _MainTex,float4( (p+fixed2(0.5,1.5))/256.0, 0.0 ,0)).x;
	fixed d = tex2Dlod( _MainTex,float4( (p+fixed2(1.5,1.5))/256.0, 0.0 ,0)).x;
#endif
    
	return fixed3(a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y,
				6.0*f*(1.0-f)*(fixed2(b-a,c-a)+(a-b-c+d)*u.yx));
}

const fixed2x2 m2 = fixed2x2(0.8,-0.6,0.6,0.8);


fixed terrainH( in fixed2 x )
{
	fixed2  p = x*0.003/SC;
    fixed a = 0.0;
    fixed b = 1.0;
	fixed2  d = fixed2(0.0,0.0);
    [unroll(100)]
for( int i=0; i<15; i++ )
    {
        fixed3 n = noised(p);
        d += n.yz;
        a += b*n.x/(1.0+dot(d,d));
		b *= 0.5;
        p = m2*p*2.0;
    }

	return SC*120.0*a;
}

fixed terrainM( in fixed2 x )
{
	fixed2  p = x*0.003/SC;
    fixed a = 0.0;
    fixed b = 1.0;
	fixed2  d = fixed2(0.0,0.0);
    [unroll(100)]
for( int i=0; i<9; i++ )
    {
        fixed3 n = noised(p);
        d += n.yz;
        a += b*n.x/(1.0+dot(d,d));
		b *= 0.5;
        p = m2*p*2.0;
    }
	return SC*120.0*a;
}

fixed terrainL( in fixed2 x )
{
	fixed2  p = x*0.003/SC;
    fixed a = 0.0;
    fixed b = 1.0;
	fixed2  d = fixed2(0.0,0.0);
    [unroll(100)]
for( int i=0; i<3; i++ )
    {
        fixed3 n = noised(p);
        d += n.yz;
        a += b*n.x/(1.0+dot(d,d));
		b *= 0.5;
        p = m2*p*2.0;
    }

	return SC*120.0*a;
}

fixed interesct( in fixed3 ro, in fixed3 rd, in fixed tmin, in fixed tmax )
{
    fixed t = tmin;
	[unroll(100)]
for( int i=0; i<256; i++ )
	{
        fixed3 pos = ro + t*rd;
		fixed h = pos.y - terrainM( pos.xz );
		if( h<(0.002*t) || t>tmax ) break;
		t += 0.5*h;
	}

	return t;
}

fixed softShadow(in fixed3 ro, in fixed3 rd )
{
    fixed res = 1.0;
    fixed t = 0.001;
	[unroll(100)]
for( int i=0; i<80; i++ )
	{
	    fixed3  p = ro + t*rd;
        fixed h = p.y - terrainM( p.xz );
		res = min( res, 16.0*h/t );
		t += h;
		if( res<0.001 ||p.y>(SC*200.0) ) break;
	}
	return clamp( res, 0.0, 1.0 );
}

fixed3 calcNormal( in fixed3 pos, fixed t )
{
    fixed2  eps = fixed2( 0.002*t, 0.0 );
    return normalize( fixed3( terrainH(pos.xz-eps.xy) - terrainH(pos.xz+eps.xy),
                            2.0*eps.x,
                            terrainH(pos.xz-eps.yx) - terrainH(pos.xz+eps.yx) ) );
}

fixed fbm( fixed2 p )
{
    fixed f = 0.0;
    f += 0.5000*tex2D( _MainTex, p/256.0 ).x; p = m2*p*2.02;
    f += 0.2500*tex2D( _MainTex, p/256.0 ).x; p = m2*p*2.03;
    f += 0.1250*tex2D( _MainTex, p/256.0 ).x; p = m2*p*2.01;
    f += 0.0625*tex2D( _MainTex, p/256.0 ).x;
    return f/0.9375;
}

const fixed kMaxT = 5000.0*SC;

fixed4 render( in fixed3 ro, in fixed3 rd )
{
    fixed3 light1 = normalize( fixed3(-0.8,0.4,-0.3) );
    // bounding plane
    fixed tmin = 1.0;
    fixed tmax = kMaxT;
#if 1
    fixed maxh = 300.0*SC;
    fixed tp = (maxh-ro.y)/rd.y;
    if( tp>0.0 )
    {
        if( ro.y>maxh ) tmin = max( tmin, tp );
        else            tmax = min( tmax, tp );
    }
#endif
	fixed sundot = clamp(dot(rd,light1),0.0,1.0);
	fixed3 col;
    fixed t = interesct( ro, rd, tmin, tmax );
    if( t>tmax)
    {
        // sky		
        col = fixed3(0.2,0.5,0.85)*1.1 - rd.y*rd.y*0.5;
        col = lerp( col, 0.85*fixed3(0.7,0.75,0.85), pow( 1.0-max(rd.y,0.0), 4.0 ) );
        // sun
		col += 0.25*fixed3(1.0,0.7,0.4)*pow( sundot,5.0 );
		col += 0.25*fixed3(1.0,0.8,0.6)*pow( sundot,64.0 );
		col += 0.2*fixed3(1.0,0.8,0.6)*pow( sundot,512.0 );
        // clouds
		fixed2 sc = ro.xz + rd.xz*(SC*1000.0-ro.y)/rd.y;
		col = lerp( col, fixed3(1.0,0.95,1.0), 0.5*smoothstep(0.5,0.8,fbm(0.0005*sc/SC)) );
        // horizon
        col = lerp( col, 0.68*fixed3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
        t = -1.0;
	}
	else
	{
        // mountains		
		fixed3 pos = ro + t*rd;
        fixed3 nor = calcNormal( pos, t );
        //nor = normalize( nor + 0.5*( fixed3(-1.0,0.0,-1.0) + fixed3(2.0,1.0,2.0)*tex2D(_SecondTex,0.01*pos.xz).xyz) );
        fixed3 ref = reflect( rd, nor );
        fixed fre = clamp( 1.0+dot(rd,nor), 0.0, 1.0 );
        fixed3 hal = normalize(light1-rd);
        
        // rock
		fixed r = tex2D( _MainTex, (7.0/SC)*pos.xz/256.0 ).x;
        col = (r*0.25+0.75)*0.9*lerp( fixed3(0.08,0.05,0.03), fixed3(0.10,0.09,0.08), 
                                     tex2D(_MainTex,0.00007*fixed2(pos.x,pos.y*48.0)/SC).x );
		col = lerp( col, 0.20*fixed3(0.45,.30,0.15)*(0.50+0.50*r),smoothstep(0.70,0.9,nor.y) );
        col = lerp( col, 0.15*fixed3(0.30,.30,0.10)*(0.25+0.75*r),smoothstep(0.95,1.0,nor.y) );

		// snow
		fixed h = smoothstep(55.0,80.0,pos.y/SC + 25.0*fbm(0.01*pos.xz/SC) );
        fixed e = smoothstep(1.0-0.5*h,1.0-0.1*h,nor.y);
        fixed o = 0.3 + 0.7*smoothstep(0.0,0.1,nor.x+h*h);
        fixed s = h*e*o;
        col = lerp( col, 0.29*fixed3(0.62,0.65,0.7), smoothstep( 0.1, 0.9, s ) );
		
         // lighting		
        fixed amb = clamp(0.5+0.5*nor.y,0.0,1.0);
		fixed dif = clamp( dot( light1, nor ), 0.0, 1.0 );
		fixed bac = clamp( 0.2 + 0.8*dot( normalize( fixed3(-light1.x, 0.0, light1.z ) ), nor ), 0.0, 1.0 );
		fixed sh = 1.0; if( dif>=0.0001 ) sh = softShadow(pos+light1*SC*0.05,light1);
		
		fixed3 lin  = fixed3(0.0,0.0,0.0);
		lin += dif*fixed3(7.00,5.00,3.00)*1.3*fixed3( sh, sh*sh*0.5+0.5*sh, sh*sh*0.8+0.2*sh );
		lin += amb*fixed3(0.40,0.60,1.00)*1.2;
        lin += bac*fixed3(0.40,0.50,0.60);
		col *= lin;
        
        //col += s*0.1*pow(fre,4.0)*fixed3(7.0,5.0,3.0)*sh * pow( clamp(dot(nor,hal), 0.0, 1.0),16.0);
        col += s*
               (0.04+0.96*pow(clamp(1.0+dot(hal,rd),0.0,1.0),5.0))*
               fixed3(7.0,5.0,3.0)*dif*sh*
               pow( clamp(dot(nor,hal), 0.0, 1.0),16.0);
        
        
        col += s*0.1*pow(fre,4.0)*fixed3(0.4,0.5,0.6)*smoothstep(0.0,0.6,ref.y);

		// fog
        fixed fo = 1.0-exp(-pow(0.001*t/SC,1.5) );
        fixed3 fco = 0.65*fixed3(0.4,0.65,1.0);// + 0.1*fixed3(1.0,0.8,0.5)*pow( sundot, 4.0 );
        col = lerp( col, fco, fo );

	}
    // sun scatter
    col += 0.3*fixed3(1.0,0.7,0.3)*pow( sundot, 8.0 );

    // gamma
	col = sqrt(col);
    
	return fixed4( col, t );
}

fixed3 camPath( fixed time )
{
	return SC*1100.0*fixed3( cos(0.0+0.23*time), 0.0, cos(1.5+0.21*time) );
}

fixed3x3 setCamera( in fixed3 ro, in fixed3 ta, in fixed cr )
{
	fixed3 cw = normalize(ta-ro);
	fixed3 cp = fixed3(sin(cr,sin(cr,sin(cr), cos(cr),0.0);
	fixed3 cu = normalize( cross(cw,cp) );
	fixed3 cv = normalize( cross(cu,cw) );
    return fixed3x3( cu, cv, cw );
}

void moveCamera( fixed time, out fixed3 oRo, out fixed3 oTa, out fixed oCr, out fixed oFl )
{
	fixed3 ro = camPath( time );
	fixed3 ta = camPath( time + 3.0 );
	ro.y = terrainL( ro.xz ) + 19.0*SC;
	ta.y = ro.y - 20.0*SC;
	fixed cr = 0.2*cos(0.1*time);
    oRo = ro;
    oTa = ta;
    oCr = cr;
    oFl = 3.0;
}



//-----------------------------------------------------
	
            fixed4 ProcessFrag(v2f i)  {
                 
    fixed time = _Time.y*0.1 - 0.1 + 0.3 + 4.0*_iMouse.x/1;

    // camera position
    fixed3 ro, ta; fixed cr, fl;
    moveCamera( time, ro, ta, cr, fl );

    // camera2world transform    
    fixed3x3 cam = setCamera( ro, ta, cr );

    // pixel
    fixed2 p = (-1 + 2.0*i.uv)/1;

    fixed t = kMaxT;
    fixed3 tot = fixed3(0.0,0.0,0.0);
	#if AA>1
    [unroll(100)]
for( int m=0; m<AA; m++ )
    [unroll(100)]
for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        fixed2 o = fixed2(fixed(m),fixed(n)) / fixed(AA) - 0.5;
        fixed2 s = (-1 + 2.0*(i.uv+o))/1;
	#else    
        fixed2 s = p;
	#endif

        // camera ray    
        fixed3 rd = cam * normalize(fixed3(s,fl));

        fixed4 res = render( ro, rd );
        t = min( t, res.w );
 
        tot += res.xyz;
	#if AA>1
    
        
                return fixed4(col, 1.0);
            }

//-----------------------------------------------------
	    ENDCG
	    }//end pass
    }//end SubShader
}//end Shader

