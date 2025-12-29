extends Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if MiasmaManager.cleared_tiles.is_empty():
		return

	var tile_width := MiasmaManager.TILE_SIZE_WIDTH
	var tile_height := MiasmaManager.TILE_SIZE_HEIGHT

	# Draw 16x8 isometric diamonds for each cleared tile
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		# Convert grid position to world position (center of tile)
		var world_pos := Vector2(
			grid_pos.x * tile_width + tile_width * 0.5,
			grid_pos.y * tile_height + tile_height * 0.5
		)
		
		# Draw isometric diamond shape (16x8)
		# Diamond points: top, right, bottom, left
		var points := PackedVector2Array([
			world_pos + Vector2(0, -tile_height * 0.5),  # Top
			world_pos + Vector2(tile_width * 0.5, 0),     # Right
			world_pos + Vector2(0, tile_height * 0.5),     # Bottom
			world_pos + Vector2(-tile_width * 0.5, 0)     # Left
		])
		
		draw_colored_polygon(points, Color.WHITE)
