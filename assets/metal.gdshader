shader_type spatial;
uniform vec4 metal_color : source_color = vec4(0.18, 0.22, 0.27, 1.0);

float grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// Original procedural surface: coarse wear and fine machining marks.
	float coarse = grain(floor(UV * 48.0));
	float scratches = step(0.97, grain(vec2(floor(UV.x * 384.0), floor(UV.y * 12.0))));
	float seams = step(0.975, fract(UV.x * 4.0)) + step(0.985, fract(UV.y * 3.0));
	ALBEDO = metal_color.rgb * (0.83 + coarse * 0.23 + scratches * 0.22) * (1.0 - min(seams, 1.0) * 0.30);
	METALLIC = 0.55;
	ROUGHNESS = 0.74;
}
