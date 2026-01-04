extends Node2D

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready():
	# PlanetArea의 input_event 시그널 연결
	var planet_area = $PlanetArea
	if planet_area:
		planet_area.input_pickable = true
		planet_area.input_event.connect(_on_planet_area_input_event)
	
	# 항상 애니메이션이 실행되게 처리
	var anim_player = $Planet
	if anim_player and not anim_player.is_playing():
		anim_player.play("default") # "default"는 애니메이션 이름에 맞게 조정

func _on_planet_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 드래그 시작
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
				get_viewport().set_input_as_handled()
			else:
				# 드래그 종료
				is_dragging = false
				get_viewport().set_input_as_handled()

func _process(_delta):
	if is_dragging:
		# 드래그 중이면 마우스 위치로 이동
		global_position = get_global_mouse_position() + drag_offset
	
	# 항상 애니메이션이 실행되게 재확인(애니메이션이 멈췄을 때 재시작)
	var anim_player = $Planet
	if anim_player and not anim_player.is_playing():
		anim_player.play("default") # "default"는 애니메이션 이름에 맞게 조정

func _input(event):
	if is_dragging:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				# 마우스 버튼을 놓으면 드래그 종료
				is_dragging = false
