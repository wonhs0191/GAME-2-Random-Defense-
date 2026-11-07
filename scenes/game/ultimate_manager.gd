extends Node
class_name UltimateManager

# 필살기를 담당한다. 플레이어가 버튼으로 쓰는 전역 스킬이고, 일정 웨이브마다 바꿀 수 있다.

signal used(ultimate: UltimateData)

const SWAP_INTERVAL := 5 # 이 웨이브마다 교체 카드를 제시한다
const BOSS_DAMAGE_SCALE := 1.0 / 7.0 # 유성우가 보스에게 주는 피해 비율 (35% → 5%)
const METEOR_BURST_RADIUS := 48.0

var current: UltimateData = null
var cooldown_left: float = 0.0
var overclock_left: float = 0.0

var _wave_manager: WaveManager = null
var _effects: Node = null

func setup(wave_manager: WaveManager, effects: Node) -> void:
	_wave_manager = wave_manager
	_effects = effects
	current = Catalog.ultimates.pick_random()

func equip(ultimate: UltimateData) -> void:
	current = ultimate

func can_use() -> bool:
	return cooldown_left <= 0.0

func attack_speed_bonus() -> float:
	return current.power if overclock_left > 0.0 else 0.0

func use() -> bool:
	if not can_use():
		return false
	cooldown_left = current.cooldown
	Sound.play("ultimate")
	match current.kind:
		UltimateData.Kind.METEOR:
			_rain_meteors()
		UltimateData.Kind.FREEZE:
			for enemy: EnemyBase in get_tree().get_nodes_in_group("enemy"):
				enemy.freeze(current.duration)
		UltimateData.Kind.OVERCLOCK:
			overclock_left = current.duration
		UltimateData.Kind.GOLD:
			GameState.add_gold(int(current.power * maxi(_wave_manager.wave, 1)))
	used.emit(current)
	return true

func _process(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	overclock_left = maxf(overclock_left - delta, 0.0)

# 처치로 그룹이 바뀌므로 복사본을 돈다.
func _rain_meteors() -> void:
	for enemy: EnemyBase in get_tree().get_nodes_in_group("enemy").duplicate():
		var burst := RevealBurst.new()
		burst.setup(current.get_color(), METEOR_BURST_RADIUS)
		burst.position = enemy.global_position
		_effects.add_child(burst)
		var scale := BOSS_DAMAGE_SCALE if enemy.data.ship == WaveManager.BOSS_SHIP else 1.0
		enemy.take_damage(enemy.max_hp * current.power * scale)
