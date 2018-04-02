using UnityEngine;
using System.Collections;
using System.Text.RegularExpressions;

public class CodeGenerator
{
    public static CodeGenerator _instance;
    public static CodeGenerator instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = new CodeGenerator();
            }
            return _instance;
        }
    }//SingleTon

    private enum types { Texture, Int, Float, Vector, Color }
    private types Types;

    [HideInInspector]
    public string ShaderName;
    string Result;

    string BaseShader;


    #region MainFunctions
    public void Init()
    {
        //BaseShader = BaseShader.BaseReplace("ShaderName",ShaderName);
        BaseShader = @"Shader ""FishManShaderTutorial/ShaderName""{
	Properties{
	    //Properties
	}

	SubShader
	{
	    Tags { ""RenderType"" = ""Transparent"" ""Queue"" = ""Transparent"" }

	    Pass
	    {
	        ZWrite Off
	        Blend SrcAlpha OneMinusSrcAlpha

	        CGPROGRAM
	        #pragma vertex vert
	        #pragma fragment frag
	        #include ""UnityCG.cginc""

            struct v2f {
		        float4 pos : SV_POSITION;
		        half2 uv : TEXCOORD0;
		        half2 uv_depth : TEXCOORD1;
		        float4 interpolatedRay : TEXCOORD2;
	        };

		    float4x4 _FrustumCornersRay;
	        half4 _MainTex_TexelSize;
	        sampler2D _CameraDepthTexture;
	        //Variables


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
	        }//end vect

            fixed4 ProcessFrag(v2f i);


	        fixed4 frag(v2f i) : SV_Target
	        {
                float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
		        float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
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
	        //Functions

//-----------------------------------------------------
	
            fixed4 ProcessFrag(v2f i)  {
                 //MainImage
        
                return fixed4(col, 1.0);
            }

//-----------------------------------------------------
	    ENDCG
	    }//end pass
    }//end SubShader
}//end Shader
";

    }

    #endregion




    public object Convert(string input)
    {
        var mainImage = Regex.Match(input, @"void\s+mainImage[^\{]+\{([^}]+)\}", RegexOptions.Multiline | RegexOptions.Singleline);
        var functions = Regex.Match(input, @"(.*)(?=void mainImage)", RegexOptions.Multiline | RegexOptions.Singleline);
        BaseReplace("ShaderName", ShaderName);
        BaseReplace("//MainImage", mainImage.Groups[1].Value);
        BaseReplace("//Functions", functions.Groups[1].Value);



        var mainImageComponents = Regex.Match(input, @"void\s+mainImage\(\s*out\s*vec4\s*(.+?)\s*\,\s*in\s*vec2\s*(.+?)\s*\)", RegexOptions.Multiline | RegexOptions.Singleline);
        var fragColor = mainImageComponents.Groups[1].Value;
        var fragCoord = mainImageComponents.Groups[2].Value;

        BaseReplace(fragColor, "fragColor");
        BaseReplace(fragCoord, "fragCoord");



        //news
        BaseReplace(@"\=\s*vec3\(([^;,]+)\)", "= vec3($1,$1,$1)", RegexOptions.Multiline | RegexOptions.Singleline);
        BaseReplace(@"\=\s*vec4\(([^;,]+)\)", "= vec3($1,$1,$1,$1)", RegexOptions.Multiline | RegexOptions.Singleline);

        BaseReplace("ivec", "int");
        BaseReplace("vec|half|float", "fixed");
        BaseReplace("mix", "lerp");
        BaseReplace("iGlobalTime", "_Time.y");
        BaseReplace("fragColor =", "return");
        BaseReplace("fract", "frac");
        BaseReplace(@"ifixed(\d)", "fixed$1");//ifixed to fixed
        BaseReplace("texture", "tex2D");
        BaseReplace("tex2DLod", "tex2Dlod");
        BaseReplace("refrac", "refract");
        BaseReplace("iChannel0", "_MainTex");
        BaseReplace("iChannel1", "_SecondTex");
        BaseReplace("iChannel2", "_ThirdTex");
        BaseReplace("iChannel3", "_FourthTex");
        //BaseReplace( "fragCoord", "i.vertex");
        BaseReplace(@"iResolution.((x|y){1,2})?", "1");
        BaseReplace(@"fragCoord.xy / iResolution.xy", "i.uv");
        BaseReplace(@"fragCoord(.xy)?", "i.uv");
        BaseReplace(@"iResolution(\.(x|y){1,2})?", "1");

        BaseReplace("iMouse", "_iMouse");
        BaseReplace("mat2", "fixed2x2");
        BaseReplace("mat3", "fixed3x3");
        BaseReplace("mat4", "fixed4x4");
        //BaseReplace( @"(m)\*(p)", "mul($1,$2)");
        BaseReplace("mod", "fmod");
        BaseReplace(@"for\(", "[unroll(100)]\nfor(");
        BaseReplace("iTime", "_Time.y");
        BaseReplace(@"(tex2Dlod\()([^,]+\,)([^)]+\)?[)]+.+(?=\)))", "$1$2float4($3,0)");
        BaseReplace(@"fixed4\(([^(,]+?)\)", "fixed4($1,$1,$1,$1)");
        BaseReplace(@"fixed3\(([^(,]+?)\)", "fixed3($1,$1,$1)");
        BaseReplace(@"fixed2\(([^(,]+?)\)", "fixed2($1,$1)");
        BaseReplace(@"tex2D\(([^,]+)\,\s*fixed2\(([^,].+)\)\,(.+)\)", "tex2Dlod($1,fixed4($2,fixed2($3,$3)))");//when vec3 col = texture( iChannel0, vec2(uv.x,1.0-uv.y), lod ).xyz; -> https://www.shadertoy.com/view/4slGWn
        //BaseReplace( @"#.+","");
        BaseReplace(@"texelFetch", "tex2D");//badan bokonesh texlod
        BaseReplace(@"atan\(([^,]+?)\,([^,]+?)\)", "atan2($2,$1)");//badan bokonesh texlod
        //BaseReplace( "([*+\\/-])\\s*(pi|PI)", "$13.14159265359");

        BaseReplace("gl_FragCoord", "((i.screenCoord.xy/i.screenCoord.w)*_ScreenParams.xy)");
        //BaseReplace( @"(.+\s*)(\*\=)\s*([^ ;*+\/]+)", "$1 = mul($1,$3)");

        if (BaseShader.Contains("_MainTex"))
        {
            Decelaration("MainTex", types.Texture);
        }
        if (BaseShader.Contains("_SecondTex"))
        {
            Decelaration("SecondTex", types.Texture);
        }
        if (BaseShader.Contains("_ThirdTex"))
        {
            Decelaration("ThirdTex", types.Texture);
        }
        if (BaseShader.Contains("_FourthTex"))
        {
            Decelaration("FourthTex", types.Texture);
        }

        if (BaseShader.Contains("iMouse"))
        {
            Decelaration("iMouse", types.Vector);
        }
        if (BaseShader.Contains("iDate"))
        {
            Decelaration("iDate", types.Vector);
        }


        return BaseShader;
    }


    void Decelaration(string name, types type)
    {

        string VariableType = "";
        string Initialize = "";
        string CorrespondingVariable = "";

        switch (type)
        {
            case types.Int:
                VariableType = "int";
                CorrespondingVariable = "int";
                Initialize = "0";
                break;
            case types.Float:
                VariableType = "float";
                CorrespondingVariable = "float";
                Initialize = "0";
                break;
            case types.Texture:
                VariableType = "2D";
                CorrespondingVariable = "sampler2D";
                Initialize = @"""white"" {}";

                break;
            case types.Color:
                VariableType = "Color";
                CorrespondingVariable = "float4";
                Initialize = "(0,0,0,0)";
                break;
            case types.Vector:
                VariableType = "Vector";
                CorrespondingVariable = "float4";
                Initialize = "(0,0,0,0)";
                break;
            default:
                VariableType = "int";
                CorrespondingVariable = "int";
                Initialize = "0";
                break;
        }
        CorrespondingVariable += " _" + name + ";";//for example sampler2D _MainTex;

        string Properties = @"_name (""name"", type) = initialize";
        Properties = Regex.Replace(Properties, "name", name);
        Properties = Regex.Replace(Properties, "type", VariableType);
        Properties = Regex.Replace(Properties, "initialize", Initialize);
        BaseReplace("//Properties", Properties);
        BaseReplace("//Variables", "$0\n" + CorrespondingVariable);
    }



    void BaseReplace(string pattern, string replacement)
    {
        try
        {

            BaseShader = Regex.Replace(BaseShader, pattern, replacement);
        }
        catch (System.Exception)
        {
            Debug.Log("");
            throw;
        }
    }

    void BaseReplace(string pattern, string replacement, RegexOptions options)
    {
        BaseShader = Regex.Replace(BaseShader, pattern, replacement, options);
    }
}
