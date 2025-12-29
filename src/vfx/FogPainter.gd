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

	# Ensure SubViewport size is synced to maintain 1:1 resolution parity
	var parent_viewport := get_parent() as SubViewport
	if not parent_viewport:
		return
	parent_viewport.size = get_tree().root.size
	var viewport_center := parent_viewport.size / 2.0

	# Get the parent Camera2D (main player camera)
	# SubViewport is a child of Camera2D, so SubViewport's (0,0) = camera's world position
	var parent_camera: Camera2D = parent_viewport.get_parent() as Camera2D
	if not parent_camera:
		return
	
	var camera_world_pos := parent_camera.global_position

	# Draw solid 16x8 rectangles for each cleared tile
	# This ensures 100% pixel coverage within grid cells, eliminating corner gaps
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		# Convert grid position to world position (origin/top-left of tile)
		var world_origin := CoordConverter.miasma_to_world_origin(grid_pos)
		
		# Calculate screen position: (world_origin - camera.global_position) + viewport_center
		var screen_pos := (world_origin - camera_world_pos) + viewport_center
		
		# Crucially, round to lock to pixel grid - prevents sub-pixel gaps
		screen_pos = screen_pos.round()
		
		# Draw solid 16x8 rectangle for 100% pixel coverage
		# This eliminates checkerboard pattern by ensuring no gaps between tiles
		var rect := Rect2(screen_pos, Vector2(16, 8))
		draw_rect(rect, Color.WHITE)
