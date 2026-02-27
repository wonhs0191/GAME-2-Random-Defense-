extends Node2D

# 유닛들이 저장된 폴더 경로 (기본값: res://Units)
@export_dir var unit_folder_path: String = "res://unit"

# 동적으로 로드된 유닛 리스트
var loaded_units: Array[PackedScene] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_load_units_dynamically()
	print(loaded_units)

func _process(delta):
	pass

# 유닛 폴더 하위의 PRD-*로 시작되는 씬들을 자동으로 로드하여 리스트에 추가
func _load_units_dynamically():
	_scan_recursive(unit_folder_path)

# 재귀적으로 폴더를 탐색하는 함수
func _scan_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				# . (현재폴더) .. (상위폴더)가 아닌 경우에만 재귀 호출 (무한루프 방지)
				if file_name != "." and file_name != "..":
					_scan_recursive(path.path_join(file_name))
			else:
				# PRD-로 시작하고 .tscn 확장자를 가진 파일만 로드
				if file_name.to_lower().begins_with("prd_") and file_name.ends_with(".tscn"):
					var full_path = path.path_join(file_name)
					var scene = load(full_path)
					if scene is PackedScene:
						loaded_units.append(scene)
			file_name = dir.get_next()

func _on_button_pressed():
	var scene_to_spawn: PackedScene = null
	if not loaded_units.is_empty():
		scene_to_spawn = loaded_units.pick_random()
		
	if scene_to_spawn:
		var new_unit = scene_to_spawn.instantiate()
		add_child(new_unit)
		
		# 화면(Viewport)의 크기를 가져와 정중앙 좌표 계산
		var viewport_size = get_viewport_rect().size
		new_unit.global_position = viewport_size / 2
