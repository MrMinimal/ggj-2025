extends Node3D

func _ready():
	$AnimationPlayer.play("plastic_bag_fly")
	
	
func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		pass
	pass # Replace with function body.
