Shader "Custom/PortalRefraction"
{
    Properties
    {
        // 显式声明主纹理，方便 Inspector 调试，虽然后端由脚本赋值
        _MainTex ("Main Texture", 2D) = "white" {}
        _InactiveColour ("Inactive Color", Color) = (1, 1, 1, 1)

        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Range(1, 8)) = 3.0
    }
    SubShader
    {
        // URP 规范：必须指定 RenderPipeline
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        Cull Off

        Pass
        {
            // --- Stencil 状态块 ---
            Stencil
            {
                Ref 1            // 设定参考值为 1 (需要和传送门屏幕设置的 Stencil 值一致)
                Comp Always       // 强制渲染
                Pass Replace        // 覆盖模板值
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // 引用 URP 核心库 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            // URP 纹理定义规范
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // SRP Batcher 兼容：所有属性必须放在 UnityPerMaterial 缓冲区中 
            CBUFFER_START(UnityPerMaterial)
                float4 _InactiveColour;
                int displayMask;
                float4 _RimColor;
                float _RimPower;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                // 使用 URP 坐标变换宏 
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS; 
                // 计算屏幕坐标 
                o.screenPos = ComputeScreenPos(o.vertex);

                // --- 计算世界坐标和世界法线并传递给 Fragment ---
                o.worldPos = vertexInput.positionWS;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // 透视除法获取 UV [cite: 7]
                float2 uv = i.screenPos.xy / i.screenPos.w;
                // URP 采样宏
                half4 portalCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);

                // --- 新增：计算边缘光 (Rim Light) ---
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                // 注意：确保法线是归一化的，防止插值带来的长度变化
                float3 normal = normalize(i.worldNormal);
                
                float rim = 1.0 - saturate(dot(normal, viewDir));
                rim = pow(rim, _RimPower); 
                
                // 将 rim 值叠加到传送门采样颜色上
                half3 finalColor = portalCol.rgb + rim * _RimColor.rgb;
                
                // 核心逻辑保持不变 (使用 finalColor 替换原来的 portalCol.rgb)
                half4 finalPortal = half4(finalColor, portalCol.a);
                
                // 核心逻辑保持不变 
                return finalPortal * displayMask + _InactiveColour * (1 - displayMask);
            }
            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}