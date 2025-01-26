extends AnimationPlayer
var level_manager: LevelManager

func _ready():
	level_manager = get_node("/root/Root/LevelManager")
	play("end")
	assert(level_manager)

func load_credits():
	level_manager.load_next_level()
