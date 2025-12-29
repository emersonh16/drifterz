extends Node2D

func _process(_delta: float) -> void:
	# Sync SubViewport size to match window size (resolution parity)
	var parent_viewport := get_parent() as SubViewport
	if parent_viewport:
		parent_viewport.size = get_tree().root.size
	
	queue_redraw()

func _draw() -> void:
	if MiasmaManager.cleared_tiles.is_empty():
		return

	# Draw 16x8 rectangles for each cleared tile to ensure full coverage
	# Since FogMask is now a child of Camera2D, the camera's transform is automatically applied
	# We draw in world coordinates and the camera handles the transformation
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		# Convert grid position to world position (center of tile) using centralized converter
		var world_center := CoordConverter.miasma_to_world_center(grid_pos)
		
		# Draw rect that covers the entire 16x8 Miasma grid unit
		# Rect position is top-left corner: center - half_size
		var rect := Rect2(world_center - Vector2(8, 4), Vector2(16, 8))
		draw_rect(rect, Color.WHITE)
