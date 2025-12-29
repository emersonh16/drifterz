extends Node
class_name CoordConverter

# This math turns a standard 2D point into an Isometric point
static func to_isometric(vector: Vector2) -> Vector2:
	return Vector2(vector.x - vector.y, (vector.x + vector.y) * 0.5)

# Convert world position to miasma grid coordinates (16x8 grid)
# Miasma tiles are 1/4 the size of ground tiles (64x32 -> 16x8)
# Pixel-perfect: tiles snap to 16/8 boundaries using explicit float division
# Aligned to ground tile boundaries: ground tile (0,0) at world (0,0) = miasma tile (0,0) at world (0,0)
static func world_to_miasma(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / 16.0), floor(pos.y / 8.0))

# Convert miasma grid coordinates to world position (origin/top-left of tile)
# Aligned so miasma (0,0) = ground (0,0) = world (0,0)
static func miasma_to_world_origin(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * 16.0, grid_pos.y * 8.0)

# Convert miasma grid coordinates to world position (center of tile)
# Returns the center point of the miasma tile in world space
# For 16x8 tiles: center = origin + (8, 4)
static func miasma_to_world_center(grid_pos: Vector2i) -> Vector2:
	var origin := miasma_to_world_origin(grid_pos)
	return Vector2(origin.x + 8.0, origin.y + 4.0)
