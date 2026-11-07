extends Node

# 화면 확인용. 실제 창으로 게임을 띄워 상황을 만들고 스크린샷을 저장한다.
# 사용: Godot --path . res://tests/screenshot.tscn -- <저장 폴더> [난이도] [웨이브]

const GAME_SCENE := preload("res://scenes/game/game_play.tscn")

var _out_dir: String = ""

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0]
	GameSetting.selected_difficulty = args[1] if args.size() > 1 else "Easy"
	GameSetting.selected_theme_texture = load("res://scenes/lobby/background_img/winter_1280.png")

	var game: Node2D = GAME_SCENE.instantiate()
	add_child(game)
	await wait_frames(10)
	game.augments.draws_until_offer = 1000000 # 찍는 도중 패널이 열리지 않게 한다

	GameState.add_gold(300)
	for i in 14:
		game.draw_unit()
	game.wave_manager.wave = (args[2].to_int() if args.size() > 2 else 10) - 1
	game.wave_manager.start_next_wave()
	await wait_frames(900)
	await shot("01_wave.png")

	# 드래그 중 하이라이트
	var grid: GridManager = game.grid
	var cell: Vector2i = grid.grid_status.keys()[0]
	grid.pick_unit(cell, grid.cell_center(cell))
	grid.set_process(false) # 마우스가 눌려 있지 않아 자동으로 놓이는 것을 막는다
	grid._hovered_cell = cell
	grid.queue_redraw()
	await wait_frames(4)
	await shot("02_drag.png")

	grid.drop_unit_at(cell)

	# 버튼 설명
	var hover := InputEventMouseMotion.new()
	hover.position = Vector2(272, 680)
	hover.global_position = hover.position
	Input.parse_input_event(hover)
	await wait_frames(40)
	await shot("02_button_tooltip.png")

	# 별 표시와 행성 설명
	var starred: UnitBase = grid.grid_status[cell]
	starred.add_star()
	starred.add_star()
	grid.set_process(true)
	grid._pointer = starred.global_position
	await wait_frames(6)
	await shot("02_tooltip.png")
	grid._pointer = Vector2.ZERO
	await wait_frames(2)
	grid.set_process(false)

	# 조합 하이라이트: 같은 유닛을 하나 더 놓고 집어 든다
	var unit: UnitBase = grid.grid_status[cell]
	var twin_cell := grid.find_spawn_cell(unit.global_position)
	game.spawn_unit(unit.data, twin_cell)
	grid.pick_unit(cell, grid.cell_center(cell))
	grid._hovered_cell = twin_cell
	grid.queue_redraw()
	await wait_frames(4)
	await shot("03_merge.png")
	grid.drop_unit_at(cell)
	grid.set_process(true)

	# 선택 패널
	game.select_unit(unit)
	await wait_frames(4)
	await shot("04_selected.png")

	# 확률표
	game.hud.odds_panel.show()
	await wait_frames(4)
	await shot("05_odds.png")
	game.hud.odds_panel.hide()

	# S등급 등장
	var s_cell := grid.find_spawn_cell(Vector2(640, 360))
	game._reveal(game.spawn_unit(Catalog.units_of_grade(UnitData.Grade.S)[0], s_cell))
	await wait_frames(8)
	await shot("06_reveal.png")

	# 증강 카드
	await wait_frames(120)
	game.select_unit(null)
	game.augments.request_offer()
	await wait_frames(4)
	await shot("07_cards.png")

	# 구역 배치 미리보기
	game.hud._on_augment_card_pressed(0)
	grid._pointer = Vector2(640, 360)
	await wait_frames(4)
	await shot("08_placement.png")
	grid.place_zone_at(grid.world_to_grid(Vector2(640, 360)))

	# 겹친 구역과 시너지 하이라이팅, 그랩 아웃라인
	grid.add_buff_zone(Rect2i(8, 1, 5, 5), AugmentData.Stat.ATTACK_SPEED, 0.15)
	grid.add_buff_zone(Rect2i(10, 3, 3, 3), AugmentData.Stat.RANGE, 0.3)
	await wait_frames(4)
	await shot("09_zones.png")
	var held_cell: Vector2i = grid.grid_status.keys()[0]
	grid.pick_unit(held_cell, grid.cell_center(held_cell))
	grid.set_process(false)
	await wait_frames(4)
	await shot("10_synergy.png")
	grid.drop_unit_at(held_cell)

	# 일시 정지와 설정
	game.hud.pause_menu.open()
	await wait_frames(4)
	await shot("11_pause.png")
	game.hud.pause_menu.setting_panel.open()
	await wait_frames(4)
	await shot("12_setting.png")
	game.hud.pause_menu.close()

	GameState.lose_lives(GameState.lives)
	await wait_frames(60)
	await shot("13_gameover.png")

	get_tree().quit()

func wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("saved ", file_name)
