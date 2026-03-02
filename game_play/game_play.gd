extends Node2D

signal wave_started

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

func _on_wave_start_pressed():
	wave_started.emit()
