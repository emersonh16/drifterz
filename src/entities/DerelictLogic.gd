extends CharacterBody2D

# Points to your physical "Part" file (The Soul)
@export var stats: Resource = preload("res://src/data/DefaultStats.tres")

func _physics_process(_delta: float) -> void:
	# 1. Get Direction (This returns 1, -1, or 0 for each axis)
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Set Velocity (Direction multiplied by your static speed of 300)
	velocity = direction * stats.max_speed
	
	# 3. Execute Movement
	move_and_slide()
