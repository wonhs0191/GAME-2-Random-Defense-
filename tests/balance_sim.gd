extends Node

# 밸런스 확인용 봇 플레이. 골드가 생기는 대로 뽑아 경로를 가장 많이 덮는 칸으로 옮긴다.
# 사용: Godot --headless --path . --fixed-fps 60 res://tests/balance_sim.tscn

const GAME_SCENE := preload("res://scenes/game/game_play.tscn")
const RUNS_PER_DIFFICULTY := 2
const COVERAGE_RANGE := 176.0
const COVERAGE_STEP := 16.0

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
	manager.start_next_wave()
	while not GameState.is_over:
		while game.draw_unit():
			_move_to_best_cell(game, coverage)
		if lost_wave == 0 and GameState.lives < lives_before:
			lost_wave = manager.wave
		frames += 1
		await get_tree().process_frame

	print("%s wave %d/%d first_leak %d lives %d units %d gold %d time %.1fmin %s" % [
		difficulty, manager.wave, manager.total_waves, lost_wave, GameState.lives,
		game.units.get_child_count(), GameState.gold, frames / 3600.0,
		"CLEAR" if GameState.lives > 0 else "LOSE",
	])
	get_tree().paused = false
	game.queue_free()
	await get_tree().process_frame

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
