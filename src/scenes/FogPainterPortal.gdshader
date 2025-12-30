shader_type canvas_item;

uniform sampler2D ground_texture : filter_nearest, repeat_enable;
uniform float world_tile_width = 64.0;
uniform float world_tile_height = 32.0;

varying vec2 world_v_pos;

void vertex() {
    // In Godot 2D, the instance transform is passed via MODEL_MATRIX.
    // We multiply it by VERTEX to get the absolute world position.
    world_v_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    // 1. Trim to Diamond shape
    vec2 centered_uv = UV - 0.5;
    if (abs(centered_uv.x) + abs(centered_uv.y) * 2.0 > 0.48) {
        discard;
    }

    // 2. BOLT TO FLOOR: Divide world position by tile size (64x32)
    // This ensures that as the hole moves, the grass underneath stays stationary.
    vec2 world_uv = world_v_pos / vec2(world_tile_width, world_tile_height);
    
    COLOR = texture(ground_texture, world_uv);
}