class_name UltimateData
extends Resource

# 필살기 1종의 정의. data/ultimates/ 아래 tres 하나가 필살기 1종이다.

enum Kind { METEOR, FREEZE, OVERCLOCK, GOLD }

const KIND_COLORS := [
	Color(1.0, 0.55, 0.25), Color(0.5, 0.85, 1.0), Color(0.5, 1.0, 0.6), Color(1.0, 0.85, 0.35),
]

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var kind: Kind = Kind.METEOR
@export var cooldown: float = 45.0 # 재사용 대기 시간 (초)
@export var power: float = 0.0     # 종류별 위력
@export var duration: float = 0.0  # 지속 시간 (초)

func get_color() -> Color:
	return KIND_COLORS[kind]

func get_title() -> String:
	return title

func get_description() -> String:
	return "%s\n재사용 %d초" % [description, cooldown]
