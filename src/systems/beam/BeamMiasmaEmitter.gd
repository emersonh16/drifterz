extends Node

func apply_bubble(bubble: Dictionary) -> void:
	MiasmaManager.cleared_tiles.clear() # <- add this line (temporary for bubble-only)

	var origin: Vector2 = bubble["origin"]
	var radius: float = bubble["radius"]
	MiasmaManager.clear_fog(origin, radius)
