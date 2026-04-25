Shader "Demo/URP_SkyDome_TwoWorlds"
{
    Properties
    {
        _TopColor("Top Color", Color) = (1,1,1,1)
        _MiddleColor("Middle Color", Color) = (1,1,1,1)
        _BottomColor("Bottom Color", Color) = (1,1,1,1)

        [Header(Sun Settings)]
        [HDR]_SunColor("Sun Color", Color) = (1, 1, 0.8, 1) // 开启 HDR 以支持泛光(Bloom)
        _SunSize("Sun Size", Range(0.0001, 0.05)) = 0.005     // 太阳大小阈值
        _SunSoftness("Sun Softness", Range(0.0, 0.005)) = 0.002 // 边缘羽化程度

        [Header(Cull Settings)]
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
            // 引入 URP 光照库以获取 GetMainLight()
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD1; // 传递世界空间坐标
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _TopColor;
            float4 _MiddleColor;
            float4 _BottomColor;
            float4 _SunColor;
            float _SunSize;
            float _SunSoftness;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // 计算世界空间坐标，用于后续计算视线方向
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                // 计算精确的视线方向 (从摄像机指向顶点)
                float3 viewDirWS = normalize(IN.positionWS - _WorldSpaceCameraPos);

                // 获取仰角高度值，范围严格在 [-1, 1] 之间
                float height = viewDirWS.y;

                // --- 基于方向向量重构天空渐变逻辑 ---
                // 当 height 从 0 增加到 1 时，属于地平线到天空顶部的渐变
                float topBlend = saturate(height); 
                // 当 height 从 0 减小到 -1 时，属于地平线到脚底的渐变
                float bottomBlend = saturate(-height);

                // 首先设定基础色为中间色 (地平线颜色)
                float4 col = _MiddleColor;
                // 向上混合天顶色
                col = lerp(col, _TopColor, topBlend);
                // 向下混合底部色
                col = lerp(col, _BottomColor, bottomBlend);

                // --- 2. 太阳绘制逻辑 ---

                // 获取主光源数据 (包含方向)
                Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction;

                // 计算视线与光源的重合度 (NdotL)
                float NdotL = dot(viewDirWS, lightDir);

                // 太阳遮罩计算：
                // 1.0 - _SunSize 设定为太阳的硬边缘
                // smoothstep 依据 _SunSoftness 生成平滑的光晕过渡
                float sunThreshold = 1.0 - _SunSize;
                float sunMask = smoothstep(sunThreshold - _SunSoftness, sunThreshold, NdotL);

                // --- 3. 图像合成 ---
                // 依据 mask 将太阳颜色叠加在天空背景上
                col.rgb = lerp(col.rgb, _SunColor.rgb, sunMask);

                return col;
            }
            ENDHLSL
        }
    }
}