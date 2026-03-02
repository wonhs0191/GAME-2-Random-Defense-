extends Node2D

signal wave_started

# 유닛들이 저장된 폴더 경로 (기본값: res://Units)
@export_dir var unit_folder_path: String = "res://unit"

# 동적으로 로드된 유닛 리스트
var loaded_units: Array[PackedScene] = []

func _ready():
    
	# 하위 노드인 background를 찾아서 GameSetting에 저장된 텍스처를 적용
	var background_node = $background
	if background_node:
		background_node.texture = GameSetting.selected_theme_texture
	
	# 난이도에 따라 맵 인스턴스화
	var map_node = $map
	if map_node:
		var map_scene_path = ""
		
		match GameSetting.selected_difficulty:
			"Easy":
				map_scene_path = "res://game_play/maps/easy.tscn"
			"Normal":
				map_scene_path = "res://game_play/maps/normal.tscn"
			"Hard":
				pass
			"Extreme":
				pass
		
		if map_scene_path != "":
			var map_scene = load(map_scene_path)
			if map_scene:
				var map_instance = map_scene.instantiate()
				map_node.add_child(map_instance)
				#! 디버깅: 노드 트리 구조 출력
				#! print("=== 노드 트리 구조 ===")
				#! print_tree()
				#! print("===================")
	
	_load_units_dynamically()

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

func _on_wave_start_pressed():
	wave_started.emit()

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
