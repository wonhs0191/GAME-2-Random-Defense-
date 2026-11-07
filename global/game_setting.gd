# 전역 변수 선언
class_name GameSetting

# 난이도별 설정. waves는 총 웨이브 수, lives는 시작 라이프, 나머지는 기본값 대비 배율.
const DIFFICULTIES := {
	"Easy": {"waves": 30, "lives": 30, "hp": 0.8, "count": 0.8, "speed": 0.9},
	"Normal": {"waves": 40, "lives": 20, "hp": 1.0, "count": 1.0, "speed": 1.0},
	"Hard": {"waves": 50, "lives": 15, "hp": 1.3, "count": 1.15, "speed": 1.1},
	"Extreme": {"waves": 60, "lives": 10, "hp": 1.7, "count": 1.3, "speed": 1.2},
}

static var selected_difficulty: String = ""
static var selected_theme_texture: Texture2D = preload("res://scenes/title/title_screen_background.png")

# 씬을 단독 실행해 난이도가 비어 있으면 Easy로 본다.
static func get_difficulty() -> Dictionary:
	return DIFFICULTIES.get(selected_difficulty, DIFFICULTIES["Easy"])
