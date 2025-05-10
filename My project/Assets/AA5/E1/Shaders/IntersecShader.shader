Shader "Custom/IntersectionGlow"
{
    Properties
    {
        _Offset("Offset", Float) = 0.6
        _EmissionColor("Emission Color", Color) = (0, 1, 1, 1)
        _Albedo("Albedo", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _CameraDepthTexture;
            float4 _EmissionColor;
            float4 _Albedo;
            float _Offset;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.pos);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float sceneDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w);
                float fragDepth = i.screenPos.z / i.screenPos.w;

                float diff = sceneDepth - fragDepth + _Offset;
                float alpha = smoothstep(0.0, 1.0, 1.0 - diff);

                float3 finalColor = _Albedo.rgb + _EmissionColor.rgb * alpha;
                return float4(finalColor, alpha);
            }
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}
