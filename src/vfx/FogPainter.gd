extends Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# 1. Get the Main Camera and Screen Stats
	var viewport = get_viewport()
	var camera = get_tree().root.get_camera_2d()
	if not camera: return
	
	var screen_size = viewport.size
	var cam_pos = camera.global_position
	
	# 2. Fill the screen with "Fog" (Black) - equivalent to JS ctx.fillRect
	# We draw a massive rectangle covering the viewport to ensure opacity
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color.BLACK)
	
	# 3. Setup "Hole" Drawing (Destination-Out equivalent)
	# In Godot, we draw transparent shapes on top, but for the shader mask, 
	# we usually draw White on Black (or vice versa). 
	# Let's draw WHITE circles that the shader will turn Transparent.
	var hole_color = Color.WHITE
	var tile_size = MiasmaManager.TILE_SIZE
	var half_size = Vector2(tile_size, tile_size) / 2.0
	
	# 4. Calculate the Camera Offset (The JS Logic: -cx + w/2)
	# This vector converts a World Coordinate to a Screen Coordinate
	var screen_center = Vector2(screen_size.x / 2.0, screen_size.y / 2.0)
	var world_to_screen_offset = screen_center - cam_pos

	# 5. Draw the Holes
	for grid_pos in MiasmaManager.cleared_tiles:
		var world_pos = Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)
		
		# KEY FIX: Manually convert to Screen Space
		var screen_draw_pos = world_pos + world_to_screen_offset
		
		# Optimization: Don't draw if way off screen (Culling)
		if not Rect2(Vector2.ZERO, screen_size).has_point(screen_draw_pos):
			continue
			
		draw_circle(screen_draw_pos + half_size, tile_size / 1.5, hole_color)
