extends Node

# The "Sparse Map" - mimics your JS clearedMap logic
# Key: Vector2i (Grid Coordinates) | Value: int (Time in msec when it was cleared)
var cleared_tiles: Dictionary = {}

# Architecture Constants - Miasma tiles are 1/4 the size of ground tiles (64x32 -> 16x8)
const TILE_SIZE_WIDTH: int = 16
const TILE_SIZE_HEIGHT: int = 8

#func _ready() -> void:
	# Listen for the Derelict's movement
	# This ensures the fog reacts automatically, keeping the Player script clean
#	SignalBus.derelict_moved.connect(_on_derelict_moved)

#func _on_derelict_moved(new_position: Vector2) -> void:
	# Clear a radius of roughly 3 tiles (192px) around the player
	# We use 200.0 for a bit of margin
#	clear_fog(new_position, 200.0)

# Port of 'clearArea' from index.js
func clear_fog(world_pos: Vector2, radius: float) -> void:
	# Convert World Position -> Miasma Grid Coordinates using centralized converter
	var center_grid: Vector2i = CoordConverter.world_to_miasma(world_pos)
	# Use average tile size for radius calculation (approximation for isometric)
	var avg_tile_size: float = (TILE_SIZE_WIDTH + TILE_SIZE_HEIGHT) / 2.0
	var radius_in_tiles: int = ceil(radius / avg_tile_size)
	var r2: float = (radius / avg_tile_size) ** 2
	
	# Loop through the bounding box of the circle
	for x in range(center_grid.x - radius_in_tiles, center_grid.x + radius_in_tiles + 1):
		for y in range(center_grid.y - radius_in_tiles, center_grid.y + radius_in_tiles + 1):
			var tile_pos := Vector2i(x, y)
			
			# Circle Check: dx*dx + dy*dy <= r2 (Do it right, no square holes)
			var dx: float = x - (world_pos.x / TILE_SIZE_WIDTH)
			var dy: float = y - (world_pos.y / TILE_SIZE_HEIGHT)
			
			if dx*dx + dy*dy <= r2:
				# Store the time it was cleared (for future regrowth logic)
				if not cleared_tiles.has(tile_pos):
					cleared_tiles[tile_pos] = Time.get_ticks_msec()
