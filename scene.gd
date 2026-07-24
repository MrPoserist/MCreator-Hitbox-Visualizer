extends Node3D

@onready var hitbox_anchor: StaticBody3D = $HitboxAnchor

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

func _on_size_value_changed(_value: float) -> void:
	hitbox_anchor.scale = Vector3(
		max_x.value - min_x.value,
		max_y.value - min_y.value,
		max_z.value - min_z.value
	)
	hitbox_anchor.position = Vector3(min_x.value, min_y.value, min_z.value)
