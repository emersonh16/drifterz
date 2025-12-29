extends Node

const BeamModel = preload("res://src/systems/beam/BeamModel.gd")
const BeamDebugVisualizer = preload("res://src/systems/beam/BeamDebugVisualizer.gd")

enum BeamMode { OFF, BUBBLE_MIN, BUBBLE_MAX, CONE, LASER }

var beam_model: BeamModel
var current_mode: BeamMode = BeamMode.OFF
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

func _input(event: InputEvent) -> void:
	# Handle mode switching with mouse wheel
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Cycle forward through modes
			current_mode = (current_mode + 1) % BeamMode.size()
			if debug_visualizer:
				debug_visualizer.set_mode(current_mode)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Cycle backward through modes (handle wrap-around)
			current_mode = (current_mode - 1 + BeamMode.size()) % BeamMode.size()
			if debug_visualizer:
				debug_visualizer.set_mode(current_mode)
		
		# Snap to Laser on Left Mouse Button press
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if current_mode != BeamMode.LASER:
				current_mode = BeamMode.LASER
				if debug_visualizer:
					debug_visualizer.set_mode(current_mode)

func _process(_delta: float) -> void:
	var origin: Vector2 = get_parent().global_position
	
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
			$BeamMiasmaEmitter.apply_laser(origin, direction, length)
	
	# Handle bubble modes (always active, not just on click)
	elif current_mode == BeamMode.BUBBLE_MIN or current_mode == BeamMode.BUBBLE_MAX:
		var radius: float = 32.0 if current_mode == BeamMode.BUBBLE_MIN else 128.0
		var bubble: Dictionary = beam_model.get_bubble_descriptor(origin, radius)
		$BeamMiasmaEmitter.apply_bubble(bubble)
		
		# Update debug visualization
		if debug_visualizer:
			debug_visualizer.update_bubble_debug(origin, radius)
	
	# Handle cone mode
	elif current_mode == BeamMode.CONE:
		# Get mouse position in world space using the camera
		var viewport := get_viewport()
		if viewport:
			var camera: Camera2D = viewport.get_camera_2d()
			if camera:
				var mouse_world_pos: Vector2 = camera.get_global_mouse_position()
				var direction: Vector2 = mouse_world_pos - origin
				var length: float = direction.length()
				if length > 16.0:
					$BeamMiasmaEmitter.apply_cone(origin, direction, 45.0, length)
	
	# OFF mode: do nothing
	elif current_mode == BeamMode.OFF:
		pass
