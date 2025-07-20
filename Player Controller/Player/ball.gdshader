shader_type spatial;

uniform float height = 64.0;
uniform sampler2D snow_albedo : source_color;
uniform sampler2D snow_roughness;
uniform sampler2D snow_normal;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 world_vertex = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 model_vertex = (inverse(MODEL_MATRIX) * world_vertex).xyz;
	float gradient_uv = (model_vertex.y / height) + 0.5;

	ALBEDO = texture(snow_albedo, UV).rgb;
	NORMAL_MAP = texture(snow_normal, UV).xyz;
	ROUGHNESS = texture(snow_roughness, UV).r;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}


//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
