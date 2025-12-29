extends MultiMeshInstance2D

func _ready():
	# Bolt the node to the world origin
	global_position = Vector2.ZERO
	# Load our existing 16x8 diamond stamp
	texture = load("res://src/vfx/miasma_stamp.png")
	texture_filter = TEXTURE_FILTER_NEAREST
	
	# Prepare the MultiMesh
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.mesh = QuadMesh.new()
	multimesh.mesh.size = Vector2(16, 8)

func _process(_delta):
	var tiles = MiasmaManager.cleared_tiles
	if multimesh.instance_count != tiles.size():
		multimesh.instance_count = tiles.size()
	
	var i = 0
	for grid_pos in tiles.keys():
		# PURE WORLD SPACE: Grid * TileSize. No camera math. 
		var world_origin = Vector2(grid_pos.x * 16.0, grid_pos.y * 8.0)
		multimesh.set_instance_transform_2d(i, Transform2D(0, world_origin))
		i += 1
