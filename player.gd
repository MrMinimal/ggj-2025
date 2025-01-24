extends Node3D

@export var speed = 5.0
@export var deadzone = 0.1
@export var sensitivity = 2.0

func _physics_process(delta):
	var acc = Input.get_accelerometer()
	var grav = Input.get_gravity()
	var mag = Input.get_magnetometer()
	var gyro = Input.get_gyroscope()
	
	
	var accel = Input.get_accelerometer()
	
	# Convert accelerometer to movement vector
	var movement = Vector3(accel.x, 0, -accel.y) * sensitivity
	print(acc,accel,grav,mag,gyro)
	
	# Apply deadzone
	if abs(movement.x) < deadzone:
		movement.x = 0
	if abs(movement.z) < deadzone:
		movement.z = 0
	
	# Normalize and apply speed
	if movement.length() > 1:
		movement = movement.normalized()
	
	# Move the node
	position += movement * speed * delta


var JavaScript = JavaScriptBridge
func _init():
	
	if !OS.has_feature('web'): pass
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
		}
		else {
			registerMotionListener()
		}
	""", true)

func get_accelerometer() -> Vector3:
	if !OS.has_feature('web'): return Input.get_accelerometer()
	
	var x = JavaScript.eval('acceleration.x')
	var y = JavaScript.eval('acceleration.y')
	var z = JavaScript.eval('acceleration.z')
	return Vector3(x, y, z)
