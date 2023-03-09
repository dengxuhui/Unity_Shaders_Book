Shader "dengxuhui/NormalMapTangentSpace"
{
    Properties
    {
        //颜色调节
        _Color("Color", Color) = (1,1,1,1)
        //纹理贴图
        _MainTex("MainTex", 2D) = "white" {}
        //法线贴图
        _BumpMap("BumpMap", 2D) = "bump" {}
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include  "Lighting.cginc"

            fixed4 _Color;

            struct a2v
            {
            };

            struct v2f
            {
            };

            v2f vert(a2v v)
            {
                v2f o;

                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                return fixed4(1, 0, 0, 1);
            }
            ENDCG
        }
    }

    FallBack "Specular"
}