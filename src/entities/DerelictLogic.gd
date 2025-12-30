extends CharacterBody2D

# The Soul: Always use the data resource 
@export var stats: Resource = preload("res://src/data/DefaultStats.tres")

func _physics_process(_delta: float) -> void:
	# 1. Look for 'Actions' (The Robust Way)
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Set Velocity
	velocity = direction * stats.max_speed
	
	# 3. Move the Body
	move_and_slide()
	
	# Note: Fog clearing is now handled by Beam node
