
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
	        

const fixed2x2 m2 = fixed2x2(0.8,-0.6,0.6,0.8);

fixed fbm( fixed2 p )
{
    fixed f = 0.0;
    f += 0.5000*tex2D( _MainTex, p/256.0, -100. ).x; p = m2*p*2.02;
    f += 0.2500*tex2D( _MainTex, p/256.0, -100. ).x; p = m2*p*2.03;
    f += 0.1250*tex2D( _MainTex, p/256.0, -100. ).x; p = m2*p*2.01;
    f += 0.0625*tex2D( _MainTex, p/256.0, -100. ).x;
    return f/0.9375;
}

fixed2 map (in fixed3 p) {
	fixed mountains = 19. * fbm(p.xz*0.091);
    fixed trees = -.35 * fbm(p.xz*10.);
    fixed rocks = -.002 * fbm(p.xz*100.);
    fixed result = p.y + mountains + trees + rocks;
    
    return fixed2(result, 1.0);
}

fixed3 mapColour (in fixed3 pos, in fixed3 nor) {    
    fixed darken = (1.0 - 0.5 * length(normalize(pos)));
	fixed3 tint = fixed3(.7, .7, .6);
    fixed3 tex2D = tex2D( _SecondTex, 0.006125*pos.xz, -100. ).xyz;
    
    return  tex2D * tint;
}

fixed2 raymarch (in fixed3 ro, in fixed3 rd) {
    fixed2 h = fixed2(0.001, 0.);
    fixed t = 0.;
    fixed tmax = 100.;
    
    for (int i = 0; i < 100; i++){
        if (h.x < 0.0001 || t > tmax) break;
        h = map(ro + t * rd);
        t += 0.25 * h.x;
    }
    
    if(t > tmax) h.y = -1.;
    
    return fixed2(t, h.y);
}

fixed shadow( in fixed3 ro, in fixed3 rd, in fixed maxt)
{
	fixed res = 1.0;
    fixed dt = 0.04;
    fixed t = .02;
    [unroll(100)]
for( int i=0; i < 20; i++ )
    {       
        fixed h = map(ro + rd*t).x;
        if( h<0.001 )
            return 0.0;
        res = min( res, maxt*h/t );
        t += h;
    }
    return res;
}

fixed3 calcNormal( in fixed3 pos, in fixed t )
{
    // show more detail the closer we are to the object
    fixed3  eps = fixed3(0.002 * t,0.0,0.0);
    fixed3 nor;
    nor.x = map(pos+eps.xyy).x - map(pos-eps.xyy).x;
    nor.y = map(pos+eps.yxy).x - map(pos-eps.yxy).x;
    nor.z = map(pos+eps.yyx).x - map(pos-eps.yyx).x;
    return normalize(nor);
}



//-----------------------------------------------------
	
fixed4 ProcessFrag(v2f i)  {
                 
	fixed2 q = i.uv / 1;
    fixed2 p = -1.0 + 2.0 * q;
    p.x *= 1/1;
    fixed2 mo = _iMouse.xy/1;
	
    // camera
	fixed an1 = 0.2*_Time.y-6.2831*mo.x;
	fixed an2 = clamp( 0.8 + 0.6*sin(2.2+_Time.y*0.11)  + 1.0*mo.y, 0.3, 1.35 );
    fixed3 ro = 10.0*normalize(fixed3(sin(an2)*cos(an1), cos(an2)-0.5, sin(an2)*sin(an1) ));
    fixed3 ww = normalize(fixed3(0.0,0.0,0.0) - ro);
    fixed3 uu = normalize(cross( fixed3(0.0,1.0,0.0), ww ));
    fixed3 vv = normalize(cross(ww,uu));
    fixed3 rd = normalize( p.x*uu + p.y*vv - 1.4*ww );

    // raymarch
    fixed3 col = fixed3(0.,0.,0.);//tex2D( _MainTex, rd ).xyz;
    fixed2 march = raymarch(ro, rd);
    
    fixed3 light = normalize(fixed3(0.9, 0.1, 0.9));
    fixed3 ambient = 5. * fixed3(0.1, 0.15, 0.2);
    fixed sundot = clamp(dot(rd,light),0.0,1.0);
    fixed3 pos = ro + march.x * rd;
    
    // if we hit geometry
    if(march.y > 0.) {
        fixed3 nor = calcNormal(pos, march.x);
        
        fixed lambert = clamp(dot(nor, light), 0., 1.);
        col = mapColour(pos, nor);
        col = lerp( col, mapColour(pos, nor) * lambert, 0.8);
        
        //snow
        //fixed snow = clamp(dot(normalize(nor), fixed3(0., 1., 0.)), 0., 1.);
        //snow = pow(snow, 5.);
        //col = lerp(col, fixed3(1.,1.,1.)*snow, clamp(rd.y + 1., 0., 1.)*0.5);
        
        // fog
        fixed fo = 1.-exp(-0.04*march.x );
        fixed3 fco = 0.9*fixed3(0.5,0.7,0.9) + 0.1*fixed3(1.0,0.8,0.5)*pow( sundot, 4.0 );
		col = lerp( col, fco, fo );
        
        fixed sh = shadow( pos, light, 10.);
    	col = 0.8*col + 0.2* col* sh ;// + ambient * (1.0 - sh);
    
     }
	 // sky
    if(march.y < 0.){
        // sky colour        
        float3 blueSky = float3(0.3,.55,0.8);
        float3 redSky = float3(0.8,0.8,0.6);
        
        float3 sky = lerp(blueSky, redSky, 1.5*pow(sundot, 8.));
        
        col =  sky*(1.0-0.8*rd.y);
        
        // stars
        float s = texture( iChannel0, rd.xz * 1.25, -100. ).x;
        s += texture( iChannel0, rd.xz* 4., -100. ).x;
        
        s = pow(s, 17.0) * 0.00005 * max(rd.y, -0.2) * pow((1. - max(sundot, 0.)), 2.); 
        if (s > .0)
        {
            float3 backStars = float3(s);
            col += backStars;
        }
        
        // sun
        col += 0.1*float3(0.9, 0.3, 0.9)*pow(sundot, 0.5);
        col += 0.2*float3(1., 0.7, 0.7)*pow(sundot, 1.);
        col += 0.95*float3(1.)*pow(sundot, 256.);
        
        // clouds
        float cloudSpeed = 0.01;
        float cloudFlux = 0.5;
        
        // layer 1
        float3 cloudColour = lerp(float3(1.0,0.95,1.0), 0.35*redSky,pow(sundot, 2.));
        
    float2 sc = cloudSpeed * 50.*iTime * ro.xz + rd.xz*(1000.0-ro.y)/rd.y;
    col = lerp( col, cloudColour, 0.5*smoothstep(0.5,0.8,fbm(0.0005*sc+fbm(0.0005*sc+iTime*cloudFlux))));
        
        // cloud layer 2
        sc = cloudSpeed * 30.*iTime * ro.xz + rd.xz*(500.0-ro.y)/rd.y;
    col = lerp( col, cloudColour, 0.5*smoothstep(0.5,0.8,fbm(0.0002*sc+fbm(0.0005*sc+iTime*cloudFlux))));
        
        // horizon        
        col = lerp( col, 0.9*float3(0.9,0.75,0.8), pow( 1.-max(rd.y+0.1,0.0), 8.0));
        
        
    }
    // contrast
    col = clamp(col, 0., 1.);
    col = col*col*(3.0-2.0*col);
    
    
    // saturation (amplify colour, subtract grayscale)
    float sat = 0.2;
    col = col * (1. + sat) - sat*dot(col, float3(0.33));
    
    // vignette
    col = col * (1.0 - dot(p, p) * 0.1);
    
  fragColor = float4(col,1.0);
  }
//-----------------------------------------------------
	    ENDCG
	    }//end pass
    }//end SubShader
}//end Shader

