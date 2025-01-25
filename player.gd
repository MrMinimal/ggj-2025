extends RigidBody3D
class_name Player

@export var player_size = 3.0
@export var speed = 20.0
@export var deadzone = 0.1 
@export var sensitivity = 2.0
@export var tilt_amount = 5.0
@export var scale_factor = 0.02
@onready var camera = $Camera3D
@onready var body = $bubble
var JavaScript = JavaScriptBridge
var target_scale = Vector3.ONE
var previous_position = Vector3.ZERO
var current_velocity = Vector3.ZERO
var prev_target_position = Vector3.ZERO
var initial_scale = Vector3.ZERO
var health_factor = 1.0 # wafrom 0.0 to 1.0

var plastic_bag_debuff: PlasticBag = null


func _ready():
	lock_rotation = true
	previous_position = position
	
func _init():
	if !OS.has_feature('web'):
		return
		
	JavaScript.eval("""
	var acceleration = { x: 0, y: 0, z: 0 }
	
	function registerMotionListener() {
		window.ondevicemotion = function(event) {
			if (event.acceleration.x === null) return
			acceleration.x = event.acceleration.x
			acceleration.y = event.acceleration.y
			acceleration.z = event.acceleration.z
		}
	}
	
	if (typeof DeviceOrientationEvent.requestPermission === 'function') {
		DeviceOrientationEvent.requestPermission().then(function(state) {
			if (state === 'granted') registerMotionListener()
		})
	} else {
		registerMotionListener()
	}
	""", true)

func get_accelerometer() -> Vector3:
	if !OS.has_feature('web'):
		return Input.get_accelerometer()
	var x = JavaScript.eval('acceleration.x')
	var y = JavaScript.eval('acceleration.y') 
	var z = JavaScript.eval('acceleration.z')
	return Vector3(x, y, z)

func _physics_process(delta):
	var movement = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward") or Input.is_action_pressed("ui_up"):
		movement.z -= 1
	if Input.is_action_pressed("move_backward") or Input.is_action_pressed("ui_down"):
		movement.z += 1
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		movement.x += 1
		
	if movement == Vector3.ZERO:
		var accel = get_accelerometer()
		movement = Vector3(accel.x, 0, -accel.y) * sensitivity
		
		# Only apply movement if tilt is significant
		var tilt_threshold = 0.5 # Adjust this value to require more tilt
		if abs(accel.x) < tilt_threshold and abs(accel.y) < tilt_threshold:
			movement = Vector3.ZERO
			
		if abs(movement.x) < deadzone:
			movement.x = 0
		if abs(movement.z) < deadzone:
			movement.z = 0
			
	if plastic_bag_debuff != null:
		var jerkig = detect_jerk(movement)
		if jerkig:
			remove_debuff_plastic_bag()
	
	if movement.length() > 1:
		movement = movement.normalized()
	
	if plastic_bag_debuff != null:
		movement = movement /2
		
		
	# Apply movement
	position += movement * speed * delta
	
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
	
	var target_global = current_velocity + self.position
	var interpolated = lerp(self.prev_target_position, target_global, 0.1)
	if not body.global_position == target_global:
		body.look_at(interpolated)
	self.prev_target_position = interpolated
	
	# Keep Y rotation at 0
	rotation.y = 0
	
	# Tilt camera slightly based on movement while maintaining top-down view
	var target_rotation = Vector3(-90.0, 0, 0)  # Base top-down rotation
	target_rotation.x += movement.z * tilt_amount  # Tilt forward/backward slightly
	target_rotation.z = -movement.x * tilt_amount  # Tilt left/right slightly
	camera.rotation_degrees = camera.rotation_degrees.lerp(target_rotation, delta * 5.0)

func take_damage(damage):
	self.health_factor -= damage
	if damage>0 && self.health_factor>0.5:
		$AudioHit.play()
		
	if self.health_factor <= 0.5:
		$AudioDeath.play()
		$bubble.visible=false
		#var level_manager: LevelManager = get_node("/root/Root/LevelManager") as LevelManager
		#level_manager.load_level(0)
	


func _on_audio_death_finished() -> void:
	var level_manager: LevelManager = get_node("/root/Root/LevelManager") as LevelManager
	level_manager.load_level(0)
func remove_debuff_plastic_bag():
	if not plastic_bag_debuff:
		return
	plastic_bag_debuff.queue_free()

func apply_debuff_plastic_bag(plastic_bag: PlasticBag):
	plastic_bag_debuff = plastic_bag
	plastic_bag.reparent(self)


var prev_accel := Vector3.ZERO
var prev_time := 0.0
var jerk_threshold := 600.0  # Adjust based on your needs

func detect_jerk(current_accel: Vector3) -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	var dt = current_time - prev_time
	
	if dt > 0:
		# Calculate jerk as rate of change of acceleration
		var jerk = (current_accel - prev_accel) / dt
		var jerk_magnitude = jerk.length()
		
		if jerk_magnitude > jerk_threshold:
			print_debug("Jerk detected! Magnitude: ", jerk_magnitude)
			print_debug("Current acceleration: ", current_accel)
			print_debug("Previous acceleration: ", prev_accel)
			print_debug("Time delta: ", dt)
			return true
	
	# Update previous values for next calculation
	prev_accel = current_accel
	prev_time = current_time
	return false
