extends Node2D

class_name EnemyBase

# 적 공용 로직. 종류별 차이는 EnemyData(tres)로만 표현한다.
# PathFollow2D는 진척률을 공유하는 문제가 있어(MAP-001) 경로상 거리를 직접 관리한다.

signal destroyed(enemy: EnemyBase)

const BAR_WIDTH_RATIO := 0.4 # 체력바 폭 / 스프라이트 폭
const BAR_HEIGHT := 4.0
const BAR_BACK_COLOR := Color(0, 0, 0, 0.7)
const BAR_COLOR := Color(0.95, 0.25, 0.25)
const FROZEN_COLOR := Color(0.5, 0.8, 1.0)
const HIT_COLOR := Color(2.2, 2.2, 2.2)
const HIT_FLASH_TIME := 0.06
const SHIP_FILL := 0.75 # 스프라이트에서 함선이 차지하는 비율
const LANE_SPREAD := 12.0 # 겹치지 않도록 경로 중심에서 좌우로 벌어지는 최대 거리 (px)
const LANE_SMOOTHING := 24.0 # 모서리에서 좌우 위치가 튀지 않도록 앞뒤를 보는 거리 (px)

var data: EnemyData
var path: Path2D
var distance: float = 0.0 # 경로 시작점부터 이동한 거리 (px)
var speed: float = 0.0
var max_hp: float = 1.0
var hp: float = 1.0
var lane: float = 0.0 # 경로 중심에서 벗어난 거리 (px)
var is_final_boss: bool = false # 경로 끝에 닿으면 라이프와 상관없이 패배한다

var _size_scale: float = 1.0
var _frozen_left: float = 0.0
var _hit_flash_left: float = 0.0
var _path_length: float = 0.0
var _bar_width: float = 0.0
var _bar_offset: float = 0.0

@onready var visual: Node2D = $Visual
@onready var engine: AnimatedSprite2D = $Visual/Engine
@onready var body: Sprite2D = $Visual/Body

func setup(enemy_data: EnemyData, enemy_path: Path2D, hp_scale: float = 1.0, speed_scale: float = 1.0, size_scale: float = 1.0) -> void:
	data = enemy_data
	path = enemy_path
	max_hp = data.max_hp * hp_scale
	hp = max_hp
	speed = data.speed * speed_scale
	lane = randf_range(-LANE_SPREAD, LANE_SPREAD)
	_size_scale = size_scale
	_path_length = path.curve.get_baked_length()

func _ready() -> void:
	add_to_group("enemy")
	var sprite_scale := data.visual_scale * _size_scale
	visual.scale = Vector2.ONE * sprite_scale
	body.texture = load(data.body_path)
	engine.sprite_frames = data.get_engine_frames()
	engine.play("default")
	_bar_width = body.texture.get_width() * sprite_scale * BAR_WIDTH_RATIO
	_bar_offset = -body.texture.get_height() * sprite_scale * 0.4
	_move_along_path()

func _process(delta: float) -> void:
	# 죽은 적이 같은 프레임에 경로 끝에 닿아 라이프까지 깎는 것을 막는다
	if is_queued_for_deletion():
		return
	if _hit_flash_left > 0.0:
		_hit_flash_left -= delta
		if _hit_flash_left <= 0.0:
			body.modulate = Color.WHITE
	if _frozen_left > 0.0:
		_frozen_left -= delta
		if _frozen_left <= 0.0:
			visual.modulate = Color.WHITE
		return
	distance += speed * delta
	if distance >= _path_length:
		_reach_goal()
		return
	_move_along_path()

func _draw() -> void:
	# 피해를 입은 적만 체력바를 그린다
	if hp >= max_hp:
		return
	var bar := Rect2(-_bar_width / 2.0, _bar_offset, _bar_width, BAR_HEIGHT)
	draw_rect(bar, BAR_BACK_COLOR)
	bar.size.x *= hp / max_hp
	draw_rect(bar, BAR_COLOR)

# 진행 방향으로 잰 함선 길이 (px).
func get_length() -> float:
	return body.texture.get_height() * visual.scale.y * SHIP_FILL

# 일정 시간 제자리에 멈춘다.
func freeze(seconds: float) -> void:
	_frozen_left = seconds
	visual.modulate = FROZEN_COLOR

func take_damage(amount: float) -> void:
	hp -= amount
	body.modulate = HIT_COLOR
	_hit_flash_left = HIT_FLASH_TIME
	queue_redraw()
	if hp <= 0.0 and is_in_group("enemy"):
		_die()

func _die() -> void:
	# 그룹에서 바로 빼서 같은 프레임의 다른 공격이 시체를 노리지 않게 한다
	remove_from_group("enemy")
	GameState.add_gold(data.reward)
	destroyed.emit(self)
	queue_free()

func _reach_goal() -> void:
	remove_from_group("enemy")
	GameState.lose_lives(GameState.lives if is_final_boss else data.life_damage)
	queue_free()

func _move_along_path() -> void:
	var curve := path.curve
	var heading := curve.sample_baked(distance + LANE_SMOOTHING) - curve.sample_baked(distance - LANE_SMOOTHING)
	var next_position := path.to_global(curve.sample_baked(distance) + heading.normalized().orthogonal() * lane)
	var direction := next_position - global_position
	# 스프라이트가 위쪽을 보고 있으므로 90도를 더한다
	if direction.length() > 0.01:
		visual.rotation = direction.angle() + PI / 2
	global_position = next_position
