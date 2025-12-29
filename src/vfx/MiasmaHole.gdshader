shader_type canvas_item;

// This "uniform" slot creates the menu option you are looking for
uniform sampler2D mask_texture;

void fragment() {
	vec4 base_color = COLOR;
	// Use SCREEN_UV for screen-space sampling: ColorRect covers full screen, mask texture is camera-relative
	// Since FogMask is now a child of Camera2D, the SubViewport output aligns 1:1 with screen space
	vec4 mask_sample = texture(mask_texture, SCREEN_UV);
	base_color.a = 1.0 - mask_sample.r;
	COLOR = base_color;
}