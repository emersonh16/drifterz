extends Node2D

# Debug visualizer for beam shapes
# Draws the laser path, core points, halos, and bubble radius

var debug_enabled: bool = true
var laser_origin: Vector2 = Vector2.ZERO
var laser_direction: Vector2 = Vector2.ZERO
var laser_length: float = 0.0
var bubble_origin: Vector2 = Vector2.ZERO
var bubble_radius: float = 0.0
var current_mode: int = 0  # BeamMode enum value

func _ready() -> void:
	# Make sure we're in the world space (not camera space)
	z_index = 100  # Draw on top

func _draw() -> void:
	if not debug_enabled:
		return
	
	# Get parent's world position for coordinate conversion
	var parent_world_pos: Vector2 = Vector2.ZERO
	var parent_node := get_parent()
	if parent_node and parent_node is Node2D:
		parent_world_pos = (parent_node as Node2D).global_position
	
	# Draw bubble mode debug
	if current_mode == 1:  # BUBBLE
		if bubble_radius > 0.0:
			# Convert world position to local space
			var local_bubble_origin := bubble_origin - parent_world_pos
			# Draw bubble circle
			var yellow_transparent := Color(Color.YELLOW.r, Color.YELLOW.g, Color.YELLOW.b, 0.3)
			draw_circle(local_bubble_origin, bubble_radius, yellow_transparent)
			draw_arc(local_bubble_origin, bubble_radius, 0.0, TAU, 32, Color.YELLOW, 2.0)
	
	# Draw laser mode debug
	if current_mode == 3:  # LASER
		if laser_length > 0.0:
			var dir_normalized := laser_direction.normalized()
			var perp := Vector2(-dir_normalized.y, dir_normalized.x)
			var end_pos := laser_origin + dir_normalized * laser_length
			
			# Convert to local space
			var local_origin := laser_origin - parent_world_pos
			var local_end := end_pos - parent_world_pos
			
			# Draw main laser line
			draw_line(local_origin, local_end, Color.CYAN, 3.0)
			
			# Draw core clearing points
			const STRIDE: float = 8.0
			const CORE_RADIUS: float = 16.0
			var distance: float = 0.0
			while distance <= laser_length:
				var step_pos := laser_origin + dir_normalized * distance
				var local_step := step_pos - parent_world_pos
				var red_transparent := Color(Color.RED.r, Color.RED.g, Color.RED.b, 0.2)
				draw_circle(local_step, CORE_RADIUS, red_transparent)
				draw_arc(local_step, CORE_RADIUS, 0.0, TAU, 16, Color.RED, 1.5)
				distance += STRIDE
			
			# Draw halo points
			const HALO_RADIUS: float = 8.0
			const HALO_OFFSET: float = 24.0
			distance = 0.0
			while distance <= laser_length:
				var step_pos := laser_origin + dir_normalized * distance
				var halo_left := step_pos + perp * HALO_OFFSET
				var halo_right := step_pos - perp * HALO_OFFSET
				var local_left := halo_left - parent_world_pos
				var local_right := halo_right - parent_world_pos
				
				var green_transparent := Color(Color.GREEN.r, Color.GREEN.g, Color.GREEN.b, 0.2)
				draw_circle(local_left, HALO_RADIUS, green_transparent)
				draw_arc(local_left, HALO_RADIUS, 0.0, TAU, 16, Color.GREEN, 1.0)
				draw_circle(local_right, HALO_RADIUS, green_transparent)
				draw_arc(local_right, HALO_RADIUS, 0.0, TAU, 16, Color.GREEN, 1.0)
				
				distance += STRIDE
			
			# Draw tip
			var magenta_transparent := Color(Color.MAGENTA.r, Color.MAGENTA.g, Color.MAGENTA.b, 0.3)
			draw_circle(local_end, CORE_RADIUS, magenta_transparent)
			draw_arc(local_end, CORE_RADIUS, 0.0, TAU, 16, Color.MAGENTA, 2.0)

func update_laser_debug(origin: Vector2, direction: Vector2, length: float) -> void:
	laser_origin = origin
	laser_direction = direction
	laser_length = length
	queue_redraw()

func update_bubble_debug(origin: Vector2, radius: float) -> void:
	bubble_origin = origin
	bubble_radius = radius
	queue_redraw()

func set_mode(mode: int) -> void:
	current_mode = mode
	queue_redraw()

