Shader "Spheya/GrassShader"
{
    Properties
    {
        [NoScaleOffset] _StaticNoise ("Static Noise", 2D) = "black" {}
        [NoScaleOffset] _DisplacementNoise("Displacement Noise", 2D) = "black" {}
        [NoScaleOffset] _HiFreqColorTex("High Frequency Color Texture", 2D) = "gray" {}
        [NoScaleOffset] _LoFreqColorTex("Low Frequency Color Texture", 2D) = "gray" {}
        [NoScaleOffset] _CloudMap("Cloud Map", 2D) = "white" {}

        [Toggle(EDGE_MATERIAL)] _EdgeMaterial ("Is Edge Material", Float) = 1.0

        _BottomColor("Bottom Color", Color) = (0,0,0,0)
        _TopColor("Top Color", Color) = (1,1,1,1)

        _SpecularPower("Specular Power", Float) = 1.0
        _SpecularIntensity("Specular Intensity", Float) = 0.0

        _HiFreqColorStrength("High Frequency Color Strength", Range(0.0, 1.0)) = 0.0
        _LoFreqColorStrength("Low Frequency Color Strength", Range(0.0, 1.0)) = 0.0
        _LoFreqColorScale("Low Frequency Color Scale", Float) = 1.0

        _GrassCut("Grass Cut", Range(0.0, 1.0)) = 0.0

        _GrassScale ("Grass Scale", Float) = 1.0
        _GrassHeight ("Grass Height", Float) = 1.0

        _DisplacementScale("Displacement Scale", Float) = 1.0
        _DisplacementIntensity("Displacement Intensity", Float) = 0.0
        _DynamicDisplacementScale ("Dynamic Displacement Scale", Float) = 1.0
        _DynamicDisplacementIntensity ("Dynamic Displacement Intensity", Float) = 0.0
        _DynamicDisplacementSpeed ("Dynamic Displacement Speed", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        ZTest Off
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Lighting.hlsl"

            #pragma shader_feature EDGE_MATERIAL

            // URP Lighting keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            #define SAMPLES 32

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float3 worldPos : TEXCOORD0;
                float height : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _StaticNoise;
            sampler2D _DisplacementNoise;
            sampler2D _HiFreqColorTex;
            sampler2D _LoFreqColorTex;
            sampler2D _SpecularMap;

            float4 _BottomColor;
            float4 _TopColor;

            float _HiFreqColorStrength;
            float _LoFreqColorStrength;
            float _LoFreqColorScale;

            float _GrassCut;

            float _GrassScale;
            float _GrassHeight;

            float _DisplacementScale;
            float _DisplacementIntensity;
            float _DynamicDisplacementScale;
            float _DynamicDisplacementIntensity;
            float _DynamicDisplacementSpeed;

            Varyings vert (Attributes attribs)
            {
                Varyings varyings;

                float3 vertexPos = attribs.vertex.xyz;
                vertexPos.y *= _GrassHeight;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(vertexPos);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(attribs.normal);

                varyings.height = 0.0; // TODO: Actually calculate this
                varyings.worldPos = vertexInput.positionWS;
                varyings.normal = vertexNormalInput.normalWS;
                varyings.vertex = vertexInput.positionCS;

                return varyings;
            }

            float4 frag (Varyings varyings, out float outDepth : SV_Depth) : SV_Target
            {
                float3 actualViewDir = varyings.worldPos - _WorldSpaceCameraPos;
                float3 worldPos = _WorldSpaceCameraPos + actualViewDir * ((varyings.height - _WorldSpaceCameraPos.y) / actualViewDir.y);
                float3 viewDir = normalize(worldPos - _WorldSpaceCameraPos);

                float3 normal = varyings.normal;

                float2 parallax = (viewDir.xz / viewDir.y) * _GrassHeight / SAMPLES;

                float2 uv = worldPos.xz * _GrassScale;
                float2 dynamicDisplacementUv = worldPos.xz * _DynamicDisplacementScale;
                float2 displacementUv = worldPos.xz * _DisplacementScale;
                float2 edgeUv = varyings.worldPos.xz * _GrassScale;

                float height = -1;

                float3 hitPos = worldPos;
                float2 hitUv = uv;
                float2 hitNormal = float2(0.0, 0.0);

                for (int h = 0; h < SAMPLES; h++) {
                    float sampleHeight = (h / float(SAMPLES));

                    float2 dynamicDisplacement  = (tex2D(_DisplacementNoise, dynamicDisplacementUv + _Time.y * _DynamicDisplacementSpeed).rg - 0.5) * sampleHeight * sampleHeight;
                    float2 staticDisplacement = (tex2D(_DisplacementNoise, displacementUv).rg - 0.5)  * sampleHeight * sampleHeight;

                    float2 displacement = staticDisplacement * _DisplacementIntensity + dynamicDisplacement * _DynamicDisplacementIntensity;

                    float grassSample = tex2D(_StaticNoise, uv + displacement).r * (1.0 + _GrassCut);

                    if (grassSample >= sampleHeight
            #ifdef EDGE_MATERIAL
                        && (dot(uv - edgeUv, normal.xz) < 0.0)
            #endif    
                    ){
                        height = sampleHeight;
                        hitPos = float3(uv.x / _GrassScale, sampleHeight * _GrassHeight, uv.y / _GrassScale);
                        hitUv = uv + displacement;

                        hitNormal = -dynamicDisplacement * _DynamicDisplacementIntensity * 3.0 + -staticDisplacement * _DisplacementIntensity * 0.7;
                    }

                    uv += parallax * _GrassScale;
                    displacementUv += parallax * _DisplacementScale;
                    dynamicDisplacementUv += parallax * _DynamicDisplacementScale;
                }

            #ifdef EDGE_MATERIAL
                if (height < 0.0) discard;
            #endif

                float4 hiFreqColor = tex2D(_HiFreqColorTex, hitUv);
                float4 loFreqColor = tex2D(_LoFreqColorTex, hitUv * _LoFreqColorScale);
                float4 colorVariation = step(loFreqColor, 0.5) * _LoFreqColorStrength;
                colorVariation.a = 0.0;
                colorVariation.g = 0.0;

                float3 fakeNormal = normalize(float3(hitNormal.x, 0.035, hitNormal.y));

                float4 clipPos = mul(UNITY_MATRIX_VP, float4(hitPos, 1.0));

            #ifdef EDGE_MATERIAL
                outDepth = clipPos.z / clipPos.w;
            #else
                outDepth = clipPos.z / clipPos.w;
            #endif

                float4 albedo = lerp(_BottomColor, _TopColor, height * height * height) + lerp(0.0, hiFreqColor * 2.0 - 1.0, _HiFreqColorStrength) - colorVariation;
                float3 col = shadeTerrain(albedo.rgb, float3(hitUv.x, 0.0, hitUv.y) / _GrassScale, fakeNormal, viewDir);

                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
