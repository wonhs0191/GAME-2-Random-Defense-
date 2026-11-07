extends Node

# 개발 시나리오 9개 Epic을 실제 씬 전환으로 따라간다. 버튼은 pressed 시그널로 눌러 씬의 연결까지 확인한다.
# 사용: Godot --headless --path . --fixed-fps 60 res://tests/scenario_test.tscn
# 마지막에 Quit 버튼으로 종료되므로 끝까지 가면 프로세스가 스스로 끝난다.

const TITLE := "res://scenes/title/title_screen.tscn"

# 씬이 바뀌어도 살아 있도록 root 아래에서 돈다.
class Runner extends Node:
	var failures := 0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		await run()

	func check(condition: bool, label: String) -> void:
		print("OK   " if condition else "FAIL ", label)
		if not condition:
			failures += 1

	func frames(count: int) -> void:
		for i in count:
			await get_tree().process_frame

	func current() -> Node:
		return get_tree().current_scene

	func wait_scene(scene_name: String) -> bool:
		for i in 300:
			if current() != null and current().name == scene_name:
				await frames(3)
				return true
			await get_tree().process_frame
		return false

	func press(path: String) -> void:
		current().get_node(path).pressed.emit()

	func start_game(difficulty_button: String) -> void:
		press("Buttons/start_button")
		check(await wait_scene("Playsetup"), "난이도 선택 화면")
		press("Difficulty/HBoxContainer/" + difficulty_button)
		press("Theme/GridContainer/Theme2")
		press("Start")
		check(await wait_scene("GamePlay"), "게임 화면")
		check(current().get_node("background").texture != null, "테마 적용")
		current().augments.draws_until_offer = 1000000

	func play_some(game: Node) -> void:
		GameState.add_gold(500)
		for i in 8:
			game.hud._on_gacha_button_pressed()
		await frames(2)
		check(game.units.get_child_count() == 8, "뽑기")
		game.hud._on_wave_button_pressed()
		check(game.wave_manager.wave == 1, "웨이브 시작")
		await frames(120)
		check(game.enemies.get_child_count() > 0, "적 등장")

	func run() -> void:
		await frames(5)

		print("--- Epic 1 Title Screen")
		get_tree().change_scene_to_file(TITLE)
		check(await wait_scene("TitleScreen"), "타이틀 화면")
		check(Sound.current_bgm == "title", "타이틀 BGM")
		check(current().get_node("tagline").text != "", "세계관 문구")

		print("--- Epic 2 Play-1")
		await start_game("Degree1")
		var game := current()
		await play_some(game)
		game.ultimates.use()
		check(not game.ultimates.can_use(), "필살기 사용")

		print("--- Epic 3 Pause 후 타이틀")
		game.hud.get_node("TopBar/PauseButton").pressed.emit()
		check(get_tree().paused, "일시 정지")
		game.hud.get_node("PauseMenu/TitleButton").pressed.emit()
		check(await wait_scene("TitleScreen"), "타이틀로 복귀")
		check(not get_tree().paused, "정지 해제")
		check(Engine.time_scale == 1.0, "배속 초기화")

		print("--- Epic 4 Setting")
		press("Buttons/setting_button")
		var panel: ColorRect = current().get_node("SettingPanel")
		check(panel.visible, "설정 열기")
		var saved_bgm := Settings.bgm_volume
		panel.bgm_slider.value = 0.3
		check(Settings.bgm_volume == 0.3, "슬라이더로 음량 변경")
		panel.get_node("CloseButton").pressed.emit()
		check(not panel.visible, "설정 닫기")
		Settings.bgm_volume = saved_bgm
		Settings.save_settings()

		print("--- Epic 5 Play-2")
		await start_game("Degree2")
		game = current()
		await play_some(game)

		print("--- Epic 6 Gameover")
		GameState.lose_lives(GameState.lives)
		await frames(2)
		check(game.hud.result_panel.visible and game.hud.result_label.text == "GAME OVER", "게임오버 화면")
		game.hud.get_node("ResultPanel/RetryButton").pressed.emit()
		await frames(10)
		check(await wait_scene("GamePlay"), "다시하기")
		check(not get_tree().paused, "다시하기 후 정지 해제")
		check(GameState.lives > 0 and not GameState.is_over, "다시하기 후 상태 초기화")
		check(current() != game, "새 게임 씬")

		print("--- Epic 7 Play-3")
		game = current()
		game.augments.draws_until_offer = 1000000
		await play_some(game)

		print("--- Epic 8 Clear")
		var manager: WaveManager = game.wave_manager
		manager.total_waves = 2
		manager._spawn_queue.clear()
		manager.state = WaveManager.State.WAITING
		manager.start_next_wave()
		for i in 60 * 60:
			if GameState.is_over:
				break
			for enemy: EnemyBase in get_tree().get_nodes_in_group("enemy"):
				enemy.take_damage(enemy.hp)
			await get_tree().process_frame
		await frames(2)
		check(game.hud.result_label.text == "CLEAR", "클리어 화면")
		game.hud.get_node("ResultPanel/TitleButton").pressed.emit()
		check(await wait_scene("TitleScreen"), "클리어 후 타이틀")

		print("--- Epic 9 Quit")
		print("SCENARIO RESULT failures=%d" % failures)
		press("Buttons/quit_button")

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Runner.new())
