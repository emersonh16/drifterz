extends MultiMeshInstance2D

# FogPainter - Portal Rendering
# Reveals the ground texture underneath the fog by using aligned UV coordinates
# NO CAMERA MATH - All positions are absolute world coordinates

# WorldGrid tile size (isometric)
const WORLD_TILE_WIDTH: float = 64.0
const WORLD_TILE_HEIGHT: float = 32.0

# FogPainter stamp size
const STAMP_WIDTH: float = 16.0
const STAMP_HEIGHT: float = 8.0

var last_tile_count: int = 0
var ground_texture: Texture2D

func _ready() -> void:
	# VERIFY WORLD ORIGIN: Ensure FogPainter is at (0,0) in world space
	if global_position != Vector2.ZERO:
		push_warning("FogPainter: global_position is not (0,0). Current: " + str(global_position))
		# Reset to (0,0) to ensure correct world-space rendering
		global_position = Vector2.ZERO
	
	# ATTACHMENT: Ensure we have a MultiMesh resource
	if not multimesh:
		multimesh = MultiMesh.new()
	
	# INITIALIZATION: Configure MultiMesh resource
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	
	# Create and set the QuadMesh (16x8 size)
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(STAMP_WIDTH, STAMP_HEIGHT)
	multimesh.mesh = quad_mesh
	
	# Initialize instance count to 0 (will be rebuilt in _process)
	multimesh.instance_count = 0
	
	# Set texture filter to Nearest for pixel-perfect rendering
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Load the ground texture (meadow2.png)
	ground_texture = load("res://src/assets/sprites/meadow2.png") as Texture2D
	if not ground_texture:
		push_error("FogPainter: Failed to load meadow2.png texture")
		return
	
	# Create shader material for portal effect
	var shader_material := ShaderMaterial.new()
	var portal_shader := load("res://src/vfx/FogPainterPortal.gdshader") as Shader
	if portal_shader:
		shader_material.shader = portal_shader
		shader_material.set_shader_parameter("ground_texture", ground_texture)
		shader_material.set_shader_parameter("world_tile_width", WORLD_TILE_WIDTH)
		shader_material.set_shader_parameter("world_tile_height", WORLD_TILE_HEIGHT)
		shader_material.set_shader_parameter("stamp_width", STAMP_WIDTH)
		shader_material.set_shader_parameter("stamp_height", STAMP_HEIGHT)
		self.material = shader_material
	else:
		# Fallback: Use texture directly without shader
		self.texture = ground_texture
		push_warning("FogPainter: Portal shader not found, using direct texture (may not align perfectly)")
	
	self_modulate = Color.WHITE  # Full brightness to reveal texture

func _process(_delta: float) -> void:
	# PERFORMANCE: Only rebuild if cleared_tiles changed
	var current_tile_count := MiasmaManager.cleared_tiles.size()
	if current_tile_count != last_tile_count:
		last_tile_count = current_tile_count
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
	
	# Set transform and custom data for each cleared tile
	var instance_index := 0
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		# WORLD-SPACE TRUTH: Convert grid to world center
		# Formula: world_center = Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)
		# This places the CENTER of the 16x8 mesh into the CENTER of the grid cell
		var world_center := Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)
		
		# QUADRANT OFFSET: Calculate which quadrant of the 64x32 tile this stamp is in
		# 4 stamps fit in each tile (4x4 grid), so we use modulo 4
		# OffsetX = (grid_pos.x % 4) * 0.25
		# OffsetY = (grid_pos.y % 4) * 0.25
		# Handle negative modulo correctly
		var mod_x: int = grid_pos.x % 4
		var mod_y: int = grid_pos.y % 4
		if mod_x < 0:
			mod_x += 4
		if mod_y < 0:
			mod_y += 4
		
		# THE POSITION: Create transform with world center
		# NO CAMERA MATH - This is absolute world position
		var instance_transform := Transform2D(0, world_center)
		
		# Set the instance transform
		multimesh.set_instance_transform_2d(instance_index, instance_transform)
		
		# Note: Custom data is not used anymore - shader calculates quadrant from world position
		# This is because INSTANCE_CUSTOM is not available in canvas_item shaders
		
		instance_index += 1
