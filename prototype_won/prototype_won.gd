extends Node2D

const PLANET_SCENE = preload("res://prototype_won/planet/planet_fire_1/planet_fire_1.tscn")
const EFFECT_SCENE = preload("res://prototype_won/planet/planet_fire_1/effect_1/planet_fire_effect_1.tscn")
const PLANET_2_SCENE = preload("res://prototype_won/planet/planet_fire_2/planet_fire_2.tscn")
const EFFECT_2_SCENE = preload("res://prototype_won/planet/planet_fire_2/effect_2/planet_fire_effect_2.tscn")

var planet_id_counter: int = 0
var planet_effect_map: Dictionary = {}  # planet_id -> effect_instance
var merge_distance: float = 100.0  # 합성 가능한 최대 거리

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	check_and_merge_planets()


func _on_button_pressed():
	# 버튼 참조 가져오기
	var button = $Button
	if button == null:
		return
	
	# 버튼의 글로벌 위치와 크기 가져오기
	var button_rect = button.get_rect()
	var button_global_pos = button.global_position
	
	# 버튼 오른쪽에 배치할 위치 계산 (버튼 너비만큼 오른쪽)
	var spawn_position = Vector2(
		button_global_pos.x + button_rect.size.x + 100,  # 버튼 오른쪽에 100픽셀 간격
		button_global_pos.y + button_rect.size.y / 2   # 버튼 세로 중앙
	)
	
	# Planet 인스턴스 생성
	var planet_instance = PLANET_SCENE.instantiate()
	
	# 고유 ID 부여
	planet_instance.planet_id = planet_id_counter
	planet_id_counter += 1
	
	add_child(planet_instance)
	
	# 위치 설정
	planet_instance.global_position = spawn_position
	
	# Effect 인스턴스 생성 및 Path2D 위에 랜덤 위치에 배치
	var effect_instance = EFFECT_SCENE.instantiate()
	
	# Path2D 참조 가져오기
	var path2d = $EnemyScout/Path2D
	if path2d and path2d.curve:
		# Path2D의 curve를 사용해서 랜덤한 위치 계산
		var random_progress = randf()  # 0.0 ~ 1.0 사이의 랜덤 값
		var path_length = path2d.curve.get_baked_length()
		var path_position = path2d.curve.sample_baked(path_length * random_progress)
		
		# Path2D의 글로벌 위치를 고려해서 effect의 목표 글로벌 위치 계산
		var effect_global_target = path2d.global_position + path_position
		
		# Effect를 씬에 직접 추가 (planet의 자식이 아니므로 planet을 드래그해도 움직이지 않음)
		add_child(effect_instance)
		
		# Effect 위치 설정 (고정됨)
		effect_instance.global_position = effect_global_target
		
		# Planet과 Effect 연결 저장
		planet_effect_map[planet_instance.planet_id] = effect_instance
	else:
		# Path2D를 찾을 수 없으면 그냥 planet 위치에 생성
		add_child(effect_instance)
		effect_instance.global_position = spawn_position
		
		# Planet과 Effect 연결 저장
		planet_effect_map[planet_instance.planet_id] = effect_instance

# 두 planet_fire_1이 가까이 있는지 확인하고 합성
func check_and_merge_planets():
	var planet_1_instances = []
	
	# 모든 planet_fire_1 인스턴스 찾기
	for child in get_children():
		# planet_fire_1인지 확인 (스크립트 경로로 판단)
		if child.get_script() != null:
			var script_path = child.get_script().resource_path
			if script_path != null and "planet_fire_1.gd" in script_path:
				# can_merge 속성이 있는지 확인
				if "can_merge" in child and child.can_merge:
					planet_1_instances.append(child)
	
	# 두 개씩 비교하여 합성 가능한지 확인
	for i in range(planet_1_instances.size()):
		for j in range(i + 1, planet_1_instances.size()):
			var planet1 = planet_1_instances[i]
			var planet2 = planet_1_instances[j]
			
			# 둘 다 합성 가능하고 드래그 중이 아닐 때만 체크
			if planet1.can_merge and planet2.can_merge and not planet1.is_dragging and not planet2.is_dragging:
				var distance = planet1.global_position.distance_to(planet2.global_position)
				if distance <= merge_distance:
					merge_planets(planet1, planet2)
					return  # 한 번에 하나씩만 합성

# 두 planet_fire_1을 합쳐서 planet_fire_2 생성
func merge_planets(planet1: Node2D, planet2: Node2D):
	# 합성 위치 계산 (두 planet의 중간 지점)
	var merge_position = (planet1.global_position + planet2.global_position) / 2.0
	
	# 기존 이펙트들 제거
	if "planet_id" in planet1 and planet1.planet_id in planet_effect_map:
		var effect1 = planet_effect_map[planet1.planet_id]
		if is_instance_valid(effect1):
			effect1.queue_free()
		planet_effect_map.erase(planet1.planet_id)
	
	if "planet_id" in planet2 and planet2.planet_id in planet_effect_map:
		var effect2 = planet_effect_map[planet2.planet_id]
		if is_instance_valid(effect2):
			effect2.queue_free()
		planet_effect_map.erase(planet2.planet_id)
	
	# 기존 planet들 제거
	planet1.queue_free()
	planet2.queue_free()
	
	# planet_fire_2 생성
	var planet2_instance = PLANET_2_SCENE.instantiate()
	add_child(planet2_instance)
	planet2_instance.global_position = merge_position
	
	# planet_fire_effect_2 생성 (기존 시스템처럼 Path2D 위에 랜덤 위치)
	var effect2_instance = EFFECT_2_SCENE.instantiate()
	
	var path2d = $EnemyScout/Path2D
	if path2d and path2d.curve:
		var random_progress = randf()
		var path_length = path2d.curve.get_baked_length()
		var path_position = path2d.curve.sample_baked(path_length * random_progress)
		var effect_global_target = path2d.global_position + path_position
		
		add_child(effect2_instance)
		effect2_instance.global_position = effect_global_target
	else:
		add_child(effect2_instance)
		effect2_instance.global_position = merge_position
