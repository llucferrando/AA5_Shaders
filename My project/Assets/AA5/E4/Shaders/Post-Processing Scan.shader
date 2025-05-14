Shader "Custom/Post-Processing Scan"
{
    Properties
    {
        [HDR] _Colour("Colour", Color) = (1,1,1,1)
        _Origin("Origin", Vector) = (0,0,0,0)
        _Power("Power", Float) = 10
        _Tiling("Tiling", Float) = 1
        _Speed("Speed", Float) = 1
        _MaskRadius("Scanner Radius", Float) = 5
        _MaskHardness("Scanner Hardness", Range(0,1)) = 1
        _MaskPower("Scanner Power", Float) = 1
        _MultiplyBlend("Multiply Blend", Range(0,1)) = 0
    }

        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "UnityShaderVariables.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            float4 _Colour;
            float3 _Origin;
            float _Power;
            float _Tiling;
            float _Speed;
            float _MaskRadius;
            float _MaskHardness;
            float _MaskPower;
            float _MultiplyBlend;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // -- Full screen triangle without using vertex buff

            v2f vert(uint id : SV_VertexID)
            {
                v2f o;
                float2 positions[3] = {
                    float2(-1.0, -1.0),
                    float2(3.0, -1.0),
                    float2(-1.0,  3.0)
                };
                o.vertex = float4(positions[id], 0, 1);
                o.uv = (positions[id] + 1.0) * 0.5;
                //#if UNITY_UV_STARTS_AT_TOP
                //    o.uv.y = 1.0 - o.uv.y;
                //#endif
                return o;
            }

            // -- Reconstruction of world position from screen UV and Depth

            float3 ReconstructWorldPosition(float2 uv, float depth)
            {
                float4 clipPos = float4(uv * 2.0 - 1.0, depth, 1.0);
                #if UNITY_UV_STARTS_AT_TOP
                clipPos.y = -clipPos.y;
                #endif
                float4 viewPos = mul(unity_CameraInvProjection, clipPos);
                viewPos.xyz /= viewPos.w;

                #if UNITY_REVERSED_Z
                viewPos.z *= -1.0;
                #endif

                float4 worldPos = mul(unity_CameraToWorld, float4(viewPos.xyz, 1.0));
                return worldPos.xyz;
            }

            float4 frag(v2f i) : SV_Target
            {
                // - Flip Y to match depth
                float2 flippedUV = float2(i.uv.x, 1.0 - i.uv.y);
                float2 uv = flippedUV * _MainTex_ST.xy + _MainTex_ST.zw;
                float4 screenColor = tex2D(_MainTex, uv);


                float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, flippedUV);
                #if UNITY_REVERSED_Z
                    rawDepth = 1.0 - rawDepth;
                #endif

                // - Get World Pos from Depth
                float3 worldPos = ReconstructWorldPosition(i.uv, rawDepth);
                
                float dist = distance(worldPos, _Origin);
                float time = _Time.y * _Speed;

                // - Compute Distance Field Mask
                float sdf = dist;
                float maxRadius = _MaskRadius + 1.0;
                float edgeStart = lerp(0.0, maxRadius - 0.001, _MaskHardness);
                float mask = smoothstep(maxRadius, edgeStart, sdf);
                mask = pow(mask, _MaskPower);

                // - Generate Scan Wave Pattern

                float wave = pow(frac(sdf * _Tiling - time), _Power);
                float alpha = _Colour.a;
                float intensity = wave * mask * alpha;

                // - Mix Colors based on Blend

                float4 scanColor = lerp(_Colour, _Colour * screenColor, _MultiplyBlend);
                return lerp(screenColor, scanColor, intensity);
            }
            ENDCG
        }
    }
        FallBack Off
}
