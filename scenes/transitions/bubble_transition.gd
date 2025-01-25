extends Control

func _on_timer_timeout() -> void:
	self.queue_free()
