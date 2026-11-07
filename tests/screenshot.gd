extends Node

# 화면 확인용. 실제 창으로 게임을 띄워 상황을 만들고 스크린샷을 저장한다.
# 사용: Godot --path . res://tests/screenshot.tscn -- <저장 폴더> [난이도]

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

	for i in 14:
		game._on_button_pressed()
	game._on_wave_start_pressed()
	await wait_frames(420)
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

	get_tree().quit()

func wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("saved ", file_name)
