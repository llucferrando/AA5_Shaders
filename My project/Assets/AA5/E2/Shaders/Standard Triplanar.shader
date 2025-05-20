Shader "Standard Triplanar"
{
    Properties
    {
        _Tiling("_Tiling", Float) = 1
        _Blend("_Blend", Float) = 1
        _Color("_Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset] _MainTex("_Albedo", 2D) = "white" {}
        [NoScaleOffset] _Mask_Map("_Mask_Map", 2D) = "white" {}
        [NoScaleOffset] _Normal_Map("_Normal_Map", 2D) = "bump" {}

        [Toggle(_USEEMISSION_ON)] _UseEmission("Use Emission", Float) = 0
        [HDR] _EmissionColor("Emission Color", Color) = (0,0,0,0)
        [NoScaleOffset] _Emission("Emission", 2D) = "white" {}


        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

        #pragma surface surf Standard vertex:vert fullforwardshadows addshadow

        #pragma shader_feature _NORMALMAP
        #pragma shader_feature _OCCLUSIONMAP
        #pragma multi_compile __ _USEEMISSION_ON

        #pragma target 3.0

        half _Tiling;
        half _Blend;
        half4 _Color;

        sampler2D _MainTex;        
        sampler2D _Normal_Map;
        sampler2D _Mask_Map;

        sampler2D _Emission;
        half4 _EmissionColor;
        half _UseEmission;

        struct Input
        {
            float3 localCoord;
            float3 localNormal;
        };

        void vert(inout appdata_full v, out Input data)
        {
            UNITY_INITIALIZE_OUTPUT(Input, data);
            data.localCoord = v.vertex.xyz;
            data.localNormal = v.normal.xyz;
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            // Blending factor of triplanar mapping
            float3 bf = normalize(abs(IN.localNormal));
            bf /= dot(bf, (float3)1);
            bf*=_Blend;

            // Triplanar mapping
            float2 tx = IN.localCoord.yz * _Tiling;
            float2 ty = IN.localCoord.zx * _Tiling;
            float2 tz = IN.localCoord.xy * _Tiling;

            // Base color
            half4 cx = tex2D(_MainTex, tx) * bf.x;
            half4 cy = tex2D(_MainTex, ty) * bf.y;
            half4 cz = tex2D(_MainTex, tz) * bf.z;
            half4 color = (cx + cy + cz) * _Color;
            o.Albedo = color.rgb;
            o.Alpha = color.a;

        #ifdef _NORMALMAP
            // Normal map
            half4 nx = tex2D(_Normal_Map, tx) * bf.x;
            half4 ny = tex2D(_Normal_Map, ty) * bf.y;
            half4 nz = tex2D(_Normal_Map, tz) * bf.z;
            o.Normal = UnpackScaleNormal(nx + ny + nz, 1);
        #endif

        #ifdef _MASKMAP
            // Mask map
            half mx = tex2D(_Mask_Map, tx).g * bf.x;
            half my = tex2D(_Mask_Map, ty).g * bf.y;
            half mz = tex2D(_Mask_Map, tz).g * bf.z;
            o.Occlusion = lerp((half4)1, mx + my + mz, 1);
        #endif

        #ifdef _USEEMISSION_ON
            half3 ex = tex2D(_Emission, tx).rgb * bf.x;
            half3 ey = tex2D(_Emission, ty).rgb * bf.y;
            half3 ez = tex2D(_Emission, tz).rgb * bf.z;
            o.Emission = (ex + ey + ez) * _EmissionColor.rgb;
        #endif

            // Misc parameters
            o.Metallic = 0;
            o.Smoothness = 0.5;
        }
        ENDCG
    }
    FallBack "Diffuse"
    CustomEditor "StandardTriplanarInspector"
}