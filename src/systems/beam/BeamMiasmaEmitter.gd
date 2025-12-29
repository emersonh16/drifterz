extends Node

func apply_bubble(bubble: Dictionary) -> void:
	# Clearing is ADDITIVE - tiles persist like JS clearedMap
	# Never call cleared_tiles.clear() - this breaks persistence
	
	var origin: Vector2 = bubble["origin"]
	var radius: float = bubble["radius"]
	MiasmaManager.clear_fog(origin, radius)
