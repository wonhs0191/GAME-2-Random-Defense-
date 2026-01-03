extends Node2D

# 드래그 관련 변수
var draggable_nodes = []  # 드래그 가능한 노드들
var selected_node = null  # 현재 선택된 노드
var drag_offset = Vector2.ZERO  # 드래그 시작 시 오프셋


# Called when the node enters the scene tree for the first time.
func _ready():
	# 모든 애니메이션 시작
	start_all_animations()
	
	# 드래그 가능한 노드들 초기화
	setup_draggable_nodes()


func start_all_animations():
	# Planet_1의 공격 애니메이션
	var planet1_attack = $Planet_1/Attack_1/AnimatedSprite2D
	if planet1_attack:
		planet1_attack.play("attack_1")
	
	# Planet_1의 행성 애니메이션
	var planet1_sprite = $Planet_1/AnimatedSprite2D
	if planet1_sprite:
		planet1_sprite.play("planet_1")
	
	# Planet_2의 공격 애니메이션
	var planet2_attack = $Planet_2/Attack_1/AnimatedSprite2D
	if planet2_attack:
		planet2_attack.play("new_animation")
	
	# Planet_2의 행성 애니메이션
	var planet2_sprite = $Planet_2/AnimatedSprite2D
	if planet2_sprite:
		planet2_sprite.play("planet_2")
	
	# Planet_3의 공격 애니메이션
	var planet3_attack = $Planet_3/Attack_3/AnimatedSprite2D
	if planet3_attack:
		planet3_attack.play()  # default 애니메이션
	
	# Planet_3의 행성 애니메이션
	var planet3_sprite = $Planet_3/AnimatedSprite2D
	if planet3_sprite:
		planet3_sprite.play("planet_3_1")
	
	# Enemy의 방패 애니메이션
	var enemy_shield = $Enemy/AnimatedSprite2D
	if enemy_shield:
		enemy_shield.play("default")


func setup_draggable_nodes():
	# 드래그 가능한 노드들을 배열에 추가
	draggable_nodes = [
		$Planet_1,
		$Planet_2,
		$Planet_3,
		$Enemy
	]


func _input(event):
	# 마우스 입력 처리
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 마우스 버튼을 누름 - 노드 선택
				select_node_at_position(event.global_position)
			else:
				# 마우스 버튼을 뗌 - 드래그 종료
				selected_node = null
				drag_offset = Vector2.ZERO
	
	elif event is InputEventMouseMotion:
		# 마우스 이동 - 드래그 중이면 노드 이동
		if selected_node != null:
			selected_node.global_position = event.global_position - drag_offset


func select_node_at_position(mouse_pos: Vector2):
	# 마우스 위치에서 클릭된 노드 찾기 (역순으로 확인하여 위에 있는 노드가 우선 선택되도록)
	for i in range(draggable_nodes.size() - 1, -1, -1):
		var node = draggable_nodes[i]
		if node == null:
			continue
		
		# 노드의 스프라이트를 찾아서 클릭 영역 확인
		var sprite = null
		var sprite_size = Vector2.ZERO
		
		# Enemy의 경우 Sprite2D를 먼저 확인
		if node.name == "Enemy":
			var sprite2d = node.get_node_or_null("Sprite2D")
			if sprite2d and sprite2d.texture:
				sprite = sprite2d
				sprite_size = sprite2d.texture.get_size() * sprite2d.scale
		
		# AnimatedSprite2D 확인
		if sprite == null:
			var anim_sprite = node.get_node_or_null("AnimatedSprite2D")
			if anim_sprite:
				sprite = anim_sprite
				# 현재 프레임의 텍스처 크기 가져오기
				if anim_sprite.sprite_frames and anim_sprite.animation:
					var frame_texture = anim_sprite.sprite_frames.get_frame_texture(anim_sprite.animation, anim_sprite.frame)
					if frame_texture:
						sprite_size = frame_texture.get_size() * anim_sprite.scale
		
		if sprite != null and sprite_size != Vector2.ZERO:
			# 스프라이트의 전역 위치 가져오기
			var sprite_global_pos = sprite.global_position
			
			# 클릭 영역 확인 (사각형 체크)
			var rect = Rect2(
				sprite_global_pos - sprite_size / 2,
				sprite_size
			)
			
			if rect.has_point(mouse_pos):
				# 노드 선택 및 드래그 오프셋 계산
				selected_node = node
				drag_offset = mouse_pos - node.global_position
				break
