extends Node

# 후반 전투 부하 측정. 유닛을 격자에 채우고 후반 웨이브를 돌려 프레임당 처리 시간을 잰다.
# 사용: Godot --headless --path . --fixed-fps 60 res://tests/perf_test.tscn

const GAME_SCENE := preload("res://scenes/game/game_play.tscn")
const UNIT_COUNT := 110
const WARMUP_FRAMES := 300
const SAMPLE_FRAMES := 3000
const BURST_EVERY_FRAMES := 240 # 스폰이 몰릴 때의 프레임 끊김도 본다
const BURST_SIZE := 40

func _ready() -> void:
	GameSetting.selected_difficulty = "Extreme"
	var game: Node2D = GAME_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.augments.draws_until_offer = 1000000
	GameState.lose_lives(0)

	var grid: GridManager = game.grid
	var placed := 0
	for x in grid.grid_size.x:
		for y in grid.grid_size.y:
			var cell := Vector2i(x, y)
			if placed < UNIT_COUNT and grid.is_cell_empty(cell):
				game.spawn_unit(Catalog.units_of_grade(placed % 4)[0], cell)
				placed += 1

	# 적이 금방 죽으면 부하가 안 잡히므로 웨이브를 키우고 체력을 올려 화면에 오래 남긴다
	var manager: WaveManager = game.wave_manager
	manager._difficulty = manager._difficulty.duplicate()
	manager._difficulty["hp"] = 40.0
	manager._difficulty["count"] = 3.0
	manager.spawn_interval = 0.2
	manager.wave = 34
	manager.start_next_wave()
	for i in WARMUP_FRAMES:
		await get_tree().process_frame

	var samples: Array[int] = []
	var peak_enemies := 0
	var last := Time.get_ticks_usec()
	for i in SAMPLE_FRAMES:
		if i % BURST_EVERY_FRAMES == 0:
			for j in BURST_SIZE:
				manager._spawn_enemy(Catalog.get_enemy("nautolan", "scout"))
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		samples.append(now - last)
		last = now
		peak_enemies = maxi(peak_enemies, get_tree().get_nodes_in_group("enemy").size())
		if manager.can_start_wave():
			manager.start_next_wave()
		GameState.lives = 10
	samples.sort()
	var total := 0
	for sample in samples:
		total += sample
	print("PERF units %d peak_enemies %d avg %.2fms p99 %.2fms max %.2fms" % [
		placed, peak_enemies, total / 1000.0 / samples.size(),
		samples[int(samples.size() * 0.99)] / 1000.0, samples[-1] / 1000.0,
	])
	get_tree().quit()
