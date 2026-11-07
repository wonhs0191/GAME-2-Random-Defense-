class_name UnitData
extends Resource

# 유닛 1종의 정의. data/units/ 아래 tres 하나가 유닛 1종이다.
# 텍스처는 뽑혔을 때만 필요하므로 경로로 들고 있다가 지연 로드한다.

enum Grade { C, B, A, S }
enum AttackType { SHOT, ZONE }

const GRADE_NAMES := ["C", "B", "A", "S"]
const GRADE_COLORS := [
	Color(0.75, 0.75, 0.75), Color(0.35, 0.7, 1.0), Color(0.8, 0.45, 1.0), Color(1.0, 0.8, 0.25),
]

const MERGE_COST := [10, 40, 160, 0]        # 등급별 조합 비용. 공짜면 S등급이 쏟아진다

const MAX_STARS := 3
const STAR_DAMAGE := [1.0, 1.6, 2.5]        # 별 수별 공격력 배율
const UPGRADE_CHANCE := [0.7, 0.4]          # 1→2성, 2→3성 성공 확률
const UPGRADE_BASE_COST := [30, 60, 120, 240] # 등급별 강화 비용. 현재 별 수를 곱한다

@export var id: String = ""
@export var alias: String = "" # 부가 정보. 공식 명칭은 id다
@export var grade: Grade = Grade.C
@export var attack_type: AttackType = AttackType.SHOT

@export_group("Sprite")
@export_file("*.png") var sheet_path: String = ""
@export var sheet_columns: int = 15
@export var sheet_rows: int = 15
@export var sheet_fps: float = 7.5

@export_group("Effect")
@export_dir var effect_dir: String = ""
@export var effect_frame_count: int = 0
@export var effect_fps: float = 30.0

@export_group("Stats")
@export var damage: float = 10.0
@export var attack_interval: float = 1.0 # 공격 간격 (초)
@export var attack_range: float = 176.0  # 사거리 (px)
@export var zone_radius: float = 56.0    # ZONE 장판 반경 (px)

var _effect_frames: SpriteFrames = null

func get_grade_name() -> String:
	return GRADE_NAMES[grade]

func get_display_name() -> String:
	return "%s  %s" % [id, alias] if alias else id

func merge_cost() -> int:
	return MERGE_COST[grade]

func upgrade_cost(stars: int) -> int:
	return UPGRADE_BASE_COST[grade] * stars

# 이펙트 프레임(1.png ~ N.png)을 SpriteFrames로 묶어 돌려준다. 같은 유닛끼리 공유한다.
func get_effect_frames() -> SpriteFrames:
	if _effect_frames:
		return _effect_frames
	_effect_frames = SpriteFrames.new()
	_effect_frames.set_animation_speed("default", effect_fps)
	for i in range(1, effect_frame_count + 1):
		_effect_frames.add_frame("default", load(effect_dir.path_join("%d.png" % i)))
	return _effect_frames
