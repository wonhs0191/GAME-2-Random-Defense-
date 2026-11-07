extends Node2D

class_name RevealBurst

# 유닛 등장 연출. 등급이 높을수록 크게 터진다.

const DURATION := 0.55
const RAY_COUNT := 12
const RING_WIDTH := 4.0
const RADIUS_BY_GRADE := [36.0, 64.0, 120.0, 220.0]

var _color: Color
var _radius: float = 0.0
var _progress: float = 0.0

func setup(grade: UnitData.Grade) -> void:
	_color = UnitData.GRADE_COLORS[grade]
	_radius = RADIUS_BY_GRADE[grade]

func _ready() -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(queue_free)

func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()

func _draw() -> void:
	var color := _color
	color.a = 1.0 - _progress
	var radius := _radius * _progress
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, RING_WIDTH)
	for i in RAY_COUNT:
		var direction := Vector2.from_angle(TAU * i / RAY_COUNT)
		draw_line(direction * radius * 0.6, direction * radius, color, 2.0)
