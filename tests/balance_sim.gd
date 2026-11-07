extends Node

# 밸런스 확인용 봇 플레이. 뽑아서 경로를 가장 많이 덮는 칸으로 옮기고, 칸이 거의 차면
# 골드를 모아 같은 유닛을 합치고 높은 등급부터 강화한다.
# 사용: Godot --headless --path . --fixed-fps 60 res://tests/balance_sim.tscn

const GAME_SCENE := preload("res://scenes/game/game_play.tscn")
const RUNS_PER_DIFFICULTY := 2
const COVERAGE_RANGE := 176.0
const COVERAGE_STEP := 16.0
const CROWDED_FREE_CELLS := 8 # 빈 칸이 이 수 이하면 뽑기 대신 조합과 강화에 쓴다

func _ready() -> void:
	for difficulty in ["Easy", "Normal", "Hard", "Extreme"]:
		for run in RUNS_PER_DIFFICULTY:
			await _play(difficulty)
	get_tree().quit()

func _play(difficulty: String) -> void:
	GameSetting.selected_difficulty = difficulty
	var game: Node2D = GAME_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	var coverage := _build_coverage(game)
	var manager: WaveManager = game.wave_manager
	var frames := 0
	var lost_wave := 0
	var lives_before := GameState.lives
	var boss_damage: int = Catalog.get_enemy("nautolan", WaveManager.BOSS_SHIP).life_damage
	var boss_leaks := 0
	var lives_last := GameState.lives
	manager.start_next_wave()
	while not GameState.is_over:
		var saving := false
		if _is_crowded(game.grid):
			saving = _merge_duplicates(game, coverage)
			saving = _upgrade_best_unit(game, saving) or saving
		while not saving and game.draw_unit():
			_move_to_best_cell(game, coverage)
		frames += 1
		await get_tree().process_frame
		# 프레임을 진행한 뒤에 봐야 게임이 끝나는 프레임의 누수도 센다
		if lost_wave == 0 and GameState.lives < lives_before:
			lost_wave = manager.wave
		# 한 프레임에 보스 피해만큼 줄었으면 보스가 경로 끝에 닿은 것이다
		if lives_last - GameState.lives >= boss_damage:
			boss_leaks += 1
		lives_last = GameState.lives

	var grades := [0, 0, 0, 0]
	for unit: UnitBase in game.grid.grid_status.values():
		grades[unit.data.grade] += 1
	print("%s wave %d/%d first_leak %d boss_leaks %d lives %d units C%d B%d A%d S%d gold %d time %.1fmin %s" % [
		difficulty, manager.wave, manager.total_waves, lost_wave, boss_leaks, GameState.lives,
		grades[0], grades[1], grades[2], grades[3], GameState.gold, frames / 3600.0,
		"CLEAR" if GameState.lives > 0 else "LOSE",
	])
	get_tree().paused = false
	game.queue_free()
	await get_tree().process_frame

func _is_crowded(grid: GridManager) -> bool:
	return grid.grid_size.x * grid.grid_size.y - grid.blocked_cells.size() - grid.grid_status.size() <= CROWDED_FREE_CELLS

# 같은 유닛이 있으면 경로를 더 많이 덮는 칸으로 합친다. 비용이 모자란 조합이 남았으면 true.
func _merge_duplicates(game: Node2D, coverage: Dictionary) -> bool:
	var grid: GridManager = game.grid
	var seen := {} # id -> 칸
	var short_of_gold := false
	for cell: Vector2i in grid.grid_status.keys():
		var unit: UnitBase = grid.grid_status[cell]
		if unit.data.grade == UnitData.Grade.S:
			continue
		if not seen.has(unit.data.id):
			seen[unit.data.id] = cell
			continue
		if GameState.gold < unit.data.merge_cost():
			short_of_gold = true
			continue
		var other: Vector2i = seen[unit.data.id]
		var from: Vector2i = cell if coverage[cell] <= coverage[other] else other
		var to: Vector2i = other if from == cell else cell
		grid.pick_unit(from, grid.cell_center(from))
		grid.drop_unit_at(to)
		seen.erase(unit.data.id)
	return short_of_gold

# 가장 높은 등급 유닛을 강화한다. 강화할 골드를 모으는 중이면 true.
func _upgrade_best_unit(game: Node2D, saving: bool) -> bool:
	var grid: GridManager = game.grid
	var best: UnitBase = null
	for unit: UnitBase in grid.grid_status.values():
		if unit.can_upgrade() and (best == null or unit.data.grade > best.data.grade):
			best = unit
	if saving or best == null:
		return false
	if GameState.gold < best.data.upgrade_cost(best.stars):
		return true
	game.upgrade_unit(best)
	return false

# 칸마다 사거리 안에 들어오는 경로 길이를 센다.
func _build_coverage(game: Node2D) -> Dictionary:
	var grid: GridManager = game.grid
	var points: Array[Vector2] = []
	for path: Path2D in game.paths:
		var offset := 0.0
		while offset <= path.curve.get_baked_length():
			points.append(path.to_global(path.curve.sample_baked(offset)))
			offset += COVERAGE_STEP

	var coverage := {}
	for x in grid.grid_size.x:
		for y in grid.grid_size.y:
			var cell := Vector2i(x, y)
			var center := grid.cell_center(cell)
			var count := 0
			for point in points:
				if center.distance_to(point) <= COVERAGE_RANGE:
					count += 1
			coverage[cell] = count
	return coverage

func _move_to_best_cell(game: Node2D, coverage: Dictionary) -> void:
	var grid: GridManager = game.grid
	var best := GridManager.NO_CELL
	for cell: Vector2i in coverage:
		if grid.is_cell_empty(cell) and (best == GridManager.NO_CELL or coverage[cell] > coverage[best]):
			best = cell
	if best == GridManager.NO_CELL:
		return
	var unit: UnitBase = game.units.get_child(-1)
	grid.pick_unit(grid.world_to_grid(unit.global_position), unit.global_position)
	grid.drop_unit_at(best)
