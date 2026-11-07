extends Node

# 헤드리스 테스트. 실행 명령은 docs/WORKLOG.md 참고.
# --fixed-fps 60으로 돌리면 게임 시간이 실제 시간보다 훨씬 빠르게 흐른다.

const GAME_SCENE := preload("res://scenes/game/game_play.tscn")

var _checks: int = 0
var _failures: int = 0

func _ready() -> void:
	await _run_all()
	print("RESULT checks=%d failures=%d" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)

func _run_all() -> void:
	test_catalog()
	test_unit_assets()
	test_enemy_assets()
	await test_grid_rules()
	await test_gacha_spawn()
	await test_enemy_follows_path()

func check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL ", label)

func wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

# 조건이 참이 될 때까지 프레임을 돌린다. 시간 초과면 false.
func wait_until(condition: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await get_tree().process_frame
	return condition.call()

func start_game(difficulty: String = "Easy") -> Node2D:
	GameSetting.selected_difficulty = difficulty
	var game: Node2D = GAME_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	return game

func end_game(game: Node2D) -> void:
	game.queue_free()
	await get_tree().process_frame

func test_catalog() -> void:
	check(Catalog.units.size() == 12, "C 유닛 12종 로드")
	check(Catalog.enemies.size() == 24, "적 24종 로드")
	check(Catalog.get_enemy("klaed", "fighter") != null, "세력+함선으로 적 조회")

func test_unit_assets() -> void:
	for unit in Catalog.units:
		check(load(unit.sheet_path) != null, "유닛 시트 로드 " + unit.id)
		var frames: SpriteFrames = unit.get_effect_frames()
		check(frames.get_frame_count("default") == unit.effect_frame_count, "이펙트 프레임 " + unit.id)
		check(frames.get_frame_texture("default", 0) != null, "이펙트 텍스처 " + unit.id)

func test_enemy_assets() -> void:
	for enemy in Catalog.enemies.values():
		check(load(enemy.body_path) != null, "적 본체 로드 " + enemy.id)
		check(enemy.get_engine_frames().get_frame_count("default") > 1, "엔진 프레임 " + enemy.id)

func test_grid_rules() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid

	check(not grid.blocked_cells.is_empty(), "경로 칸 등록")
	check(grid.grid_size.y * grid.tile_size.y + int(grid.position.y) <= 720, "격자가 화면 안에 있음")

	var path_cell: Vector2i = grid.blocked_cells.keys()[0]
	check(not grid.is_cell_empty(path_cell), "경로 칸은 배치 불가")
	check(not grid.is_cell_empty(Vector2i(-1, 0)), "범위 밖은 배치 불가")
	check(not grid.is_cell_empty(grid.grid_size), "범위 밖은 배치 불가 (끝)")

	var unit: UnitBase = game.UNIT_SCENE.instantiate()
	unit.setup(Catalog.units[0])
	game.units.add_child(unit)
	var home := grid.find_spawn_cell(Vector2(640, 360))
	check(grid.is_cell_empty(home), "스폰 칸은 빈 칸")
	grid.add_new_unit(unit, home)
	check(grid.grid_status[home] == unit, "유닛 등록")

	# 빈 칸으로 이동
	var target := grid.find_spawn_cell(Vector2(640, 360))
	check(target != home, "다음 스폰 칸은 다른 칸")
	grid.pick_unit(home, unit.global_position)
	check(not grid.grid_status.has(home), "집으면 자리가 빔")
	grid.drop_unit_at(target)
	check(grid.grid_status[target] == unit, "빈 칸으로 이동")

	# 경로 칸에 놓으면 원위치
	grid.pick_unit(target, unit.global_position)
	grid.drop_unit_at(path_cell)
	check(grid.grid_status.get(target) == unit, "경로 칸 드롭은 원위치")

	# 다른 유닛 칸에 놓으면 원위치
	var other: UnitBase = game.UNIT_SCENE.instantiate()
	other.setup(Catalog.units[1])
	game.units.add_child(other)
	var other_cell := grid.find_spawn_cell(Vector2(640, 360))
	grid.add_new_unit(other, other_cell)
	grid.pick_unit(target, unit.global_position)
	grid.drop_unit_at(other_cell)
	check(grid.grid_status.get(target) == unit, "유닛 칸 드롭은 원위치")
	check(grid.grid_status.get(other_cell) == other, "기존 유닛 유지")

	# 칸을 전부 채우면 NO_CELL
	var filler: UnitBase = game.UNIT_SCENE.instantiate()
	filler.setup(Catalog.units[0])
	for x in grid.grid_size.x:
		for y in grid.grid_size.y:
			if grid.is_cell_empty(Vector2i(x, y)):
				grid.grid_status[Vector2i(x, y)] = filler
	check(grid.find_spawn_cell(Vector2(640, 360)) == GridManager.NO_CELL, "빈 칸 없으면 NO_CELL")
	filler.free()
	grid.grid_status.clear()
	await end_game(game)

func test_gacha_spawn() -> void:
	var game := await start_game()
	for i in 5:
		game._on_button_pressed()
	await wait_frames(2)
	check(game.units.get_child_count() == 5, "뽑기 5회 = 유닛 5개")
	check(game.grid.grid_status.size() == 5, "유닛 5개 격자 등록")
	var unit: UnitBase = game.units.get_child(0)
	var frame_before := unit.sprite.frame
	await wait_frames(30)
	check(unit.sprite.frame != frame_before, "행성 애니메이션 재생")
	await end_game(game)

func test_enemy_follows_path() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	check(manager.state == WaveManager.State.WAITING, "첫 웨이브 대기")
	game._on_wave_start_pressed()
	check(manager.wave == 1, "웨이브 1 시작")

	var spawned := await wait_until(func(): return game.enemies.get_child_count() > 0, 120)
	check(spawned, "적 스폰")
	if spawned:
		var enemy: EnemyBase = game.enemies.get_child(0)
		var start_distance := enemy.distance
		await wait_frames(60)
		check(enemy.distance > start_distance, "적이 경로를 따라 이동")

	# 전투가 아직 없으므로 적이 전부 경로를 빠져나가면 웨이브가 끝난다
	var finished := await wait_until(func(): return manager.state == WaveManager.State.PREP, 60 * 120)
	check(finished, "적이 모두 나가면 준비 단계")
	check(game.enemies.get_child_count() == 0, "경로 끝에서 적 제거")
	await end_game(game)
