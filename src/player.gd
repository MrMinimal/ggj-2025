extends RigidBody3D
class_name Player

@export var player_size = 3.0
@export var speed = 20.0
@export var tilt_amount = 5.0
@export var scale_factor = 0.02
@export var bubble_pop_scene: PackedScene

@onready var camera = $Camera3D
@onready var body = $bubble
@onready var face_sad = $bubble/FaceSad
@onready var face_happy = $bubble/FaceHappy

var level_manager: LevelManager
var target_scale = Vector3.ONE
var previous_position = Vector3.ZERO
var current_velocity = Vector3.ZERO
var prev_target_position = Vector3.ZERO
var initial_scale = Vector3.ZERO
var health_factor = 1.0 # from 0.0 to 1.0
var isDead: bool = false # Do not trigger dead state stuff multiple times
var plastic_bag_debuff: PlasticBag = null

var iframes_timer = 0 #counts down the duration of iframes
var iframes_duration = 180 #duration of the iframes
var blink_timer = 2 #used to time the blinking, higher value, slower blink

func _ready() -> void:
	level_manager = get_node("/root/Root/LevelManager") as LevelManager
	lock_rotation = true
	previous_position = position

func _physics_process(delta: float) -> void:
	if self.isDead:
		return
		
	if position.y < -10:
		self.isDead = true
		level_manager.restart_level()
	
	# Handle movement in child classes
	_handle_movement(delta)
	
	# Update body scaling and effects
	_update_body_effects(delta)
	
	# Update iframes and blinking
	_update_iframes()

# Virtual method to be overridden by child classes
func _handle_movement(_delta: float) -> void:
	pass

func _update_body_effects(delta: float) -> void:
	# Calculate velocity
	current_velocity = (position - previous_position) / delta
	previous_position = position
	
	# Calculate scale based on X velocity
	var x_speed = current_velocity.length()
	var scale_multiplier_z = self.player_size * self.health_factor + (x_speed * scale_factor)
	var scale_multiplier_x = self.player_size * self.health_factor - (x_speed * scale_factor)
	target_scale = Vector3(scale_multiplier_x, self.player_size * self.health_factor, scale_multiplier_z)
	
	# Smoothly interpolate body scale
	body.scale = body.scale.lerp(target_scale, delta * 10.0)
	$CollisionShape3D.scale = body.scale
	
	var target_global = current_velocity + self.position
	var interpolated = lerp(self.prev_target_position, target_global, 0.1)
	if not body.global_position == target_global:
		body.look_at(interpolated, Vector3.UP)
	self.prev_target_position = interpolated
	
	# Keep Y rotation at 0
	rotation.y = 0
	
	# Tilt camera
	_update_camera_tilt(delta)

func _update_camera_tilt(delta: float) -> void:
	var movement = current_velocity.normalized()
	var target_rotation = Vector3(-90.0, 0, 0)  # Base top-down rotation
	target_rotation.x += movement.z * tilt_amount  # Tilt forward/backward slightly
	target_rotation.z = -movement.x * tilt_amount  # Tilt left/right slightly
	camera.rotation_degrees = camera.rotation_degrees.lerp(target_rotation, delta * 5.0)

func _update_iframes() -> void:
	if iframes_timer > 0:
		iframes_timer -= 1
		blink_timer -= 1
		if blink_timer <= 0:
			blink_timer = 2
			body.visible = !body.visible
	else:
		face_sad.visible = false
		face_happy.visible = true

func take_damage(damage: float) -> void:
	if damage > 0: #if it's damage, not healing
		face_sad.visible = true
		face_happy.visible = false
		if iframes_timer <= 0: #if no iframes
			self.health_factor -= damage #deal damage
			if self.health_factor > 0.5: #if damaged, but still alive
				iframes_timer = iframes_duration #set iframes
				$AudioHit.play() #play hit audio
	else: #if healing
		self.health_factor -= damage #apply health
		
	if self.health_factor <= 0.5 && !self.isDead:
		self.isDead = true
		$AudioDeath.play()
		body.visible = false
		var instance: Node3D = bubble_pop_scene.instantiate()
		instance.position = self.position
		self.get_parent().add_child(instance)

func _on_audio_death_finished() -> void:
	level_manager.restart_level()
	
func remove_debuff_plastic_bag() -> void:
	if not plastic_bag_debuff:
		return
	plastic_bag_debuff.queue_free()

func apply_debuff_plastic_bag(plastic_bag: PlasticBag) -> void:
	plastic_bag_debuff = plastic_bag
	plastic_bag.call_deferred("reparent", self)
