Shader "Custom/TriplanarShader"
{
    Properties
    {
        _Tiling("Tiling", Float) = 1
        _Blend("_Blend", Float) = 1
        _Color("Color", Color) = (1,1,1,1)

        [NoScaleOffset] _Albedo("Albedo", 2D) = "white" {}
        [NoScaleOffset] _Normal_Map("Normal Map", 2D) = "bump" {}

        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows addshadow
        #pragma target 3.0

        sampler2D _Albedo;
        sampler2D _Normal_Map;

        float _Tiling;
        float _Blend;
        fixed4 _Color;

        half _Glossiness;
        half _Metallic;

        struct Input
        {
            float3 worldPos;
            float3 worldNormal;
            INTERNAL_DATA
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float3 worldPos = IN.worldPos * _Tiling;
            float3 normal = normalize(IN.worldNormal);

            // Triplanar blend weights
            float3 blends = abs(normal);
            blends = pow(blends, _Blend);
            blends /= (blends.x + blends.y + blends.z);

            // --- Albedo projections ---
            float3 albedoX = tex2D(_Albedo, worldPos.yz).rgb;
            float3 albedoY = tex2D(_Albedo, worldPos.xz).rgb;
            float3 albedoZ = tex2D(_Albedo, worldPos.xy).rgb;
            float3 finalAlbedo = albedoX * blends.x + albedoY * blends.y + albedoZ * blends.z;

            // --- Normal projections ---
            float3 nX = UnpackNormal(tex2D(_Normal_Map, worldPos.yz));
            float3 nY = UnpackNormal(tex2D(_Normal_Map, worldPos.xz));
            float3 nZ = UnpackNormal(tex2D(_Normal_Map, worldPos.xy));

            // Reorient from projection axis to world approximation
            nX = float3(nX.z, nX.y, -nX.x); // eje X (ZY)
            nY = float3(nY.x, nY.z, -nY.y); // eje Y (XZ)
            nZ = float3(-nZ.x, nZ.y, nZ.z); // eje Z (XY)

            float3 blendedNormal = normalize(nX * blends.x + nY * blends.y + nZ * blends.z);

            // --- Output ---
            o.Albedo = finalAlbedo * _Color.rgb;
            o.Normal = WorldNormalVector(IN, blendedNormal);
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = _Color.a;
        }

        ENDCG
    }

    FallBack "Diffuse"
}
