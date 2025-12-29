extends Node
class_name CoordConverter

# This math turns a standard 2D point into an Isometric point
static func to_isometric(vector: Vector2) -> Vector2:
	return Vector2(vector.x - vector.y, (vector.x + vector.y) * 0.5)

# Convert world position to miasma grid coordinates (16x8 grid)
# Miasma tiles are 1/4 the size of ground tiles (64x32 -> 16x8)
static func world_to_miasma(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / 16), floor(pos.y / 8))

# Convert miasma grid coordinates to world position (center of tile)
# Returns the center point of the miasma tile in world space
static func miasma_to_world_center(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * 16 + 8, grid_pos.y * 8 + 4)
