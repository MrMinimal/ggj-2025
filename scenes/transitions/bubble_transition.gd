extends Control

func _ready() -> void:
	$AnimationPlayer.play("fade_from_black")

func _on_timer_timeout() -> void:
	self.queue_free()
