@tool
extends MeshInstance3D

@export var grid_size: int = 16:   # Размер сетки (например, 20x20)
	set(val): grid_size = val; queue_redraw_grid()
@export var cell_size: float = 0.0625: # Размер одной ячейки в метрах
	set(val): cell_size = val; queue_redraw_grid()
@export var color: Color = Color(0.835, 0.835, 0.835, 0.6)

func _ready() -> void:
	queue_redraw_grid()

func queue_redraw_grid() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES) # Рисуем линиями
	
	var half_size = (grid_size * cell_size) / 2.0
	
	# Создаем материал, чтобы сетка светилась или имела нужный цвет
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED # Без теней
	mat.albedo_color = color # Серый цвет с прозрачностью
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	st.set_material(mat)
	
	# Линии вдоль оси X и Z
	for i in range(grid_size + 1):
		var pos = -half_size + (i * cell_size)
		
		# Линии параллельные оси Z
		st.add_vertex(Vector3(pos, 0, -half_size))
		st.add_vertex(Vector3(pos, 0, half_size))
		
		# Линии параллельные оси X
		st.add_vertex(Vector3(-half_size, 0, pos))
		st.add_vertex(Vector3(half_size, 0, pos))
		
	mesh = st.commit()
