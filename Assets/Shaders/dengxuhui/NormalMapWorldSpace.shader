Shader "dengxuhui/NormalMapWorldSpace"
{
    Properties
    {
        _MainTex("MainTex",2D) = "white" {}
        _BumpMap("BumpMap",2D) = "bump" {}
        _BumpScale("BumpScale",Float) = 1.0
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
            #include "Lighting.cginc"
            ENDCG

        }

    }
    FallBack "Specular"
}