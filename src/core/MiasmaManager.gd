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
	
	# Use absolute world pixels for distance calculation
	var r_sq: float = radius * radius
	
	# Set loop ranges to cover the full ellipse (different for X and Y due to isometric)
	var x_range: int = ceil(radius / 16.0)
	var y_range: int = ceil(radius / 8.0)
	
	# Loop through the bounding box of the ellipse
	for x in range(center_grid.x - x_range, center_grid.x + x_range + 1):
		for y in range(center_grid.y - y_range, center_grid.y + y_range + 1):
			var tile_pos := Vector2i(x, y)
			
			# Get the tile's world center position
			var t_world: Vector2 = CoordConverter.miasma_to_world_center(tile_pos)
			
			# Calculate distance in world pixels with Y scaled for isometric flattening
			var dx: float = t_world.x - world_pos.x
			var dy: float = (t_world.y - world_pos.y) * 2.0
			
			# Clear tile only if within the elliptical radius (absolute world-pixel distance check)
			if (dx*dx + dy*dy) <= r_sq:
				# Store the time it was cleared (for future regrowth logic)
				if not cleared_tiles.has(tile_pos):
					cleared_tiles[tile_pos] = Time.get_ticks_msec()
