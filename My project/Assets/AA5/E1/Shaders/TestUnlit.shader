Shader "Unlit/TestUnlitScrolling"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ColorOne ("Color One", Color) = (1,1,1,1)
        _ColorTwo ("Color Two", Color) = (1,1,1,1)
        _FresnelGlowColor("Fresnel Glow Color", Color) = (0, 0.7, 1, 1)
        _Ramp ("Ramp", Float) = 1
        _ScrollSpeed ("Scroll Speed", Vector) = (0.1, 0.0, 0, 0)
        _MainTexTiling ("Main Tex Tiling", Vector) = (1, 1, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
            float4 _ScrollSpeed;
            float4 _MainTexTiling;
            float4 _ColorOne, _ColorTwo;
            float _Ramp;
            float4 _FresnelGlowColor;

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

                // Scroll + tiling like in ShieldFinal_Builtin
                o.uv = v.uv * _MainTexTiling.xy + (_Time.y * _ScrollSpeed.xy);

                o.screenSpace = ComputeScreenPos(o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos.xyz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 screenSpaceUV = i.screenSpace.xy / i.screenSpace.w;
                float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenSpaceUV));
                float3 mixedColor = lerp(_ColorOne, _ColorTwo, depth);
                float fresnel = pow(1 - dot(i.viewDir, i.normal), _Ramp);
                float3 fresnelGlow = fresnel * _FresnelGlowColor.rgb;

                float3 finalColor = lerp(mixedColor, col.rgb, fresnel) + fresnelGlow;
                return fixed4(finalColor, 1);
            }
            ENDCG
        }
    }
}
