extends Node3D
@onready var sprite3d = $AnimatedSprite3D

func _ready():
	sprite3d.play("causics")
