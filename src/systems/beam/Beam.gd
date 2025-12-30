extends Node2D

# Beam - The Input System for Fog Clearing
# Calculates which 16x8 tiles fall within clearing radius
# Sends coordinates to MiasmaManager

# Clearing configuration
@export var clearing_radius: float = 64.0  # World pixels

# Reference to parent (DerelictLogic)
var parent_body: CharacterBody2D

func _ready() -> void:
	parent_body = get_parent() as CharacterBody2D
	if not parent_body:
		push_error("Beam: Parent must be a CharacterBody2D")

func _process(_delta: float) -> void:
	if not parent_body:
		return
	
	# Get player's world position
	var player_pos := parent_body.global_position
	
	# Clear fog around player position (world-space carving)
	MiasmaManager.clear_fog(player_pos, clearing_radius)
	
	# Run buffer check every 60 frames
	MiasmaManager.buffer_check(player_pos)

