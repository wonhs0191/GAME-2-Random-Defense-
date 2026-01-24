extends CharacterBody2D

var move_speed: float = 100.0  # 이동 속도
var path_follow: PathFollow2D = null  # PathFollow2D 참조
var moving_forward: bool = true  # 앞으로 이동 중인지 여부

# Called when the node enters the scene tree for the first time.
func _ready():
	# Engine 애니메이션을 항상 활성화
	var engine = $Engine
	if engine:
		engine.play("Engine")
	
	# 부모 노드가 PathFollow2D인지 확인
	if get_parent() is PathFollow2D:
		path_follow = get_parent()
		# 초기 위치를 0으로 설정
		path_follow.progress_ratio = 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if path_follow == null:
		return
	
	# Path의 길이를 가져와서 속도 계산
	var path_length = path_follow.get_parent().curve.get_baked_length()
	if path_length <= 0:
		return
	
	# 이동 거리 계산
	var move_distance = move_speed * delta / path_length
	
	# 진행 방향에 따라 progress_ratio 조절
	if moving_forward:
		path_follow.progress_ratio += move_distance
		# 끝에 도달하면 방향 전환
		if path_follow.progress_ratio >= 1.0:
			path_follow.progress_ratio = 1.0
			moving_forward = false
	else:
		path_follow.progress_ratio -= move_distance
		# 시작점에 도달하면 방향 전환
		if path_follow.progress_ratio <= 0.0:
			path_follow.progress_ratio = 0.0
			moving_forward = true
