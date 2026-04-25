Shader "Demo/URP_SkyDome_TwoWorlds"
{
    Properties
    {
        _TopColor("Top Color", Color) = (1,1,1,1)
        _MiddleColor("Middle Color", Color) = (1,1,1,1)
        _BottomColor("Bottom Color", Color) = (1,1,1,1)

        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 1

    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "Queue"="Background"
            "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            ZWrite On
            ZTest LEqual
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _TopColor;
            float4 _MiddleColor;
            float4 _BottomColor;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float t = saturate(1.0 - IN.uv.y);
                
                float4 col = lerp(_BottomColor, _MiddleColor, saturate(t * 2.0));
                col = lerp(col, _TopColor, saturate((t - 0.5) * 2.0));

                return col;
            }
            ENDHLSL
        }
    }
}