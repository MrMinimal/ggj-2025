extends Node3D

func _ready() -> void:
	$CPUParticles3D.emitting = true

func _on_timer_timeout() -> void:
	self.queue_free()
