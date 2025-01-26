extends Node3D
@onready var splash_player = %SplashPlayer

func _ready() -> void:
	$SplashPlayer.play("splash")

func splash():
	splash_player.play("splash")


func _on_timer_timeout() -> void:
	self.queue_free()
