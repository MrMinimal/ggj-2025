extends Node3D

@export var push_force: float = 30.0
@export var field_radius: float = 5.0
var isPlayerInAra = false;
var body

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		self.body = body
		isPlayerInAra = true

func _physics_process(delta: float) -> void:
	if !isPlayerInAra:
		return
		
	var direction = (body.global_position - global_position).normalized()
	print(direction * push_force)
	body.apply_central_force(direction * push_force)
	
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		self.body = null
		isPlayerInAra = false
