shader_type canvas_item;

uniform float crawl_width = 560.0;
uniform float crawl_height = 1300.0;
uniform float horizon_scale = 0.70;

void vertex() {
	float depth = clamp(VERTEX.y / crawl_height, 0.0, 1.0);
	float perspective = mix(horizon_scale, 1.0, depth);
	float center_x = crawl_width * 0.5;
	VERTEX.x = center_x + (VERTEX.x - center_x) * perspective;
	VERTEX.y = crawl_height * pow(depth, 1.12);
}
