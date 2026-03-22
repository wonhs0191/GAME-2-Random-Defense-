extends Node2D
class_name GridManager

@export var tile_size: Vector2i = Vector2i(64, 64) # 기본 그리드 칸 크기 (필요시 인스펙터에서 수정)
@export var grid_size: Vector2i = Vector2i(20, 15) # 화면에 그릴 그리드의 가로세로 칸 수
@export var line_color: Color = Color(1, 1, 1, 0.2) # 그리드 선 색상 (반투명 흰색)
@export var line_thickness: float = 1.0 # 그리드 선 두께

# 디버깅 및 사용자 확인을 위해 기본적으로는 보이게 설정합니다.
# 추후 드래그 앤 드롭 시에만 보이게 하려면 _ready 등에서 hide() 처리 후 시그널로 켭니다.
var show_grid: bool = false:
	set(value):
		show_grid = value
		queue_redraw() # visible 상태가 바뀔 때마다 _draw() 함수를 다시 호출하도록 예약

# 격자에 유닛이 놓여있는지 추적하는 딕셔너리
# 격자에 유닛이 놓여있는지 추적하는 딕셔너리
# Key: Vector2i (격자 좌표), Value: Area2D/Node2D (유닛 객체)
var grid_status: Dictionary = {}

# ======== 드래그 앤 드롭 중앙 제어 변수 ========
var dragged_unit: Node2D = null
var drag_offset: Vector2 = Vector2.ZERO
var original_grid_pos: Vector2i
@export var snap_duration: float = 0.15 # 유닛 이동 애니메이션 속도
# ===============================================

func _ready() -> void:
	# 시작 시 그리드를 업데이트합니다.
	queue_redraw()

func _draw() -> void:
	if not show_grid:
		return
		
	var width = grid_size.x * tile_size.x
	var height = grid_size.y * tile_size.y
	
	# 세로선 그리기 (Vertical lines)
	for x in range(grid_size.x + 1):
		var start_pos = Vector2(x * tile_size.x, 0)
		var end_pos = Vector2(x * tile_size.x, height)
		draw_line(start_pos, end_pos, line_color, line_thickness)
		
	# 가로선 그리기 (Horizontal lines)
	for y in range(grid_size.y + 1):
		var start_pos = Vector2(0, y * tile_size.y)
		var end_pos = Vector2(width, y * tile_size.y)
		draw_line(start_pos, end_pos, line_color, line_thickness)

# (유틸리티) 글로벌 픽셀 좌표를 그리드 타일 좌표(Vector2i)로 변환하는 함수
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x / tile_size.x), floor(world_pos.y / tile_size.y))

# (유틸리티) 그리드 타일 좌표(Vector2i)를 월드 픽셀 좌표(타일의 좌상단)로 변환하는 함수
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size.x, grid_pos.y * tile_size.y)

# (유틸리티) 특정 격자 좌표가 비어있는지 확인.
# 그리드 영역 안(0~grid_size)인지, 범위 내에 빈 칸인지 리턴합니다.
func is_cell_empty(cell_pos: Vector2i) -> bool:
	if cell_pos.x < 0 or cell_pos.y < 0 or cell_pos.x >= grid_size.x or cell_pos.y >= grid_size.y:
		return false
	return not grid_status.has(cell_pos)

# 유닛을 특정 격자 좌표에 점유/등록 시킵니다.
func register_unit(cell_pos: Vector2i, unit: Node) -> void:
	if not is_cell_empty(cell_pos):
		push_warning("Grid: Cell is out of bounds or already occupied!")
		return
	grid_status[cell_pos] = unit
	print("[GridManager] Registered unit " + unit.name + " at " + str(cell_pos) + " | Total units: " + str(grid_status.size()))

# 유닛의 격자 좌표 점유를 해제합니다.
func unregister_unit(cell_pos: Vector2i) -> void:
	if grid_status.has(cell_pos):
		grid_status.erase(cell_pos)

# (핵심 기능) 특정 좌표가 꽉 찼을 때, 그 주변에서 가장 가까운 빈 칸을 찾아줍니다 (BFS 탐색 방식).
# 유닛 소환(Spawn) 시 같은 자리에 겹치지 않고 옆으로 밀려나게 할 때 사용합니다.
func get_closest_empty_cell(start_cell: Vector2i) -> Vector2i:
	if is_cell_empty(start_cell):
		return start_cell
		
	# 탐색을 위한 큐(Queue)와 방문 기록(Visited)
	var queue: Array[Vector2i] = [start_cell]
	var visited: Dictionary = {start_cell: true}
	
	# 상하좌우 및 대각선 탐색 방향 (우, 하, 좌, 상, 우하, 좌하, 좌상, 우상)
	var directions: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)
	]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		# 현재 위치 기준 8방향 탐색
		for dir in directions:
			var neighbor = current + dir
			if not visited.has(neighbor):
				visited[neighbor] = true
				
				# 맵 범위를 벗어난 곳은 탐색하지 않음
				if neighbor.x >= 0 and neighbor.y >= 0 and neighbor.x < grid_size.x and neighbor.y < grid_size.y:
					if is_cell_empty(neighbor):
						return neighbor # 가장 먼저 찾은 빈 공간 리턴
					else:
						queue.append(neighbor) # 꽉 찼으면 큐에 넣고 계속 탐색 확장
						
	# 맵 전체가 꽉 차서 빈 곳을 찾을 수 없는 경우
	push_warning("Grid: No empty cells available around " + str(start_cell))
	return start_cell # 실패 시 그냥 원래 위치 반환 (겹침 허용)

# =========================================================================
# 중앙 집중식 드래그 앤 드롭 / 입력 제어 (Centralized Input Handling)
# =========================================================================

func _process(_delta: float) -> void:
	# 드래그 중인 유닛이 있다면 마우스 커서를 따라다니게 함
	if dragged_unit:
		dragged_unit.global_position = get_global_mouse_position() + drag_offset

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_pick_unit()
		else:
			if dragged_unit:
				_drop_unit()

# 마우스 위치에 있는 유닛을 찾아 집어 듭니다.
func _try_pick_unit() -> void:
	var mouse_pos = get_global_mouse_position()
	var clicked_cell = world_to_grid(mouse_pos)
	
	# 딕셔너리에 클릭한 칸에 유닛이 있다고 기록되어 있는지 확인
	if grid_status.has(clicked_cell):
		var target_unit = grid_status[clicked_cell]
		
		# 유닛이 맞는지 확인 (메모리 해제된 객체인지 확인용 is_instance_valid)
		if is_instance_valid(target_unit):
			dragged_unit = target_unit
			original_grid_pos = clicked_cell
			
			# 자리 비우기 및 그리드 시각화 켜기
			unregister_unit(original_grid_pos)
			show_grid = true
			
			drag_offset = dragged_unit.global_position - mouse_pos
			dragged_unit.z_index = 100 # 드래그 시 맨 앞에 보이게
			get_viewport().set_input_as_handled() # 이벤트 전파 중단

# 집어든 유닛을 현재 마우스 위치의 격자에 맞춰 내려놓습니다.
func _drop_unit() -> void:
	show_grid = false
	var target_grid_pos = world_to_grid(get_global_mouse_position())
	
	if is_cell_empty(target_grid_pos):
		# 정상 스냅: 타일 정중앙으로 이동
		var target_world_pos = grid_to_world(target_grid_pos) + Vector2(tile_size.x/2.0, tile_size.y/2.0)
		register_unit(target_grid_pos, dragged_unit)
		_tween_unit(dragged_unit, target_world_pos)
	else:
		# 겹침/비정상: 원래 있던 자리로 복귀 및 다시 점유
		var original_world_pos = grid_to_world(original_grid_pos) + Vector2(tile_size.x/2.0, tile_size.y/2.0)
		register_unit(original_grid_pos, dragged_unit)
		_tween_unit(dragged_unit, original_world_pos)
		
	dragged_unit.z_index = 0
	dragged_unit = null # 손에서 놓음

# 부드러운 스냅 애니메이션 서브루틴
func _tween_unit(unit: Node2D, target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(unit, "global_position", target_pos, snap_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# =========================================================================
# 외부(GamePlay 버튼 등)에서 새 유닛을 생성했을 때 직접 넘겨받는 함수
# =========================================================================
func add_new_unit(unit: Node2D, spawn_world_pos: Vector2) -> void:
	var target_cell = world_to_grid(spawn_world_pos)
	
	# 자리가 꽉 차있으면 주변(가까운 빈 곳) 탐색
	if not is_cell_empty(target_cell):
		target_cell = get_closest_empty_cell(target_cell)
		
	# 찾은 안전한 위치로 유닛을 보내고 딕셔너리에 점유 상태 등록
	unit.global_position = grid_to_world(target_cell) + Vector2(tile_size.x/2.0, tile_size.y/2.0)
	register_unit(target_cell, unit)
