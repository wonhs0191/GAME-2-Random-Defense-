extends Node2D
class_name GridManager

signal merge_requested(moved: UnitBase, target: UnitBase)
signal merge_unaffordable(cost: int)
signal unit_clicked(unit: UnitBase) # 빈 곳을 누르면 null
signal zone_placed(rect: Rect2i)

# 증강으로 놓은 버프 구역
class BuffZone:
	var rect: Rect2i
	var stat: AugmentData.Stat
	var value: float

@export var tile_size: Vector2i = Vector2i(64, 64) # 기본 그리드 칸 크기 (필요시 인스펙터에서 수정)
@export var grid_size: Vector2i = Vector2i(20, 9) # 화면에 그릴 그리드의 가로세로 칸 수
@export var line_color: Color = Color(1, 1, 1, 0.2) # 그리드 선 색상 (반투명 흰색)
@export var line_thickness: float = 1.0 # 그리드 선 두께
@export var highlight_valid_color: Color = Color(0.0, 0.8, 1.0, 0.35) # 드롭 가능 (하늘색)
@export var highlight_invalid_color: Color = Color(1.0, 0.5, 0.5, 0.35) # 드롭 불가능 (분홍색)
@export var highlight_merge_color: Color = Color(1.0, 0.8, 0.25, 0.9) # 조합 가능 (금색)
@export var range_color: Color = Color(1, 1, 1, 0.5) # 드래그 중 사거리 표시 색상
@export var click_slop: float = 8.0 # 이 거리 안에서 놓으면 드래그가 아니라 클릭으로 본다 (px)

const NO_CELL := Vector2i(-1, -1)
const MAX_ZONE_STACK := 2 # 같은 능력치 구역은 이 수까지만 겹쳐 적용된다
const ZONE_FILL_ALPHA := 0.08
const ZONE_HIGHLIGHT_ALPHA := 0.3 # 유닛을 들고 있거나 구역을 놓는 중일 때
const ZONE_BORDER_ALPHA := 0.8
const ZONE_BORDER_WIDTH := 2.0
const ZONE_BORDER_GAP := 3.0 # 능력치가 다른 구역의 테두리가 겹치지 않도록 띄우는 간격

# 드래그 앤 드롭 시에만 보이도록 합니다.
var show_grid: bool = false:
	set(value):
		show_grid = value
		queue_redraw() # visible 상태가 바뀔 때마다 _draw() 함수를 다시 호출하도록 예약

# 선택된 유닛. 사거리를 표시합니다.
var selected_unit: UnitBase = null:
	set(value):
		selected_unit = value
		queue_redraw()

# 격자에 유닛이 놓여있는지 추적하는 딕셔너리
# Key: Vector2i (격자 좌표), Value: UnitBase (유닛 객체)
var grid_status: Dictionary = {}

# 적 경로가 지나가는 칸. 유닛을 놓을 수 없습니다.
var blocked_cells: Dictionary = {}

var buff_zones: Array[BuffZone] = []

# ======== 드래그 앤 드롭 중앙 제어 변수 ========
var dragged_unit: UnitBase = null
var drag_offset: Vector2 = Vector2.ZERO
var original_grid_pos: Vector2i
@export var snap_duration: float = 0.15 # 유닛 이동 애니메이션 속도

var _press_position: Vector2 = Vector2.ZERO

# 구역 배치 중일 때의 크기와 색. 배치 중이 아니면 크기가 0입니다.
var _placement_size: Vector2i = Vector2i.ZERO
var _placement_color: Color = Color.WHITE
var _placement_rect: Rect2i = Rect2i()

# 드래그 중 마우스가 위치한 셀 (하이라이트 렌더링용)
var _hovered_cell: Vector2i = NO_CELL

# 마지막 마우스 위치 (글로벌 좌표)
var _pointer: Vector2 = Vector2.ZERO
# ===============================================

func _ready() -> void:
	# 시작 시 그리드를 업데이트합니다.
	queue_redraw()

func _draw() -> void:
	# 유닛을 들고 있으면 구역을 밝혀 어디에 놓을지 보여 줍니다 (시너지 하이라이팅)
	var zone_alpha := ZONE_HIGHLIGHT_ALPHA if dragged_unit else ZONE_FILL_ALPHA
	for zone in buff_zones:
		_draw_zone(zone.rect, AugmentData.STAT_COLORS[zone.stat], zone_alpha, ZONE_BORDER_GAP * zone.stat)
	if is_placing_zone():
		_draw_zone(_placement_rect, _placement_color, ZONE_HIGHLIGHT_ALPHA, 0.0)

	if selected_unit:
		draw_arc(to_local(selected_unit.global_position), selected_unit.get_attack_range(), 0.0, TAU, 64, range_color, 1.5)

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
				elif can_merge_at(cell):
					_draw_cell_crystal(origin, highlight_merge_color)
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
		var hovered_center := cell_center(_hovered_cell)
		draw_arc(to_local(hovered_center), dragged_unit.get_attack_range(hovered_center), 0.0, TAU, 64, range_color, 1.5)

func _draw_zone(rect: Rect2i, color: Color, fill_alpha: float, inset: float) -> void:
	var area := Rect2(Vector2(rect.position * tile_size), Vector2(rect.size * tile_size))
	draw_rect(area, Color(color, fill_alpha))
	draw_rect(area.grow(-inset - ZONE_BORDER_WIDTH), Color(color, ZONE_BORDER_ALPHA), false, ZONE_BORDER_WIDTH)

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

# 들고 있는 유닛을 이 칸의 유닛과 합칠 수 있는지 확인합니다.
func can_merge_at(cell_pos: Vector2i) -> bool:
	return _is_merge_target(cell_pos) and GameState.gold >= dragged_unit.data.merge_cost()

func _is_merge_target(cell_pos: Vector2i) -> bool:
	return dragged_unit != null and grid_status.has(cell_pos) and dragged_unit.can_merge_with(grid_status[cell_pos])

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

# =========================================================================
# 버프 구역 (증강)
# =========================================================================

func add_buff_zone(rect: Rect2i, stat: AugmentData.Stat, value: float) -> void:
	var zone := BuffZone.new()
	zone.rect = rect
	zone.stat = stat
	zone.value = value
	buff_zones.append(zone)
	queue_redraw()

# 이 칸의 능력치 증가율. 겹친 구역은 효과가 큰 순으로 MAX_ZONE_STACK개까지 합산합니다.
func zone_bonus(cell_pos: Vector2i, stat: AugmentData.Stat) -> float:
	var values: Array[float] = []
	for zone in buff_zones:
		if zone.stat == stat and zone.rect.has_point(cell_pos):
			values.append(zone.value)
	values.sort()
	var total := 0.0
	for value in values.slice(-MAX_ZONE_STACK):
		total += value
	return total

func is_placing_zone() -> bool:
	return _placement_size != Vector2i.ZERO

# 마우스 위치에 구역 미리보기를 띄웁니다. 게임이 멈춘 상태에서 호출됩니다.
func begin_zone_placement(zone_size: Vector2i, color: Color) -> void:
	_placement_size = zone_size
	_placement_color = color
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_placement_preview()

# cell을 중심으로 구역을 놓습니다. 격자 밖으로 나가면 안쪽으로 밀어 넣습니다.
func place_zone_at(cell_pos: Vector2i) -> void:
	var rect := zone_rect_at(cell_pos, _placement_size)
	_placement_size = Vector2i.ZERO
	process_mode = Node.PROCESS_MODE_INHERIT
	queue_redraw()
	zone_placed.emit(rect)

func zone_rect_at(cell_pos: Vector2i, zone_size: Vector2i) -> Rect2i:
	return Rect2i((cell_pos - zone_size / 2).clamp(Vector2i.ZERO, grid_size - zone_size), zone_size)

func _update_placement_preview() -> void:
	_placement_rect = zone_rect_at(world_to_grid(_pointer), _placement_size)
	queue_redraw()

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
	if is_placing_zone():
		_update_placement_preview()
		return

	if not dragged_unit:
		return

	# 창 밖 등에서 버튼을 놓아도 놓침이 없도록 눌림 상태를 직접 확인합니다.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_drop_unit()
		return

	# 드래그 중인 유닛이 있다면 마우스 커서를 따라다니게 함
	dragged_unit.global_position = _pointer + drag_offset

	# 마우스가 위치한 셀이 바뀌었으면 리드로우 요청 (하이라이트 업데이트)
	var new_hovered = world_to_grid(_pointer)
	if new_hovered != _hovered_cell:
		_hovered_cell = new_hovered
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_pointer = to_global(make_input_local(event).position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_placing_zone():
			place_zone_at(world_to_grid(_pointer))
			get_viewport().set_input_as_handled()
		elif not _try_pick_unit():
			unit_clicked.emit(null)

# 마우스 위치에 있는 유닛을 찾아 집어 듭니다. 집었으면 true.
func _try_pick_unit() -> bool:
	var clicked_cell = world_to_grid(_pointer)

	# 딕셔너리에 클릭한 칸에 유닛이 있다고 기록되어 있는지 확인
	if grid_status.has(clicked_cell):
		var target_unit = grid_status[clicked_cell]

		# 유닛이 맞는지 확인 (메모리 해제된 객체인지 확인용 is_instance_valid)
		if is_instance_valid(target_unit):
			pick_unit(clicked_cell, _pointer)
			get_viewport().set_input_as_handled() # 이벤트 전파 중단
			return true
	return false

# 특정 칸의 유닛을 집어 듭니다.
func pick_unit(cell_pos: Vector2i, mouse_pos: Vector2) -> void:
	dragged_unit = grid_status[cell_pos]
	original_grid_pos = cell_pos
	_press_position = mouse_pos

	# 자리 비우기 및 그리드 시각화 켜기
	unregister_unit(original_grid_pos)
	show_grid = true

	drag_offset = dragged_unit.global_position - mouse_pos
	dragged_unit.z_index = 100 # 드래그 시 맨 앞에 보이게
	dragged_unit.on_picked()

# 집어든 유닛을 현재 마우스 위치의 격자에 맞춰 내려놓습니다.
func _drop_unit() -> void:
	var unit := dragged_unit
	var clicked := _pointer.distance_to(_press_position) < click_slop
	drop_unit_at(world_to_grid(_pointer))
	if clicked:
		unit_clicked.emit(unit)

# 드래그 중이면 유닛을 원래 자리로 돌려놓습니다.
func cancel_drag() -> void:
	if dragged_unit:
		drop_unit_at(original_grid_pos)

func drop_unit_at(target_grid_pos: Vector2i) -> void:
	show_grid = false
	_hovered_cell = NO_CELL # 하이라이트 초기화

	# 같은 유닛 위에 놓으면 합친다. 처리는 GamePlay가 한다
	if can_merge_at(target_grid_pos):
		var moved := dragged_unit
		dragged_unit = null
		merge_requested.emit(moved, grid_status[target_grid_pos])
		return
	if _is_merge_target(target_grid_pos):
		merge_unaffordable.emit(dragged_unit.data.merge_cost())

	# 겹침/비정상이면 원래 있던 자리로 복귀
	var final_cell = target_grid_pos if is_cell_empty(target_grid_pos) else original_grid_pos
	register_unit(final_cell, dragged_unit)
	_tween_unit(dragged_unit, cell_center(final_cell))
	dragged_unit.on_placed(cell_center(final_cell))

	dragged_unit.z_index = 0
	dragged_unit = null # 손에서 놓음

# 부드러운 스냅 애니메이션 서브루틴
func _tween_unit(unit: Node2D, target_pos: Vector2) -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
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
	unit.on_placed(unit.global_position)
