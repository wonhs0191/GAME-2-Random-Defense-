extends Node2D

const UNIT_SCENE := preload("res://entities/units/unit.tscn")
const TITLE_SCENE := "res://scenes/title/title_screen.tscn"

# 난이도별 맵. Hard부터 경로가 분기한다.
const MAP_SCENES := {
	"Easy": "res://scenes/game/maps/easy.tscn",
	"Normal": "res://scenes/game/maps/normal.tscn",
	"Hard": "res://scenes/game/maps/hard.tscn",
	"Extreme": "res://scenes/game/maps/extreme.tscn",
}

const PATH_COLOR := Color(1, 1, 1, 0.12)
const PATH_WIDTH := 40.0
const DEATH_BURST_RADIUS := 28.0
const DEATH_BURST_COLOR := Color(1.0, 0.7, 0.3)
const SHAKE_STRENGTH := 6.0
const SHAKE_TIME := 0.25
const FACTION_NAMES := {"nautolan": "Nautolan", "klaed": "Kla'ed", "nairan": "Nairan"}

# 웨이브 클리어 보상 = 기본 + 웨이브 번호 × 증가량
const WAVE_REWARD_BASE := 10
const WAVE_REWARD_STEP := 2

var paths: Array[Path2D] = []
var selected_unit: UnitBase = null

var _lives: int = 0
var _faction: String = ""
var _shake_tween: Tween = null

@onready var grid: GridManager = $Grid
@onready var zones: Node2D = $Zones
@onready var units: Node2D = $Units
@onready var enemies: Node2D = $Enemies
@onready var effects: Node2D = $Effects
@onready var wave_manager: WaveManager = $WaveManager
@onready var augments: AugmentManager = $AugmentManager
@onready var ultimates: UltimateManager = $UltimateManager
@onready var hud: CanvasLayer = $HUD

func _ready():
	# 하위 노드인 background를 찾아서 GameSetting에 저장된 텍스처를 적용
	$background.texture = GameSetting.selected_theme_texture

	var difficulty := GameSetting.get_difficulty()
	paths = _load_map()
	for path in paths:
		grid.block_path(path)
	_show_paths()

	GameState.reset(difficulty["lives"])
	wave_manager.setup(paths, enemies, difficulty)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	wave_manager.all_waves_cleared.connect(GameState.end_game.bind(true))
	GameState.game_ended.connect(_on_game_ended)
	_lives = GameState.lives
	GameState.lives_changed.connect(_on_lives_changed)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.enemy_destroyed.connect(_on_enemy_destroyed)

	ultimates.setup(wave_manager, effects)
	augments.setup(grid, ultimates)
	hud.setup(wave_manager, augments, ultimates)
	hud.wave_start_pressed.connect(wave_manager.start_next_wave)
	hud.gacha_pressed.connect(draw_unit)
	hud.upgrade_pressed.connect(_on_upgrade_pressed)
	grid.merge_requested.connect(merge_units)
	grid.merge_unaffordable.connect(hud.show_merge_unaffordable)
	grid.unit_clicked.connect(select_unit)
	hud.title_requested.connect(_on_title_requested)
	Sound.play_bgm("battle")
	hud.augment_chosen.connect(augments.choose)
	hud.ultimate_pressed.connect(ultimates.use)
	ultimates.used.connect(hud.show_ultimate)
	augments.offered.connect(hud.show_augment_cards)
	augments.placement_started.connect(hud.show_placement_hint)
	augments.closed.connect(_on_augments_closed)

# 난이도에 따라 맵을 인스턴스화하고 경로 목록을 돌려준다
func _load_map() -> Array[Path2D]:
	var map_scene_path: String = MAP_SCENES.get(GameSetting.selected_difficulty, MAP_SCENES["Easy"])
	var map_instance: Node = load(map_scene_path).instantiate()
	$map.add_child(map_instance)

	var found: Array[Path2D] = []
	for child in map_instance.get_children():
		if child is Path2D:
			found.append(child)
	return found

# 경로가 겹치는 구간이 진해지지 않도록 그룹으로 묶어 한 번에 반투명을 입힌다
func _show_paths() -> void:
	var group := CanvasGroup.new()
	group.self_modulate = PATH_COLOR
	$map.add_child(group)
	for path in paths:
		var line := Line2D.new()
		# 베이크된 점을 쓰면 모서리에 불필요한 점이 많아지므로 제어점만 잇는다
		for i in path.curve.point_count:
			line.add_point(path.to_global(path.curve.get_point_position(i)))
		line.width = PATH_WIDTH
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		group.add_child(line)

# 골드를 내고 화면 중앙 가까운 빈 칸에 유닛을 뽑는다. 뽑았으면 true.
func draw_unit() -> bool:
	if augments.is_busy():
		return false
	# 화면(Viewport)의 정중앙 기준으로 가까운 빈 칸을 찾는다
	var target_cell := grid.find_spawn_cell(get_viewport_rect().size / 2)
	if target_cell == GridManager.NO_CELL:
		return false
	if not GameState.spend_gold(GameState.GACHA_COST):
		return false
	Sound.play("gacha")
	_reveal(spawn_unit(Catalog.pick_random_unit(), target_cell))
	augments.on_unit_drawn()
	return true

func spawn_unit(unit_data: UnitData, cell: Vector2i) -> UnitBase:
	var new_unit: UnitBase = UNIT_SCENE.instantiate()
	new_unit.setup(unit_data, self)
	units.add_child(new_unit)

	# (핵심) GridManager에게 새로 생성된 유닛을 던져주어 알아서 배치하게 만듦
	grid.add_new_unit(new_unit, cell)
	return new_unit

func _reveal(unit: UnitBase) -> void:
	unit.pop_in()
	var burst := RevealBurst.new()
	burst.setup(UnitData.GRADE_COLORS[unit.data.grade], RevealBurst.RADIUS_BY_GRADE[unit.data.grade])
	burst.position = unit.position
	effects.add_child(burst)
	hud.show_reveal(unit.data)
	Sound.play("reveal_" + unit.data.get_grade_name().to_lower())

# 골드를 내고 같은 유닛 2개를 없애 target 자리에 상위 등급 유닛을 랜덤으로 만든다.
func merge_units(moved: UnitBase, target: UnitBase) -> void:
	GameState.spend_gold(target.data.merge_cost())
	if selected_unit == moved or selected_unit == target:
		select_unit(null)
	var cell: Vector2i = grid.grid_status.find_key(target)
	var next_grade: UnitData.Grade = target.data.grade + 1
	grid.unregister_unit(cell)
	moved.queue_free()
	target.queue_free()
	Sound.play("merge")
	_reveal(spawn_unit(Catalog.pick_unit_of_grade(next_grade), cell))

func select_unit(unit: UnitBase) -> void:
	selected_unit = unit
	grid.selected_unit = unit
	hud.show_unit(unit)

# 골드를 내고 강화를 시도한다. 실패해도 골드는 돌아오지 않는다. 별이 올랐으면 true.
func upgrade_unit(unit: UnitBase, roll: float = randf()) -> bool:
	if not unit.can_upgrade() or not GameState.spend_gold(unit.data.upgrade_cost(unit.stars)):
		return false
	var succeeded: bool = roll < UnitData.UPGRADE_CHANCE[unit.stars - 1]
	if succeeded:
		unit.add_star()
	hud.show_upgrade_result(succeeded)
	Sound.play("upgrade_success" if succeeded else "upgrade_fail")
	if selected_unit == unit:
		hud.show_unit(unit)
	return succeeded

func _on_upgrade_pressed() -> void:
	upgrade_unit(selected_unit)

func _on_wave_started(wave: int) -> void:
	var boss_wave := wave_manager.is_boss_wave(wave)
	Sound.play("boss_warning" if boss_wave else "wave_start")
	Sound.play_bgm("boss" if boss_wave else "battle")
	var faction := wave_manager.faction_for_wave(wave)
	if boss_wave:
		hud.show_boss_warning(wave_manager.is_final_wave(wave))
	elif faction != _faction:
		hud.show_faction(FACTION_NAMES[faction])
	_faction = faction

func _on_enemy_destroyed(enemy: EnemyBase) -> void:
	var burst := RevealBurst.new()
	burst.setup(DEATH_BURST_COLOR, DEATH_BURST_RADIUS)
	burst.position = enemy.global_position
	effects.add_child(burst)
	Sound.play("enemy_die")

func _on_lives_changed(lives: int) -> void:
	if lives < _lives:
		Sound.play("life_lost")
		_shake_screen()
	_lives = lives

# 노드는 그대로 두고 화면만 흔들어 좌표 계산에 영향을 주지 않는다.
func _shake_screen() -> void:
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_shake_tween.tween_method(_apply_shake, SHAKE_STRENGTH, 0.0, SHAKE_TIME)

func _apply_shake(strength: float) -> void:
	var offset := Vector2.from_angle(randf() * TAU) * strength
	get_viewport().canvas_transform = Transform2D(0.0, offset)

func _exit_tree() -> void:
	# 배속과 화면 흔들림은 씬 밖까지 남으므로 되돌린다
	Engine.time_scale = 1.0
	get_viewport().canvas_transform = Transform2D.IDENTITY

func _on_title_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)

func _on_wave_cleared(wave: int) -> void:
	GameState.add_gold(WAVE_REWARD_BASE + wave * WAVE_REWARD_STEP)
	Sound.play_bgm("battle")
	if wave_manager.is_final_wave(wave):
		return
	if wave_manager.is_boss_wave(wave):
		augments.request_offer()
	if wave % UltimateManager.SWAP_INTERVAL == 0:
		augments.request_ultimate_offer()

func _on_augments_closed() -> void:
	hud.hide_augment_ui()
	hud.show_unit(selected_unit)

func _on_game_ended(cleared: bool) -> void:
	get_tree().paused = true
	Sound.stop_bgm()
	Sound.play("clear" if cleared else "gameover")
