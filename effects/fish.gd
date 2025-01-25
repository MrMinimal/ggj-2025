extends Node3D

func _ready() -> void:
	$MeshInstance3D.position.x = randf_range(2, 7)
