
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
	        
// Sphere intersection
fixed sphIntersect( in fixed3 ro, in fixed3 rd, in fixed4 sph )
{
	fixed3 oc = ro - sph.xyz;
	fixed b = dot( oc, rd );
	fixed c = dot( oc, oc ) - sph.w*sph.w;
	fixed h = b*b - c;
	if( h<0.0 ) return -1.0;
	return -b - sqrt( h );
}

//=====================================================

fixed2 hash2( fixed n ) { return frac(sin(fixed2(n,n+1.0))*fixed2(43758.5453123,22578.1459123)); }




//-----------------------------------------------------
	
            fixed4 ProcessFrag(v2f i)  {
                 
	fixed2 p = (2.0*i.uv-1) / 1;
    fixed s = (2.0*_iMouse.x-1) / 1;
    if( _iMouse.z<0.001 ) s=0.0;
    
	fixed3 ro = fixed3(0.0, 0.0, 4.0 );
	fixed3 rd = normalize( fixed3(p,-2.0) );
	
    // sphere animation
    fixed4 sph = fixed4( cos( _Time.y + fixed3(2.0,1.0,1.0) + 0.0 )*fixed3(1.5,1.2,1.0), 1.0 );

    fixed4 rrr = tex2D( _MainTex, (i.uv)/iChannelResolution[0].xy, -99.0  ).xzyw;


    fixed3 col = fixed3(0.0,0.0,0.0);

    fixed tmin = 1e10;


    fixed t2 = sphIntersect( ro, rd, sph );
    if( t2>0.0 && t2<tmin )
    {
        tmin = t2;
        fixed t = t2;
        fixed3 pos = ro + t*rd;
        fixed3 nor = normalize( pos - sph.xyz );
		col = fixed3(1.2,1.2,1.2);
        col *= 0.6+0.4*nor.y;
	
        
                return fixed4(col, 1.0);
            }

//-----------------------------------------------------
	    ENDCG
	    }//end pass
    }//end SubShader
}//end Shader

