extends Node2D

func _process(_delta: float) -> void:
	# We redraw every frame to ensure smooth movement/updates
	# (We will optimize this later if the dictionary gets huge)
	queue_redraw()

func _draw() -> void:
	# 1. Set the "Hole" color to White
	var hole_color = Color.WHITE
	var tile_size = MiasmaManager.TILE_SIZE
	
	# 2. Loop through every cleared tile in the Manager
	for grid_pos in MiasmaManager.cleared_tiles:
		# 3. Convert Grid Coordinate -> World Position
		# (Note: If your game is Isometric, we will adjust this math shortly)
		var draw_pos = Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)
		
		# 4. Draw a Circle for the hole (Soft and organic)
		# We add half a tile size to center it
		var center = draw_pos + Vector2(tile_size / 2.0, tile_size / 2.0)
		draw_circle(center, tile_size / 1.5, hole_color)
