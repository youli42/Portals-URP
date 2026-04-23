Shader "Custom/Slice"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        // 核心切片参数
        sliceNormal("normal", Vector) = (0,0,0,0)   // 切片平面的法线
        sliceCentre ("centre", Vector) = (0,0,0,0) // 切片平面的中心点
        sliceOffsetDst("offset", Float) = 0        // 切片偏移距离
    }
    SubShader
    {
        // 渲染队列设置为几何体，忽略投影器
        Tags { "Queue" = "Geometry" "IgnoreProjector" = "True"  "RenderType"="Geometry" }
        LOD 200

        CGPROGRAM
        // 基于物理的标准光照模型，并为所有光照类型启用阴影
        #pragma surface surf Standard addshadow
        // 使用 Shader Model 3.0 目标，以获得更好的光照效果
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos; // 关键：获取像素的世界坐标
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // 切面的世界空间法线：沿此方向超出中心点的部分将被剔除（不可见）
        float3 sliceNormal;
        // 切面的世界空间中心点
        float3 sliceCentre;
        // 增加此值使更多网格可见，减小此值则使更少网格可见
        float sliceOffsetDst;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // 计算经过偏移调整后的切面中心点
            float3 adjustedCentre = sliceCentre + sliceNormal * sliceOffsetDst;
            // 计算当前像素位置到切面中心点的向量
            float3 offsetToSliceCentre = adjustedCentre - IN.worldPos;
            
            // 核心剔除逻辑：
            // 计算点乘结果，若像素点处于切面法线所指的“背面”，clip 函数会将其像素舍弃
            clip (dot(offsetToSliceCentre, sliceNormal));
            
            // 反照率（Albedo）由纹理采样并叠加颜色值决定
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;

            // 金属度和光滑度由材质面板中的滑块变量控制
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    
    FallBack "VertexLit"
}