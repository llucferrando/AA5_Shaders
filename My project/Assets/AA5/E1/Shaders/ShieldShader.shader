Shader "Custom/AnimatedParticles"
{
    Properties
    {
        _Color ("Particle Color", Color) = (1,1,1,1)
        _Density ("Density", Float) = 20.0
        _Speed ("Speed", Float) = 1.0
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
            #include "UnityCG.cginc"

            fixed4 _Color;
            float _Density;
            float _Speed;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv * _Density;
                uv.x += _Time.y * _Speed;

                float2 cell = floor(uv);
                float2 f = frac(uv);

                float noise = sin(dot(cell, float2(12.9898,78.233))) * 43758.5453;
                float rnd = frac(noise);

                float dist = length(f - float2(rnd, frac(sin(_Time.y + rnd * 10.0))));

                float alpha = smoothstep(0.05, 0.02, dist);

                return fixed4(_Color.rgb, alpha * _Color.a);
            }
            ENDCG
        }
    }
}
