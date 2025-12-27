extends Camera2D

func _process(_delta: float) -> void:
	# 1. Reach out to the main game window (the root viewport)
	# 2. Find whatever camera is currently active (the Player's camera)
	var main_cam = get_tree().root.get_camera_2d()
	
	# 3. Copy its position and zoom exactly
	if main_cam:
		global_position = main_cam.global_position
		zoom = main_cam.zoom
