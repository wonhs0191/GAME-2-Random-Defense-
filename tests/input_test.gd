extends Node

# 실제 입력 경로 확인. 마우스 이벤트를 흘려 버튼과 드래그가 동작하는지 본다.
# 입력 상태가 필요하므로 창 모드로 실행한다: Godot --path . res://tests/input_test.tscn

const GAME_SCENE := preload("res://scenes/game/game_play.tscn")
const GACHA_BUTTON := Vector2(1136, 680)
const WAVE_BUTTON := Vector2(144, 680)

var _failures: int = 0

func _ready() -> void:
	GameSetting.selected_difficulty = "Easy"
	var game: Node2D = GAME_SCENE.instantiate()
	add_child(game)
	await wait_frames(5)

	var gold_before := GameState.gold
	await click(GACHA_BUTTON)
	check(game.units.get_child_count() == 1, "GACHA 클릭으로 유닛 생성")
	check(GameState.gold == gold_before - GameState.GACHA_COST, "GACHA 클릭으로 골드 차감")

	var grid: GridManager = game.grid
	var unit: UnitBase = game.units.get_child(0)
	var target := Vector2i(0, 2)
	await drag(unit.global_position, grid.cell_center(target))
	check(grid.grid_status.get(target) == unit, "드래그로 이동")
	await wait_frames(30)
	check(unit.global_position == grid.cell_center(target), "칸 중앙으로 스냅")
	check(grid.dragged_unit == null, "드롭 후 손에서 놓음")
	check(not grid.show_grid, "드롭 후 격자 숨김")

	var path_cell: Vector2i = grid.blocked_cells.keys()[0]
	await drag(unit.global_position, grid.cell_center(path_cell))
	await wait_frames(30)
	check(unit.global_position == grid.cell_center(target), "경로 칸 드롭은 복귀")

	# 하단 버튼 위에서 놓아도 드래그가 끝나야 한다 (UNIT-005)
	await drag(unit.global_position, GACHA_BUTTON)
	await wait_frames(30)
	check(grid.dragged_unit == null, "버튼 위에서 놓아도 드래그 종료")
	check(unit.global_position == grid.cell_center(target), "격자 밖 드롭은 복귀")

	await click(WAVE_BUTTON)
	check(game.wave_manager.wave == 1, "WAVE START 클릭으로 시작")

	print("INPUT RESULT failures=%d" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)

func check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL ", label)

func wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func move_to(position: Vector2, held: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(event)
	await wait_frames(2)

func press(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	Input.parse_input_event(event)
	await wait_frames(2)

func click(position: Vector2) -> void:
	await move_to(position, false)
	await press(position, true)
	await press(position, false)

func drag(from: Vector2, to: Vector2) -> void:
	await move_to(from, false)
	await press(from, true)
	await move_to(from.lerp(to, 0.5), true)
	await move_to(to, true)
	await press(to, false)
