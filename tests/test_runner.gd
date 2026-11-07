extends Node

# 헤드리스 테스트. 실행 명령은 docs/WORKLOG.md 참고.
# --fixed-fps 60으로 돌리면 게임 시간이 실제 시간보다 훨씬 빠르게 흐른다.

const GAME_SCENE := preload("res://scenes/game/game_play.tscn")
const ENEMY_SCENE := preload("res://entities/enemies/enemy.tscn")

var _checks: int = 0
var _failures: int = 0

func _ready() -> void:
	await _run_all()
	print("RESULT checks=%d failures=%d" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)

func _run_all() -> void:
	test_no_broken_references()
	test_catalog()
	test_unit_assets()
	test_enemy_assets()
	await test_menu_scenes()
	await test_grid_rules()
	await test_gacha_economy()
	await test_enemy_follows_path()
	await test_shot_kills_enemy()
	await test_zone_burns_enemy()
	await test_killed_enemy_does_not_leak()
	await test_held_unit_does_not_attack()
	await test_zone_stays_when_dropped_in_place()
	await test_game_over()
	await test_clear()

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
	get_tree().paused = false
	game.queue_free()
	await get_tree().process_frame

func first_unit(attack_type: UnitData.AttackType) -> UnitData:
	for unit in Catalog.units:
		if unit.attack_type == attack_type:
			return unit
	return null

func spawn_enemy(game: Node2D, ship: String = "scout", hp_scale: float = 1.0) -> EnemyBase:
	var enemy: EnemyBase = ENEMY_SCENE.instantiate()
	enemy.setup(Catalog.get_enemy("nautolan", ship), game.paths[0], hp_scale)
	game.enemies.add_child(enemy)
	return enemy

# 씬과 리소스가 참조하는 파일이 모두 있는지 확인한다.
func test_no_broken_references() -> void:
	var pattern := RegEx.create_from_string("path=\"(res://[^\"]+)\"")
	for file_path in _find_text_resources("res://"):
		var text := FileAccess.get_file_as_string(file_path)
		for found in pattern.search_all(text):
			var target := found.get_string(1)
			check(FileAccess.file_exists(target), "%s -> %s" % [file_path, target])

func _find_text_resources(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".tscn") or file_name.ends_with(".tres"):
			found.append(dir_path.path_join(file_name))
	for dir_name in DirAccess.get_directories_at(dir_path):
		if not dir_name.begins_with("."):
			found.append_array(_find_text_resources(dir_path.path_join(dir_name)))
	return found

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

func test_menu_scenes() -> void:
	var title: Node = load("res://scenes/title/title_screen.tscn").instantiate()
	add_child(title)
	await wait_frames(5)
	check(title.is_inside_tree(), "타이틀 씬 실행")
	title.queue_free()

	var setup: Control = load("res://scenes/lobby/playsetup.tscn").instantiate()
	add_child(setup)
	await wait_frames(5)
	GameSetting.selected_difficulty = ""
	setup.activate_start_button()
	check(setup.start_button.disabled, "난이도 미선택이면 시작 불가")
	setup._on_degree_2_pressed()
	check(GameSetting.selected_difficulty == "Normal", "난이도 선택 저장")
	check(not setup.start_button.disabled, "난이도 선택 후 시작 가능")
	setup._on_theme_3_pressed()
	check(GameSetting.selected_theme_texture == setup.theme03, "테마 선택 저장")
	check(setup.has_node("Difficulty/HBoxContainer/Degree1/Fighter"), "난이도 버튼 장식 함선")
	check(setup.has_node("Difficulty/HBoxContainer/Degree4/Dreadnought"), "난이도 버튼 장식 함선 (Extreme)")
	setup.queue_free()
	await get_tree().process_frame

func test_grid_rules() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid

	check(not grid.blocked_cells.is_empty(), "경로 칸 등록")
	check(grid.grid_size.y * grid.tile_size.y + int(grid.position.y) <= 720, "격자가 화면 안에 있음")

	var path_cell: Vector2i = grid.blocked_cells.keys()[0]
	check(not grid.is_cell_empty(path_cell), "경로 칸은 배치 불가")
	check(not grid.is_cell_empty(Vector2i(-1, 0)), "범위 밖은 배치 불가")
	check(not grid.is_cell_empty(grid.grid_size), "범위 밖은 배치 불가 (끝)")

	var home := grid.find_spawn_cell(Vector2(640, 360))
	check(grid.is_cell_empty(home), "스폰 칸은 빈 칸")
	var unit: UnitBase = game.spawn_unit(Catalog.units[0], home)
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
	var other_cell := grid.find_spawn_cell(Vector2(640, 360))
	var other: UnitBase = game.spawn_unit(Catalog.units[1], other_cell)
	grid.pick_unit(target, unit.global_position)
	grid.drop_unit_at(other_cell)
	check(grid.grid_status.get(target) == unit, "유닛 칸 드롭은 원위치")
	check(grid.grid_status.get(other_cell) == other, "기존 유닛 유지")

	# 칸을 전부 채우면 NO_CELL
	var filler := Node.new()
	for x in grid.grid_size.x:
		for y in grid.grid_size.y:
			if grid.is_cell_empty(Vector2i(x, y)):
				grid.grid_status[Vector2i(x, y)] = filler
	check(grid.find_spawn_cell(Vector2(640, 360)) == GridManager.NO_CELL, "빈 칸 없으면 NO_CELL")
	var gold_before := GameState.gold
	check(not game.draw_unit(), "빈 칸 없으면 뽑기 실패")
	check(GameState.gold == gold_before, "뽑기 실패 시 골드 유지")
	filler.free()
	grid.grid_status.clear()
	await end_game(game)

func test_gacha_economy() -> void:
	var game := await start_game()
	check(GameState.gold == GameState.START_GOLD, "시작 골드")
	for i in 5:
		check(game.draw_unit(), "뽑기 성공 %d" % i)
	await wait_frames(2)
	check(game.units.get_child_count() == 5, "뽑기 5회 = 유닛 5개")
	check(game.grid.grid_status.size() == 5, "유닛 5개 격자 등록")
	check(GameState.gold == GameState.START_GOLD - GameState.GACHA_COST * 5, "골드 차감")
	check(not game.draw_unit(), "골드 부족이면 뽑기 실패")
	check(game.units.get_child_count() == 5, "골드 부족이면 유닛 없음")
	check(game.hud.gacha_button.disabled, "골드 부족이면 버튼 비활성")

	var unit: UnitBase = game.units.get_child(0)
	var frame_before := unit.sprite.frame
	await wait_frames(30)
	check(unit.sprite.frame != frame_before, "행성 애니메이션 재생")
	await end_game(game)

func test_enemy_follows_path() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	check(manager.state == WaveManager.State.WAITING, "첫 웨이브 대기")
	check(not game.hud.wave_button.disabled, "대기 중 시작 버튼 활성")
	manager.start_next_wave()
	check(manager.wave == 1, "웨이브 1 시작")
	await wait_frames(1)
	check(game.hud.wave_button.disabled, "웨이브 중 시작 버튼 비활성")

	var spawned := await wait_until(func(): return game.enemies.get_child_count() > 0, 120)
	check(spawned, "적 스폰")
	if spawned:
		var enemy: EnemyBase = game.enemies.get_child(0)
		var start_distance := enemy.distance
		await wait_frames(60)
		check(enemy.distance > start_distance, "적이 경로를 따라 이동")

	# 유닛이 없으면 적이 전부 빠져나가고 라이프가 준다
	var lives_before := GameState.lives
	var gold_before := GameState.gold
	var finished := await wait_until(func(): return manager.state == WaveManager.State.PREP, 60 * 120)
	check(finished, "적이 모두 나가면 준비 단계")
	check(game.enemies.get_child_count() == 0, "경로 끝에서 적 제거")
	check(GameState.lives < lives_before, "경로 끝 도달 시 라이프 감소")
	check(GameState.gold == gold_before + game.WAVE_REWARD_BASE + game.WAVE_REWARD_STEP, "웨이브 보상")

	# 준비 시간이 끝나면 자동으로 다음 웨이브
	var next := await wait_until(func(): return manager.wave == 2, 60 * 20)
	check(next, "준비 시간 후 자동 시작")
	await end_game(game)

func test_shot_kills_enemy() -> void:
	var game := await start_game()
	var unit: UnitBase = game.spawn_unit(first_unit(UnitData.AttackType.SHOT), Vector2i(0, 2))
	var enemy := spawn_enemy(game)
	var reward := enemy.data.reward
	var gold_before := GameState.gold

	var fired := await wait_until(func(): return game.effects.get_child_count() > 0, 60 * 10)
	check(fired, "사거리 안의 적에게 투사체 발사")
	var enemy_ref: WeakRef = weakref(enemy)
	var killed := await wait_until(func(): return enemy_ref.get_ref() == null, 60 * 20)
	check(killed, "투사체로 적 처치")
	check(GameState.gold == gold_before + reward, "처치 골드 지급")
	check(unit.global_position == game.grid.cell_center(Vector2i(0, 2)), "유닛 위치 유지")
	await end_game(game)

func test_zone_burns_enemy() -> void:
	var game := await start_game()
	var unit: UnitBase = game.spawn_unit(first_unit(UnitData.AttackType.ZONE), Vector2i(0, 2))
	await wait_frames(1)
	check(game.zones.get_child_count() == 1, "ZONE 장판 생성")
	var zone: ZoneField = game.zones.get_child(0)
	check(zone.visible, "사거리 안에 경로가 있으면 장판 표시")
	check(zone.global_position.distance_to(unit.global_position) <= unit.data.attack_range, "장판은 사거리 안")

	var enemy := spawn_enemy(game, "bomber", 100.0)
	var max_hp := enemy.max_hp
	var burned := await wait_until(func(): return is_instance_valid(enemy) and enemy.hp < max_hp, 60 * 90)
	check(burned, "장판에 들어온 적이 피해를 입음")

	# 유닛이 사라지면 장판도 사라진다
	unit.free()
	await wait_frames(2)
	check(game.zones.get_child_count() == 0, "유닛 제거 시 장판 제거")
	await end_game(game)

func test_killed_enemy_does_not_leak() -> void:
	var game := await start_game()
	var enemy := spawn_enemy(game)
	enemy.distance = game.paths[0].curve.get_baked_length() - 0.01
	var lives_before := GameState.lives
	var gold_before := GameState.gold
	enemy.take_damage(enemy.hp)
	await wait_frames(2)
	check(GameState.gold == gold_before + enemy_reward("scout"), "처치 골드 1회 지급")
	check(GameState.lives == lives_before, "죽은 적은 라이프를 깎지 않음")
	await end_game(game)

func enemy_reward(ship: String) -> int:
	return Catalog.get_enemy("nautolan", ship).reward

func test_held_unit_does_not_attack() -> void:
	var game := await start_game()
	var cell := Vector2i(0, 2)
	var unit: UnitBase = game.spawn_unit(first_unit(UnitData.AttackType.SHOT), cell)
	game.grid.pick_unit(cell, unit.global_position)
	game.grid.set_process(false) # 테스트에서는 마우스가 눌려 있지 않아 자동으로 놓이는 것을 막는다
	spawn_enemy(game)
	await wait_frames(60)
	check(game.effects.get_child_count() == 0, "드래그 중에는 공격 안 함")
	game.grid.drop_unit_at(cell)
	var fired := await wait_until(func(): return game.effects.get_child_count() > 0, 60 * 10)
	check(fired, "내려놓으면 공격 재개")
	await end_game(game)

func test_zone_stays_when_dropped_in_place() -> void:
	var game := await start_game()
	var cell := Vector2i(0, 2)
	var unit: UnitBase = game.spawn_unit(first_unit(UnitData.AttackType.ZONE), cell)
	await wait_frames(1)
	var zone: ZoneField = game.zones.get_child(0)
	var position_before := zone.global_position
	game.grid.pick_unit(cell, unit.global_position)
	check(not zone.visible, "드래그 중 장판 숨김")
	game.grid.drop_unit_at(cell)
	check(zone.visible, "내려놓으면 장판 표시")
	check(zone.global_position == position_before, "제자리에 놓으면 장판 위치 유지")
	await end_game(game)

func test_game_over() -> void:
	var game := await start_game()
	GameState.lose_lives(GameState.lives)
	await get_tree().process_frame
	check(GameState.is_over, "라이프 0이면 종료")
	check(get_tree().paused, "게임오버 시 정지")
	check(game.hud.result_panel.visible, "결과 패널 표시")
	check(game.hud.result_label.text == "GAME OVER", "게임오버 문구")
	await end_game(game)

func test_clear() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	manager.total_waves = 1
	manager.start_next_wave()
	var cleared := await wait_until(func(): return GameState.is_over, 60 * 120)
	check(cleared, "마지막 웨이브 후 종료")
	check(GameState.lives > 0, "라이프가 남은 채 종료")
	check(game.hud.result_label.text == "CLEAR", "클리어 문구")
	check(manager.state == WaveManager.State.FINISHED, "웨이브 진행 종료")
	await end_game(game)
