extends Node

# data/ 아래 tres를 읽어 유닛·적 목록을 만든다.
# 폴더에 tres만 추가하면 게임에 반영된다 (COMMON-006 행성 추가 용이성).

const UNIT_DIR := "res://data/units"
const ENEMY_DIR := "res://data/enemies"

var units: Array[UnitData] = []
var enemies: Dictionary = {} # id -> EnemyData

func _ready() -> void:
	for resource in _load_dir(UNIT_DIR):
		units.append(resource)
	for resource in _load_dir(ENEMY_DIR):
		enemies[resource.id] = resource

func _load_dir(path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var file_names := DirAccess.get_files_at(path)
	file_names.sort()
	for file_name in file_names:
		# export 빌드에서는 tres가 .remap으로 바뀌어 보인다
		file_name = file_name.trim_suffix(".remap")
		if file_name.ends_with(".tres"):
			resources.append(load(path.path_join(file_name)))
	return resources

func get_enemy(faction: String, ship: String) -> EnemyData:
	return enemies.get("%s_%s" % [faction, ship])

func pick_random_unit() -> UnitData:
	return units.pick_random()
