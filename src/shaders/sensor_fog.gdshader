shader_type canvas_item;

uniform vec2 ship_uv = vec2(0.5, 0.8);
uniform vec4 fog_color : source_color = vec4(0.025, 0.055, 0.11, 0.92);
uniform float reveal_radius = 0.19;
uniform float edge_feather = 0.095;
uniform float screen_aspect = 1.77778;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 offset = UV - ship_uv;
	offset.x *= screen_aspect;
	float distance_from_ship = length(offset);
	float fog_mask = smoothstep(reveal_radius, reveal_radius + edge_feather, distance_from_ship);

	vec2 noise_cell = floor(UV * vec2(90.0, 52.0) + TIME * vec2(1.8, -0.7));
	float grain = hash(noise_cell);
	float scan = 0.5 + 0.5 * sin(UV.y * 720.0 + TIME * 3.0);
	float texture_alpha = mix(0.78, 1.0, grain) * mix(0.92, 1.0, scan);

	COLOR = vec4(fog_color.rgb, fog_color.a * fog_mask * texture_alpha);
}
