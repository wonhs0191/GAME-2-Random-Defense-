class_name EnemyData
extends Resource

# 적 1종의 정의. data/enemies/ 아래 tres 하나가 적 1종이다.

@export var id: String = ""
@export var faction: String = ""
@export var ship: String = ""

@export_group("Sprite")
@export_file("*.png") var body_path: String = ""
@export_file("*.png") var engine_path: String = ""
@export var engine_fps: float = 10.0
@export var visual_scale: float = 1.0

@export_group("Stats")
@export var max_hp: float = 30.0
@export var speed: float = 60.0  # 이동 속도 (px/s)
@export var reward: int = 1      # 처치 골드
@export var life_damage: int = 1 # 경로 끝 도달 시 깎는 라이프

var _engine_frames: SpriteFrames = null

# 엔진 스프라이트는 정사각 프레임이 가로로 이어진 시트다.
func get_engine_frames() -> SpriteFrames:
	if _engine_frames:
		return _engine_frames
	var sheet: Texture2D = load(engine_path)
	var frame_size: int = sheet.get_height()
	_engine_frames = SpriteFrames.new()
	_engine_frames.set_animation_speed("default", engine_fps)
	for i in range(sheet.get_width() / frame_size):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(i * frame_size, 0, frame_size, frame_size)
		_engine_frames.add_frame("default", frame)
	return _engine_frames
