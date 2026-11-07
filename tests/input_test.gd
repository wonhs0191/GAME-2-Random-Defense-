extends Node

# 실제 입력 경로 확인. 마우스 이벤트를 흘려 버튼과 드래그가 동작하는지 본다.
# 입력 상태가 필요하므로 창 모드로 실행한다: Godot --path . --fixed-fps 60 res://tests/input_test.tscn

const GAME_SCENE := preload("res://scenes/game/game_play.tscn")
const GACHA_BUTTON := Vector2(1136, 680)
const WAVE_BUTTON := Vector2(144, 680)
const UPGRADE_BUTTON := Vector2(758, 680)
const ODDS_BUTTON := Vector2(942, 680)
const ODDS_CLOSE_BUTTON := Vector2(640, 598)
const AUGMENT_CARD_2 := Vector2(640, 340)
const PAUSE_BUTTON := Vector2(1232, 32)
const SPEED_BUTTON := Vector2(1160, 32)
const RESUME_BUTTON := Vector2(640, 302)
const PAUSE_SETTING_BUTTON := Vector2(640, 386)
const SETTING_CLOSE_BUTTON := Vector2(640, 512)
const ULTIMATE_BUTTON := Vector2(272, 680)
const SYNTHETIC_DEVICE := 100

# 실제 마우스가 창 위에서 움직이면 합성 입력과 섞여 드래그 위치가 튄다.
# 트리 맨 뒤에 두면 _input을 가장 먼저 받으므로 여기서 실제 마우스 이벤트를 막는다.
class RealMouseFilter extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse and event.device != SYNTHETIC_DEVICE:
			get_viewport().set_input_as_handled()

var _failures: int = 0

func _ready() -> void:
	var mouse_filter := RealMouseFilter.new()
	mouse_filter.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child.call_deferred(mouse_filter)
	await wait_frames(2)

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

	# 클릭은 선택, 강화 버튼은 골드 소모
	GameState.add_gold(1000)
	await click(unit.global_position)
	check(game.selected_unit == unit, "유닛 클릭으로 선택")
	check(grid.dragged_unit == null, "클릭 후 손에서 놓음")
	check(grid.grid_status.get(target) == unit, "클릭해도 제자리")
	var gold_at_upgrade := GameState.gold
	await click(UPGRADE_BUTTON)
	check(GameState.gold == gold_at_upgrade - unit.data.upgrade_cost(1), "강화 버튼 클릭으로 골드 소모")
	check(game.selected_unit == unit, "강화 버튼을 눌러도 선택 유지")
	var empty_cell := grid.find_spawn_cell(Vector2(640, 360))
	await click(grid.cell_center(empty_cell))
	check(game.selected_unit == null, "빈 칸 클릭으로 선택 해제")

	await click(ODDS_BUTTON)
	check(game.hud.odds_panel.visible, "확률표 버튼으로 열기")
	await click(ODDS_CLOSE_BUTTON)
	check(not game.hud.odds_panel.visible, "닫기 버튼으로 닫기")

	# 같은 유닛 위로 끌어 놓으면 합쳐진다
	var data: UnitData = Catalog.units_of_grade(UnitData.Grade.C)[0]
	var from_cell := grid.find_spawn_cell(Vector2(640, 360))
	var from_unit: UnitBase = game.spawn_unit(data, from_cell)
	var to_cell := grid.find_spawn_cell(Vector2(640, 360))
	var to_unit: UnitBase = game.spawn_unit(data, to_cell)
	await wait_frames(2)
	await drag(from_unit.global_position, to_unit.global_position)
	await wait_frames(30)
	var merged: UnitBase = grid.grid_status.get(to_cell)
	check(merged != null and merged.data.grade == UnitData.Grade.B, "드래그로 조합")
	check(not grid.grid_status.has(from_cell), "조합 후 원래 칸 비움")
	check(game.selected_unit == null, "조합 드래그는 선택이 아님")

	# 증강: 카드 클릭, 구역 배치 클릭
	game.augments.request_offer()
	await wait_frames(2)
	await click(AUGMENT_CARD_2)
	check(game.augments.placing != null, "증강 카드 클릭으로 선택")
	var zone_cell := Vector2i(4, 4)
	await click(grid.cell_center(zone_cell))
	check(grid.buff_zones.size() == 1, "클릭으로 구역 배치")
	check(grid.buff_zones[0].rect.has_point(zone_cell), "클릭한 곳에 구역")
	check(not get_tree().paused, "구역 배치 후 재개")

	# 일시 정지 메뉴와 설정 창은 게임이 멈춘 상태에서 눌린다
	await click(PAUSE_BUTTON)
	check(get_tree().paused, "일시 정지 버튼 클릭")
	await click(PAUSE_SETTING_BUTTON)
	check(game.hud.pause_menu.setting_panel.visible, "정지 중 설정 열기 클릭")
	await click(SETTING_CLOSE_BUTTON)
	check(not game.hud.pause_menu.setting_panel.visible, "정지 중 설정 닫기 클릭")
	await click(RESUME_BUTTON)
	check(not get_tree().paused, "계속하기 클릭")

	await click(SPEED_BUTTON)
	check(Engine.time_scale == 2.0, "배속 버튼 클릭")
	await click(SPEED_BUTTON)
	await click(SPEED_BUTTON)
	check(Engine.time_scale == 1.0, "배속 순환")

	await click(ULTIMATE_BUTTON)
	check(not game.ultimates.can_use(), "필살기 버튼 클릭")

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
	event.device = SYNTHETIC_DEVICE
	event.position = position
	event.global_position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(event)
	await wait_frames(2)

func press(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.device = SYNTHETIC_DEVICE
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
