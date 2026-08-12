shader_type canvas_item;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float ax = abs(uv.x);
	float ay = abs(uv.y);
	float hex = max(ax * 0.866025 + ay * 0.5, ay);
	if (hex > 0.45) {
		discard;
	}
	COLOR = texture(TEXTURE, UV);
}
