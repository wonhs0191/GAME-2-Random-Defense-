extends Node

# 헤드리스 테스트. 실행 명령은 docs/WORKLOG.md 참고.
# --fixed-fps 60으로 돌리면 게임 시간이 실제 시간보다 훨씬 빠르게 흐른다.

const GAME_SCENE := preload("res://scenes/game/game_play.tscn")
const ENEMY_SCENE := preload("res://entities/enemies/enemy.tscn")
const OFFERS_OFF := 1000000

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
	test_gacha_odds()
	await test_merge()
	await test_merge_rules()
	await test_merge_removes_zone()
	await test_upgrade()
	await test_upgrade_needs_gold()
	await test_upgraded_damage_applies()
	await test_select_unit()
	await test_reveal()
	await test_odds_panel()
	test_augment_data()
	await test_offer_after_five_draws()
	await test_pause_during_offer()
	await test_offer_cancels_drag()
	await test_offer_after_boss()
	await test_queued_offers()
	await test_zone_bonus()
	await test_zone_stack_limit()
	await test_zone_rect_stays_inside()
	await test_zone_applies_in_combat()
	await test_grab_outline()
	await test_enemy_follows_path()
	await test_shot_kills_enemy()
	await test_zone_burns_enemy()
	await test_killed_enemy_does_not_leak()
	test_faction_rotation()
	test_wave_composition()
	await test_boss_spawn()
	await test_final_boss()
	await test_final_boss_leak_loses()
	await test_boss_leak_keeps_game_going()
	await test_boss_hud()
	await test_maps()
	await test_multi_path_spawn()
	await test_enemy_lanes()
	await test_large_ships_spawn_apart()
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
	# 뽑기 횟수를 세는 테스트만 켠다. 나머지는 패널로 멈추면 안 된다
	game.augments.draws_until_offer = OFFERS_OFF
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
	check(Catalog.units_of_grade(UnitData.Grade.C).size() == 12, "C 유닛 12종 로드")
	for grade in Catalog.GRADE_ODDS:
		check(not Catalog.units_of_grade(grade).is_empty(), "등급별 유닛 존재 " + UnitData.GRADE_NAMES[grade])
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

func test_gacha_odds() -> void:
	var total_odds := 0.0
	var counts := {}
	var trials := 40000
	for i in trials:
		var grade: UnitData.Grade = Catalog.pick_random_unit().grade
		counts[grade] = counts.get(grade, 0) + 1
	for grade in Catalog.GRADE_ODDS:
		var odds: float = Catalog.GRADE_ODDS[grade]
		total_odds += odds
		var percent: float = 100.0 * counts.get(grade, 0) / trials
		check(abs(percent - odds) <= 0.3 + odds * 0.03, "뽑기 확률 %s %.2f%%" % [UnitData.GRADE_NAMES[grade], percent])
	check(is_equal_approx(total_odds, 100.0), "확률 합계 100%")
	check(Catalog.GRADE_ODDS[UnitData.Grade.S] == 0.5, "S등급 확률은 기획값 0.5%")

# 중앙 근처 빈 칸에 유닛을 놓고 칸과 함께 돌려준다.
func place_unit(game: Node2D, data: UnitData) -> Array:
	var cell: Vector2i = game.grid.find_spawn_cell(Vector2(640, 360))
	return [game.spawn_unit(data, cell), cell]

func test_merge() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid
	var data: UnitData = Catalog.units_of_grade(UnitData.Grade.C)[0]
	var first: Array = place_unit(game, data)
	var second: Array = place_unit(game, data)
	await wait_frames(1)
	game.select_unit(first[0])
	var gold_before := GameState.gold

	grid.pick_unit(first[1], first[0].global_position)
	check(grid.can_merge_at(second[1]), "같은 유닛 칸은 조합 가능")
	grid.drop_unit_at(second[1])
	await wait_frames(2)

	check(GameState.gold == gold_before - data.merge_cost(), "조합 골드 소모")
	check(game.units.get_child_count() == 1, "조합하면 유닛 1개")
	check(grid.grid_status.size() == 1, "조합하면 칸 1개 점유")
	check(not grid.grid_status.has(first[1]), "옮긴 유닛 칸은 빈다")
	var result: UnitBase = grid.grid_status.get(second[1])
	check(result != null and result.data.grade == UnitData.Grade.B, "조합 결과는 상위 등급")
	check(result != null and result.stars == 1, "조합 결과는 1성")
	check(grid.dragged_unit == null and not grid.show_grid, "조합 후 드래그 종료")
	check(game.selected_unit == null, "조합한 유닛의 선택 해제")
	check(not game.hud.upgrade_button.visible, "조합 후 강화 버튼 숨김")
	await end_game(game)

func test_merge_rules() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid
	var c_units := Catalog.units_of_grade(UnitData.Grade.C)
	var first: Array = place_unit(game, c_units[0])
	var other: Array = place_unit(game, c_units[1])
	grid.pick_unit(first[1], first[0].global_position)
	check(not grid.can_merge_at(other[1]), "다른 유닛은 조합 불가")
	grid.drop_unit_at(other[1])
	await wait_frames(1)
	check(grid.grid_status.get(first[1]) == first[0], "다른 유닛에 놓으면 원위치")
	check(grid.grid_status.get(other[1]) == other[0], "다른 유닛 유지")

	# 골드가 모자라면 합치지 않고 이유를 알린다
	var poor: Array = place_unit(game, c_units[2])
	var poor_target: Array = place_unit(game, c_units[2])
	GameState.spend_gold(GameState.gold)
	grid.pick_unit(poor[1], poor[0].global_position)
	check(not grid.can_merge_at(poor_target[1]), "골드 부족이면 조합 불가")
	grid.drop_unit_at(poor_target[1])
	await wait_frames(1)
	check(grid.grid_status.get(poor[1]) == poor[0], "골드 부족이면 원위치")
	check(grid.grid_status.get(poor_target[1]) == poor_target[0], "골드 부족이면 대상 유지")
	check(game.hud.message_label.text.begins_with("조합 골드 부족"), "골드 부족 문구")
	check(GameState.gold == 0, "조합 실패 시 골드 유지")

	# 등급을 끝까지 올린다
	GameState.add_gold(1000)
	var grades := [UnitData.Grade.C, UnitData.Grade.B, UnitData.Grade.A]
	for grade in grades:
		var data: UnitData = Catalog.units_of_grade(grade)[0]
		var a: Array = place_unit(game, data)
		var b: Array = place_unit(game, data)
		grid.pick_unit(a[1], a[0].global_position)
		grid.drop_unit_at(b[1])
		await wait_frames(1)
		var merged: UnitBase = grid.grid_status.get(b[1])
		check(merged.data.grade == grade + 1, "%s 조합 결과" % UnitData.GRADE_NAMES[grade])

	var top: UnitData = Catalog.units_of_grade(UnitData.Grade.S)[0]
	var s_first: Array = place_unit(game, top)
	var s_second: Array = place_unit(game, top)
	grid.pick_unit(s_first[1], s_first[0].global_position)
	check(not grid.can_merge_at(s_second[1]), "S등급은 조합 불가")
	grid.drop_unit_at(s_second[1])
	await wait_frames(1)
	check(grid.grid_status.get(s_first[1]) == s_first[0], "S등급을 겹치면 원위치")
	check(grid.grid_status.get(s_second[1]) == s_second[0], "S등급 대상 유지")
	await end_game(game)

func test_merge_removes_zone() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid
	var zone_data: UnitData = null
	for unit in Catalog.units_of_grade(UnitData.Grade.C):
		if unit.attack_type == UnitData.AttackType.ZONE:
			zone_data = unit
			break
	var first: Array = place_unit(game, zone_data)
	var second: Array = place_unit(game, zone_data)
	await wait_frames(1)
	check(game.zones.get_child_count() == 2, "ZONE 유닛 2개면 장판 2개")
	grid.pick_unit(first[1], first[0].global_position)
	grid.drop_unit_at(second[1])
	await wait_frames(3)
	var result: UnitBase = grid.grid_status.get(second[1])
	var expected := 1 if result.data.attack_type == UnitData.AttackType.ZONE else 0
	check(game.zones.get_child_count() == expected, "재료 유닛의 장판 제거")
	await end_game(game)

func test_upgrade() -> void:
	var game := await start_game()
	GameState.add_gold(1000)
	var data: UnitData = Catalog.units_of_grade(UnitData.Grade.C)[0]
	var unit: UnitBase = game.spawn_unit(data, Vector2i(0, 2))
	var base_damage := unit.get_damage()
	var gold := GameState.gold

	check(not game.upgrade_unit(unit, 0.71), "1→2성 확률 밖이면 실패")
	gold -= data.upgrade_cost(1)
	check(unit.stars == 1, "실패하면 별 유지")
	check(GameState.gold == gold, "실패해도 골드 소모")
	check(game.hud.message_label.text == "강화 실패...", "실패 문구")

	check(game.upgrade_unit(unit, 0.69), "1→2성 확률 안이면 성공")
	gold -= data.upgrade_cost(1)
	check(unit.stars == 2, "성공하면 별 증가")
	check(GameState.gold == gold, "성공 골드 소모")
	check(is_equal_approx(unit.get_damage(), base_damage * UnitData.STAR_DAMAGE[1]), "2성 공격력")
	check(game.hud.message_label.text == "강화 성공!", "성공 문구")

	check(not game.upgrade_unit(unit, 0.41), "2→3성 확률 밖이면 실패")
	gold -= data.upgrade_cost(2)
	check(data.upgrade_cost(2) == data.upgrade_cost(1) * 2, "별이 높을수록 비용 증가")
	check(game.upgrade_unit(unit, 0.39), "2→3성 확률 안이면 성공")
	gold -= data.upgrade_cost(2)
	check(unit.stars == UnitData.MAX_STARS, "3성 도달")
	check(is_equal_approx(unit.get_damage(), base_damage * UnitData.STAR_DAMAGE[2]), "3성 공격력")
	check(GameState.gold == gold, "누적 골드 소모")

	check(not game.upgrade_unit(unit, 0.0), "3성은 강화 불가")
	check(unit.stars == UnitData.MAX_STARS, "3성 초과 없음")
	check(GameState.gold == gold, "강화 불가면 골드 유지")
	await end_game(game)

func test_upgrade_needs_gold() -> void:
	var game := await start_game()
	var unit: UnitBase = game.spawn_unit(Catalog.units_of_grade(UnitData.Grade.S)[0], Vector2i(0, 2))
	var cost := unit.data.upgrade_cost(1)
	check(GameState.gold < cost, "시작 골드로는 S 강화 불가")
	var gold := GameState.gold
	check(not game.upgrade_unit(unit, 0.0), "골드 부족이면 강화 실패")
	check(unit.stars == 1 and GameState.gold == gold, "골드 부족이면 변화 없음")
	await end_game(game)

func test_upgraded_damage_applies() -> void:
	var game := await start_game()
	GameState.add_gold(1000)
	var unit: UnitBase = game.spawn_unit(first_unit(UnitData.AttackType.SHOT), Vector2i(0, 2))
	game.upgrade_unit(unit, 0.0)
	spawn_enemy(game, "bomber", 100.0)
	var fired := await wait_until(func(): return game.effects.get_child_count() > 0, 60 * 10)
	check(fired, "강화 유닛 발사")
	if fired:
		var projectile: Projectile = game.effects.get_child(0)
		check(is_equal_approx(projectile.damage, unit.get_damage()), "투사체에 강화 공격력 적용")
	await end_game(game)

func test_select_unit() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid
	var hud: CanvasLayer = game.hud
	var placed: Array = place_unit(game, Catalog.units_of_grade(UnitData.Grade.C)[0])
	var unit: UnitBase = placed[0]
	var cell: Vector2i = placed[1]
	check(not hud.upgrade_button.visible, "선택 전에는 강화 버튼 숨김")

	# 놓은 자리에서 그대로 떼면 클릭이다
	grid._pointer = unit.global_position
	grid.pick_unit(cell, grid._pointer)
	grid._drop_unit()
	check(game.selected_unit == unit, "클릭으로 유닛 선택")
	check(grid.selected_unit == unit, "격자에 선택 전달")
	check(hud.upgrade_button.visible, "선택하면 강화 버튼 표시")
	check(hud.unit_info_label.text.contains(unit.data.id), "선택 유닛 정보 표시")
	check(hud.upgrade_button.text.contains("70%"), "강화 확률 표시")

	# 골드가 모자라면 버튼이 꺼지고, 벌면 켜진다
	GameState.spend_gold(GameState.gold)
	check(hud.upgrade_button.disabled, "골드 부족이면 강화 버튼 비활성")
	GameState.add_gold(unit.data.upgrade_cost(1))
	check(not hud.upgrade_button.disabled, "골드가 생기면 강화 버튼 활성")

	# 3성이면 강화 완료
	unit.stars = UnitData.MAX_STARS
	hud.show_unit(unit)
	check(hud.upgrade_button.disabled and hud.upgrade_button.text == "강화 완료", "3성이면 강화 완료")
	unit.stars = 1

	game.select_unit(null)
	check(not hud.upgrade_button.visible, "선택 해제하면 강화 버튼 숨김")

	# 다른 칸으로 끌면 선택하지 않는다
	var target := grid.find_spawn_cell(Vector2(640, 360))
	grid._pointer = unit.global_position
	grid.pick_unit(cell, grid._pointer)
	grid._pointer = grid.cell_center(target)
	grid._drop_unit()
	check(game.selected_unit == null, "드래그는 선택이 아님")
	check(grid.grid_status.get(target) == unit, "드래그는 그대로 이동")

	# 빈 곳을 누르면 선택이 풀린다
	game.select_unit(unit)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	grid._pointer = grid.cell_center(cell)
	grid._unhandled_input(press)
	check(game.selected_unit == null, "빈 칸을 누르면 선택 해제")
	await end_game(game)

func test_reveal() -> void:
	var game := await start_game()
	var hud: CanvasLayer = game.hud
	var c_unit: Array = place_unit(game, Catalog.units_of_grade(UnitData.Grade.C)[0])
	game._reveal(c_unit[0])
	check(game.effects.get_child_count() == 1, "등장 연출 생성")
	check(c_unit[0].scale.x < 0.01, "등장 시 크기 0에서 시작")
	check(hud.message_label.modulate.a == 0.0, "C등급은 문구 없음")
	var finished := await wait_until(func(): return game.effects.get_child_count() == 0, 120)
	check(finished, "등장 연출 종료")
	check(c_unit[0].scale.is_equal_approx(Vector2.ONE), "등장 후 원래 크기")

	var a_unit: Array = place_unit(game, Catalog.units_of_grade(UnitData.Grade.A)[0])
	game._reveal(a_unit[0])
	check(hud.message_label.text.begins_with("A등급 등장"), "A등급 문구")
	check(hud.message_label.modulate.a == 1.0, "A등급 문구 표시")
	check(hud.flash.modulate.a == 0.0, "A등급은 화면 번쩍임 없음")

	var s_unit: Array = place_unit(game, Catalog.units_of_grade(UnitData.Grade.S)[0])
	game._reveal(s_unit[0])
	check(hud.message_label.text.begins_with("S등급 등장"), "S등급 문구")
	check(hud.flash.modulate.a > 0.0, "S등급 화면 번쩍임")
	var faded := await wait_until(func(): return hud.flash.modulate.a == 0.0 and hud.message_label.modulate.a == 0.0, 240)
	check(faded, "문구와 번쩍임이 사라짐")
	await end_game(game)

func test_odds_panel() -> void:
	var game := await start_game()
	var hud: CanvasLayer = game.hud
	check(not hud.odds_panel.visible, "확률표는 처음에 숨김")
	hud._on_odds_button_pressed()
	check(hud.odds_panel.visible, "확률표 열기")
	var text: String = hud.odds_label.text
	for grade in Catalog.GRADE_ODDS:
		check(text.contains("%s등급  %.1f%%" % [UnitData.GRADE_NAMES[grade], Catalog.GRADE_ODDS[grade]]), "확률표 등급 표시")
	check(text.contains("1성 → 2성  70%") and text.contains("2성 → 3성  40%"), "확률표 강화 표시")
	check(text.contains("C 10G / B 40G / A 160G"), "확률표 조합 비용 표시")
	hud._on_odds_close_button_pressed()
	check(not hud.odds_panel.visible, "확률표 닫기")
	await end_game(game)

func test_augment_data() -> void:
	check(Catalog.augments.size() == 6, "증강 6종 로드")
	var stats := {}
	for augment in Catalog.augments:
		stats[augment.stat] = true
		check(augment.value > 0.0, "증강 수치 " + augment.id)
		check(augment.get_description().contains("%d%%" % roundi(augment.value * 100.0)), "증강 설명 " + augment.id)
	check(stats.size() == AugmentData.STAT_NAMES.size(), "공격력, 공속, 사거리 증강이 모두 있음")

# 카드를 고르고 구역을 놓아 패널을 닫는다.
func close_offer(game: Node2D, cell: Vector2i = Vector2i(3, 3)) -> void:
	game.augments.choose(0)
	game.grid.place_zone_at(cell)

func test_offer_after_five_draws() -> void:
	var game := await start_game()
	var augments: AugmentManager = game.augments
	var hud: CanvasLayer = game.hud
	GameState.add_gold(1000)
	augments.draws_until_offer = AugmentManager.DRAWS_PER_OFFER
	for i in AugmentManager.DRAWS_PER_OFFER - 1:
		game.draw_unit()
	check(not augments.is_busy(), "뽑기 4회까지는 증강 없음")
	await wait_frames(1)
	check(hud.gacha_button.text.contains("증강까지 1회"), "남은 뽑기 표시")

	game.draw_unit()
	check(augments.is_busy(), "뽑기 5회째 증강 제시")
	check(get_tree().paused, "패널 표시 중 게임 정지")
	check(hud.augment_panel.visible, "증강 패널 표시")
	check(augments.cards.size() == AugmentManager.CARD_COUNT, "카드 3장")
	var unique := {}
	for card in augments.cards:
		unique[card.id] = true
	check(unique.size() == AugmentManager.CARD_COUNT, "카드가 서로 다름")
	check(hud.augment_cards[0].text.contains(augments.cards[0].get_title()), "카드에 증강 이름 표시")

	var gold := GameState.gold
	var unit_count: int = game.units.get_child_count()
	check(not game.draw_unit(), "패널 표시 중 뽑기 불가")
	check(GameState.gold == gold and game.units.get_child_count() == unit_count, "패널 표시 중 뽑기 무효")

	var chosen: AugmentData = augments.cards[1]
	hud._on_augment_card_pressed(1)
	check(augments.placing == chosen, "카드 선택")
	check(not hud.augment_panel.visible, "카드 선택 후 패널 숨김")
	check(hud.placement_label.visible, "구역 배치 안내 표시")
	check(get_tree().paused, "구역 배치 중에도 정지")
	check(game.grid.is_placing_zone(), "구역 배치 시작")
	check(game.grid.process_mode == Node.PROCESS_MODE_ALWAYS, "정지 중에도 격자 입력 처리")

	game.grid._pointer = game.grid.cell_center(Vector2i(10, 4))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	game.grid._unhandled_input(press)
	check(game.grid.buff_zones.size() == 1, "클릭으로 구역 배치")
	check(game.grid.buff_zones[0].stat == chosen.stat, "고른 증강의 구역")
	check(game.grid.buff_zones[0].rect.has_point(Vector2i(10, 4)), "클릭한 칸이 구역 안")
	check(not get_tree().paused, "구역 배치 후 재개")
	check(not augments.is_busy(), "증강 처리 종료")
	check(not hud.placement_label.visible, "배치 안내 숨김")
	check(game.grid.process_mode == Node.PROCESS_MODE_INHERIT, "격자 처리 모드 복구")
	check(augments.draws_until_offer == AugmentManager.DRAWS_PER_OFFER, "뽑기 횟수 다시 계산")
	await end_game(game)

func test_pause_during_offer() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	var unit: UnitBase = game.spawn_unit(first_unit(UnitData.AttackType.SHOT), Vector2i(0, 2))
	var enemy := spawn_enemy(game, "bomber", 100.0)
	manager.state = WaveManager.State.PREP
	manager.prep_left = 10.0
	await wait_frames(30)

	game.augments.request_offer()
	await wait_frames(1)
	var enemy_distance := enemy.distance
	var prep_left := manager.prep_left
	var unit_cooldown := unit._cooldown
	var effect_count: int = game.effects.get_child_count()
	await wait_frames(60)
	check(enemy.distance == enemy_distance, "정지 중 적 이동 없음")
	check(manager.prep_left == prep_left, "정지 중 웨이브 시간 멈춤")
	check(unit._cooldown == unit_cooldown, "정지 중 유닛 공격 없음")
	check(game.effects.get_child_count() == effect_count, "정지 중 발사 없음")

	close_offer(game)
	await wait_frames(30)
	check(enemy.distance > enemy_distance, "재개 후 적 이동")
	check(manager.prep_left < prep_left, "재개 후 웨이브 시간 진행")
	await end_game(game)

func test_offer_cancels_drag() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid
	var cell := Vector2i(0, 2)
	var unit: UnitBase = game.spawn_unit(Catalog.units[0], cell)
	grid.pick_unit(cell, unit.global_position)
	game.augments.request_offer()
	check(grid.dragged_unit == null, "패널이 열리면 드래그 취소")
	check(grid.grid_status.get(cell) == unit, "드래그 취소 시 원위치")
	check(not grid.show_grid, "드래그 취소 시 격자 숨김")
	check(not unit.is_held, "드래그 취소 후 유닛 활성")
	close_offer(game)
	await end_game(game)

func test_offer_after_boss() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	game._on_wave_cleared(9)
	check(not game.augments.is_busy(), "일반 웨이브 클리어는 증강 없음")
	game._on_wave_cleared(10)
	check(game.augments.is_busy(), "보스 처치 후 증강")
	close_offer(game)
	game._on_wave_cleared(manager.total_waves)
	check(not game.augments.is_busy(), "마지막 보스 뒤에는 증강 없음")
	await end_game(game)

func test_queued_offers() -> void:
	var game := await start_game()
	var augments: AugmentManager = game.augments
	augments.request_offer()
	augments.request_offer()
	check(augments.pending_offers == 1, "진행 중이면 다음 증강 대기")
	close_offer(game)
	check(get_tree().paused, "대기 증강이 있으면 정지 유지")
	check(game.hud.augment_panel.visible, "대기 증강 패널 표시")
	check(not game.hud.placement_label.visible, "대기 증강 표시 때 안내 숨김")
	close_offer(game, Vector2i(10, 4))
	check(not get_tree().paused, "대기 증강까지 끝나면 재개")
	check(game.grid.buff_zones.size() == 2, "증강 2개 모두 적용")
	await end_game(game)

func test_zone_bonus() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid
	var data := first_unit(UnitData.AttackType.SHOT)
	var inside: UnitBase = game.spawn_unit(data, Vector2i(0, 2))
	var outside: UnitBase = game.spawn_unit(data, Vector2i(19, 7))
	await wait_frames(1)
	var base_damage := outside.get_damage()
	var base_interval := outside.get_attack_interval()
	var base_range := outside.get_attack_range()
	var rect := Rect2i(0, 1, 3, 3)
	grid.add_buff_zone(rect, AugmentData.Stat.DAMAGE, 0.4)
	grid.add_buff_zone(rect, AugmentData.Stat.ATTACK_SPEED, 0.25)
	grid.add_buff_zone(rect, AugmentData.Stat.RANGE, 0.5)
	check(is_equal_approx(inside.get_damage(), base_damage * 1.4), "구역 안 공격력 증가")
	check(is_equal_approx(inside.get_attack_interval(), base_interval / 1.25), "구역 안 공격 간격 감소")
	check(is_equal_approx(inside.get_attack_range(), base_range * 1.5), "구역 안 사거리 증가")
	check(outside.get_damage() == base_damage, "구역 밖 공격력 유지")
	check(outside.get_attack_interval() == base_interval, "구역 밖 공격 간격 유지")
	check(outside.get_attack_range() == base_range, "구역 밖 사거리 유지")

	# 구역 밖으로 옮기면 효과가 사라지고, 다시 넣으면 돌아온다
	var target := Vector2i(5, 7)
	check(grid.is_cell_empty(target) and not rect.has_point(target), "구역 밖 빈 칸")
	grid.pick_unit(Vector2i(0, 2), inside.global_position)
	grid.drop_unit_at(target)
	inside.global_position = grid.cell_center(target)
	check(inside.get_damage() == base_damage, "구역 밖으로 옮기면 효과 없음")
	check(is_equal_approx(inside.get_attack_range(grid.cell_center(Vector2i(0, 2))), base_range * 1.5), "놓을 칸 기준 사거리 계산")
	await end_game(game)

func test_zone_stack_limit() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid
	var rect := Rect2i(0, 0, 3, 3)
	var cell := Vector2i(1, 1)
	grid.add_buff_zone(rect, AugmentData.Stat.DAMAGE, 0.1)
	grid.add_buff_zone(rect, AugmentData.Stat.DAMAGE, 0.2)
	check(is_equal_approx(grid.zone_bonus(cell, AugmentData.Stat.DAMAGE), 0.3), "구역 2개는 합산")
	grid.add_buff_zone(rect, AugmentData.Stat.DAMAGE, 0.4)
	check(is_equal_approx(grid.zone_bonus(cell, AugmentData.Stat.DAMAGE), 0.6), "3번째부터는 큰 값 2개만")
	check(grid.zone_bonus(cell, AugmentData.Stat.RANGE) == 0.0, "다른 능력치에는 영향 없음")
	check(grid.zone_bonus(Vector2i(4, 4), AugmentData.Stat.DAMAGE) == 0.0, "구역 밖 칸은 효과 없음")
	await end_game(game)

func test_zone_rect_stays_inside() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid
	var bounds := Rect2i(Vector2i.ZERO, grid.grid_size)
	var size := Vector2i(5, 5)
	check(grid.zone_rect_at(Vector2i(10, 4), size) == Rect2i(8, 2, 5, 5), "구역 중심이 클릭한 칸")
	for cell in [Vector2i(0, 0), Vector2i(19, 8), Vector2i(0, 8), Vector2i(19, 0), Vector2i(-3, 20)]:
		check(bounds.encloses(grid.zone_rect_at(cell, size)), "구역이 격자 안 %s" % cell)
	await end_game(game)

func test_zone_applies_in_combat() -> void:
	var game := await start_game()
	var cell := Vector2i(0, 2)
	var unit: UnitBase = game.spawn_unit(first_unit(UnitData.AttackType.SHOT), cell)
	game.grid.add_buff_zone(Rect2i(cell, Vector2i.ONE), AugmentData.Stat.DAMAGE, 0.5)
	spawn_enemy(game, "bomber", 100.0)
	var fired := await wait_until(func(): return game.effects.get_child_count() > 0, 60 * 10)
	check(fired, "구역 안 유닛 발사")
	if fired:
		var projectile: Projectile = game.effects.get_child(0)
		check(is_equal_approx(projectile.damage, unit.data.damage * 1.5), "투사체에 구역 공격력 적용")
	await end_game(game)

func test_grab_outline() -> void:
	var game := await start_game()
	var grid: GridManager = game.grid
	var cell := Vector2i(0, 2)
	var unit: UnitBase = game.spawn_unit(Catalog.units_of_grade(UnitData.Grade.C)[0], cell)
	check(unit.sprite.material == null, "평소에는 외곽선 없음")
	grid.pick_unit(cell, unit.global_position)
	check(unit.sprite.material != null, "집으면 외곽선")
	grid.drop_unit_at(cell)
	check(unit.sprite.material == null, "놓으면 외곽선 제거")
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

func wave_manager_for(difficulty: String) -> WaveManager:
	var manager := WaveManager.new()
	var no_paths: Array[Path2D] = []
	manager.setup(no_paths, self, GameSetting.DIFFICULTIES[difficulty])
	return manager

func test_faction_rotation() -> void:
	for difficulty in GameSetting.DIFFICULTIES:
		var manager := wave_manager_for(difficulty)
		var total := manager.total_waves
		var counts := {}
		var order: Array[String] = []
		for wave in range(1, total + 1):
			var faction := manager.faction_for_wave(wave)
			counts[faction] = counts.get(faction, 0) + 1
			if not order.has(faction):
				order.append(faction)
		check(order == ["nautolan", "klaed", "nairan"], "세력 순서 " + difficulty)
		for faction in counts:
			check(abs(counts[faction] - total / 3.0) <= 1.0, "세력별 웨이브 1/3 %s %s" % [difficulty, faction])
		manager.free()

	var easy := wave_manager_for("Easy")
	check(easy.faction_for_wave(10) == "nautolan", "Easy 10웨이브는 Nautolan")
	check(easy.faction_for_wave(11) == "klaed", "Easy 11웨이브부터 Klaed")
	check(easy.faction_for_wave(21) == "nairan", "Easy 21웨이브부터 Nairan")
	easy.free()

func test_wave_composition() -> void:
	for difficulty in GameSetting.DIFFICULTIES:
		var manager := wave_manager_for(difficulty)
		var boss_waves := 0
		var all_valid := true
		var boss_only_when_expected := true
		var faction_matches := true
		for wave in range(1, manager.total_waves + 1):
			var list := manager.build_wave(wave)
			var bosses := 0
			for enemy in list:
				if enemy == null:
					all_valid = false
					continue
				if enemy.ship == WaveManager.BOSS_SHIP:
					bosses += 1
				if enemy.faction != manager.faction_for_wave(wave):
					faction_matches = false
			if manager.is_boss_wave(wave):
				boss_waves += 1
				boss_only_when_expected = boss_only_when_expected and bosses == 1 and list[-1].ship == WaveManager.BOSS_SHIP
			else:
				boss_only_when_expected = boss_only_when_expected and bosses == 0
		check(all_valid, "모든 웨이브 적 조회 성공 " + difficulty)
		check(faction_matches, "웨이브 적이 해당 세력 " + difficulty)
		check(boss_only_when_expected, "보스 웨이브에만 보스 1기 " + difficulty)
		check(boss_waves == manager.total_waves / WaveManager.BOSS_INTERVAL, "10웨이브마다 보스 " + difficulty)
		check(manager.is_boss_wave(manager.total_waves), "마지막 웨이브는 보스 " + difficulty)
		check(not manager.is_boss_wave(0), "시작 전은 보스 웨이브가 아님 " + difficulty)
		check(manager.boss_hp_scale(10) > manager.hp_scale(10), "보스 체력 배율 " + difficulty)
		check(manager.boss_hp_scale(manager.total_waves) / manager.hp_scale(manager.total_waves) > manager.boss_hp_scale(10) / manager.hp_scale(10), "최종 보스 배율이 더 큼 " + difficulty)
		manager.free()

func find_boss(game: Node2D) -> EnemyBase:
	for enemy: EnemyBase in game.enemies.get_children():
		if enemy.data.ship == WaveManager.BOSS_SHIP:
			return enemy
	return null

func test_boss_spawn() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	manager.wave = 9
	manager.start_next_wave()
	var spawned := await wait_until(func(): return find_boss(game) != null, 60 * 30)
	check(spawned, "10웨이브 보스 스폰")
	if spawned:
		var boss := find_boss(game)
		check(boss.data.faction == "nautolan", "보스는 해당 세력 함선")
		check(is_equal_approx(boss.max_hp, boss.data.max_hp * manager.boss_hp_scale(10)), "보스 체력 배율 적용")
		check(boss.visual.scale.is_equal_approx(Vector2.ONE * boss.data.visual_scale), "일반 보스 크기")
	await end_game(game)

func test_final_boss() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	manager.wave = manager.total_waves - 1
	manager.start_next_wave()
	var spawned := await wait_until(func(): return find_boss(game) != null, 60 * 60)
	check(spawned, "최종 보스 스폰")
	if spawned:
		var boss := find_boss(game)
		check(boss.data.faction == "nairan", "최종 보스는 마지막 세력")
		check(is_equal_approx(boss.max_hp, boss.data.max_hp * manager.boss_hp_scale(manager.total_waves)), "최종 보스 체력 배율")
		check(boss.visual.scale.is_equal_approx(Vector2.ONE * boss.data.visual_scale * WaveManager.FINAL_BOSS_SIZE_SCALE), "최종 보스 크기")
		check(game.hud.status_label.text == "최종 보스 전투", "최종 보스 문구")
	await end_game(game)

func test_final_boss_leak_loses() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	manager.wave = manager.total_waves
	manager.state = WaveManager.State.FIGHTING
	var boss := manager._spawn_enemy(Catalog.get_enemy("nairan", WaveManager.BOSS_SHIP))
	check(boss.is_final_boss, "마지막 웨이브 보스는 최종 보스")
	check(GameState.lives >= boss.data.life_damage * 2, "일반 보스 피해보다 라이프가 많은 상태")
	boss.distance = game.paths[0].curve.get_baked_length() - 0.01
	await wait_frames(2)
	check(GameState.is_over, "최종 보스 도달 시 게임 종료")
	check(GameState.lives == 0, "최종 보스 도달 시 라이프 0")
	check(game.hud.result_label.text == "GAME OVER", "최종 보스 도달 시 패배")
	await end_game(game)

func test_boss_leak_keeps_game_going() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	manager.wave = 10
	var boss := manager._spawn_enemy(Catalog.get_enemy("nautolan", WaveManager.BOSS_SHIP))
	check(not boss.is_final_boss, "중간 보스는 최종 보스가 아님")
	var expected_lives := GameState.lives - boss.data.life_damage
	boss.distance = game.paths[0].curve.get_baked_length() - 0.01
	await wait_frames(2)
	check(GameState.lives == expected_lives, "중간 보스는 라이프만 차감")
	check(not GameState.is_over, "중간 보스 도달로 게임이 끝나지 않음")
	await end_game(game)

func test_boss_hud() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	var hud: CanvasLayer = game.hud
	manager.wave = 9
	manager.state = WaveManager.State.PREP
	manager.prep_left = 12.0
	await wait_frames(2)
	check(hud.status_label.text.begins_with("보스 출현"), "다음 보스 예고")
	check(not hud.wave_label.text.begins_with("BOSS"), "준비 중에는 보스 표시 없음")

	manager.start_next_wave()
	await wait_frames(2)
	check(hud.wave_label.text == "BOSS WAVE 10/30", "보스 웨이브 표시")
	check(hud.wave_label.modulate == hud.BOSS_COLOR, "보스 웨이브 색상")
	check(hud.status_label.text == "보스 전투", "보스 전투 문구")

	manager.wave = 10
	manager.state = WaveManager.State.PREP
	await wait_frames(2)
	check(hud.wave_label.text == "WAVE 10/30", "보스 처치 후 표시 복귀")
	check(hud.wave_label.modulate == Color.WHITE, "보스 처치 후 색상 복귀")
	await end_game(game)

func test_maps() -> void:
	var expected_paths := {"Easy": 1, "Normal": 1, "Hard": 2, "Extreme": 4}
	for difficulty in expected_paths:
		var game := await start_game(difficulty)
		var grid: GridManager = game.grid
		check(game.paths.size() == expected_paths[difficulty], "경로 수 " + difficulty)
		for path: Path2D in game.paths:
			var curve := path.curve
			var label := "%s %s" % [difficulty, path.name]
			check(curve.get_point_position(0).x < 0.0, "시작점이 화면 밖 " + label)
			check(curve.get_point_position(curve.point_count - 1).x > 1280.0, "끝점이 화면 밖 " + label)
			var aligned := true
			var all_blocked := true
			for i in range(1, curve.point_count - 1):
				var point := curve.get_point_position(i)
				aligned = aligned and grid.cell_center(grid.world_to_grid(point)) == point
			var offset := 0.0
			while offset <= curve.get_baked_length():
				var cell := grid.world_to_grid(curve.sample_baked(offset))
				if grid.is_cell_in_bounds(cell):
					all_blocked = all_blocked and not grid.is_cell_empty(cell)
				offset += 16.0
			check(aligned, "제어점이 타일 중앙 " + label)
			check(all_blocked, "경로 칸 전부 배치 금지 " + label)
		# 뽑은 유닛이 나오는 중앙 칸에서 경로에 닿아야 조작 없이도 싸울 수 있다
		var home := grid.cell_center(grid.find_spawn_cell(Vector2(640, 360)))
		var nearest := INF
		for path: Path2D in game.paths:
			nearest = minf(nearest, home.distance_to(path.curve.get_closest_point(home)))
		if difficulty == "Hard" or difficulty == "Extreme":
			check(nearest <= 176.0, "중앙 스폰 칸이 경로 사거리 안 " + difficulty)
		await end_game(game)

func test_multi_path_spawn() -> void:
	for difficulty in ["Hard", "Extreme"]:
		var game := await start_game(difficulty)
		var manager: WaveManager = game.wave_manager
		var used := {}
		for i in 60:
			manager._spawn_enemy(Catalog.get_enemy("nautolan", "scout"))
		for enemy: EnemyBase in game.enemies.get_children():
			used[enemy.path] = true
		check(used.size() == game.paths.size(), "모든 경로에 스폰 " + difficulty)
		await end_game(game)

func test_enemy_lanes() -> void:
	var game := await start_game()
	var lanes := {}
	var inside := true
	for i in 8:
		var enemy := spawn_enemy(game)
		enemy.distance = 300.0 + i * 700.0
		lanes[enemy.lane] = true
		inside = inside and abs(enemy.lane) <= EnemyBase.LANE_SPREAD
	check(lanes.size() > 1, "적마다 다른 위치로 이동")
	check(inside, "좌우 분산은 지정 범위 안")
	await wait_frames(30)
	var within_path := true
	for enemy: EnemyBase in game.enemies.get_children():
		var center: Vector2 = game.paths[0].curve.sample_baked(enemy.distance)
		within_path = within_path and enemy.global_position.distance_to(center) <= EnemyBase.LANE_SPREAD + 1.0
	check(within_path, "분산해도 경로 폭 안으로 이동")
	await end_game(game)

func test_large_ships_spawn_apart() -> void:
	var game := await start_game()
	var manager: WaveManager = game.wave_manager
	var ship := Catalog.get_enemy("nautolan", "battlecruiser")
	var queue: Array[EnemyData] = [ship, ship]
	manager._spawn_queue = queue
	manager.state = WaveManager.State.SPAWNING
	var spawned := await wait_until(func(): return game.enemies.get_child_count() == 2, 60 * 10)
	check(spawned, "대형 함선 2기 스폰")
	if spawned:
		var first: EnemyBase = game.enemies.get_child(0)
		var second: EnemyBase = game.enemies.get_child(1)
		check(first.distance - second.distance >= first.get_length() - 2.0, "대형 함선은 서로 겹치지 않게 간격 유지")
	await end_game(game)

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
	# 최종 보스를 놓치면 패배하므로 나오는 대로 처치한다
	var kill_all := func():
		for enemy: EnemyBase in get_tree().get_nodes_in_group("enemy"):
			enemy.take_damage(enemy.hp)
		return GameState.is_over
	var cleared := await wait_until(kill_all, 60 * 60)
	check(cleared, "마지막 웨이브 후 종료")
	check(GameState.lives > 0, "라이프가 남은 채 종료")
	check(game.hud.result_label.text == "CLEAR", "클리어 문구")
	check(manager.state == WaveManager.State.FINISHED, "웨이브 진행 종료")
	await end_game(game)
