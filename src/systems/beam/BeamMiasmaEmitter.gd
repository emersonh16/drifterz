extends Node

# BeamMiasmaEmitter: Routes beam mode actions to appropriate MiasmaManager functions
# Additive Miasma Rule: Never resets or clears cleared_tiles dictionary - tiles persist forever
# All clearing operations are additive and permanent (only removed by future Regrowth System)

func apply_bubble(bubble: Dictionary) -> void:
	# Clearing is ADDITIVE - tiles persist like JS clearedMap
	# Never call cleared_tiles.clear() - this breaks persistence
	
	var origin: Vector2 = bubble["origin"]
	var radius: float = bubble["radius"]
	MiasmaManager.clear_fog(origin, radius)

func apply_laser(origin: Vector2, direction: Vector2, length: float) -> void:
	# Apply persistent laser path clearing
	# Creates a wide tunnel that stays in the world forever
	MiasmaManager.clear_laser_path(origin, direction, length)

func apply_cone(origin: Vector2, direction: Vector2, angle: float, length: float) -> void:
	# TODO: Implement cone clearing logic
	# For now, use a simple bubble at the tip
	var tip_pos := origin + direction.normalized() * length
	MiasmaManager.clear_fog(tip_pos, 32.0)
