extends Node2D

class_name UnitBase

# 유닛 공용 로직. 종류별 차이는 UnitData(tres)로만 표현한다.
# 드래그는 GridManager가 전담하므로 여기에 입력 처리를 두지 않는다.

const PROJECTILE_SCENE := preload("res://entities/projectiles/projectile.tscn")
const ZONE_SCENE := preload("res://entities/projectiles/zone_field.tscn")

const RESCAN_INTERVAL := 0.1 # 공격 대상이 없을 때 다시 찾는 간격 (초)
const ZONE_SAMPLE_STEP := 16.0 # 장판 위치 후보를 경로에서 뽑는 간격 (px)
const SPRITE_SIZES := [50.0, 52.0, 56.0, 60.0] # 등급별 행성 크기 (px)
const RING_RADIUS := 30.0
const STAR_RADIUS := 5.0
const STAR_OUTLINE := 2.0
const STAR_SPACING := 13.0
const STAR_OFFSET := 24.0 # 별 표시 위치 (유닛 중심 아래, px)
const STAR_COLOR := Color(1.0, 0.85, 0.35)
const STAR_OUTLINE_COLOR := Color(0.1, 0.08, 0.2)
const POP_DURATION := 0.3

var data: UnitData
var is_held: bool = false # 드래그 중에는 공격하지 않는다
var stars: int = 1

var _game: Node2D
var _frame_time: float = 0.0
var _cooldown: float = 0.0
var _zone: ZoneField = null
var _zone_in_range: bool = false
var _placed_position: Vector2 = Vector2.INF

@onready var sprite: Sprite2D = $Sprite

func setup(unit_data: UnitData, game: Node2D) -> void:
	data = unit_data
	_game = game

func _ready() -> void:
	sprite.texture = load(data.sheet_path)
	sprite.hframes = data.sheet_columns
	sprite.vframes = data.sheet_rows
	sprite.scale = Vector2.ONE * SPRITE_SIZES[data.grade] / (sprite.texture.get_width() / sprite.hframes)
	# 같은 행성이 똑같이 돌지 않도록 시작 프레임을 흩어 놓는다
	_frame_time = randf() * sprite.hframes * sprite.vframes / data.sheet_fps

func _exit_tree() -> void:
	if _zone:
		_zone.queue_free()

func _draw() -> void:
	# 행성 위에 등급 고리와 2성 이상 표시를 그린다
	if data.grade > UnitData.Grade.C:
		draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 48, UnitData.GRADE_COLORS[data.grade], 2.0)
	if stars < 2:
		return
	var first_x := -STAR_SPACING * (stars - 1) / 2.0
	for i in stars:
		var center := Vector2(first_x + STAR_SPACING * i, STAR_OFFSET)
		_draw_star(center, STAR_RADIUS + STAR_OUTLINE, STAR_OUTLINE_COLOR)
		_draw_star(center, STAR_RADIUS, STAR_COLOR)

func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -radius), center + Vector2(radius, 0),
		center + Vector2(0, radius), center + Vector2(-radius, 0),
	]), color)

func _process(delta: float) -> void:
	_frame_time += delta
	sprite.frame = int(_frame_time * data.sheet_fps) % (sprite.hframes * sprite.vframes)

	_cooldown -= delta
	if _cooldown > 0.0 or is_held:
		return
	var attacked := _shoot() if data.attack_type == UnitData.AttackType.SHOT else _burn_zone()
	_cooldown = data.attack_interval if attacked else RESCAN_INTERVAL

func get_damage() -> float:
	return data.damage * UnitData.STAR_DAMAGE[stars - 1]

func can_upgrade() -> bool:
	return stars < UnitData.MAX_STARS

func add_star() -> void:
	stars += 1
	queue_redraw()

# 같은 유닛 2개를 합치면 상위 등급이 나온다. 최고 등급은 합칠 수 없다.
func can_merge_with(other: UnitBase) -> bool:
	return other != self and data.id == other.data.id and data.grade < UnitData.Grade.S

# 뽑히거나 합쳐져 나올 때 튀어나오는 연출.
func pop_in() -> void:
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, POP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# GridManager가 유닛을 집을 때 호출한다.
func on_picked() -> void:
	is_held = true
	if _zone:
		_zone.hide()

# GridManager가 유닛을 칸에 놓을 때 호출한다.
func on_placed(world_position: Vector2) -> void:
	is_held = false
	if data.attack_type == UnitData.AttackType.ZONE:
		# 제자리에 다시 놓으면 장판 위치를 유지한다
		if world_position != _placed_position:
			_place_zone(world_position)
		_zone.visible = _zone_in_range
	_placed_position = world_position

# 사거리 안의 적 중 가장 앞서 간 적을 쏜다.
func _shoot() -> bool:
	var target := _find_target()
	if target == null:
		return false
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	_game.effects.add_child(projectile)
	projectile.launch(data.get_effect_frames(), global_position, target, get_damage())
	return true

func _find_target() -> EnemyBase:
	var best: EnemyBase = null
	for enemy: EnemyBase in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_to(enemy.global_position) > data.attack_range:
			continue
		if best == null or enemy.distance > best.distance:
			best = enemy
	return best

# 장판 안의 모든 적에게 피해를 준다.
func _burn_zone() -> bool:
	if _zone == null or not _zone.visible:
		return false
	var hit := false
	for enemy: EnemyBase in get_tree().get_nodes_in_group("enemy"):
		if _zone.global_position.distance_to(enemy.global_position) <= data.zone_radius:
			enemy.take_damage(get_damage())
			hit = true
	return hit

# 사거리 안의 경로 위 임의의 지점에 장판을 깐다. 어디에 깔릴지는 운이다.
func _place_zone(from: Vector2) -> void:
	var candidates: Array[Vector2] = []
	for path: Path2D in _game.paths:
		var length := path.curve.get_baked_length()
		var offset := 0.0
		while offset <= length:
			var point := path.to_global(path.curve.sample_baked(offset))
			if point.distance_to(from) <= data.attack_range:
				candidates.append(point)
			offset += ZONE_SAMPLE_STEP

	if _zone == null:
		_zone = ZONE_SCENE.instantiate()
		_game.zones.add_child(_zone)
		_zone.setup(data.get_effect_frames(), data.zone_radius)

	_zone_in_range = not candidates.is_empty()
	if _zone_in_range:
		_zone.global_position = candidates.pick_random()
