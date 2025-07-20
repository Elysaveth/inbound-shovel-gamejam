shader_type spatial;

uniform sampler2D snow_albedo : source_color;
uniform sampler2D snow_normal;
uniform sampler2D snow_roughness;
uniform sampler2D dirt_albedo : source_color;
uniform sampler2D dirt_normal;
uniform sampler2D dirt_roughness;
uniform sampler2D dynamic_snow_mask;
uniform float uv_scale = 1.0;
uniform float snow_height = 1.0;

void fragment() {
	vec2 uv = UV * uv_scale;
	vec3 snow_a = texture(snow_albedo, uv).rgb;
	vec3 snow_n = texture(snow_normal, uv).rgb;
	float snow_r = texture(snow_roughness, uv).r;
	vec3 dirt_a = texture(dirt_albedo, uv).rgb;
	vec3 dirt_n = texture(dirt_normal, uv).rgb;
	float dirt_r = texture(dirt_roughness, uv).r;

	float snow_mask = COLOR.r;
	snow_mask = texture(dynamic_snow_mask, UV).r;

	ALBEDO = mix(snow_a, snow_a, snow_mask);
	//ALBEDO = mix(dirt_a, snow_a, snow_mask);
	NORMAL = mix(snow_a, snow_n, snow_mask);
	//NORMAL = mix(dirt_n, snow_n, snow_mask);
	ROUGHNESS = mix(snow_r, snow_r, snow_mask);
	//ROUGHNESS = mix(dirt_r, snow_r, snow_mask);
}

void vertex() {
	float snow_mask = COLOR.r;
	snow_mask = texture(dynamic_snow_mask, UV).r;
	VERTEX.y += snow_mask * snow_height;
	NORMAL.y = VERTEX.y;
}
