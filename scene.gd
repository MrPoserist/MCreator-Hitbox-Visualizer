extends Node3D

@onready var hitbox_anchor: StaticBody3D = $HitboxAnchor
@onready var model_root: Node3D = $ModelRoot

@onready var min_x: SpinBox = $UI/HBoxContainer/MinValue/X
@onready var min_y: SpinBox = $UI/HBoxContainer/MinValue/Y
@onready var min_z: SpinBox = $UI/HBoxContainer/MinValue/Z
@onready var max_x: SpinBox = $UI/HBoxContainer/MaxValue/X
@onready var max_y: SpinBox = $UI/HBoxContainer/MaxValue/Y
@onready var max_z: SpinBox = $UI/HBoxContainer/MaxValue/Z

var show_debug_collisions_hint: bool:
	set(visible):
		print("Set show_debug_collisions_hint: ", visible)
		var tree: SceneTree = get_tree()
		# https://github.com/godotengine/godot-proposals/issues/2072
		tree.debug_collisions_hint = visible
		
		# Traverse tree to call toggle collision visibility
		var node_stack: Array[Node] = [tree.get_root()]
		while not node_stack.is_empty():
			var node: Node = node_stack.pop_back()
			if is_instance_valid(node):
				if   node is CollisionShape2D \
					or node is CollisionPolygon2D \
					or node is CollisionObject2D:
					# queue_redraw on instances of
					node.queue_redraw()
				elif node is TileMap:
					# use visibility mode to force redraw
					node.collision_visibility_mode = TileMap.VISIBILITY_MODE_FORCE_HIDE
					node.collision_visibility_mode = TileMap.VISIBILITY_MODE_DEFAULT
				elif node is RayCast3D \
					or node is CollisionShape3D \
					or node is CollisionPolygon3D \
					or node is CollisionObject3D \
					or node is GPUParticlesCollision3D \
					or node is GPUParticlesCollisionBox3D \
					or node is GPUParticlesCollisionHeightField3D \
					or node is GPUParticlesCollisionSDF3D \
					or node is GPUParticlesCollisionSphere3D:
					# remove and re-add the node to the tree to force a redraw
					# https://github.com/godotengine/godot/blob/26b1fd0d842fa3c2f090ead47e8ea7cd2d6515e1/scene/3d/collision_object_3d.cpp#L39
					var parent: Node = node.get_parent()
					if parent:
						parent.remove_child(node)
						parent.add_child(node)
				node_stack.append_array(node.get_children())
	get:
		return get_tree().debug_collisions_hint

func _ready() -> void:
	show_debug_collisions_hint = true
	get_window().files_dropped.connect(_on_files_dropped)

func _on_size_value_changed(_value: float) -> void:
	hitbox_anchor.scale = Vector3(
		max_x.value - min_x.value,
		max_y.value - min_y.value,
		max_z.value - min_z.value
	)
	hitbox_anchor.position = Vector3(min_x.value, min_y.value, min_z.value)
	min_x.max_value = max_x.value - min_x.step
	min_y.max_value = max_y.value - min_y.step
	min_z.max_value = max_z.value - min_z.step
	max_x.min_value = min_x.value + max_x.step
	max_y.min_value = min_y.value + max_y.step
	max_z.min_value = min_z.value + max_z.step

func _on_files_dropped(files: PackedStringArray):
	if files.is_empty(): return
	for file_path in files:
		var ext: String = file_path.get_extension().to_lower()
		if ext != "json": return
		
	load_model(files[0])
	hitbox_anchor.scale = Vector3(1,1,1)
	hitbox_anchor.position = Vector3(0,0,0)
	min_x.value = 0
	min_y.value = 0
	min_z.value = 0
	max_x.value = 1
	max_y.value = 1
	max_z.value = 1

func load_model(path: String):
	for child in model_root.get_children():
		child.queue_free()
	
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("Ошибка чтения JSON")
		return
	
	var data: Dictionary = json.data
	if !data.has("elements"):
		push_error("В модели нет elements")
		return
	
	for element in data["elements"]:
		create_cube(element)

func create_cube(element: Dictionary):
	var from := Vector3(
		element["from"][0],
		element["from"][1],
		element["from"][2]
	) / 16.0
	
	var to := Vector3(
		element["to"][0],
		element["to"][1],
		element["to"][2]
	) / 16.0
	
	var size := to - from
	var center := (from + to) * 0.5
	var mesh := BoxMesh.new()
	mesh.size = size
	
	var cube := MeshInstance3D.new()
	cube.mesh = mesh
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(randf_range(0.4, 0.7), randf_range(0.4, 0.7), randf_range(0.4, 0.7))
	cube.material_override = material
	
	if element.has("rotation"):
		var rot = element["rotation"]
		var origin := Vector3(
			rot["origin"][0],
			rot["origin"][1],
			rot["origin"][2]
		) / 16.0
		
		var pivot := Node3D.new()
		pivot.position = origin
		cube.position = center - origin
		
		var angle = deg_to_rad(float(rot["angle"]))
		match rot["axis"]:
			"x":
				pivot.rotate_x(angle)
			"y":
				pivot.rotate_y(angle)
			"z":
				pivot.rotate_z(angle)
		pivot.add_child(cube)
		model_root.add_child(pivot)
	else:
		cube.position = center
		model_root.add_child(cube)
