extends Node
class_name CoordConverter

# This math turns a standard 2D point into an Isometric point
static func to_isometric(vector: Vector2) -> Vector2:
	return Vector2(vector.x - vector.y, (vector.x + vector.y) * 0.5)
