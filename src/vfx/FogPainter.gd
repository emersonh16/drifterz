extends MultiMeshInstance2D

# MultiMesh strategy for watertight isometric coverage
# Uses a 16x8 texture stamp that naturally interlocks with zero gaps

var _multimesh_resource: MultiMesh

func _ready() -> void:
	# Create MultiMesh resource
	_multimesh_resource = MultiMesh.new()
	_multimesh_resource.mesh = _create_quad_mesh()
	_multimesh_resource.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh_resource.instance_count = 0  # Will be set dynamically
	multimesh = _multimesh_resource
	
	# Set texture filter to Nearest for pixel-perfect rendering
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Load the miasma stamp texture
	var stamp_texture := load("res://src/vfx/miasma_stamp.png") as Texture2D
	if stamp_texture:
		texture = stamp_texture
	else:
		push_error("FogPainter: Failed to load miasma_stamp.png. Please create a 16x8 white isometric diamond texture.")
	
	# Ensure SubViewport size matches screen size for 1:1 resolution parity
	var parent_viewport := get_parent() as SubViewport
	if parent_viewport:
		parent_viewport.size = get_tree().root.size

func _process(_delta: float) -> void:
	# Ensure SubViewport size matches screen size for 1:1 resolution parity
	var parent_viewport := get_parent() as SubViewport
	if parent_viewport:
		parent_viewport.size = get_tree().root.size
	
	_update_multimesh()

func _create_quad_mesh() -> QuadMesh:
	# Create a 16x8 quad mesh for the isometric diamond stamp
	# The quad is a simple rectangle; the diamond shape comes from the texture
	var quad := QuadMesh.new()
	quad.size = Vector2(16, 8)
	return quad

func _update_multimesh() -> void:
	if not _multimesh_resource:
		return
	
	if MiasmaManager.cleared_tiles.is_empty():
		_multimesh_resource.instance_count = 0
		return
	
	# Get the SubViewport and Camera2D
	var parent_viewport := get_parent() as SubViewport
	if not parent_viewport:
		return
	
	var parent_camera: Camera2D = parent_viewport.get_parent() as Camera2D
	if not parent_camera:
		return
	
	# Calculate viewport center and camera position
	var viewport_center := parent_viewport.size / 2.0
	var camera_world_pos := parent_camera.global_position
	
	# Set instance count to match cleared tiles
	var tile_count := MiasmaManager.cleared_tiles.size()
	_multimesh_resource.instance_count = tile_count
	
	# Set transform for each cleared tile
	var instance_index := 0
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		# PIXEL-PERFECT ANCHOR: Get tile world ORIGIN (not center) - this is the grid anchor
		var tile_world_origin := CoordConverter.miasma_to_world_origin(grid_pos)
		
		# Calculate screen space origin
		var screen_origin := (tile_world_origin - camera_world_pos) + viewport_center
		
		# SNAP IT: Floor the origin to lock to pixel grid (not the center)
		var snapped_origin := screen_origin.floor()
		
		# Create 2D transform: position at snapped origin, no rotation, scale 1:1
		var transform := Transform2D.IDENTITY
		transform.origin = snapped_origin
		
		# Set the instance transform
		_multimesh_resource.set_instance_transform_2d(instance_index, transform)
		instance_index += 1
