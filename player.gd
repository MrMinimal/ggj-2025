extends RigidBody3D
class_name Player

@export var player_size = 3.0
@export var speed = 20.0
@export var deadzone = 0.1 
@export var sensitivity = 2.0
@export var tilt_amount = 5.0
@export var scale_factor = 0.02
@export var accel_curve: Curve 
@export var bubble_pop_scene: PackedScene
@onready var camera = $Camera3D
@onready var body = $bubble
@onready var face_sad = $bubble/FaceSad
@onready var face_happy = $bubble/FaceHappy
var JavaScript = JavaScriptBridge
var level_manager: LevelManager
var target_scale = Vector3.ONE
var previous_position = Vector3.ZERO
var current_velocity = Vector3.ZERO
var prev_target_position = Vector3.ZERO
var initial_scale = Vector3.ZERO
var health_factor = 1.0 # wafrom 0.0 to 1.0
var isDead: bool = false # Do not trigger dead state stuff multiple times
var plastic_bag_debuff: PlasticBag = null

var iframes_timer = 0 #counts down the duration of iframes
var iframes_duration = 180 #duration of the iframes
var blink_timer = 2 #used to time the blinking, higher value, slower blink


func _ready():
	level_manager = get_node("/root/Root/LevelManager") as LevelManager
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
	if self.isDead:
		return
		
	if position.y < - 10:
		self.isDead = true
		level_manager.restart_level()	
	
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
		
		# First normalize the raw accelerometer input if it's too large
		var normalized_accel = Vector2(accel.x, accel.y)
		if normalized_accel.length() > 1:
			normalized_accel = normalized_accel.normalized()
			
		# Calculate base movement before curve application
		movement = Vector3(normalized_accel.x, 0, -normalized_accel.y)
		
		# Apply deadzone
		if abs(movement.x) < deadzone:
			movement.x = 0
		if abs(movement.z) < deadzone:
			movement.z = 0
			
		# Calculate magnitude for curve
		var tilt_magnitude = movement.length()
		
		# Apply the acceleration curve
		if accel_curve and tilt_magnitude > 0:
			var curve_multiplier = accel_curve.sample(tilt_magnitude)
			movement *= curve_multiplier * sensitivity
		else:
			movement *= sensitivity
			
	if plastic_bag_debuff != null:
		var jerking = detect_jerk(movement)
		if jerking:
			remove_debuff_plastic_bag()
	
	if plastic_bag_debuff != null:
		movement = movement / 2
	
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
	$CollisionShape3D.scale = body.scale
	
	var target_global = current_velocity + self.position
	var interpolated = lerp(self.prev_target_position, target_global, 0.1)
	if not body.global_position == target_global:
		body.look_at(interpolated, Vector3.UP)
	self.prev_target_position = interpolated
	
	# Keep Y rotation at 0
	rotation.y = 0
	
	# Tilt camera slightly based on movement while maintaining top-down view
	var target_rotation = Vector3(-90.0, 0, 0)  # Base top-down rotation
	target_rotation.x += movement.z * tilt_amount  # Tilt forward/backward slightly
	target_rotation.z = -movement.x * tilt_amount  # Tilt left/right slightly
	camera.rotation_degrees = camera.rotation_degrees.lerp(target_rotation, delta * 5.0)
	
	#damage blinking
	if iframes_timer>0:
		iframes_timer-=1
		blink_timer-=1
		if blink_timer<=0:
			blink_timer=2
			if $bubble.visible==true:
				$bubble.visible=false
			else:
				$bubble.visible=true
	else:
		face_sad.visible = false
		face_happy.visible = true

func take_damage(damage):
	if damage>0: #if it's damage, not healing
		face_sad.visible = true
		face_happy.visible = false
		if iframes_timer<=0: #if no iframes
			self.health_factor -= damage #deal damage
			if self.health_factor>0.5: #if damaged, but still alive
				iframes_timer = iframes_duration #set iframes
				$AudioHit.play() #play hit audio
	else: #if healing
		self.health_factor -= damage #apply health
		
	if self.health_factor <= 0.5 && !self.isDead:
		self.isDead = true
		$AudioDeath.play()
		$bubble.visible = false
		var instance: Node3D = bubble_pop_scene.instantiate()
		instance.position = self.position
		self.get_parent().add_child(instance)
		

func _on_audio_death_finished() -> void:
	level_manager.restart_level()
	
func remove_debuff_plastic_bag():
	if not plastic_bag_debuff:
		return
	plastic_bag_debuff.queue_free()

func apply_debuff_plastic_bag(plastic_bag: PlasticBag):
	plastic_bag_debuff = plastic_bag
	plastic_bag.call_deferred("reparent",self)


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
