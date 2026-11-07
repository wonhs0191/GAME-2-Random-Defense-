class_name AugmentData
extends Resource

# 증강 1종의 정의. data/augments/ 아래 tres 하나가 증강 1종이다.
# 고른 증강은 격자 위 구역이 되고, 구역 안 유닛의 능력치만 오른다.

enum Stat { DAMAGE, ATTACK_SPEED, RANGE }

const STAT_NAMES := ["공격력", "공격 속도", "사거리"]
const STAT_COLORS := [Color(1.0, 0.45, 0.35), Color(0.4, 1.0, 0.6), Color(0.4, 0.7, 1.0)]

@export var id: String = ""
@export var stat: Stat = Stat.DAMAGE
@export var value: float = 0.1 # 증가율 (0.1 = +10%)
@export var zone_size: Vector2i = Vector2i(3, 3) # 구역 크기 (칸)

func get_color() -> Color:
	return STAT_COLORS[stat]

func get_title() -> String:
	return "%s 구역" % STAT_NAMES[stat]

func get_description() -> String:
	return "%dx%d 칸 안의 유닛\n%s +%d%%" % [zone_size.x, zone_size.y, STAT_NAMES[stat], roundi(value * 100.0)]
