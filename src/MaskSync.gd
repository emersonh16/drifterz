extends Camera2D

# We need to talk to the viewport container (fogmask) to resize it
@onready var fog_viewport: SubViewport = get_parent()

func _process(_delta: float) -> void:
	# 1. Find the Main Camera used by the player
	var main_cam = get_tree().root.get_camera_2d()
	
	if main_cam:
		# 2. Match Position and Zoom exactly
		global_position = main_cam.global_position
		zoom = main_cam.zoom
		
		# 3. Match Screen Resolution
		# If the game window size changes, the mask texture must resize too
		# otherwise the "holes" will be drawn in the wrong place.
		var screen_size = get_viewport().get_visible_rect().size
		
		# Only update if the size actually changed (saves performance)
		if fog_viewport.size != Vector2i(screen_size):
			fog_viewport.size = Vector2i(screen_size)
