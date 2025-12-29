extends Node

# MiasmaManager - The Source of Truth for Cleared Fog Tiles
# Simple, world-space fog clearing system

# The persistent dictionary of cleared tiles
# Key: Vector2i (miasma grid coordinates)
# Value: int (timestamp in milliseconds - for future regrowth system)
var cleared_tiles: Dictionary = {}

# Clear fog at a world position with radius
# world_pos: Vector2 - world pixel coordinates
# radius: float - clearing radius in world pixels
func clear_fog(world_pos: Vector2, radius: float) -> void:
	# Grid Law: Convert world position to miasma grid coordinates
	var center_grid := Vector2i(floor(world_pos.x / 16.0), floor(world_pos.y / 8.0))
	
	# Calculate bounding box in grid space
	# Add buffer to ensure we cover all tiles within radius
	var radius_x: int = int(ceil((radius + 16.0) / 16.0))
	var radius_y: int = int(ceil((radius + 8.0) / 8.0))
	
	# Loop through all tiles in the bounding box
	for x_offset in range(-radius_x, radius_x + 1):
		for y_offset in range(-radius_y, radius_y + 1):
			var grid_pos := center_grid + Vector2i(x_offset, y_offset)
			
			# Convert grid position back to world center for distance check
			var tile_world_center := Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)
			
			# Check if tile center is within radius
			var distance_sq := world_pos.distance_squared_to(tile_world_center)
			if distance_sq <= radius * radius:
				# Add to cleared tiles (persistent, additive)
				# Only add if not already cleared (avoid duplicate work)
				if not cleared_tiles.has(grid_pos):
					cleared_tiles[grid_pos] = Time.get_ticks_msec()
