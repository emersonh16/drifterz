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

	# Get the main camera's world position to adjust drawing coordinates
	# Since SubViewport is a child of Camera2D, we need to account for camera position
	var main_viewport := get_tree().root.get_viewport()
	if not main_viewport:
		return
	var main_camera: Camera2D = main_viewport.get_camera_2d()
	if not main_camera:
		return
	
	var camera_world_pos := main_camera.global_position
	
	# Get the SubViewport to calculate center offset
	var parent_viewport := get_parent() as SubViewport
	if not parent_viewport:
		return
	var viewport_center := parent_viewport.size / 2.0

	# Draw isometric diamonds for each cleared tile to match the isometric grid
	# The camera is positioned at viewport center, so we need to offset drawing by viewport center
	# to center the cleared area on the player
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		# Convert grid position to world position (center of tile)
		var world_center := CoordConverter.miasma_to_world_center(grid_pos)
		
		# Convert to SubViewport-relative coordinates (origin is at camera world position)
		# Add viewport center offset so player (at camera world pos) appears at viewport center
		var viewport_relative := (world_center - camera_world_pos) + viewport_center
		
		# Define diamond polygon points relative to center (isometric offsets)
		# These offsets create a perfect 16x8 diamond that tiles seamlessly
		var diamond_points := PackedVector2Array([
			viewport_relative + Vector2(0, -4),   # Top
			viewport_relative + Vector2(8, 0),    # Right
			viewport_relative + Vector2(0, 4),    # Bottom
			viewport_relative + Vector2(-8, 0)    # Left
		])
		
		# Draw isometric diamond polygon instead of axis-aligned rectangle
		draw_colored_polygon(diamond_points, Color.WHITE)
