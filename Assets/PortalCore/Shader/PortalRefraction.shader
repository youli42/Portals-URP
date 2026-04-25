Shader "Custom/PortalRefraction"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _InactiveColour ("Inactive Color", Color) = (1, 1, 1, 1)

        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Range(1, 8)) = 3.0

        [Header(Refraction Settings)]
        [Normal] _RefractionNormalMap ("Refraction Normal Map", 2D) = "bump" {}
        _RefractionStrength ("Refraction Strength", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" } // [cite: 2]
        LOD 100
        Cull Off

        Pass
        {
            Stencil
            {
                Ref 1 // [cite: 3]
                Comp Always
                Pass Replace
            }
            
            HLSLPROGRAM // [cite: 4]
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION; // [cite: 5]
                float3 normal : NORMAL; // [cite: 5]
                float4 tangent : TANGENT; // 新增：模型切线
                float2 uv : TEXCOORD0;    // 新增：模型UV，用于采样法线贴图
            };

            struct v2f
            {
                float4 vertex : SV_POSITION; // [cite: 6]
                float4 screenPos : TEXCOORD0; // [cite: 7]
                float3 worldPos : TEXCOORD1; // [cite: 7]
                float3 worldNormal : TEXCOORD2; // [cite: 7]
                float4 worldTangent : TEXCOORD3; // 新增：传递到片元的切线
                float2 uv : TEXCOORD4;           // 新增：传递到片元的UV
            };

            TEXTURE2D(_MainTex); // [cite: 8]
            SAMPLER(sampler_MainTex); // [cite: 8]

            // 声明法线贴图
            TEXTURE2D(_RefractionNormalMap);
            SAMPLER(sampler_RefractionNormalMap);

            CBUFFER_START(UnityPerMaterial) // [cite: 9]
                float4 _InactiveColour;
                int displayMask; // [cite: 10]
                float4 _RimColor;
                float _RimPower;
                
                // 确保 SRP Batcher 兼容
                float4 _RefractionNormalMap_ST;
                float _RefractionStrength;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz); // [cite: 11]
                o.vertex = vertexInput.positionCS; // [cite: 12]
                o.screenPos = ComputeScreenPos(o.vertex);
                o.worldPos = vertexInput.positionWS; // [cite: 13]
                o.worldNormal = TransformObjectToWorldNormal(v.normal); // [cite: 14]
                
                // 计算并传递世界空间切线
                o.worldTangent = float4(TransformObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                
                // 应用 Tiling 和 Offset
                o.uv = TRANSFORM_TEX(v.uv, _RefractionNormalMap);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // 1. 构建基础向量
                float3 worldNormal = normalize(i.worldNormal);
                float3 worldTangent = normalize(i.worldTangent.xyz);
                // 根据切线的 w 分量计算副切线，确保镜像 UV 等情况下的法线方向正确
                float3 worldBitangent = cross(worldNormal, worldTangent) * i.worldTangent.w * unity_WorldTransformParams.w;

                // 2. 采样法线贴图并解包
                half4 normalSample = SAMPLE_TEXTURE2D(_RefractionNormalMap, sampler_RefractionNormalMap, i.uv);
                float3 tangentNormal = UnpackNormal(normalSample);

                // 3. 将法线从切线空间转换到世界空间
                // 若未赋贴图，tangentNormal 为 (0,0,1)，此处计算结果直接等于 worldNormal
                float3 finalWorldNormal = tangentNormal.x * worldTangent + tangentNormal.y * worldBitangent + tangentNormal.z * worldNormal;
                finalWorldNormal = normalize(finalWorldNormal);

                // 4. 将法线转换到观察空间 (View Space)
                float3 viewNormal = TransformWorldToViewDir(finalWorldNormal, true);
                
                // 5. 计算折射 UV 偏移 (使用观察空间法线的 XY 平面)
                float2 distortion = viewNormal.xy * _RefractionStrength;

                // 6. 应用偏移并采样传送门主屏幕
                float2 screenUV = i.screenPos.xy / i.screenPos.w; // [cite: 14]
                screenUV += distortion;

                half4 portalCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, screenUV); // [cite: 15]

                // --- 边缘光 (Rim Light) ---
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos); // [cite: 16]
                // 优化：让边缘光也受到法线贴图的影响，细节更丰富
                float rim = 1.0 - saturate(dot(finalWorldNormal, viewDir)); // [cite: 18]
                rim = pow(rim, _RimPower); // [cite: 18]

                half3 finalColor = portalCol.rgb + rim * _RimColor.rgb; // [cite: 19]
                half4 finalPortal = half4(finalColor, portalCol.a); // [cite: 20]

                return finalPortal * displayMask + _InactiveColour * (1 - displayMask); // [cite: 21]
            }
            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}