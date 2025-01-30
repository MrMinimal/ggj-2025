extends Node3D

@export var spawn_position := Vector3.ZERO
@export var force_mouse_controls := false  # For testing

# Debug visualization
var debug_mesh: MeshInstance3D
var debug_material: StandardMaterial3D

func _ready() -> void:
	if not Engine.is_editor_hint():
		var player_scene: PackedScene
		
		# Use mouse controls if forced or if we're on desktop platforms
		if force_mouse_controls or is_desktop_platform():
			player_scene = preload("res://src/player_mouse.tscn")
		else:
			player_scene = preload("res://src/player_mobile.tscn")  # Mobile version
			
		var player = player_scene.instantiate()
		player.position = spawn_position
		add_child(player)
	else:
		_setup_debug_visuals()

func is_desktop_platform() -> bool:
	# Check for web platform first
	if OS.has_feature('web'):
		# Web platform has specific tags for the host system
		return OS.has_feature('web_windows') or \
			   OS.has_feature('web_linuxbsd') or \
			   OS.has_feature('web_macos')
	
	# Check for native desktop platforms
	return OS.has_feature('windows') or \
		   OS.has_feature('linuxbsd') or \
		   OS.has_feature('macos')

func _setup_debug_visuals() -> void:
	if debug_mesh != null:
		return
		
	debug_material = StandardMaterial3D.new()
	debug_material.no_depth_test = true
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_material.albedo_color = Color(0, 1, 0, 0.5)  # Semi-transparent green
	
	debug_mesh = MeshInstance3D.new()
	add_child(debug_mesh)
	_update_debug_mesh()

func _update_debug_mesh() -> void:
	if not Engine.is_editor_hint() or not debug_mesh:
		return
		
	var immediate_mesh := ImmediateMesh.new()
	debug_mesh.mesh = immediate_mesh
	debug_mesh.material_override = debug_material
	debug_mesh.position = spawn_position
	
	# Draw spawn point marker
	var size := 1.0  # Size of the spawn point marker
	
	# Draw vertical arrow
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(Vector3(0, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(0, size * 2, 0))
	immediate_mesh.surface_end()
	
	# Draw arrow head
	var arrow_size := size * 0.3
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	immediate_mesh.surface_add_vertex(Vector3(0, size * 2, 0))  # Tip
	immediate_mesh.surface_add_vertex(Vector3(arrow_size, size * 1.7, arrow_size))
	immediate_mesh.surface_add_vertex(Vector3(-arrow_size, size * 1.7, arrow_size))
	
	immediate_mesh.surface_add_vertex(Vector3(0, size * 2, 0))  # Tip
	immediate_mesh.surface_add_vertex(Vector3(arrow_size, size * 1.7, -arrow_size))
	immediate_mesh.surface_add_vertex(Vector3(-arrow_size, size * 1.7, -arrow_size))
	
	immediate_mesh.surface_add_vertex(Vector3(0, size * 2, 0))  # Tip
	immediate_mesh.surface_add_vertex(Vector3(arrow_size, size * 1.7, arrow_size))
	immediate_mesh.surface_add_vertex(Vector3(arrow_size, size * 1.7, -arrow_size))
	
	immediate_mesh.surface_add_vertex(Vector3(0, size * 2, 0))  # Tip
	immediate_mesh.surface_add_vertex(Vector3(-arrow_size, size * 1.7, arrow_size))
	immediate_mesh.surface_add_vertex(Vector3(-arrow_size, size * 1.7, -arrow_size))
	immediate_mesh.surface_end()
	
	# Draw ground circle
	var segments := 32
	var prev_point := Vector3.ZERO
	for i in range(segments + 1):
		var angle := (i / float(segments)) * TAU
		var point := Vector3(cos(angle) * size, 0, sin(angle) * size)
		if i > 0:
			immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			immediate_mesh.surface_add_vertex(prev_point)
			immediate_mesh.surface_add_vertex(point)
			immediate_mesh.surface_end()
		prev_point = point

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_debug_mesh()
