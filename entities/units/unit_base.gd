extends Node2D

class_name UnitBase

# 유닛 공용 로직. 종류별 차이는 UnitData(tres)로만 표현한다.
# 드래그는 GridManager가 전담하므로 여기에 입력 처리를 두지 않는다.

const PROJECTILE_SCENE := preload("res://entities/projectiles/projectile.tscn")
const ZONE_SCENE := preload("res://entities/projectiles/zone_field.tscn")
const GRAB_OUTLINE := preload("res://entities/units/grab_outline.tres")

const RESCAN_INTERVAL := 0.1 # 공격 대상이 없을 때 다시 찾는 간격 (초)
const ZONE_SAMPLE_STEP := 16.0 # 장판 위치 후보를 경로에서 뽑는 간격 (px)
const SPRITE_SIZES := [50.0, 52.0, 56.0, 60.0] # 등급별 행성 크기 (px)
const RING_RADIUS := 30.0
const STAR_RADIUS := 7.0
const STAR_INNER_RATIO := 0.45 # 별의 안쪽 꼭짓점 반지름 비율
const STAR_TIPS := 5
const STAR_OUTLINE := 2.5
const STAR_SPACING := 15.0
const STAR_OFFSET := 23.0 # 별 표시 위치 (유닛 중심 아래, px)
const STAR_COLOR := Color(1.0, 0.85, 0.35)
const STAR_OUTLINE_COLOR := Color(0.1, 0.08, 0.2)
const POP_DURATION := 0.3
const OUTLINE_SCREEN_WIDTH := 2.0 # 집어 든 유닛의 외곽선 두께 (px)

var data: UnitData
var is_held: bool = false # 드래그 중에는 공격하지 않는다
var stars: int = 1

var _game: Node2D
var _frame_time: float = 0.0
var _cooldown: float = 0.0
var _zone: ZoneField = null
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
	draw_colored_polygon(star_points(center, radius), color)

# 위쪽 꼭짓점부터 바깥과 안쪽을 번갈아 찍은 별 모양.
static func star_points(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in STAR_TIPS * 2:
		var length := radius if i % 2 == 0 else radius * STAR_INNER_RATIO
		points.append(center + Vector2.from_angle(-PI / 2.0 + PI * i / STAR_TIPS) * length)
	return points

func _process(delta: float) -> void:
	_frame_time += delta
	sprite.frame = int(_frame_time * data.sheet_fps) % (sprite.hframes * sprite.vframes)

	_cooldown -= delta
	if _cooldown > 0.0 or is_held:
		return
	var attacked := _shoot() if data.attack_type == UnitData.AttackType.SHOT else _burn_zone()
	_cooldown = get_attack_interval() if attacked else RESCAN_INTERVAL

func get_damage() -> float:
	return data.damage * UnitData.STAR_DAMAGE[stars - 1] * (1.0 + _zone_bonus(global_position, AugmentData.Stat.DAMAGE))

func get_attack_interval() -> float:
	var bonus: float = _zone_bonus(global_position, AugmentData.Stat.ATTACK_SPEED) + _game.ultimates.attack_speed_bonus()
	return data.attack_interval / (1.0 + bonus)

# 놓을 위치에 따라 구역 효과가 달라지므로 위치를 받는다.
func get_attack_range(at: Vector2 = global_position) -> float:
	return data.attack_range * (1.0 + _zone_bonus(at, AugmentData.Stat.RANGE))

# 사거리 안에 적이 지나는 길이 있는지 본다.
func reaches_path() -> bool:
	var attack_range := get_attack_range()
	for path: Path2D in _game.paths:
		var nearest := path.to_global(path.curve.get_closest_point(path.to_local(global_position)))
		if nearest.distance_to(global_position) <= attack_range:
			return true
	return false

# 현재 칸의 구역 효과.
func get_zone_bonus(stat: AugmentData.Stat) -> float:
	return _zone_bonus(global_position, stat)

func _zone_bonus(at: Vector2, stat: AugmentData.Stat) -> float:
	var grid: GridManager = _game.grid
	return grid.zone_bonus(grid.world_to_grid(at), stat)

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
	# 다섯 번째 뽑기는 바로 증강 패널이 열려 멈추므로 멈춘 동안에도 재생한다
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "scale", Vector2.ONE, POP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# GridManager가 유닛을 집을 때 호출한다.
func on_picked() -> void:
	is_held = true
	GRAB_OUTLINE.set_shader_parameter("width", OUTLINE_SCREEN_WIDTH / sprite.scale.x)
	sprite.material = GRAB_OUTLINE
	if _zone:
		_zone.hide()

# GridManager가 유닛을 칸에 놓을 때 호출한다.
func on_placed(world_position: Vector2) -> void:
	is_held = false
	sprite.material = null
	if data.attack_type == UnitData.AttackType.ZONE:
		# 제자리에 다시 놓으면 장판 위치를 유지한다
		if world_position != _placed_position:
			_place_zone(world_position)
		_zone.show()
	_placed_position = world_position

# 사거리 안의 적 중 가장 앞서 간 적을 쏜다.
func _shoot() -> bool:
	var target := _find_target(get_attack_range())
	if target == null:
		return false
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	_game.effects.add_child(projectile)
	projectile.launch(data.get_effect_frames(), global_position, target, get_damage())
	Sound.play("shot")
	return true

func _find_target(attack_range: float) -> EnemyBase:
	var best: EnemyBase = null
	for enemy: EnemyBase in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_to(enemy.global_position) > attack_range:
			continue
		if best == null or enemy.distance > best.distance:
			best = enemy
	return best

# 장판 안의 모든 적에게 피해를 준다.
func _burn_zone() -> bool:
	if not _zone.visible:
		return false
	var hit := false
	for enemy: EnemyBase in get_tree().get_nodes_in_group("enemy"):
		if _zone.global_position.distance_to(enemy.global_position) <= data.zone_radius:
			enemy.take_damage(get_damage())
			hit = true
	return hit

# 사거리 안의 경로 위 임의의 지점에 장판을 깐다. 어디에 깔릴지는 운이다.
# 경로는 화면 밖에서 시작하므로 격자 안쪽만 본다. 사거리에 경로가 없으면 가장 가까운 지점에 깐다.
func _place_zone(from: Vector2) -> void:
	var candidates: Array[Vector2] = []
	var nearest := Vector2.INF
	var attack_range := get_attack_range(from)
	var play_area: Rect2 = _game.grid.get_world_rect()
	for path: Path2D in _game.paths:
		var length := path.curve.get_baked_length()
		var offset := 0.0
		while offset <= length:
			var point := path.to_global(path.curve.sample_baked(offset))
			offset += ZONE_SAMPLE_STEP
			if not play_area.has_point(point):
				continue
			if point.distance_to(from) <= attack_range:
				candidates.append(point)
			if point.distance_squared_to(from) < nearest.distance_squared_to(from):
				nearest = point

	if _zone == null:
		_zone = ZONE_SCENE.instantiate()
		_game.zones.add_child(_zone)
		_zone.setup(data.get_effect_frames(), data.zone_radius, data.effect_center)

	_zone.global_position = nearest if candidates.is_empty() else candidates.pick_random()
