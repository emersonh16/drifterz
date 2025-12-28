extends Node

const BeamModel = preload("res://src/systems/beam/BeamModel.gd")

var beam_model: BeamModel

func _ready() -> void:
	print("BeamController _ready() running")

	beam_model = BeamModel.new()

	var origin: Vector2 = get_parent().global_position
	var radius: float = 64.0

	var bubble: Dictionary = beam_model.get_bubble_descriptor(origin, radius)
	print("Bubble descriptor:", bubble)

func _process(_delta: float) -> void:
	var origin: Vector2 = get_parent().global_position
	var radius: float = 64.0

	var bubble: Dictionary = beam_model.get_bubble_descriptor(origin, radius)
	$BeamMiasmaEmitter.apply_bubble(bubble)
