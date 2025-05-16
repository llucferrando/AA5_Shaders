Shader "Custom/NewSurfaceShader"
{
    Properties
    {
        _Tess("Tesselation", Range(1,32)) = 4
        _SurfaceColor ("SurfaceColor", Color) = (1,1,1,1)
        _SurfaceSnow ("SurfaceSnow", 2D) = "white" {}
        _SurfaceSnow_Normal("Surface Snow Normal", 2D) = "bump" {}
        _SurfaceSnow_Mask("Surface Snow Mask (R=AO, G=Metallic, B=Smoothness)", 2D) = "black" {}

        _CrackedColor ("CrackedColor", Color) = (1,1,1,1)
        _CrackedSnow ("CrackedSnow", 2D) = "white" {}
        _CrackedSnow_Normal("Cracked Snow Normal", 2D) = "bump" {}
        _CrackedSnow_Mask("Cracked Snow Mask (R=AO, G=Metallic, B=Smoothness)", 2D) = "black" {}

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
        #pragma surface surf Standard fullforwardshadows vertex:disp tessellate:tessDistance 
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
            v.vertex.xyz += v.normal * _Displacement;
        }

        sampler2D _SurfaceSnow;
        sampler2D _SurfaceSnow_Normal;
        sampler2D _SurfaceSnow_Mask;
        fixed4 _SurfaceColor;

        sampler2D _CrackedSnow;
        sampler2D _CrackedSnow_Normal;
        sampler2D _CrackedSnow_Mask;
        fixed4 _CrackedColor;

        struct Input
        {
            float2 uv_SurfaceSnow;
            float2 uv_SurfaceSnow_Normal;
            float2 uv_SurfaceSnow_Mask;
            float2 uv_CrackedSnow;
            float2 uv_CrackedSnow_Normal;
            float2 uv_CrackedSnow_Mask;
            float2 uv_Splat;
        };

        half _Glossiness;
        half _Metallic;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            half amount = tex2D(_Splat, IN.uv_Splat).r;

            // Albedo
            fixed4 albedo0 = tex2D(_SurfaceSnow, IN.uv_SurfaceSnow) * _SurfaceColor;
            fixed4 albedo1 = tex2D(_CrackedSnow, IN.uv_CrackedSnow) * _CrackedColor;
            fixed4 c = lerp(albedo0, albedo1, amount);
            o.Albedo = c.rgb;

            // Normal
            fixed3 normal0 = UnpackNormal(tex2D(_SurfaceSnow_Normal, IN.uv_SurfaceSnow_Normal));
            fixed3 normal1 = UnpackNormal(tex2D(_CrackedSnow_Normal, IN.uv_CrackedSnow_Normal));
            o.Normal = normalize(lerp(normal0, normal1, amount));

            // Mask maps
            fixed4 mask0 = tex2D(_SurfaceSnow_Mask, IN.uv_SurfaceSnow_Mask);
            fixed4 mask1 = tex2D(_CrackedSnow_Mask, IN.uv_CrackedSnow_Mask);

            float ao = lerp(mask0.r, mask1.r, amount);
            float metallic = lerp(mask0.g, mask1.g, amount);
            float smoothness = lerp(mask0.b, mask1.b, amount);

            o.Metallic = metallic;
            o.Smoothness = smoothness;
            o.Occlusion = ao;

            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
