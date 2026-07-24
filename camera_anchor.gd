extends Node3D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		rotation.x += -event.relative.y / 400
		rotation.y += -event.relative.x / 400
	
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			$Camera.position.z = clampf(
				$Camera.position.z + 0.5 * position.z, 2, 8
			)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			$Camera.position.z = clampf(
				$Camera.position.z - 0.5 * position.z, 2, 8
			)
