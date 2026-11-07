extends Node

# data/ 아래 tres를 읽어 유닛·적 목록을 만든다.
# 폴더에 tres만 추가하면 게임에 반영된다 (COMMON-006 행성 추가 용이성).

const UNIT_DIR := "res://data/units"
const ENEMY_DIR := "res://data/enemies"
const AUGMENT_DIR := "res://data/augments"

# 뽑기 등급 확률 (%)
const GRADE_ODDS := {
	UnitData.Grade.C: 80.0,
	UnitData.Grade.B: 15.0,
	UnitData.Grade.A: 4.5,
	UnitData.Grade.S: 0.5,
}

var units: Array[UnitData] = []
var enemies: Dictionary = {} # id -> EnemyData
var augments: Array[AugmentData] = []

func _ready() -> void:
	for resource in _load_dir(UNIT_DIR):
		units.append(resource)
	for resource in _load_dir(ENEMY_DIR):
		enemies[resource.id] = resource
	for resource in _load_dir(AUGMENT_DIR):
		augments.append(resource)

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

func units_of_grade(grade: UnitData.Grade) -> Array[UnitData]:
	return units.filter(func(unit: UnitData): return unit.grade == grade)

func pick_unit_of_grade(grade: UnitData.Grade) -> UnitData:
	return units_of_grade(grade).pick_random()

# 등급을 확률대로 정한 뒤 그 등급 안에서 균등하게 뽑는다.
func pick_random_unit() -> UnitData:
	var roll := randf() * 100.0
	for grade in GRADE_ODDS:
		roll -= GRADE_ODDS[grade]
		if roll < 0.0:
			return pick_unit_of_grade(grade)
	return pick_unit_of_grade(UnitData.Grade.C)
