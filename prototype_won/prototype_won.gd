extends Node2D

const PLANET_SCENE = preload("res://prototype_won/planet/planet_fire_1/planet_fire_1.tscn")
const EFFECT_SCENE = preload("res://prototype_won/planet/planet_fire_1/effect_1/planet_fire_effect_1.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


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
	else:
		# Path2D를 찾을 수 없으면 그냥 planet 위치에 생성
		add_child(effect_instance)
		effect_instance.global_position = spawn_position
