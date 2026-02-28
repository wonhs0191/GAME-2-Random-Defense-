extends Node2D

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# ready에서 Area2D의 input_event 시그널을 연결
func _ready():
	var area_2d = $Area2D
	if area_2d:
		area_2d.input_event.connect(_on_area_2d_input_event)
		area_2d.input_pickable = true

# 드래그 중 위치 이동
func _process(delta):
	if is_dragging:
		# 마우스를 따라다니게 만듦 (보정값 적용)
		global_position = get_global_mouse_position() + drag_offset

# 3. 드롭(내려놓기) 로직
func _drop_unit():
	is_dragging = false

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 마우스를 눌렀을 때: 드래그 시작
			is_dragging = true
			# 마우스 커서 중심점과 유닛 중심점의 차이를 보정 (자연스러운 드래그를 위해)
			drag_offset = global_position - get_global_mouse_position()
			get_viewport().set_input_as_handled()
		else:
			# 마우스를 뗐을 때: 드래그 종료
			_drop_unit()