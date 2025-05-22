Shader "Custom/NewSurfaceShader"
{
    Properties
    {
        _Tess("Tesselation", Range(1,32)) = 4

        _SurfaceColor ("SurfaceColor", Color) = (1,1,1,1)
        _SurfaceSnow ("SurfaceSnow", 2D) = "white" {}
        _SurfaceSnow_Normal("Surface Snow Normal", 2D) = "bump" {}
        //[NoScaleOffset] _SurfaceSnow_Mask("Surface Snow Mask", 2D) = "black" {}

        _CrackedColor ("CrackedColor", Color) = (1,1,1,1)
        _CrackedSnow ("CrackedSnow", 2D) = "white" {}
        _CrackedSnow_Normal("Cracked Snow Normal", 2D) = "bump" {}

        _GroundColor ("GroundColor", Color) = (1,1,1,1)
        _GroundTexture("Ground Texture", 2D) = "white" {}
        _GroundTexture_Normal("Surface Snow Normal", 2D) = "bump" {}

        //[NoScaleOffset] _CrackedSnow_Mask("Cracked Snow Mask", 2D) = "black" {}

        _Splat("SplatMap", 2D) =  "black" {}
        _Displacement("Displacement", Range(0,1.0))=0.3
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _Threshold0("Snow to Crack Threshold", Range(0,1)) = 0.2
        _Threshold1("Crack to Ground Threshold", Range(0,1)) = 0.5
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

            float height = tex2Dlod(_Splat, float4(v.texcoord.xy, 0, 0)).r;
            float disp = -_Displacement * (1 - height); 
            v.vertex.xyz += v.normal * -disp;
            // float d = tex2Dlod(_Splat, float4(v.texcoord.xy,0,0)).r * _Displacement;
            // v.vertex.xyz -= v.normal * d;
            // v.vertex.xyz += v.normal * _Displacement;
        }

        sampler2D _SurfaceSnow;
        sampler2D _SurfaceSnow_Normal;
        //sampler2D _SurfaceSnow_Mask;
        fixed4 _SurfaceColor;
        float _Threshold0;
        float _Threshold1;
        sampler2D _CrackedSnow;
        sampler2D _CrackedSnow_Normal;

        fixed4 _GroundColor;
        sampler2D _GroundTexture;
        sampler2D _GroundTexture_Normal;
       //sampler2D _CrackedSnow_Mask;
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

        float _Glossiness;
        float _Metallic;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
                float height = tex2D(_Splat, IN.uv_Splat).r;
                
                // Albedos
                float3 albedo_snow = tex2D(_SurfaceSnow, IN.uv_SurfaceSnow).rgb * _SurfaceColor.rgb;
                float3 albedo_crack = tex2D(_CrackedSnow, IN.uv_CrackedSnow).rgb * _CrackedColor.rgb;
                float3 albedo_ground = tex2D(_GroundTexture, IN.uv_Splat).rgb * _GroundColor.rgb;

                // Blend weights 
                float snow_w   = saturate(1.0 - smoothstep(_Threshold0 - 0.05, _Threshold0 + 0.05, height));
                float ground_w = smoothstep(_Threshold1 - 0.05, _Threshold1 + 0.05, height);
                float crack_w  = 1.0 - snow_w - ground_w;

                // Albedo blend final
                o.Albedo = albedo_snow * snow_w + albedo_crack * crack_w + albedo_ground * ground_w;

                // Normals
                float3 n_snow   = UnpackNormal(tex2D(_SurfaceSnow_Normal, IN.uv_SurfaceSnow_Normal));
                float3 n_crack  = UnpackNormal(tex2D(_CrackedSnow_Normal, IN.uv_CrackedSnow_Normal));
                float3 n_ground = UnpackNormal(tex2D(_GroundTexture_Normal, IN.uv_Splat));
                o.Normal = normalize(n_snow * snow_w + n_crack * crack_w + n_ground * ground_w);

                // Metallic y Smoothness 

                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;

                /* No nos funcionan los mask maps

                fixed4 mask0 = tex2D(_SurfaceSnow_Mask, IN.uv_SurfaceSnow_Mask);
                fixed4 mask1 = tex2D(_CrackedSnow_Mask, IN.uv_CrackedSnow_Mask);
                o.Occlusion = occlusion;
                */

                o.Alpha = 1;

        }
        ENDCG
    }
    FallBack "Diffuse"
}

