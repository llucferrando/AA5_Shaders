Shader "Custom/Builtin_IntersectionGlow"
{
    Properties
    {
        _Offset("Offset", Float) = 0.6
        _Emission("Emission", Color) = (0, 1, 1, 1)
        _Albedo("Albedo", Color) = (1, 1, 1, 1)
        _AlphaClipThreshold("Alpha Clip Threshold", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _CameraDepthTexture;

            float _Offset;
            float4 _Emission;
            float4 _Albedo;
            float _AlphaClipThreshold;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.screenPos = ComputeScreenPos(o.pos);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 1. Obtener coordenadas de pantalla
                float2 screenUV = i.screenPos.xy / i.screenPos.w;

                // 2. Canal A del screenPos (como en Shader Graph Raw)
                float screenAlpha = i.screenPos.a;
                float offsetAlpha = screenAlpha - _Offset;

                // 3. Profundidad de la escena
                float rawSceneDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);
                float sceneDepth = Linear01Depth(rawSceneDepth);  // Compatibilidad Built-in

                // 4. Diferencia de profundidad e intersección
                float depthDiff = sceneDepth - offsetAlpha;
                float interMask = smoothstep(0.0, 1.0, 1.0 - depthDiff);

                // 5. Aplicar máscara de intersección al alpha
                float alpha = interMask;

                // Opcional: Clipping como en Shader Graph
                clip(alpha - _AlphaClipThreshold);

                // 6. Color final
                float3 color = _Albedo.rgb + _Emission.rgb * interMask;

                return float4(color, alpha);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
