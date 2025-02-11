extends CanvasLayer

var blink_timer=0
var blink_dur=20
var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("pulsate")
	player = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player:
		if player.health_factor < 1:
			$Health.visible=false
		else:
			$Health.visible=true
		if player.health_factor < 0.8:
			$Health2.visible=false
			blink_timer-=1
			if blink_timer<=0:
				$Health3.visible = not $Health3.visible
				blink_timer=blink_dur
		else:
			$Health2.visible=true
			$Health3.visible=true
			blink_timer=blink_dur
