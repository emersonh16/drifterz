extends Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if MiasmaManager.cleared_tiles.is_empty():
		return

	var tile_size := MiasmaManager.TILE_SIZE

	# Compute bubble center (average of cleared tiles)
	var sum := Vector2.ZERO
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		sum += Vector2(grid_pos.x, grid_pos.y)
	var center_grid := sum / MiasmaManager.cleared_tiles.size()
	var center_world := center_grid * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)

	# Compute bubble radius (farthest cleared tile)
	var max_dist := 0.0
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		var world_pos := Vector2(grid_pos.x, grid_pos.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
		max_dist = max(max_dist, center_world.distance_to(world_pos))

	draw_circle(center_world, max_dist + tile_size * 0.5, Color.WHITE)
