Shader "dengxuhui/WaterWave"
{
    Properties
    {
        _Color("Main Color", Color) = (1,1,1,1)
        _MainTex("Base (RGB)", 2D) = "white" {}
        _WaveMap("Wave Normal Map", 2D) = "bump" {}
        _CubeMap("CubeMap", Cube) = "_Skybox" {}
        _WaveXSpeed("Wave X Speed", Range(-0.1, 0.1)) = 0.05
        _WaveYSpeed("Wave Y Speed", Range(-0.1, 0.1)) = 0.05
        _Distortion("Distortion", Range(0, 100)) = 10
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent" "RenderType" = "Opaque"
        }

        GrabPass
        {
            "_RefractionTex"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WaveMap;
            float4 _WaveMap_ST;
            samplerCUBE _Cubemap;
            fixed _WaveXSpeed;
            fixed _WaveYSpeed;
            float _Distortion;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //使用裁剪空间坐标计算屏幕坐标，这个坐标是非线性坐标，需要经过透视除法得到正在的屏幕坐标
                o.scrPos = ComputeGrabScreenPos(o.pos);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);
                //构建切线空间到世界空间的变换矩阵
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);
                //水波效果主要通过对噪声图的采样实现，采样根据_Time来偏移
                //这里添加了两层水波叠加，如果只有一层就是单向的流程，模拟河流可以，但是这里用来模拟海水
                //因此这里就需要使用两层采样来进行叠加
                float3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
                float3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
                float3 bump = normalize(bump1 + bump2);

                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                //里水面越深，偏移越大
                i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
                //折射颜色
                fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                fixed4 texColor = tex2D(_MainTex, i.uv.xy + offset);
                fixed3 reflDir = reflect(-viewDir, bump);
                //反射颜色
                fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * _Color.rgb;
                //计算菲涅耳系数
                fixed3 fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
                fixed3 finalColor = (reflCol * fresnel + (1 - fresnel) * refrCol) * texColor;
                return fixed4(finalColor, 1);
            }
            ENDCG
        }

    }
    Fallback Off
}