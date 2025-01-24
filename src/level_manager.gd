extends Node

class_name LevelManager

var current_level_index: int = 0
var current_level: Node = null
var levels: Array[String] = [
	"res://scenes/level_0/level_0.tscn",
	"res://scenes/level_1/level_1.tscn",
	# Add more level paths here
]

func _ready() -> void:
	load_level(current_level_index)

func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("Invalid level index: " + str(index))
		return
	
	# Remove current level if it exists
	if current_level:
		current_level.queue_free()
	
	# Load and instance new level
	var level_scene = load(levels[index])
	if level_scene:
		current_level = level_scene.instantiate()
		add_child(current_level)
		current_level_index = index
	else:
		push_error("Failed to load level: " + levels[index])

func load_next_level() -> void:
	load_level(current_level_index + 1)

func load_previous_level() -> void:
	load_level(current_level_index - 1)

func restart_level() -> void:
	load_level(current_level_index)
