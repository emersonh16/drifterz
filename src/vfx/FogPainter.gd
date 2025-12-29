extends MultiMeshInstance2D

# FogPainter - World-Space Fog Rendering
# Renders cleared fog tiles using MultiMesh at fixed world coordinates
# NO CAMERA MATH - All positions are absolute world coordinates

func _ready() -> void:
	# ATTACHMENT: Ensure we have a MultiMesh resource
	if not multimesh:
		multimesh = MultiMesh.new()
	
	# INITIALIZATION: Configure MultiMesh resource
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	
	# Create and set the QuadMesh (16x8 size for texture bypass test)
	# TEMPORARY: Testing without texture to rule out texture as gap cause
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(16.0, 8.0)
	multimesh.mesh = quad_mesh
	
	# Initialize instance count to 0 (will be rebuilt in _process)
	multimesh.instance_count = 0
	
	# Set texture filter to Nearest for pixel-perfect rendering
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Physical Sandwich method: Draw grass-colored diamonds on top of fog
	# This "re-draws" the meadow exactly where the player has walked
	# Meadow green color (matches typical grass texture)
	self_modulate = Color(0.4, 0.6, 0.3, 1.0)  # Meadow green

func _process(_delta: float) -> void:
	# DATA REFRESH: Rebuild MultiMesh based on cleared tiles
	_rebuild_multimesh()

func _rebuild_multimesh() -> void:
	if not multimesh:
		return
	
	# Clear and rebuild instance count
	if MiasmaManager.cleared_tiles.is_empty():
		multimesh.instance_count = 0
		return
	
	# Set instance count to match cleared tiles
	var tile_count := MiasmaManager.cleared_tiles.size()
	multimesh.instance_count = tile_count
	
	# Set transform for each cleared tile
	var instance_index := 0
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		# WORLD-SPACE TRUTH: Convert grid to world center
		# Formula: world_center = Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)
		# This places the CENTER of the 16x8 mesh into the CENTER of the grid cell
		var world_center := Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)
		
		# THE POSITION: Create transform with world center
		# NO CAMERA MATH - This is absolute world position
		var instance_transform := Transform2D(0, world_center)
		
		# Set the instance transform
		multimesh.set_instance_transform_2d(instance_index, instance_transform)
		instance_index += 1
