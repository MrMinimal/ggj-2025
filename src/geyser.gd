extends Node3D

@export var push_force: float = 60.0
@export var field_radius: float = 5.0
var isPlayerInAra = false;
var body

func _on_area_3d_body_entered(body_entered: Node3D) -> void:
	if body_entered.is_in_group("player"):
		self.body = body_entered
		isPlayerInAra = true

func _physics_process(delta: float) -> void:
	if !isPlayerInAra:
		return
		
	var direction = (body.global_position - global_position).normalized()
	print(direction * push_force)
	body.apply_central_force(direction * push_force)
	
func _on_area_3d_body_exited(body_exited: Node3D) -> void:
	if body_exited.is_in_group("player"):
		self.body = null
		isPlayerInAra = false
