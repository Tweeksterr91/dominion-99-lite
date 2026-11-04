shader_type spatial;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 tint : source_color = vec4(0.6, 0.65, 0.7, 1.0);
void fragment() {
	vec3 original = texture(albedo_tex, UV).rgb;
	float value = dot(original, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = mix(original, vec3(value), 0.82) * tint.rgb * 1.45;
	ROUGHNESS = 0.76;
}
