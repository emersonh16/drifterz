shader_type canvas_item;

// This "uniform" slot creates the menu option you are looking for
uniform sampler2D mask_texture;

void fragment() {
	vec4 base_color = COLOR;
	vec4 mask_sample = texture(mask_texture, UV);
	base_color.a = 1.0 - mask_sample.r;
	COLOR = base_color;
}