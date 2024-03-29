// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "UI/Default"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)

        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255

        _TextureSampleAdd("Texture Sample Add", Color) = (0,0,0,0)
        _UIMaskSoftnessX("UI Mask Softness X", Float) = 0
        _UIMaskSoftnessY("UI Mask Softness Y", Float) = 0
        _ClipRect("Clip Rect", vector) = (0,0,1,1)

        _ColorMask("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
    }

        SubShader
        {
            Tags
            {
                "Queue" = "Transparent"
                "IgnoreProjector" = "True"
                "RenderType" = "Transparent"
                "PreviewType" = "Plane"
                "CanUseSpriteAtlas" = "True"
                "ShaderModel" = "4.5"
            }

            Stencil
            {
                Ref[_Stencil]
                Comp[_StencilComp]
                Pass[_StencilOp]
                ReadMask[_StencilReadMask]
                WriteMask[_StencilWriteMask]
            }

            Cull Off
            Lighting Off
            ZWrite Off
            ZTest[unity_GUIZTestMode]
            Blend One OneMinusSrcAlpha
            ColorMask[_ColorMask]

            Pass
            {
                Name "Default"
            HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
                CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float4 _Color;
                float4 _TextureSampleAdd;
                float4 _ClipRect;
                float4 _MainTex_ST;
                float _UIMaskSoftnessX;
                float _UIMaskSoftnessY;
                CBUFFER_END

                #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
                #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

                struct appdata_t
                {
                    float4 vertex   : POSITION;
                    float4 color    : COLOR;
                    float2 texcoord : TEXCOORD0;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct v2f
                {
                    float4 vertex   : SV_POSITION;
                    float4 color : COLOR;
                    float2 texcoord  : TEXCOORD0;
                    float3 worldPosition : TEXCOORD1;
                    float4  mask : TEXCOORD2;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                        UNITY_VERTEX_OUTPUT_STEREO
                };


                v2f vert(appdata_t v)
                {
                    v2f OUT;
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_TRANSFER_INSTANCE_ID(v, OUT);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);

                    OUT.worldPosition = vertexInput.positionWS.xyz;
                    OUT.vertex = vertexInput.positionCS;

                    float2 pixelSize = vertexInput.positionCS.w;
                    pixelSize /= float2(1, 1) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));

                    float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                    float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
                    OUT.texcoord = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
                    OUT.mask = float4(v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy)));

                    OUT.color = v.color * _Color;
                    return OUT;
                }

                float4 frag(v2f IN) : SV_Target
                {
                     UNITY_SETUP_INSTANCE_ID(IN);
                     UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                    //Round up the alpha color coming from the interpolator (to 1.0/256.0 steps)
                    //The incoming alpha could have numerical instability, which makes it very sensible to
                    //HDR color transparency blend, when it blends with the world's texture.
                    const half alphaPrecision = half(0xff);
                    const half invAlphaPrecision = half(1.0 / alphaPrecision);
                    IN.color.a = round(IN.color.a * alphaPrecision) * invAlphaPrecision;

                    half4 color = IN.color * (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd);

                    #ifdef UNITY_UI_CLIP_RECT
                    half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw);
                    color.a *= m.x * m.y;
                    #endif

                    #ifdef UNITY_UI_ALPHACLIP
                    clip(color.a - 0.001);
                    #endif

                    color.rgb *= color.a;

                    return color;
                }
            ENDHLSL
       }
    }
}