class_name UnitData
extends Resource

# 유닛 1종의 정의. data/units/ 아래 tres 하나가 유닛 1종이다.
# 텍스처는 뽑혔을 때만 필요하므로 경로로 들고 있다가 지연 로드한다.

enum Grade { C, B, A, S }
enum AttackType { SHOT, ZONE }

@export var id: String = ""
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

# 이펙트 프레임(1.png ~ N.png)을 SpriteFrames로 묶어 돌려준다. 같은 유닛끼리 공유한다.
func get_effect_frames() -> SpriteFrames:
	if _effect_frames:
		return _effect_frames
	_effect_frames = SpriteFrames.new()
	_effect_frames.set_animation_speed("default", effect_fps)
	for i in range(1, effect_frame_count + 1):
		_effect_frames.add_frame("default", load(effect_dir.path_join("%d.png" % i)))
	return _effect_frames
