extends Node2D

class_name EnemyBase

# 적 공용 로직. 종류별 차이는 EnemyData(tres)로만 표현한다.
# PathFollow2D는 진척률을 공유하는 문제가 있어(MAP-001) 경로상 거리를 직접 관리한다.

signal reached_goal(enemy: EnemyBase)

var data: EnemyData
var path: Path2D
var distance: float = 0.0 # 경로 시작점부터 이동한 거리 (px)
var speed: float = 0.0

var _path_length: float = 0.0

@onready var visual: Node2D = $Visual
@onready var engine: AnimatedSprite2D = $Visual/Engine
@onready var body: Sprite2D = $Visual/Body

func setup(enemy_data: EnemyData, enemy_path: Path2D, speed_scale: float = 1.0) -> void:
	data = enemy_data
	path = enemy_path
	speed = data.speed * speed_scale
	_path_length = path.curve.get_baked_length()

func _ready() -> void:
	add_to_group("enemy")
	visual.scale = Vector2.ONE * data.visual_scale
	body.texture = load(data.body_path)
	engine.sprite_frames = data.get_engine_frames()
	engine.play("default")
	_move_along_path()

func _process(delta: float) -> void:
	distance += speed * delta
	if distance >= _path_length:
		reached_goal.emit(self)
		queue_free()
		return
	_move_along_path()

func _move_along_path() -> void:
	var next_position := path.to_global(path.curve.sample_baked(distance))
	var direction := next_position - global_position
	# 스프라이트가 위쪽을 보고 있으므로 90도를 더한다
	if direction.length() > 0.01:
		visual.rotation = direction.angle() + PI / 2
	global_position = next_position
