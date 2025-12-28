extends Node2D

@onready var world_grid: TileMapLayer = $WorldGrid

func _ready() -> void:
	# This loops through a 20x20 area and places your ground tile
	for x in range(80):
		for y in range(80):
			# Parameters: (Grid Coordinates, Source ID, Atlas Coordinates)
			world_grid.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
