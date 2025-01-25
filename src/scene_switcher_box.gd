extends Node3D
@onready var area = $Area3D
var level_manager: LevelManager

func _ready():
	level_manager = get_node("/root/Root/LevelManager")
	assert(level_manager)
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	level_manager.load_next_level()
