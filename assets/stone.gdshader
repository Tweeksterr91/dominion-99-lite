shader_type spatial;
uniform vec4 stone_color : source_color = vec4(0.2, 0.3, 0.25, 1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	float grain = hash(floor(UV * 96.0));
	float patches = hash(floor(UV * 12.0));
	float mortar = max(step(0.955, fract(UV.x * 4.0)), step(0.96, fract(UV.y * 3.0)));
	ALBEDO = stone_color.rgb * (0.72 + patches * 0.35 + grain * 0.13) * (1.0 - mortar * 0.28);
	ROUGHNESS = 0.95;
}
