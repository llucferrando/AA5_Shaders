Shader "Custom/ShieldScroll"
{
    Properties
    {
        _TextureSpeed("Texture Speed", Vector) = (0.1, 0, 0, 0)
        _MainColor("Main Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 _TextureSpeed;
            float4 _MainColor;

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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv + (_Time.y * _TextureSpeed.xy); // desplazamiento con el tiempo
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float value = sin(i.uv.x * 10) * 0.5 +0.5+0.5;
                return float4(value, value, value, 1) * _MainColor;
            }
            ENDCG
        }
    }
}
