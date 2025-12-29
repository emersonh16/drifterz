extends Node

const BeamModel = preload("res://src/systems/beam/BeamModel.gd")
const BeamDebugVisualizer = preload("res://src/systems/beam/BeamDebugVisualizer.gd")

enum BeamMode { OFF, BUBBLE, CONE, LASER }

var beam_model: BeamModel
var current_mode: BeamMode = BeamMode.BUBBLE
var debug_visualizer: Node2D = null

func _ready() -> void:
	print("BeamController _ready() running")
	beam_model = BeamModel.new()
	
	# Setup debug visualizer
	var visualizer_node := $BeamVisualizer as Node2D
	if visualizer_node:
		debug_visualizer = BeamDebugVisualizer.new()
		visualizer_node.add_child(debug_visualizer)
		debug_visualizer.set_mode(current_mode)

func _process(_delta: float) -> void:
	var origin: Vector2 = get_parent().global_position
	
	# Handle mode switching with mouse wheel (for now, simple toggle)
	if Input.is_action_just_pressed("ui_up"):  # Temporary: use up arrow to switch to laser
		current_mode = BeamMode.LASER
		if debug_visualizer:
			debug_visualizer.set_mode(current_mode)
	elif Input.is_action_just_pressed("ui_down"):  # Temporary: use down arrow to switch to bubble
		current_mode = BeamMode.BUBBLE
		if debug_visualizer:
			debug_visualizer.set_mode(current_mode)
	
	# Handle laser mode
	if current_mode == BeamMode.LASER:
		# Get mouse position in world space using the camera
		var viewport := get_viewport()
		if not viewport:
			return
		
		var camera: Camera2D = viewport.get_camera_2d()
		if not camera:
			return
		
		# Convert screen position to world position using camera
		var mouse_world_pos: Vector2 = camera.get_global_mouse_position()
		
		# Calculate direction and length from player to mouse
		var direction: Vector2 = mouse_world_pos - origin
		var length: float = direction.length()
		
		# Update debug visualization
		if debug_visualizer:
			debug_visualizer.update_laser_debug(origin, direction, length)
		
		# Only clear if mouse button is pressed and mouse is far enough away
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and length > 16.0:
			MiasmaManager.clear_laser_path(origin, direction, length)
	
	# Handle bubble mode (always active, not just on click)
	elif current_mode == BeamMode.BUBBLE:
		var radius: float = 64.0
		var bubble: Dictionary = beam_model.get_bubble_descriptor(origin, radius)
		$BeamMiasmaEmitter.apply_bubble(bubble)
		
		# Update debug visualization
		if debug_visualizer:
			debug_visualizer.update_bubble_debug(origin, radius)
