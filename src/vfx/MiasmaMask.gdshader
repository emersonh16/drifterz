shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	vec4 world_pixels = texture(screen_texture, SCREEN_UV);
	// If we see the white diamonds, the fog becomes 100% transparent
	float alpha = 1.0;
	if (world_pixels.r > 0.8) { alpha = 0.0; }
	COLOR = vec4(0.05, 0.07, 0.1, alpha);
}

