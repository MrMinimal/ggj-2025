extends Player
class_name PlayerMobile

@export var deadzone = 0.1
@export var sensitivity = 4.0

var JavaScript = JavaScriptBridge

func _init() -> void:
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

func _handle_movement(delta: float) -> void:
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
		var jerking = detect_jerk(movement)
		if jerking:
			remove_debuff_plastic_bag()
	
	if movement.length() > 1:
		movement = movement.normalized()
	
	if plastic_bag_debuff != null:
		movement = movement / 2
		
	# Apply movement
	position += movement * speed * delta

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
			return true
	
	# Update previous values for next calculation
	prev_accel = current_accel
	prev_time = current_time
	return false

func detect_keyboard_jerk(current_movement: Vector3) -> bool:
	if current_movement == Vector3.ZERO:
		return false
		
	var current_time = Time.get_ticks_msec() / 1000.0
	var dt = current_time - prev_time
	
	if dt > 0:
		# Scale keyboard movement to match accelerometer range
		var scaled_movement = current_movement * sensitivity * 10.0
		var jerk = (scaled_movement - prev_accel) / dt
		var jerk_magnitude = jerk.length()
		
		if jerk_magnitude > jerk_threshold:
			return true
	
	prev_accel = current_movement * sensitivity * 10.0
	prev_time = current_time
	return false
