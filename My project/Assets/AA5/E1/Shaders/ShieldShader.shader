Shader "Custom/ShieldFinal"
{
    Properties
    {
        _HexTexture("Hex Texture", 2D) = "white" {}
        _TextureSpeed("Texture Speed", Vector) = (0.0, -0.1, 0, 0)
        _HexTiling("Hex Tiling", Vector) = (4, 4, 0, 0)
        _MainColor("Main Color", Color) = (0, 1, 1, 1)
        _GlowColor("Glow Color", Color) = (1, 0.5, 0, 1)
        _FresnelColor("Fresnel Color", Color) = (0, 0.7, 1, 1)
        _FresnelPower("Fresnel Power", Range(1, 8)) = 3
        _AlphaThreshold("Alpha Threshold", Range(0, 1)) = 0.2

        _ScanlineFrequency("Scanline Frequency", Float) = 600
        _ScanlineSpeed("Scanline Speed", Float) = 2
        _ScanlineIntensity("Scanline Intensity", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        ZTest LEqual
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _HexTexture;
            sampler2D_float _CameraDepthTexture;

            float4 _TextureSpeed;
            float4 _HexTiling;
            float4 _MainColor;
            float4 _GlowColor;
            float4 _FresnelColor;
            float _FresnelPower;
            float _AlphaThreshold;

            float _ScanlineFrequency;
            float _ScanlineSpeed;
            float _ScanlineIntensity;

            // Soft Light Blend
            float SoftLight(float a, float b)
            {
                return (1.0 - 2.0 * b) * a * a + 2.0 * b * a;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
            };

            v2f vert(appdata v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv * _HexTiling.xy + (_Time.y * _TextureSpeed.xy);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldViewDir = normalize(_WorldSpaceCameraPos - worldPos.xyz);
                o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Sample hex pattern
                float4 tex = tex2D(_HexTexture, i.uv);
                float texValue = tex.r;
                if (texValue < _AlphaThreshold)
                    discard;

                // Scanlines (screenspace)
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                float scan = sin(screenUV.y * _ScanlineFrequency + _Time.y * _ScanlineSpeed);
                float scanValue = smoothstep(0.3, 0.7, scan * 0.5 + 0.5) * _ScanlineIntensity;

                // Final pattern input = hex × scanlines
                float blendInput = texValue * scanValue;

                // Glow (Fresnel + Intersection)
                float fresnel = pow(1.0 - saturate(dot(i.worldViewDir, i.worldNormal)), _FresnelPower);

                float sceneZ = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r);
                float fragZ = LinearEyeDepth(i.screenPos.z);
                float depthFade = smoothstep(0.05, 0.0, abs(sceneZ - fragZ));

                float glowValue = fresnel + depthFade;

                // Final alpha using soft light
                float finalAlpha = SoftLight(glowValue, blendInput);
                finalAlpha = saturate(finalAlpha);

                // Color based on inputs
                float4 baseColor = _MainColor * blendInput;
                float4 fresnelGlow = _FresnelColor * fresnel;
                float4 intersectionGlow = _GlowColor * depthFade;

                float4 color = baseColor + fresnelGlow + intersectionGlow;
                color.a = finalAlpha;

                return color;
            }
            ENDCG
        }
    }
}
