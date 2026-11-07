extends Node2D

const UNIT_SCENE := preload("res://entities/units/unit.tscn")

# 난이도별 맵. 경로 분기가 필요한 Hard, Extreme은 M2에서 교체한다.
const MAP_SCENES := {
	"Easy": "res://scenes/game/maps/easy.tscn",
	"Normal": "res://scenes/game/maps/normal.tscn",
	"Hard": "res://scenes/game/maps/normal.tscn",
	"Extreme": "res://scenes/game/maps/normal.tscn",
}

const PATH_COLOR := Color(1, 1, 1, 0.12)
const PATH_WIDTH := 40.0

@onready var grid: GridManager = $Grid
@onready var units: Node2D = $Units
@onready var enemies: Node2D = $Enemies
@onready var wave_manager: WaveManager = $WaveManager

func _ready():
	# 하위 노드인 background를 찾아서 GameSetting에 저장된 텍스처를 적용
	$background.texture = GameSetting.selected_theme_texture

	var paths := _load_map()
	for path in paths:
		grid.block_path(path)
		_show_path(path)
	wave_manager.setup(paths, enemies, GameSetting.get_difficulty())

# 난이도에 따라 맵을 인스턴스화하고 경로 목록을 돌려준다
func _load_map() -> Array[Path2D]:
	var map_scene_path: String = MAP_SCENES.get(GameSetting.selected_difficulty, MAP_SCENES["Easy"])
	var map_instance: Node = load(map_scene_path).instantiate()
	$map.add_child(map_instance)

	var paths: Array[Path2D] = []
	for child in map_instance.get_children():
		if child is Path2D:
			paths.append(child)
	return paths

func _show_path(path: Path2D) -> void:
	var line := Line2D.new()
	# 베이크된 점을 쓰면 모서리에서 반투명이 겹쳐 진해지므로 제어점만 잇는다
	for i in path.curve.point_count:
		line.add_point(path.curve.get_point_position(i))
	line.width = PATH_WIDTH
	line.default_color = PATH_COLOR
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	path.add_child(line)

func _on_wave_start_pressed():
	wave_manager.start_next_wave()

func _on_button_pressed():
	# 화면(Viewport)의 정중앙 기준으로 가까운 빈 칸을 찾는다
	var center_pos = get_viewport_rect().size / 2
	var target_cell := grid.find_spawn_cell(center_pos)
	if target_cell == GridManager.NO_CELL:
		return

	var new_unit: UnitBase = UNIT_SCENE.instantiate()
	new_unit.setup(Catalog.pick_random_unit())
	units.add_child(new_unit)

	# (핵심) GridManager에게 새로 생성된 유닛을 던져주어 알아서 배치하게 만듦
	grid.add_new_unit(new_unit, target_cell)
