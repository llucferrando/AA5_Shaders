Shader "Unlit/ShieldShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0, 1, 2, 1)
        _Texture_Speed ("Texture Speed", Vector) = (0.1, 0.0, 0, 0)
        _Texture_Tiling ("Texture Tiling", Vector) = (1, 1, 0, 0)
        _ScanlineSpeed ("Scanline Speed", Float) = 1
        _ScanlineDensity ("Scanline Density", Float) = 50
        _Fresnel_Power ("Fresnel Power", Float) = 1
        _Depth_Blend ("Depth Blend", Float) = 3
        _SoftBlendIntensity ("Soft Blend Intensity", Float) = 1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;
            float2 _Texture_Speed;
            float4 _Texture_Tiling;
            float _Fresnel_Power;
            float4 _Color;
            float _ScanlineSpeed;
            float _ScanlineDensity;
            float _Depth_Blend;
            float _SoftBlendIntensity;

            float SoftLight(float a, float b)
            {
                return (1.0 - 2.0 * b) * a * a + 2.0 * b * a;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenSpace : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * _Texture_Tiling.xy + (_Time.y * _Texture_Speed);
                o.screenSpace = ComputeScreenPos(o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos.xyz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 screenUV = i.screenSpace.xy / i.screenSpace.w;

                // Scanlines
                float scanlinePos = frac(screenUV.y * _ScanlineDensity + _Time.y * _ScanlineSpeed);
                float scanline = smoothstep(0.4, 0.6, scanlinePos);
                float3 pattern = (col.rgb * scanline * _Color.rgb);

                // Profundidad
                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));

                // Fresnel
                float fresnel = pow(1 - dot(i.viewDir, i.normal), _Fresnel_Power);

                // Intersección
                float fragDepth = i.screenSpace.a;
                float offsetDepth = fragDepth - _Depth_Blend;
                float diff = depth - offsetDepth;
                float intersectionGlow = smoothstep(0.0, 1.0, 1.0 - diff);

                float totalGlow = fresnel + intersectionGlow;
                float3 glowColor = totalGlow * _Color.rgb;

                // SoftLight blend
                float3 softBlend;
                softBlend.r = SoftLight(totalGlow, pattern.r);
                softBlend.g = SoftLight(totalGlow, pattern.g);
                softBlend.b = SoftLight(totalGlow, pattern.b);

                float3 finalColor = pattern + glowColor;
                float alpha = dot(softBlend, float3(1, 1, _SoftBlendIntensity)) ;

                return fixed4(finalColor, saturate(alpha));
            }
            ENDCG
        }
    }
}
