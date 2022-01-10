#include "CloudShadows.hlsl"

float _SpecularPower;
float _SpecularIntensity;

float3 lightTerrain(float3 albedo, float3 normal, float3 viewDirection, Light light) {
    float diffuse = max(dot(normal, light.direction), 0.0);
    float shadow = light.shadowAttenuation < 0.5 ? 0.0 : 1.0;

    float n0 = saturate(-dot(normal, viewDirection));
    float fresnel = pow(1.0 - n0, _SpecularPower);
    
    float specular = fresnel * _SpecularIntensity;

    return diffuse * shadow * (light.color * albedo + specular * light.color);
}

float3 shadeTerrain(float3 albedo, float3 positionWS, float3 normalWS, float3 viewDirection) {
    Light mainLight = GetMainLight(); 
         
    float3 indirectLight = SampleSH(normalWS) * albedo;

#ifdef _MAIN_LIGHT_SHADOWS
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    mainLight.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
#endif

	float3 result = lightTerrain(albedo, normalWS, viewDirection, mainLight);
    float cloudShadows = getCloudShadows(positionWS, mainLight.direction);
    result *= cloudShadows;

#ifdef _ADDITIONAL_LIGHTS
    int additionalLightsCount = GetAdditionalLightsCount();
    for (int i = 0; i < additionalLightsCount; ++i)
    {
        Light light = GetAdditionalLight(i, positionWS);
		result += lightTerrain(albedo, normalWS, viewDirection, light);
    }
#endif

    result += indirectLight;

	return result;
}