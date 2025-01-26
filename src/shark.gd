extends Node3D

var timer = 120
var ini_pos
var retract_pos = -4.5
var state = "out" #other state = "in"
var target = retract_pos
var lerp_val=0.2 #0.2 for jumping out, 0.1 for retracting
@export var timer_out = 120
@export var timer_in = 160

func _ready():
	ini_pos = $SharkBody.position.x

func _physics_process(delta):
	timer-=1
	
	if timer < 0:
		if state == "out":
			target = retract_pos
			lerp_val=0.05
			timer = timer_in
			state = "in"
			
		elif state == "in":
			target = ini_pos
			lerp_val=0.2
			timer = timer_out
			state = "out"
			
		
	$SharkBody.position.x=lerp($SharkBody.position.x,target,lerp_val)


func _on_area_3d_body_entered(body: Node3D):
	if not body.is_in_group("player"):
		return
	
	var player = body as Player
	player.take_damage(0.2)
	
	var instance = preload("res://effects/water_hand/scripts/water_splash.tscn").instantiate()
	self.add_child(instance)
