extends Player
class_name PlayerMouse

# Spring constants for rubber-like behavior
@export var spring_length := 100.0  # Maximum distance before movement
@export var spring_stiffness := 5.0  # How strong the spring pulls
@export var spring_damping := 2.0    # How quickly oscillations settle
@export var max_force := 500.0       # Maximum force applied

# Drawing helpers
var debug_draw: MeshInstance3D
var debug_material: StandardMaterial3D

# Mouse interaction variables
var is_dragging := false
var mouse_start := Vector2.ZERO
var current_mouse := Vector2.ZERO
var drag_force := Vector3.ZERO

func _ready() -> void:
	super._ready()
	# Make sure we process input
	set_process_input(true)
	
	if Engine.is_editor_hint():
		setup_debug_draw()

func setup_debug_draw() -> void:
	debug_material = StandardMaterial3D.new()
	debug_material.no_depth_test = true
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_material.albedo_color = Color(0, 0, 1, 0.5)  # Blue with transparency
	
	debug_draw = MeshInstance3D.new()
	add_child(debug_draw)
	update_debug_mesh()

func _handle_movement(_delta: float) -> void:
	if is_dragging:
		# Get current camera
		var camera := get_viewport().get_camera_3d()
		if not camera:
			return
			
		# Project mouse positions to world space on a plane at player's height
		var plane := Plane(Vector3.UP, position.y)
		# Get ray for start position
		var from_start: Vector3 = camera.project_ray_origin(mouse_start)
		var dir_start: Vector3 = camera.project_ray_normal(mouse_start)
		# Get ray for current position
		var from_current: Vector3 = camera.project_ray_origin(current_mouse)
		var dir_current: Vector3 = camera.project_ray_normal(current_mouse)
		
		var start_pos: Vector3 = plane.intersects_ray(from_start, dir_start)
		var current_pos: Vector3 = plane.intersects_ray(from_current, dir_current)
		
		if start_pos and current_pos:
			# Calculate spring force
			var displacement: Vector3 = current_pos - start_pos
			var distance: float = displacement.length()
			
			if distance > 0:
				var direction: Vector3 = displacement.normalized()
				var spring_force: Vector3 = direction * min(distance * spring_stiffness, max_force)
				
				# Apply damping based on current velocity
				var damping: Vector3 = -linear_velocity * spring_damping
				drag_force = spring_force + damping
				
				# Apply force
				apply_central_force(drag_force)
				
				if Engine.is_editor_hint():
					update_debug_mesh()
					
				# Check for plastic bag jerk
				if plastic_bag_debuff != null and is_jerk_motion(displacement):
					remove_debuff_plastic_bag()

func update_debug_mesh() -> void:
	if not Engine.is_editor_hint() or not debug_draw:
		return
		
	var immediate_mesh := ImmediateMesh.new()
	debug_draw.mesh = immediate_mesh
	debug_draw.material_override = debug_material
	
	# Draw circle
	var segments := 32
	var prev_point := Vector3.ZERO
	for i in range(segments + 1):
		var angle := (i / float(segments)) * TAU
		var point := Vector3(cos(angle) * spring_length, 0, sin(angle) * spring_length)
		if i > 0:
			immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			immediate_mesh.surface_add_vertex(prev_point)
			immediate_mesh.surface_add_vertex(point)
			immediate_mesh.surface_end()
		prev_point = point

	# Draw force direction if dragging
	if is_dragging and drag_force != Vector3.ZERO:
		var force_dir := drag_force.normalized()
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		immediate_mesh.surface_add_vertex(Vector3.ZERO)
		immediate_mesh.surface_add_vertex(force_dir * spring_length)
		immediate_mesh.surface_end()
		
		# Arrow head
		var tip := force_dir * spring_length
		var right := (force_dir.rotated(Vector3.UP, PI * 0.75) * spring_length * 0.1)
		var left := (force_dir.rotated(Vector3.UP, -PI * 0.75) * spring_length * 0.1)
		
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		immediate_mesh.surface_add_vertex(tip)
		immediate_mesh.surface_add_vertex(tip + right)
		immediate_mesh.surface_end()
		
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		immediate_mesh.surface_add_vertex(tip)
		immediate_mesh.surface_add_vertex(tip + left)
		immediate_mesh.surface_end()

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Left mouse button: ", "pressed" if event.pressed else "released")
			is_dragging = event.pressed
			if is_dragging:
				mouse_start = event.position
				current_mouse = mouse_start
			else:
				drag_force = Vector3.ZERO
			if Engine.is_editor_hint():
				update_debug_mesh()
				
	elif event is InputEventMouseMotion and is_dragging:
		current_mouse = event.position
		if Engine.is_editor_hint():
			update_debug_mesh()

# Check if the motion is jerky enough to break free from plastic bag
func is_jerk_motion(displacement: Vector3) -> bool:
	var jerk_threshold := spring_length * 0.5  # Adjust this value to tune sensitivity
	return displacement.length() > jerk_threshold and drag_force.length() > max_force * 0.8
