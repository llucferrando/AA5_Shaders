Shader "Custom/ShieldFinal_Builtin"
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

        _IntersectionOffset("Intersection Offset", Float) = 0.6
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
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

            float _IntersectionOffset;

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
                float3 viewDir : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
            };

            v2f vert(appdata v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv * _HexTiling.xy + (_Time.y * _TextureSpeed.xy);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos.xyz);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Hex pattern
                float4 tex = tex2D(_HexTexture, i.uv);
                float texVal = tex.r;
                if (texVal < _AlphaThreshold)
                    discard;

                // Scanlines (screen-space)
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                float scan = sin(screenUV.y * _ScanlineFrequency + _Time.y * _ScanlineSpeed);
                float scanVal = smoothstep(0.3, 0.7, scan * 0.5 + 0.5) * _ScanlineIntensity;

                float blendInput = texVal * scanVal;

                // Fresnel glow
                float fresnel = pow(1.0 - saturate(dot(i.viewDir, i.worldNormal)), _FresnelPower);

                // Intersection mask (Built-in friendly)
                float sceneRawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);
                float sceneDepth = Linear01Depth(sceneRawDepth);
                float fragDepth = i.screenPos.a - _IntersectionOffset;
                float interMask = smoothstep(0.0, 1.0, 1.0 - (sceneDepth - fragDepth));

                // Combine glow (fresnel + intersection)
                float glowVal = saturate(fresnel + interMask);

                // Final alpha (softlight blend)
                float finalAlpha = saturate(SoftLight(glowVal, blendInput));

                // Final color
                float4 baseColor = _MainColor * blendInput;
                float4 fresnelGlow = _FresnelColor * fresnel;
                float4 interGlow = _GlowColor * interMask;

                float4 color = baseColor + fresnelGlow + interGlow;
                color.a = finalAlpha;

                return color;
            }
            ENDCG
        }
    }
}
