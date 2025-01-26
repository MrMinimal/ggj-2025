extends Node3D

@onready var animation_tree : AnimationTree = %AnimationTree

@export var splash_scene: PackedScene

signal raised
signal slaped

func _ready() -> void:
	$AnimationPlayer.play("Slap")

func play_default():
	animation_tree.set("parameters/Transition/transition_request", "default")

func spawn_splash():
	var instance = self.splash_scene.instantiate()
	get_parent().add_child(instance)
	instance.global_position = $SplashSpawnLocation.global_position
