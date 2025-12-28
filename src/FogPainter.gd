extends Node2D

@onready var mask_camera: Camera2D = get_parent().get_node("MaskCamera")

# Optimization: Store tile size as float once to avoid casting every frame
@onready var tile_size_f: float = float(MiasmaManager.TILE_SIZE)
@onready var half_tile: Vector2 = Vector2(tile_size_f / 2.0, tile_size_f / 2.0)

func _process(_delta: float) -> void:
	if not mask_camera:
		return
		
	# FIX 1: Sync Position in _process, NOT _draw.
	# This ensures the transform is set before the rendering server asks "where are you?"
	# using get_screen_center_position() is safer for Drag Center cameras than global_position.
	global_position = mask_camera.get_screen_center_position()
	
	queue_redraw()

func _draw() -> void:
	# If MiasmaManager isn't ready, abort
	if MiasmaManager.cleared_tiles.is_empty() and MiasmaManager.player_exact_position == Vector2.ZERO:
		return

	var hole_color = Color.WHITE
	
	# Since we synced global_position to the Camera Center in _process,
	# Local (0,0) is now the CENTER of the screen.
	
	# We need the camera's world position for the math below.
	# Since global_position == cam_center, we can use our own position.
	var cam_center_world = global_position
	
	# --- Draw the "Memory" (The Grid) ---
	for grid_pos in MiasmaManager.cleared_tiles:
		# 1. Calculate Tile Top-Left (World)
		var tile_top_left = Vector2(grid_pos.x * tile_size_f, grid_pos.y * tile_size_f)
		
		# 2. FIX 2: Apply Half-Tile Offset to get Center
		# The previous "Down/Right" issue suggests we were drawing at Top-Left.
		# Adding this moves the draw point to the physical center of the grid square.
		var tile_center_world = tile_top_left + half_tile
		
		# 3. Convert to Local Space
		# Formula: Target_World - Origin_World = Local_Offset
		var center_local = tile_center_world - cam_center_world
		
		# 4. Draw
		# We divide by 1.5 to ensure slight overlap/feathering logic is maintained
		draw_circle(center_local, tile_size_f / 1.5, hole_color)
		
	# --- Draw the "Live Vision" ---
	if MiasmaManager.player_exact_position != Vector2.ZERO:
		var player_local = MiasmaManager.player_exact_position - cam_center_world
		var player_radius_local = (200.0 / 1.5) 
		draw_circle(player_local, player_radius_local, hole_color)
