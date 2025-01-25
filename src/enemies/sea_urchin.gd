extends Node3D
func _ready():
	$AnimationPlayer.play("idel_animation_sea_urchin")


func _on_area_3d_body_entered(body):
	if not body.is_in_group("player"):
		return
	
	var player = body as Player
	player.take_damage(0.2)
