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

	# Get the parent Camera2D (main player camera)
	# SubViewport is a child of Camera2D, so SubViewport's (0,0) = camera's world position
	var parent_camera: Camera2D = get_parent().get_parent() as Camera2D
	if not parent_camera:
		return
	
	var camera_world_pos := parent_camera.global_position
	
	# Get the SubViewport to calculate center offset
	# MaskSync camera is positioned at viewport center, so world (0,0) appears at viewport center
	var parent_viewport := get_parent() as SubViewport
	if not parent_viewport:
		return
	var viewport_center := parent_viewport.size / 2.0

	# Draw isometric diamonds for each cleared tile
	# Convert world coordinates to SubViewport coordinates:
	# SubViewport (0,0) = camera world position
	# MaskSync camera is at viewport_center, so we offset by viewport_center
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		# Convert grid position to world position (origin of tile to match ground tile alignment)
		# Ground tiles are positioned at their origin, so miasma should match
		var world_origin := CoordConverter.miasma_to_world_origin(grid_pos)
		
		# Convert to SubViewport coordinates
		# Since SubViewport is child of Camera2D, its (0,0) = camera world position
		# MaskSync camera is at viewport_center, so we add viewport_center offset
		var viewport_origin := (world_origin - camera_world_pos) + viewport_center
		
		# Round to nearest pixel for pixel-perfect rendering
		viewport_origin = viewport_origin.round()
		
		# Define diamond polygon points (16x8 isometric diamond)
		# Tile is 16x8, so center is at (8, 4) from origin
		# Diamond extends 8px horizontally and 4px vertically from center
		var tile_center_offset := Vector2(8, 4)
		var diamond_points := PackedVector2Array([
			viewport_origin + tile_center_offset + Vector2(0, -4),   # Top
			viewport_origin + tile_center_offset + Vector2(8, 0),    # Right
			viewport_origin + tile_center_offset + Vector2(0, 4),   # Bottom
			viewport_origin + tile_center_offset + Vector2(-8, 0)    # Left
		])
		
		# Draw isometric diamond polygon
		draw_colored_polygon(diamond_points, Color.WHITE)
