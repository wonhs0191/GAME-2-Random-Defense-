extends Control

@onready var background   = $background
@onready var theme_detail = $Theme/theme_detail
@onready var start_button = $Start

# 난이도별 구역 설명. 수치는 GameSetting에서 가져온다.
const DIFFICULTY_LORE := {
	"Easy": "안정 구역. 확률 붕괴의 여파가 아직 약하다.",
	"Normal": "붕괴 구역. 외계 연합 함대의 정규 항로다.",
	"Hard": "분기 구역. 항로가 두 갈래로 갈라진다.",
	"Extreme": "특이점 구역. 항로가 네 갈래로 얽혀 있다.",
}

const THEME_NAMES := ["OIL6", "BORKFEST", "AMMO-8", "SUBMERGED CHIMERA", "FUNKYFUTURE8", "WINTER WONDERLAND"]

@onready var difficulty_detail: Label = $DifficultyDetail

# 맵 선언(경로) 		#TODO : 경로 변경 시 수정 필요
var theme01 = preload("res://scenes/lobby/background_img/oil_1280.png")
var theme02 = preload("res://scenes/lobby/background_img/borkfest_1280.png")
var theme03 = preload("res://scenes/lobby/background_img/ammo_1280.png")
var theme04 = preload("res://scenes/lobby/background_img/submerged_1280.png")
var theme05 = preload("res://scenes/lobby/background_img/funky_1280.png")
var theme06 = preload("res://scenes/lobby/background_img/winter_1280.png")

func _ready():
	GameSetting.selected_theme_texture = preload("res://scenes/title/title_screen_background.png")
	background.texture = GameSetting.selected_theme_texture
	theme_detail.text = ""
	Sound.bind_buttons(self)
	start_button.tooltip_text = "고른 난이도와 테마로 시작합니다."
	for i in THEME_NAMES.size():
		get_node("Theme/GridContainer/Theme%d" % (i + 1)).tooltip_text = "배경 테마: " + THEME_NAMES[i]
	var degree_index := 1
	for difficulty_name in GameSetting.DIFFICULTIES:
		var difficulty: Dictionary = GameSetting.DIFFICULTIES[difficulty_name]
		get_node("Difficulty/HBoxContainer/Degree%d" % degree_index).tooltip_text = "%s\n%d 웨이브, 라이프 %d" % [
			DIFFICULTY_LORE[difficulty_name], difficulty["waves"], difficulty["lives"],
		]
		degree_index += 1
	Sound.play_bgm("lobby")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	GameSetting.selected_theme_texture
	# TODO : 경로 변경 시 수정 필요
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/title/title_screen.tscn")

# 시작 버튼 활성화(난이도 선택 시)
func activate_start_button():
	if GameSetting.selected_difficulty != "":
		start_button.disabled = false
		var difficulty: Dictionary = GameSetting.get_difficulty()
		difficulty_detail.text = "행성 관리자, 방어 구역을 지정했습니다.\n%s\n%d 웨이브, 라이프 %d" % [
			DIFFICULTY_LORE[GameSetting.selected_difficulty], difficulty["waves"], difficulty["lives"],
		]
	else:
		start_button.disabled = true
		difficulty_detail.text = ""

######### 난이도 저장 ###########
func _on_degree_1_pressed():
	GameSetting.selected_difficulty = "Easy"
	activate_start_button()

func _on_degree_2_pressed():
	GameSetting.selected_difficulty = "Normal"
	activate_start_button()

func _on_degree_3_pressed():
	GameSetting.selected_difficulty = "Hard"
	activate_start_button()

func _on_degree_4_pressed():
	GameSetting.selected_difficulty = "Extreme"
	activate_start_button()

# ========= [테마 1] =========
# func _on_theme_1_mouse_entered(): # 마우스 올리면: 프리뷰
# 	background.texture = theme01
# 	theme_detail.text = "OIL6"

func _on_theme_1_pressed():       # 클릭하면: 저장 (확정)
	background.texture = theme01
	GameSetting.selected_theme_texture = theme01
	theme_detail.text = "OIL6"
	#print("테마 1", GameSetting.selected_theme_texture)

# func _on_theme_1_mouse_exited():  # 마우스 나가면: 저장된 걸로 복구
# 	background.texture = GameSetting.selected_theme_texture
# 	theme_detail.text = ""


# ========= [테마 2] =========
# func _on_theme_2_mouse_entered():
# 	background.texture = theme02
# 	theme_detail.text = "Borkfest"

func _on_theme_2_pressed():
	background.texture = theme02
	GameSetting.selected_theme_texture = theme02
	theme_detail.text = "BORKFEST"
	#print("테마 2 : ", GameSetting.selected_theme_texture)

# func _on_theme_2_mouse_exited():
# 	background.texture = GameSetting.selected_theme_texture
# 	theme_detail.text = ""


# ========= [테마 3] =========
# func _on_theme_3_mouse_entered():
# 	background.texture = theme03
# 	theme_detail.text = "AMMO-8"
	
func _on_theme_3_pressed():
	background.texture = theme03
	GameSetting.selected_theme_texture = theme03
	theme_detail.text = "AMMO-8"
	#print("테마 3")

# func _on_theme_3_mouse_exited():
# 	background.texture = GameSetting.selected_theme_texture
# 	theme_detail.text = ""


# ========= [테마 4] =========
# func _on_theme_4_mouse_entered():
# 	background.texture = theme04
# 	theme_detail.text = "SUBMERGED CHIMERA"

func _on_theme_4_pressed():
	background.texture = theme04
	GameSetting.selected_theme_texture = theme04
	theme_detail.text = "SUBMERGED CHIMERA"

# func _on_theme_4_mouse_exited():
# 	background.texture = GameSetting.selected_theme_texture
# 	theme_detail.text = ""


# ========= [테마 5] =========
# func _on_theme_5_mouse_entered():
# 	background.texture = theme05
# 	theme_detail.text = "FUNKYFUTURE8"

func _on_theme_5_pressed():
	background.texture = theme05
	GameSetting.selected_theme_texture = theme05
	theme_detail.text = "FUNKYFUTURE8"

# func _on_theme_5_mouse_exited():
# 	background.texture = GameSetting.selected_theme_texture
# 	theme_detail.text = ""


# ========= [테마 6] =========
# func _on_theme_6_mouse_entered():
# 	background.texture = theme06
# 	theme_detail.text = "WINTER WONDERLAND"

func _on_theme_6_pressed():
	background.texture = theme06
	GameSetting.selected_theme_texture = theme06
	theme_detail.text = "WINTER WONDERLAND"

# func _on_theme_6_mouse_exited():
# 	background.texture = GameSetting.selected_theme_texture
# 	theme_detail.text = ""


func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/game/game_play.tscn")
