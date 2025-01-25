extends Node3D
class_name PlasticBag

func _ready():
	$AnimationPlayer.play("plastic_bag_fly")
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var player = body as Player
	player.apply_debuff_plastic_bag(self)
