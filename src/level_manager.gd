extends Node
class_name LevelManager

@export var current_level_index: int = 0
@export var transition_scene: PackedScene 
var current_level: Node = null

func _ready() -> void:
	load_level(current_level_index)

func load_level(index: int) -> void:
	if index < 0:
		push_error("Invalid level index: " + str(index))
		return
	
	if current_level:
		current_level.queue_free()
	
	var level_path = "res://scenes/level_%d/level_%d.tscn" % [index, index]
	var level_scene = load(level_path)
	if level_scene:
		current_level = level_scene.instantiate()
		add_child(current_level)
		current_level_index = index
		
		var transition = self.transition_scene.instantiate()
		add_child(transition)
	else:
		push_error("Failed to load level: " + level_path)

func load_next_level() -> void:
	load_level(current_level_index + 1)

func load_previous_level() -> void:
	load_level(current_level_index - 1)

func restart_level() -> void:
	load_level(current_level_index)
