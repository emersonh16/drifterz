extends Node

# The "Sparse Map" - mimics your JS clearedMap logic
# Key: Vector2i (Grid Coordinates) | Value: int (Time in msec when it was cleared)
var cleared_tiles: Dictionary = {}

# Architecture Constants - Miasma tiles are 1/4 the size of ground tiles (64x32 -> 16x8)
const TILE_SIZE_WIDTH: int = 16
const TILE_SIZE_HEIGHT: int = 8

#func _ready() -> void:
	# Listen for the Derelict's movement
	# This ensures the fog reacts automatically, keeping the Player script clean
#	SignalBus.derelict_moved.connect(_on_derelict_moved)

#func _on_derelict_moved(new_position: Vector2) -> void:
	# Clear a radius of roughly 3 tiles (192px) around the player
	# We use 200.0 for a bit of margin
#	clear_fog(new_position, 200.0)

# Port of 'clearArea' from index.js
func clear_fog(world_pos: Vector2, radius: float) -> void:
	# Convert World Position -> Miasma Grid Coordinates using centralized converter
	var center_grid: Vector2i = CoordConverter.world_to_miasma(world_pos)
	
	# Check distance to nearest point of each tile, not center
	# This eliminates checkerboard patterns by ensuring tiles are cleared if ANY part is within radius
	# Add generous buffer to loop ranges to ensure we check ALL tiles that could possibly overlap
	var r_sq: float = radius * radius
	# Buffer needs to account for: tile half-size (8px) + isometric scaling effects
	var radius_with_tile_buffer: float = radius + 16.0  # Generous buffer to catch all overlapping tiles
	
	# Set loop ranges to cover the full ellipse (different for X and Y due to isometric)
	# Ensure ranges are integers for proper bounding box coverage
	var x_range: int = ceil(radius_with_tile_buffer / 16.0)
	var y_range: int = ceil(radius_with_tile_buffer / 8.0)
	
	# Loop through the bounding box of the ellipse
	# Ensure we iterate through ALL tiles in the range to prevent checkerboard pattern
	for x in range(center_grid.x - x_range, center_grid.x + x_range + 1):
		for y in range(center_grid.y - y_range, center_grid.y + y_range + 1):
			var tile_pos := Vector2i(x, y)
			
			# Get the tile's world origin and center
			var t_origin: Vector2 = CoordConverter.miasma_to_world_origin(tile_pos)
			var t_center: Vector2 = CoordConverter.miasma_to_world_center(tile_pos)
			
			# Calculate distance from clearing center to tile center
			var dx_center: float = t_center.x - world_pos.x
			var dy_center_unscaled: float = t_center.y - world_pos.y
			
			# Find nearest point on tile to clearing center (in world space)
			# Tile bounds: x in [origin.x, origin.x+16], y in [origin.y, origin.y+8]
			# Clamp clearing center to tile bounds to get nearest point
			var nearest_x: float = clamp(world_pos.x, t_origin.x, t_origin.x + 16.0)
			var nearest_y: float = clamp(world_pos.y, t_origin.y, t_origin.y + 8.0)
			
			# Calculate distance from clearing center to nearest point
			var dx_nearest: float = nearest_x - world_pos.x
			var dy_nearest_unscaled: float = nearest_y - world_pos.y
			
			# Apply isometric Y scaling (2.0x) for distance calculation
			var dy_nearest_scaled: float = dy_nearest_unscaled * 2.0
			
			# Calculate isometric distance squared
			var nearest_dist_sq: float = dx_nearest * dx_nearest + dy_nearest_scaled * dy_nearest_scaled
			
			# Clear tile if nearest point is within radius
			# This ensures ALL overlapping tiles are cleared, eliminating checkerboard pattern
			if nearest_dist_sq <= r_sq:
				# Store the time it was cleared (for future regrowth logic)
				# Only add if not already cleared (additive clearing - matches JS clearedMap behavior)
				if not cleared_tiles.has(tile_pos):
					cleared_tiles[tile_pos] = Time.get_ticks_msec()

# Multi-Pass Laser: Creates organic, slightly irregular tunnel edges with sweep and broom logic
# Clears a multi-layer tunnel along a path: Core (thick center) + Halos (side points)
# Surgical Requirement: Uses stride of 8.0 pixels to step along the path
# Halos: Two parallel rows of clearing stamps +/- 12px from the core path to widen the tunnel
# Sweep: Adds organic offset using sin(phase) * amplitude for irregular edges
# Broom: Perpendicular clearing pass at the end to ensure a clean wide cut
func clear_laser_path(origin: Vector2, direction: Vector2, length: float) -> void:
	# Normalize direction vector
	var dir_normalized := direction.normalized()
	var perp := Vector2(-dir_normalized.y, dir_normalized.x)  # Perpendicular vector for halos
	
	# Stride: step size along the path (8.0 pixels as per surgical requirement)
	const STRIDE: float = 8.0
	
	# Core clearing: thick center line (radius 16)
	const CORE_RADIUS: float = 16.0
	
	# Halo clearing: side points (radius 8)
	const HALO_RADIUS: float = 8.0
	const HALO_OFFSET: float = 12.0  # Distance from center for halo points (+/- 12px as per requirement)
	
	# Sweep parameters: creates organic, slightly irregular edges
	const SWEEP_AMPLITUDE: float = 3.0  # Maximum offset in pixels
	const SWEEP_FREQUENCY: float = 0.1  # Frequency of the sine wave (adjusts how often it oscillates)
	
	# Step along the path from origin to end
	var distance: float = 0.0
	while distance <= length:
		# Calculate sweep offset: offset = sin(phase) * amplitude
		# Phase increases with distance to create organic variation
		var phase: float = distance * SWEEP_FREQUENCY
		var sweep_offset: float = sin(phase) * SWEEP_AMPLITUDE
		
		# Apply sweep offset perpendicular to the direction
		var step_pos := origin + dir_normalized * distance + perp * sweep_offset
		
		# Clear core at this step (uses isometric distance formula via clear_fog)
		clear_fog(step_pos, CORE_RADIUS)
		
		# Clear halos: two parallel rows +/- 12px from the core path (with sweep applied)
		var halo_left := step_pos + perp * HALO_OFFSET
		var halo_right := step_pos - perp * HALO_OFFSET
		clear_fog(halo_left, HALO_RADIUS)
		clear_fog(halo_right, HALO_RADIUS)
		
		distance += STRIDE
	
	# Broom logic: Perpendicular clearing pass at the end to ensure a clean wide cut
	var tip_pos := origin + dir_normalized * length
	var broom_width: float = 24.0  # Width of the broom pass
	var broom_steps: int = 5  # Number of steps in the broom pass
	
	# Clear perpendicular line at the tip
	for i in range(-broom_steps, broom_steps + 1):
		var broom_offset: float = (float(i) / float(broom_steps)) * broom_width
		var broom_pos := tip_pos + perp * broom_offset
		clear_fog(broom_pos, CORE_RADIUS)
	
	# Ensure the tip itself is cleared
	clear_fog(tip_pos, CORE_RADIUS)

# Keyhole Cone: Creates a V-shape with increasing radius and rounded cap
# Steps along path with 8px stride, calculating increasing radius: r = tan(half_angle) * distance
# Stamps a flattened circle at final length to create the rounded "Cap"
func clear_cone_path(origin: Vector2, direction: Vector2, angle: float, length: float) -> void:
	# Normalize direction vector
	var dir_normalized := direction.normalized()
	
	# Convert angle from degrees to radians and calculate half-angle
	var half_angle_rad: float = deg_to_rad(angle) * 0.5
	
	# Stride: step size along the path (8.0 pixels to match laser path)
	const STRIDE: float = 8.0
	
	# Step along the path from origin to end
	var distance: float = 0.0
	while distance <= length:
		var step_pos := origin + dir_normalized * distance
		
		# Calculate increasing radius: r = tan(half_angle) * distance
		var radius: float = tan(half_angle_rad) * distance
		
		# Minimum radius to ensure clearing starts at origin
		if radius < 4.0:
			radius = 4.0
		
		# Clear at this step (uses isometric distance formula via clear_fog)
		clear_fog(step_pos, radius)
		
		distance += STRIDE
	
	# Stamp a flattened circle at the final length to create the rounded "Cap"
	var cap_pos := origin + dir_normalized * length
	var cap_radius: float = tan(half_angle_rad) * length
	if cap_radius < 8.0:
		cap_radius = 8.0
	clear_fog(cap_pos, cap_radius)
