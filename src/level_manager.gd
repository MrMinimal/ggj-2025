extends Node
class_name LevelManager

@export var current_level_index: int = 0
@export var transition_scene: PackedScene 
var current_level: Node = null

func _ready() -> void:
	load_level(current_level_index)

func perform_level_load(scene: PackedScene, index: int) -> void:
	# Perfom ascension 
	if(index != 0):
		var player = get_node("/root/Root/LevelManager/Level/Player") as Player
		assert(player)
		var topCollisionShape3D = get_node("/root/Root/LevelManager/Level/CSGBox3D/StaticBody3D/CollisionShape3D2") as CollisionShape3D
		assert(topCollisionShape3D)
		await topCollisionShape3D.call_deferred("set_disabled", true)
		
		var push_force = 5000
		player.apply_central_force(Vector3.UP * push_force)
		
		await get_tree().create_timer(2.0).timeout
		if current_level:
			# We cannot have two scenes called Level
			# so we rename the old first
			current_level.name = "LevelUnload" 
			current_level.queue_free()
			
	
	current_level = scene.instantiate()
	add_child(current_level)
	current_level.name = "Level" # Must always be level to not break paths
	current_level_index = index
	
	var transition = transition_scene.instantiate()
	add_child(transition)

func load_level(index: int) -> void:
	if index < 0:
		push_error("Invalid level index: " + str(index))
		return
	
	if index == 3:
		var scene = load("res://scenes/credits/credits.tscn")
		await perform_level_load(scene, index)
		return
		
	var level_path = "res://scenes/level_%d/level_%d.tscn" % [index, index]
	var level_scene = load(level_path)
	
	if level_scene:
		await perform_level_load(level_scene, index)
	else:
		push_error("Failed to load level: " + level_path)

func load_next_level() -> void:
	load_level(current_level_index + 1)

func load_previous_level() -> void:
	load_level(current_level_index - 1)

func restart_level() -> void:
	load_level(current_level_index)
