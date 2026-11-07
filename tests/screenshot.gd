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
	unit.add_star()
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

	GameState.lose_lives(GameState.lives)
	await wait_frames(4)
	await shot("07_gameover.png")

	get_tree().quit()

func wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("saved ", file_name)
