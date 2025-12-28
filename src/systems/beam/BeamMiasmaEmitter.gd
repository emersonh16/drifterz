extends Node

func apply_bubble(bubble: Dictionary) -> void:
	var origin: Vector2 = bubble["origin"]
	var radius: float = bubble["radius"]

	MiasmaManager.clear_fog(origin, radius)
