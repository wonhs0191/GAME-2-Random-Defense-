extends Node
class_name WaveManager

# 웨이브 진행을 담당한다. 맵 씬은 경로만 가지고, 무엇이 언제 나오는지는 여기서 정한다.
#
# WAITING(첫 웨이브 대기) → SPAWNING → FIGHTING → PREP(준비) → SPAWNING ... → FINISHED

signal state_changed(state: State)
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal all_waves_cleared

enum State { WAITING, PREP, SPAWNING, FIGHTING, FINISHED }

const ENEMY_SCENE := preload("res://entities/enemies/enemy.tscn")

# 함선별 첫 등장 웨이브
const SHIP_UNLOCK_WAVE := {
	"scout": 1, "fighter": 2, "bomber": 5, "torpedo": 9,
	"frigate": 13, "support": 17, "battlecruiser": 21,
}
const RECENT_SHIP_COUNT := 3 # 최근 해금된 함선 N종 중에서 뽑는다

@export var prep_time: float = 15.0
@export var spawn_interval: float = 0.9

var state: State = State.WAITING
var wave: int = 0
var total_waves: int = 1
var prep_left: float = 0.0
var faction: String = "nautolan"

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

# 대기·준비 중에 다음 웨이브를 바로 시작한다.
func start_next_wave() -> void:
	if state != State.WAITING and state != State.PREP:
		return
	wave += 1
	_spawn_queue = build_wave(wave)
	_spawn_timer = 0.0
	wave_started.emit(wave)
	_set_state(State.SPAWNING)

# n번째 웨이브에 나올 적 목록을 만든다.
func build_wave(wave_number: int) -> Array[EnemyData]:
	var ships: Array[String] = []
	for ship in SHIP_UNLOCK_WAVE:
		if SHIP_UNLOCK_WAVE[ship] <= wave_number:
			ships.append(ship)
	var recent := ships.slice(-RECENT_SHIP_COUNT)
	var count := int(round((6 + wave_number * 1.2) * _difficulty["count"]))
	var list: Array[EnemyData] = []
	for i in count:
		list.append(Catalog.get_enemy(faction, recent.pick_random()))
	return list

func _process(delta: float) -> void:
	match state:
		State.PREP:
			prep_left -= delta
			if prep_left <= 0.0:
				start_next_wave()
		State.SPAWNING:
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				_spawn_timer += spawn_interval
				_spawn_enemy(_spawn_queue.pop_front())
				if _spawn_queue.is_empty():
					_set_state(State.FIGHTING)
		State.FIGHTING:
			if get_tree().get_nodes_in_group("enemy").is_empty():
				_finish_wave()

func _spawn_enemy(enemy_data: EnemyData) -> void:
	var enemy: EnemyBase = ENEMY_SCENE.instantiate()
	enemy.setup(enemy_data, _paths.pick_random(), _difficulty["speed"])
	_enemy_parent.add_child(enemy)

func _finish_wave() -> void:
	wave_cleared.emit(wave)
	if wave >= total_waves:
		_set_state(State.FINISHED)
		all_waves_cleared.emit()
	else:
		prep_left = prep_time
		_set_state(State.PREP)

func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(state)
