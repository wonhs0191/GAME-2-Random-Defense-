extends Node2D
class_name GridManager

@export var tile_size: Vector2i = Vector2i(64, 64) # 기본 그리드 칸 크기 (필요시 인스펙터에서 수정)
@export var grid_size: Vector2i = Vector2i(20, 9) # 화면에 그릴 그리드의 가로세로 칸 수
@export var line_color: Color = Color(1, 1, 1, 0.2) # 그리드 선 색상 (반투명 흰색)
@export var line_thickness: float = 1.0 # 그리드 선 두께
@export var highlight_valid_color: Color = Color(0.0, 0.8, 1.0, 0.35) # 드롭 가능 (하늘색)
@export var highlight_invalid_color: Color = Color(1.0, 0.5, 0.5, 0.35) # 드롭 불가능 (분홍색)
@export var range_color: Color = Color(1, 1, 1, 0.5) # 드래그 중 사거리 표시 색상

const NO_CELL := Vector2i(-1, -1)

# 드래그 앤 드롭 시에만 보이도록 합니다.
var show_grid: bool = false:
	set(value):
		show_grid = value
		queue_redraw() # visible 상태가 바뀔 때마다 _draw() 함수를 다시 호출하도록 예약

# 격자에 유닛이 놓여있는지 추적하는 딕셔너리
# Key: Vector2i (격자 좌표), Value: UnitBase (유닛 객체)
var grid_status: Dictionary = {}

# 적 경로가 지나가는 칸. 유닛을 놓을 수 없습니다.
var blocked_cells: Dictionary = {}

# ======== 드래그 앤 드롭 중앙 제어 변수 ========
var dragged_unit: UnitBase = null
var drag_offset: Vector2 = Vector2.ZERO
var original_grid_pos: Vector2i
@export var snap_duration: float = 0.15 # 유닛 이동 애니메이션 속도

# 드래그 중 마우스가 위치한 셀 (하이라이트 렌더링용)
var _hovered_cell: Vector2i = NO_CELL
# ===============================================

func _ready() -> void:
	# 시작 시 그리드를 업데이트합니다.
	queue_redraw()

func _draw() -> void:
	if not show_grid:
		return

	var width = grid_size.x * tile_size.x
	var height = grid_size.y * tile_size.y

	# 드래그 중일 때 각 셀에 크리스탈 하이라이트를 그립니다.
	if dragged_unit:
		for x in range(grid_size.x):
			for y in range(grid_size.y):
				var cell = Vector2i(x, y)
				var origin = Vector2(x * tile_size.x, y * tile_size.y)
				if is_cell_empty(cell):
					_draw_cell_crystal(origin, highlight_valid_color)
				else:
					_draw_cell_crystal(origin, highlight_invalid_color)

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

	# 놓을 위치 기준 사거리 표시
	if dragged_unit and _hovered_cell != NO_CELL:
		draw_arc(to_local(cell_center(_hovered_cell)), dragged_unit.data.attack_range, 0.0, TAU, 64, range_color, 1.5)

# (내부) 크리스탈/보석 스타일 셀 렌더링
# 셀을 중앙 기준 4개 삼각형으로 분할 → 중앙이 가장 밝고 가장자리로 갈수록 어두워짐
func _draw_cell_crystal(origin: Vector2, base_color: Color) -> void:
	var w = float(tile_size.x)
	var h = float(tile_size.y)

	# 꼭짓점 정의
	var tl = origin
	var tr = origin + Vector2(w, 0.0)
	var br = origin + Vector2(w, h)
	var bl = origin + Vector2(0.0, h)
	var center = origin + Vector2(w * 0.5, h * 0.5)

	# 중앙 색: 흰색을 살짝 혼합하여 크리스탈 내부 발광 효과
	var bright = base_color.lerp(Color.WHITE, 0.55)
	# 가장자리 색: 베이스보다 어둡고 반투명
	var edge = base_color
	edge.a *= 0.5

	# 4개 삼각형 팬 (상 / 우 / 하 / 좌)
	draw_polygon(PackedVector2Array([center, tl, tr]), PackedColorArray([bright, edge, edge]))
	draw_polygon(PackedVector2Array([center, tr, br]), PackedColorArray([bright, edge, edge]))
	draw_polygon(PackedVector2Array([center, br, bl]), PackedColorArray([bright, edge, edge]))
	draw_polygon(PackedVector2Array([center, bl, tl]), PackedColorArray([bright, edge, edge]))

# (유틸리티) 글로벌 픽셀 좌표를 그리드 타일 좌표(Vector2i)로 변환하는 함수
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos = to_local(world_pos)
	return Vector2i(floor(local_pos.x / tile_size.x), floor(local_pos.y / tile_size.y))

# (유틸리티) 그리드 타일 좌표(Vector2i)를 타일 정중앙의 글로벌 픽셀 좌표로 변환하는 함수
func cell_center(cell_pos: Vector2i) -> Vector2:
	return to_global(Vector2(cell_pos) * Vector2(tile_size) + Vector2(tile_size) / 2.0)

func is_cell_in_bounds(cell_pos: Vector2i) -> bool:
	return cell_pos.x >= 0 and cell_pos.y >= 0 and cell_pos.x < grid_size.x and cell_pos.y < grid_size.y

# (유틸리티) 특정 격자 좌표가 비어있는지 확인.
# 그리드 영역 안이고, 경로가 아니며, 유닛이 없는 칸인지 리턴합니다.
func is_cell_empty(cell_pos: Vector2i) -> bool:
	if not is_cell_in_bounds(cell_pos):
		return false
	return not blocked_cells.has(cell_pos) and not grid_status.has(cell_pos)

# 경로가 지나는 칸을 배치 금지로 등록합니다.
func block_path(path: Path2D) -> void:
	var length = path.curve.get_baked_length()
	var step = tile_size.x / 4.0
	var offset = 0.0
	while offset <= length:
		var cell = world_to_grid(path.to_global(path.curve.sample_baked(offset)))
		if is_cell_in_bounds(cell):
			blocked_cells[cell] = true
		offset += step

# 유닛을 특정 격자 좌표에 점유/등록 시킵니다.
func register_unit(cell_pos: Vector2i, unit: UnitBase) -> void:
	if not is_cell_empty(cell_pos):
		push_warning("Grid: Cell is out of bounds or already occupied!")
		return
	grid_status[cell_pos] = unit

# 유닛의 격자 좌표 점유를 해제합니다.
func unregister_unit(cell_pos: Vector2i) -> void:
	if grid_status.has(cell_pos):
		grid_status.erase(cell_pos)

# (핵심 기능) 특정 좌표가 꽉 찼을 때, 그 주변에서 가장 가까운 빈 칸을 찾아줍니다 (BFS 탐색 방식).
# 유닛 소환(Spawn) 시 같은 자리에 겹치지 않고 옆으로 밀려나게 할 때 사용합니다.
# 빈 칸이 하나도 없으면 NO_CELL을 돌려줍니다.
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
				if is_cell_in_bounds(neighbor):
					if is_cell_empty(neighbor):
						return neighbor # 가장 먼저 찾은 빈 공간 리턴
					else:
						queue.append(neighbor) # 꽉 찼으면 큐에 넣고 계속 탐색 확장

	return NO_CELL

# =========================================================================
# 중앙 집중식 드래그 앤 드롭 / 입력 제어 (Centralized Input Handling)
# =========================================================================

func _process(_delta: float) -> void:
	if not dragged_unit:
		return

	# 창 밖 등에서 버튼을 놓아도 놓침이 없도록 눌림 상태를 직접 확인합니다.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_drop_unit()
		return

	# 드래그 중인 유닛이 있다면 마우스 커서를 따라다니게 함
	var mouse_world = get_global_mouse_position()
	dragged_unit.global_position = mouse_world + drag_offset

	# 마우스가 위치한 셀이 바뀌었으면 리드로우 요청 (하이라이트 업데이트)
	var new_hovered = world_to_grid(mouse_world)
	if new_hovered != _hovered_cell:
		_hovered_cell = new_hovered
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_pick_unit()

# 마우스 위치에 있는 유닛을 찾아 집어 듭니다.
func _try_pick_unit() -> void:
	var mouse_pos = get_global_mouse_position()
	var clicked_cell = world_to_grid(mouse_pos)

	# 딕셔너리에 클릭한 칸에 유닛이 있다고 기록되어 있는지 확인
	if grid_status.has(clicked_cell):
		var target_unit = grid_status[clicked_cell]

		# 유닛이 맞는지 확인 (메모리 해제된 객체인지 확인용 is_instance_valid)
		if is_instance_valid(target_unit):
			pick_unit(clicked_cell, mouse_pos)
			get_viewport().set_input_as_handled() # 이벤트 전파 중단

# 특정 칸의 유닛을 집어 듭니다.
func pick_unit(cell_pos: Vector2i, mouse_pos: Vector2) -> void:
	dragged_unit = grid_status[cell_pos]
	original_grid_pos = cell_pos

	# 자리 비우기 및 그리드 시각화 켜기
	unregister_unit(original_grid_pos)
	show_grid = true

	drag_offset = dragged_unit.global_position - mouse_pos
	dragged_unit.z_index = 100 # 드래그 시 맨 앞에 보이게

# 집어든 유닛을 현재 마우스 위치의 격자에 맞춰 내려놓습니다.
func _drop_unit() -> void:
	drop_unit_at(world_to_grid(get_global_mouse_position()))

func drop_unit_at(target_grid_pos: Vector2i) -> void:
	show_grid = false
	_hovered_cell = NO_CELL # 하이라이트 초기화

	# 겹침/비정상이면 원래 있던 자리로 복귀
	var final_cell = target_grid_pos if is_cell_empty(target_grid_pos) else original_grid_pos
	register_unit(final_cell, dragged_unit)
	_tween_unit(dragged_unit, cell_center(final_cell))

	dragged_unit.z_index = 0
	dragged_unit = null # 손에서 놓음

# 부드러운 스냅 애니메이션 서브루틴
func _tween_unit(unit: Node2D, target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(unit, "global_position", target_pos, snap_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# =========================================================================
# 외부(GamePlay 버튼 등)에서 새 유닛을 생성했을 때 직접 넘겨받는 함수
# =========================================================================

# spawn_world_pos 주변에 유닛을 놓을 수 있는 칸을 찾습니다. 없으면 NO_CELL.
func find_spawn_cell(spawn_world_pos: Vector2) -> Vector2i:
	return get_closest_empty_cell(world_to_grid(spawn_world_pos))

# 찾은 안전한 위치로 유닛을 보내고 딕셔너리에 점유 상태 등록
func add_new_unit(unit: UnitBase, target_cell: Vector2i) -> void:
	unit.global_position = cell_center(target_cell)
	register_unit(target_cell, unit)
