extends Node

# One-time utility script to generate the 16x8 isometric diamond texture
# Run this once, then delete the script

func _ready() -> void:
	generate_diamond_texture()
	print("DIAMOND CREATED")

func generate_diamond_texture() -> void:
	# Create a new Image of size 16x8 with RGBA8 format
	var image := Image.create(16, 8, false, Image.FORMAT_RGBA8)
	
	# Fill with complete transparency (Alpha 0)
	image.fill(Color(0, 0, 0, 0))
	
	# Define diamond vertices: Top(8,0), Right(16,4), Bottom(8,8), Left(0,4)
	var diamond_vertices := PackedVector2Array([
		Vector2(8, 0),   # Top
		Vector2(16, 4),  # Right
		Vector2(8, 8),   # Bottom
		Vector2(0, 4)    # Left
	])
	
	# Iterate through all pixels and set to white if inside diamond
	for y in range(8):
		for x in range(16):
			var pixel_pos := Vector2(x, y)
			
			# Check if pixel is inside the diamond polygon
			if _point_in_polygon(pixel_pos, diamond_vertices):
				# Set pixel to solid white (Alpha 1.0)
				image.set_pixel(x, y, Color.WHITE)
	
	# Save the image to the target path
	var save_path := "res://src/vfx/miasma_stamp.png"
	var error := image.save_png(save_path)
	
	if error != OK:
		push_error("Failed to save diamond texture: " + str(error))
	else:
		print("Diamond texture saved to: " + save_path)

# Point-in-polygon test using ray casting algorithm
# Returns true if point is inside the polygon
func _point_in_polygon(point: Vector2, vertices: PackedVector2Array) -> bool:
	if vertices.size() < 3:
		return false
	
	var inside := false
	var j := vertices.size() - 1
	
	for i in range(vertices.size()):
		var vi := vertices[i]
		var vj := vertices[j]
		
		# Check if ray from point to right intersects edge
		if ((vi.y > point.y) != (vj.y > point.y)) and \
		   (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x):
			inside = !inside
		
		j = i
	
	return inside
