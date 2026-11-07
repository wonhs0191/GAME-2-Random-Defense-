extends Control

class_name GachaReveal

# 뽑기 연출. 행성이 화면 가운데 나타나 등급만큼 폭죽을 터뜨린 뒤 보관함으로 날아간다.
# 연출 중에도 게임은 계속되고 입력도 막지 않는다. 연달아 뽑으면 앞 연출을 바로 끝낸다.

signal finished(unit: UnitBase)

const STAGE_CENTER := Vector2(640, 300)
const SHELL_AREA := Vector2(300, 170) # 폭죽이 터지는 범위 (가운데 기준, px)
const POP_TIME := 0.22
const FLY_TIME := 0.24
const FRAME_RATE := 7.5
const RAY_COUNT := 12
const RAY_LENGTH := 420.0
const RAY_SPIN := 0.5 # 초당 회전 (라디안)

# 등급별 연출 크기 (C, B, A, S)
const HOLD_TIMES := [0.35, 0.55, 1.0, 1.7]
const DIM_ALPHAS := [0.0, 0.0, 0.4, 0.65]
const PLANET_ZOOMS := [2.0, 2.4, 3.0, 3.6]
const SHELL_COUNTS := [1, 2, 5, 10]
const SPARK_COUNTS := [20, 32, 48, 64]
const RAY_ALPHAS := [0.0, 0.08, 0.14, 0.2]

var _unit: UnitBase = null
var _tween: Tween = null
var _shell_tween: Tween = null
var _frame_time: float = 0.0
var _ray_angle: float = 0.0

@onready var dim: ColorRect = $Dim
@onready var planet: Sprite2D = $Planet
@onready var name_label: Label = $NameLabel

func is_playing() -> bool:
	return _unit != null

func play(unit: UnitBase, is_new: bool = false) -> void:
	skip()
	_unit = unit
	var data := unit.data
	var grade := data.grade
	_frame_time = 0.0
	planet.texture = load(data.sheet_path)
	planet.hframes = data.sheet_columns
	planet.vframes = data.sheet_rows
	var fit: float = UnitBase.SPRITE_SIZES[grade] / (planet.texture.get_width() / float(planet.hframes))
	planet.position = STAGE_CENTER
	planet.scale = Vector2.ZERO
	planet.show()
	var heading := "%s등급  신규 발견!" % data.get_grade_name() if is_new else "%s등급" % data.get_grade_name()
	name_label.text = "%s\n%s" % [heading, data.get_display_name()]
	name_label.modulate = Color(UnitData.GRADE_COLORS[grade], 0.0)

	_tween = create_tween()
	_tween.tween_property(planet, "scale", Vector2.ONE * fit * PLANET_ZOOMS[grade], POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(dim, "modulate:a", DIM_ALPHAS[grade], POP_TIME)
	_tween.parallel().tween_property(name_label, "modulate:a", 1.0, POP_TIME)
	_tween.tween_interval(HOLD_TIMES[grade])
	_tween.tween_property(planet, "position", unit.global_position, FLY_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(planet, "scale", Vector2.ONE * fit, FLY_TIME)
	_tween.parallel().tween_property(dim, "modulate:a", 0.0, FLY_TIME)
	_tween.parallel().tween_property(name_label, "modulate:a", 0.0, FLY_TIME)
	_tween.tween_callback(skip)

	_shell_tween = create_tween().set_parallel()
	var shells: int = SHELL_COUNTS[grade]
	for i in shells:
		_shell_tween.tween_callback(_launch_shell.bind(grade)).set_delay((POP_TIME + HOLD_TIMES[grade]) * i / shells)

# 연출을 바로 끝낸다.
func skip() -> void:
	if _unit == null:
		return
	if _tween:
		_tween.kill()
	if _shell_tween:
		_shell_tween.kill()
	var unit := _unit
	_unit = null
	planet.hide()
	dim.modulate.a = 0.0
	name_label.modulate.a = 0.0
	queue_redraw()
	finished.emit(unit)

func _launch_shell(grade: UnitData.Grade) -> void:
	var firework := Firework.new()
	var color: Color = UnitData.GRADE_COLORS[grade]
	firework.setup(color.lerp(Color.WHITE, randf() * 0.5), SPARK_COUNTS[grade])
	firework.position = STAGE_CENTER + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SHELL_AREA
	add_child(firework)

func _process(delta: float) -> void:
	if _unit == null:
		return
	_frame_time += delta
	planet.frame = int(_frame_time * FRAME_RATE) % (planet.hframes * planet.vframes)
	_ray_angle += RAY_SPIN * delta
	queue_redraw()

# 행성 뒤로 도는 빛줄기.
func _draw() -> void:
	if _unit == null or RAY_ALPHAS[_unit.data.grade] == 0.0:
		return
	var color := Color(UnitData.GRADE_COLORS[_unit.data.grade], RAY_ALPHAS[_unit.data.grade])
	var width := PI / RAY_COUNT / 2.0
	for i in RAY_COUNT:
		var angle := _ray_angle + TAU * i / RAY_COUNT
		draw_colored_polygon(PackedVector2Array([
			STAGE_CENTER,
			STAGE_CENTER + Vector2.from_angle(angle - width) * RAY_LENGTH,
			STAGE_CENTER + Vector2.from_angle(angle + width) * RAY_LENGTH,
		]), color)
