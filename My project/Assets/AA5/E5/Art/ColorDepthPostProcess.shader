Shader "Hidden/Custom/ColorDepth"
{
  HLSLINCLUDE
      #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
      #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/Colors.hlsl"
      TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
      TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);
      float _Blend;
      float4 Frag(VaryingsDefault i) : SV_Target
      {
          float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

            float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoordStereo));
          return lerp(color, frac(float4(depth,depth,depth,1)), _Blend);
      }
      ENDHLSL
      SubShader
      {
          Cull Off ZWrite Off ZTest Always
          Pass
          {
              HLSLPROGRAM
                  #pragma vertex VertDefault
                  #pragma fragment Frag
              ENDHLSL
          }
      }
}
