extends Node2D

class_name UnitBase

# 유닛 공용 로직. 종류별 차이는 UnitData(tres)로만 표현한다.
# 드래그는 GridManager가 전담하므로 여기에 입력 처리를 두지 않는다.

var data: UnitData

var _frame_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite

func setup(unit_data: UnitData) -> void:
	data = unit_data

func _ready() -> void:
	sprite.texture = load(data.sheet_path)
	sprite.hframes = data.sheet_columns
	sprite.vframes = data.sheet_rows
	# 같은 행성이 똑같이 돌지 않도록 시작 프레임을 흩어 놓는다
	_frame_time = randf() * sprite.hframes * sprite.vframes / data.sheet_fps

func _process(delta: float) -> void:
	_frame_time += delta
	sprite.frame = int(_frame_time * data.sheet_fps) % (sprite.hframes * sprite.vframes)
