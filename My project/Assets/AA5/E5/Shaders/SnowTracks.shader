Shader "Custom/NewSurfaceShader"
{
    Properties
    {
        _Tess("Tesselation", Range(1,32)) = 4
        _SurfaceColor ("SurfaceColor", Color) = (1,1,1,1)
        _SurfaceSnow ("SurfaceSnow", 2D) = "white" {}
        _CrackedColor ("CrackedColor", Color) = (1,1,1,1)
        _CrackedSnow ("CrackedSnow", 2D) = "white" {}
        _GroundColor ("GroundColor", Color) = (1,1,1,1)
        _GroundTex ("GroundTex", 2D) = "white" {}
        _Splat("SplatMap", 2D) =  "black" {}
        _Displacement("Displacement", Range(0,1.0))=0.3
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:disp tessellate:tessDistance 

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        #include "Tessellation.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            float _Tess;

            float4 tessDistance (appdata v0, appdata v1, appdata v2) {
                float minDist = 10.0;
                float maxDist = 25.0;
                return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
            }

            sampler2D _Splat;
            float _Displacement;

            void disp (inout appdata v)
            {
                float d = tex2Dlod(_Splat, float4(v.texcoord.xy,0,0)).r * _Displacement;
                v.vertex.xyz -= v.normal * d;
                v.vertex.xyz += v.normal* _Displacement;
            }

        sampler2D _CrackedSnow;
        fixed4 _CrackedColor;
        sampler2D _SurfaceSnow;
        fixed4 _SurfaceColor;
        sampler2D _GroundTex;
        fixed4 _GroundColor;

        struct Input
        {
            float2 uv_CrackedSnow;
            float2 uv_SurfaceSnow;
            float2 uv_Ground;
            float2 uv_Splat;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            half amount = tex2Dlod(_Splat, float4(IN.uv_Splat,0,0)).r;
            // Albedo comes from a texture tinted by color
            fixed4 c= lerp(tex2D(_SurfaceSnow, IN.uv_SurfaceSnow)*_SurfaceColor, tex2D(_CrackedSnow, IN.uv_CrackedSnow)*_CrackedColor,  amount);

            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
