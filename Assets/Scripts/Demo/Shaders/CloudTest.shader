// 升级提示：已将 '_Object2World' 替换为 'unity_ObjectToWorld'

Shader "Demo/CloudTest"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Emission ("Emission", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        LOD 200

        CGPROGRAM
        // 基于物理的标准光照模型，并启用所有光源类型的阴影
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // 使用 Shader Model 3.0 目标，以获得更精细的光照效果
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        void vert(inout appdata_full data){
            float3 worldVert = mul (unity_ObjectToWorld, data.vertex);
            // 被注释的代码（顶点动画）：根据时间和世界坐标产生正弦波位移
            //data.vertex.xyz += sin(_Time.x + data.vertex.xyz + worldVert * .1) * .2;
        }

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _Emission;

        // 为此着色器添加 GPU 实例化（Instancing）支持。你需要在使用了该着色器的材质上勾选“启用实例化”（Enable Instancing）。
        // 有关实例化的更多信息，请参阅 https://docs.unity3d.com/Manual/GPUInstancing.html
        // 开启统一缩放假设
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // 在此处放置更多每个实例（per-instance）的属性
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // 反射率（Albedo）来自受 _Color 变量调节的纹理
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // 金属度（Metallic）和光滑度（Smoothness）来自滑动条变量
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Emission = _Emission;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}