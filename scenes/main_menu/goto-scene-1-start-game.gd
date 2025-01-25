extends MarginContainer

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
