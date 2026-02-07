extends Control

@onready var background   = $background
@onready var theme_detail = $Theme/theme_detail
@onready var start_button = $Start

# 맵 선언(경로) 		#TODO : 경로 변경 시 수정 필요
var theme01 = preload("res://playsetup/background_img/oil_1280.png")
var theme02 = preload("res://playsetup/background_img/borkfest_1280.png")
var theme03 = preload("res://playsetup/background_img/ammo_1280.png")
var theme04 = preload("res://playsetup/background_img/submerged_1280.png")
var theme05 = preload("res://playsetup/background_img/funky_1280.png")
var theme06 = preload("res://playsetup/background_img/winter_1280.png")

func _ready():
	GameData.selected_theme_texture = preload("res://title_screen/title_screen_background.png")
	background.texture = GameData.selected_theme_texture
	theme_detail.text = ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	GameData.selected_theme_texture
	# TODO : 경로 변경 시 수정 필요
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")

# 시작 버튼 활성화(난이도 선택 시)
func activate_start_button():
	if GameData.selected_difficulty != "":
		start_button.disabled = false
	else:
		start_button.disabled = true

######### 난이도 저장 ###########
func _on_degree_1_pressed():
	GameData.selected_difficulty = "Easy"
	activate_start_button()

func _on_degree_2_pressed():
	GameData.selected_difficulty = "Normal"
	activate_start_button()

func _on_degree_3_pressed():
	GameData.selected_difficulty = "Hard"
	activate_start_button()

func _on_degree_4_pressed():
	GameData.selected_difficulty = "Extreme"
	activate_start_button()

# ========= [테마 1] =========
# func _on_theme_1_mouse_entered(): # 마우스 올리면: 프리뷰
# 	background.texture = theme01
# 	theme_detail.text = "OIL6"

func _on_theme_1_pressed():       # 클릭하면: 저장 (확정)
	background.texture = theme01
	GameData.selected_theme_texture = theme01
	theme_detail.text = "OIL6"
	print("테마 1", GameData.selected_theme_texture)

# func _on_theme_1_mouse_exited():  # 마우스 나가면: 저장된 걸로 복구
# 	background.texture = GameData.selected_theme_texture
# 	theme_detail.text = ""


# ========= [테마 2] =========
# func _on_theme_2_mouse_entered():
# 	background.texture = theme02
# 	theme_detail.text = "Borkfest"

func _on_theme_2_pressed():
	background.texture = theme02
	GameData.selected_theme_texture = theme02
	theme_detail.text = "BORKFEST"
	print("테마 2 : ", GameData.selected_theme_texture)

# func _on_theme_2_mouse_exited():
# 	background.texture = GameData.selected_theme_texture
# 	theme_detail.text = ""


# ========= [테마 3] =========
# func _on_theme_3_mouse_entered():
# 	background.texture = theme03
# 	theme_detail.text = "AMMO-8"
	
func _on_theme_3_pressed():
	background.texture = theme03
	GameData.selected_theme_texture = theme03
	theme_detail.text = "AMMO-8"
	print("테마 3")

# func _on_theme_3_mouse_exited():
# 	background.texture = GameData.selected_theme_texture
# 	theme_detail.text = ""


# ========= [테마 4] =========
# func _on_theme_4_mouse_entered():
# 	background.texture = theme04
# 	theme_detail.text = "SUBMERGED CHIMERA"

func _on_theme_4_pressed():
	background.texture = theme04
	GameData.selected_theme_texture = theme04
	theme_detail.text = "SUBMERGED CHIMERA"

# func _on_theme_4_mouse_exited():
# 	background.texture = GameData.selected_theme_texture
# 	theme_detail.text = ""


# ========= [테마 5] =========
# func _on_theme_5_mouse_entered():
# 	background.texture = theme05
# 	theme_detail.text = "FUNKYFUTURE8"

func _on_theme_5_pressed():
	background.texture = theme05
	GameData.selected_theme_texture = theme05
	theme_detail.text = "FUNKYFUTURE8"

# func _on_theme_5_mouse_exited():
# 	background.texture = GameData.selected_theme_texture
# 	theme_detail.text = ""


# ========= [테마 6] =========
# func _on_theme_6_mouse_entered():
# 	background.texture = theme06
# 	theme_detail.text = "WINTER WONDERLAND"

func _on_theme_6_pressed():
	background.texture = theme06
	GameData.selected_theme_texture = theme06
	theme_detail.text = "WINTER WONDERLAND"

# func _on_theme_6_mouse_exited():
# 	background.texture = GameData.selected_theme_texture
# 	theme_detail.text = ""
