extends Node2D

class_name EnemyBase

# 적 공용 로직. 종류별 차이는 EnemyData(tres)로만 표현한다.
# PathFollow2D는 진척률을 공유하는 문제가 있어(MAP-001) 경로상 거리를 직접 관리한다.

const BAR_WIDTH := 28.0
const BAR_HEIGHT := 4.0
const BAR_BACK_COLOR := Color(0, 0, 0, 0.7)
const BAR_COLOR := Color(0.95, 0.25, 0.25)

var data: EnemyData
var path: Path2D
var distance: float = 0.0 # 경로 시작점부터 이동한 거리 (px)
var speed: float = 0.0
var max_hp: float = 1.0
var hp: float = 1.0

var _path_length: float = 0.0
var _bar_offset: float = 0.0

@onready var visual: Node2D = $Visual
@onready var engine: AnimatedSprite2D = $Visual/Engine
@onready var body: Sprite2D = $Visual/Body

func setup(enemy_data: EnemyData, enemy_path: Path2D, hp_scale: float = 1.0, speed_scale: float = 1.0) -> void:
	data = enemy_data
	path = enemy_path
	max_hp = data.max_hp * hp_scale
	hp = max_hp
	speed = data.speed * speed_scale
	_path_length = path.curve.get_baked_length()

func _ready() -> void:
	add_to_group("enemy")
	visual.scale = Vector2.ONE * data.visual_scale
	body.texture = load(data.body_path)
	engine.sprite_frames = data.get_engine_frames()
	engine.play("default")
	_bar_offset = -body.texture.get_height() * data.visual_scale * 0.4
	_move_along_path()

func _process(delta: float) -> void:
	distance += speed * delta
	if distance >= _path_length:
		_reach_goal()
		return
	_move_along_path()

func _draw() -> void:
	# 피해를 입은 적만 체력바를 그린다
	if hp >= max_hp:
		return
	var bar := Rect2(-BAR_WIDTH / 2.0, _bar_offset, BAR_WIDTH, BAR_HEIGHT)
	draw_rect(bar, BAR_BACK_COLOR)
	bar.size.x *= hp / max_hp
	draw_rect(bar, BAR_COLOR)

func take_damage(amount: float) -> void:
	hp -= amount
	queue_redraw()
	if hp <= 0.0 and is_in_group("enemy"):
		_die()

func _die() -> void:
	# 그룹에서 바로 빼서 같은 프레임의 다른 공격이 시체를 노리지 않게 한다
	remove_from_group("enemy")
	GameState.add_gold(data.reward)
	queue_free()

func _reach_goal() -> void:
	remove_from_group("enemy")
	GameState.lose_lives(data.life_damage)
	queue_free()

func _move_along_path() -> void:
	var next_position := path.to_global(path.curve.sample_baked(distance))
	var direction := next_position - global_position
	# 스프라이트가 위쪽을 보고 있으므로 90도를 더한다
	if direction.length() > 0.01:
		visual.rotation = direction.angle() + PI / 2
	global_position = next_position
