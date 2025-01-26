extends Node3D

var init_scale

func _ready():
	self.init_scale = self.scale
	$AnimationPlayer.play("idel_animation_sea_urchin")


func _physics_process(delta: float) -> void:
	self.scale = lerp(self.scale, self.init_scale, 0.02)


func _on_area_3d_body_entered(body):
	if not body.is_in_group("player"):
		return
	
	var player = body as Player
	player.take_damage(0.2)
	self.scale = self.scale * 0.7
