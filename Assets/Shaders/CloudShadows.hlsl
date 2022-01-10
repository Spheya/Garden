#define CLOUD_SHADOW_INTENSITY 0.7

#define CLOUD_MAP_SCALE 0.003

#define CLOUD_SPEED 0.5

sampler2D _CloudMap;

float getCloudShadows(float3 worldPos, float3 mainLightDirection) {
	float2 cloudUv = worldPos.xz * CLOUD_MAP_SCALE;

	float2 uvOffset = mainLightDirection.xz * 0.1;

	float value = 
		tex2D(_CloudMap, +cloudUv*2.0 + _Time.y * CLOUD_SPEED * CLOUD_MAP_SCALE * 5.0 + uvOffset).r * 0.2 +
		tex2D(_CloudMap, -cloudUv     - _Time.y * CLOUD_SPEED * CLOUD_MAP_SCALE       - uvOffset).r * 0.8;

	value = smoothstep(0.3, 0.65, value);
	value *= value * value;

	value = min(value + (1.0 - CLOUD_SHADOW_INTENSITY), 1.0);

	return value;
}