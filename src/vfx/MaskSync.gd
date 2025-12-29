extends Camera2D

var main_camera: Camera2D

func _ready() -> void:
	# Set process priority to ensure this runs AFTER player movement logic
	process_priority = 100

func _process(_delta: float) -> void:
	# Step 1: Check if main_camera is null or invalid
	if not is_instance_valid(main_camera):
		# Step 2: Attempt to find the camera
		main_camera = get_tree().root.get_camera_2d()
	
	# Step 3: If it is STILL null, return (do nothing this frame)
	if not main_camera:
		return
	
	# Step 4: Ensure SubViewport size matches main window size
	var parent_viewport := get_parent() as SubViewport
	if parent_viewport:
		# Get the main window's visible rect size
		var main_viewport := get_tree().root.get_viewport()
		if main_viewport:
			var visible_rect := main_viewport.get_visible_rect()
			parent_viewport.size = visible_rect.size
	
	# Step 5: Sync Logic - Sync position, zoom, and offset
	# Round position to align SubViewport pixels with screen pixels (prevents jitter)
	global_position = main_camera.global_position
	zoom = main_camera.zoom
	offset = main_camera.offset
