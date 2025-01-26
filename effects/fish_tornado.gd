extends Node3D

@export var fish_count = 2
@export var horizontal_offset = 2
@export var fish_scene: PackedScene

func _ready() -> void:
	for i in fish_count:
		var instance = self.fish_scene.instantiate()
		self.add_child(instance)
		instance.rotate(Vector3.UP, randf_range(0, 360))		
		

func _process(delta: float) -> void:
	self.rotate_y(delta * 2)
