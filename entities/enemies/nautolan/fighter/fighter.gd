extends EnemyBase

var path_2d: Path2D            = null          # Path2D 참조
var progress: float            = 0.0           # 각 bomber만의 progress 값 (0.0 ~ 1.0)
var previous_position: Vector2 = Vector2.ZERO  # 이전 프레임의 위치 (방향 계산용)

func _init():
	move_speed = 50.0

func _ready():
	super._ready()
	
	# 부모 노드가 Path2D인지 확인
	if get_parent() is Path2D:
		path_2d = get_parent() as Path2D
		# 각 fighter는 자신만의 progress를 0부터 시작
		progress = 0.0
		
		# Path2D의 curve 시작점(0, 0)에 fighter를 초기 위치로 배치
		if path_2d:
			var path_start_position = path_2d.curve.sample_baked(0.0)
			global_position = path_2d.global_position + path_start_position
			previous_position = global_position

func _process(delta):
	# Path2D 하위에 있지 않으면 경로 추적하지 않음
	if path_2d == null:
		return
	
	# Path의 길이를 가져와서 속도 계산
	var path_length = path_2d.curve.get_baked_length()
	if path_length <= 0:
		return
	
	# 이동 거리 계산 (각 fighter는 자신만의 progress를 증가)
	var move_distance = move_speed * delta / path_length
	progress += move_distance
	
	# 경로 끝에 도달하면 제거
	if progress >= 1.0:
		progress = 1.0
		queue_free()
		return
	
	# progress 값에 해당하는 경로상의 위치 계산
	var path_position = path_2d.curve.sample_baked(progress * path_length)
	
	# Path2D의 global_position을 기준으로 경로상의 위치 계산
	# Path2D의 curve는 (0, 0)에서 시작하므로, Path2D의 위치를 기준으로 계산
	var new_position = path_2d.global_position + path_position
	global_position = new_position
	
	# 방향 계산: 현재 위치와 이전 위치를 비교
	var direction = new_position - previous_position
	if direction.length() > 0.01:  # 움직임이 충분히 있을 때만 회전
		# 스프라이트의 기본 방향이 반대이므로 180도(π)를 더함
		rotation = direction.angle() + PI/2
	
	# 이전 위치 업데이트
	previous_position = new_position
