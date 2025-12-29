extends Camera2D

# Syncs the SubViewport camera with the main player camera
# This camera is inside FogMask SubViewport and needs to match the parent Camera2D
# Position camera at viewport center so it looks at the right world position

func _process(_delta: float) -> void:
	# Get the parent Camera2D (the main player camera)
	var parent_camera: Camera2D = get_parent().get_parent() as Camera2D
	if not parent_camera:
		return
	
	# Get the SubViewport to calculate center
	var viewport := get_parent() as SubViewport
	if not viewport:
		return
	
	# Position camera at viewport center in SubViewport coordinate space
	# This ensures the camera looks at the SubViewport's origin (camera world pos) at viewport center
	var viewport_center := viewport.size / 2.0
	position = viewport_center
	
	# Sync zoom and offset to match the main camera
	zoom = parent_camera.zoom
	offset = parent_camera.offset
