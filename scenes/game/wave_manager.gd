extends Node
class_name WaveManager

# 웨이브 진행을 담당한다. 맵 씬은 경로만 가지고, 무엇이 언제 나오는지는 여기서 정한다.
#
# WAITING(첫 웨이브 대기) → SPAWNING → FIGHTING → PREP(준비) → SPAWNING ... → FINISHED

signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal all_waves_cleared
signal enemy_destroyed(enemy: EnemyBase)

enum State { WAITING, PREP, SPAWNING, FIGHTING, FINISHED }

const ENEMY_SCENE := preload("res://entities/enemies/enemy.tscn")

# 함선별 첫 등장 웨이브
const SHIP_UNLOCK_WAVE := {
	"scout": 1, "fighter": 2, "bomber": 5, "torpedo": 9,
	"frigate": 13, "support": 17, "battlecruiser": 21,
}
const RECENT_SHIP_COUNT := 3 # 최근 해금된 함선 N종 중에서 뽑는다

# 전체 웨이브를 세력 수로 나눠 차례로 등장한다
const FACTIONS := ["nautolan", "klaed", "nairan"]

const BOSS_SHIP := "dreadnought"
const BOSS_INTERVAL := 10
const BOSS_HP_SCALE := 2.0
const FINAL_BOSS_HP_SCALE := 3.0
const FINAL_BOSS_SIZE_SCALE := 1.5
const BOSS_ESCORT_SCALE := 0.5 # 보스 웨이브의 호위 함선 수 배율

@export var prep_time: float = 15.0
@export var spawn_interval: float = 0.9

var state: State = State.WAITING
var wave: int = 0
var total_waves: int = 1
var prep_left: float = 0.0

var _paths: Array[Path2D] = []
var _enemy_parent: Node = null
var _difficulty: Dictionary = {}
var _spawn_queue: Array[EnemyData] = []
var _spawn_timer: float = 0.0

func setup(paths: Array[Path2D], enemy_parent: Node, difficulty: Dictionary) -> void:
	_paths = paths
	_enemy_parent = enemy_parent
	_difficulty = difficulty
	total_waves = difficulty["waves"]

func can_start_wave() -> bool:
	return state == State.WAITING or state == State.PREP

# 대기·준비 중에 다음 웨이브를 바로 시작한다.
func start_next_wave() -> void:
	if not can_start_wave():
		return
	wave += 1
	_spawn_queue = build_wave(wave)
	_spawn_timer = 0.0
	wave_started.emit(wave)
	state = State.SPAWNING

# n번째 웨이브에 나올 적 목록을 만든다.
func build_wave(wave_number: int) -> Array[EnemyData]:
	var ships: Array[String] = []
	for ship in SHIP_UNLOCK_WAVE:
		if SHIP_UNLOCK_WAVE[ship] <= wave_number:
			ships.append(ship)
	var recent := ships.slice(-RECENT_SHIP_COUNT)
	var faction := faction_for_wave(wave_number)
	var boss_wave := is_boss_wave(wave_number)
	var count: float = (6 + wave_number * 1.2) * _difficulty["count"]
	if boss_wave:
		count *= BOSS_ESCORT_SCALE
	var list: Array[EnemyData] = []
	for i in int(round(count)):
		list.append(Catalog.get_enemy(faction, recent.pick_random()))
	# 호위를 앞세우고 보스는 맨 뒤에 나온다
	if boss_wave:
		list.append(Catalog.get_enemy(faction, BOSS_SHIP))
	return list

# n번째 웨이브에 등장하는 세력.
func faction_for_wave(wave_number: int) -> String:
	return FACTIONS[(wave_number - 1) * FACTIONS.size() / total_waves]

func is_final_wave(wave_number: int) -> bool:
	return wave_number == total_waves

func is_boss_wave(wave_number: int) -> bool:
	return wave_number > 0 and (wave_number % BOSS_INTERVAL == 0 or is_final_wave(wave_number))

# n번째 웨이브의 체력 배율.
func hp_scale(wave_number: int) -> float:
	var step := wave_number - 1
	return _difficulty["hp"] * (1.0 + 0.15 * step + 0.01 * step * step)

# n번째 웨이브 보스의 체력 배율.
func boss_hp_scale(wave_number: int) -> float:
	return hp_scale(wave_number) * (FINAL_BOSS_HP_SCALE if is_final_wave(wave_number) else BOSS_HP_SCALE)

func _process(delta: float) -> void:
	match state:
		State.PREP:
			prep_left -= delta
			if prep_left <= 0.0:
				start_next_wave()
		State.SPAWNING:
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				var enemy := _spawn_enemy(_spawn_queue.pop_front())
				# 큰 함선은 같은 속도로 줄지어 겹치므로 앞 함선이 지나갈 시간만큼 기다린다
				_spawn_timer += maxf(spawn_interval, enemy.get_length() / enemy.speed)
				if _spawn_queue.is_empty():
					state = State.FIGHTING
		State.FIGHTING:
			if get_tree().get_nodes_in_group("enemy").is_empty():
				_finish_wave()

func _spawn_enemy(enemy_data: EnemyData) -> EnemyBase:
	var enemy: EnemyBase = ENEMY_SCENE.instantiate()
	var is_boss := enemy_data.ship == BOSS_SHIP
	var enemy_hp_scale := boss_hp_scale(wave) if is_boss else hp_scale(wave)
	var is_final_boss := is_boss and is_final_wave(wave)
	var size_scale := FINAL_BOSS_SIZE_SCALE if is_final_boss else 1.0
	enemy.setup(enemy_data, _paths.pick_random(), enemy_hp_scale, _difficulty["speed"], size_scale)
	enemy.is_final_boss = is_final_boss
	enemy.destroyed.connect(enemy_destroyed.emit)
	_enemy_parent.add_child(enemy)
	return enemy

func _finish_wave() -> void:
	wave_cleared.emit(wave)
	if wave >= total_waves:
		state = State.FINISHED
		all_waves_cleared.emit()
	else:
		prep_left = prep_time
		state = State.PREP
