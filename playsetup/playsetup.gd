extends Control

@onready var background   = $background
@onready var theme_detail = $theme_detail

# 맵 선언(경로) 		#TODO : 경로 변경 시 수정 필요
var theme01 = preload("res://playsetup/background_img/oil_1280.png")
var theme02 = preload("res://playsetup/background_img/borkfest_1280.png")
var theme03 = preload("res://playsetup/background_img/ammo_1280.png")
var theme04 = preload("res://playsetup/background_img/submerged_1280.png")
var theme05 = preload("res://playsetup/background_img/funky_1280.png")
var theme06 = preload("res://playsetup/background_img/winter_1280.png")



func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# func _on_degree_2_pressed():
# 	gamemanager.selected_difficulty = "Normal"

# func _on_degree_3_pressed():
# 	gamemanager.selected_difficulty = "Hard"

# func _on_degree_4_pressed():
# 	gamemanager.selected_difficulty = "Extreme"

func _on_theme_1_mouse_entered():
	background.texture = theme01
	theme_detail.text = "빛조차 삼켜버린 듯한 칠흑 같은 암흑 공간입니다. 검은 기름이 떠다니는 듯한 희미한 잔재만이 남아있으며, 절대적인 고요와 적막만이 감도는 미지의 공허(Void) 지대입니다."

func _on_theme_2_mouse_entered():
	background.texture = theme02
	theme_detail.text = "끓어오르는 용암처럼 붉게 타오르는 작열의 우주입니다. 초신성 폭발의 잔재가 여전히 뜨겁게 요동치며, 강렬한 열기와 에너지가 끊임없이 뿜어져 나오는 파괴적인 화염 지대입니다."

func _on_theme_3_mouse_entered():
	background.texture = theme03
	theme_detail.text = "짙은 녹색 가스와 방사능 먼지로 뒤덮인 위험 구역입니다. 마치 오래된 전장의 위장막처럼 탁하고 무거운 분위기가 흐르며, 생명체의 접근을 거부하는 고밀도의 맹독성 성운입니다."

func _on_theme_4_mouse_entered():
	background.texture = theme04
	theme_detail.text = "마치 심해의 깊은 곳처럼 짙은 자줏빛으로 잠겨있는 심연입니다. 플라즈마 파동이 물결처럼 일렁이며, 알 수 없는 고대의 에너지가 깊숙이 가라앉아 있는 신비로운 잠식의 공간입니다."

func _on_theme_5_mouse_entered():
	background.texture = theme05
	theme_detail.text = "강렬한 네온 핑크빛 성운이 춤추는 몽환적인 우주입니다. 사이키델릭한 에너지가 소용돌이치며, 마치 환각을 보는 듯한 착각을 불러일으키는 매혹적이고 신비로운 심우주 구역입니다."

func _on_theme_6_mouse_entered():
	background.texture = theme06
	theme_detail.text = "절대영도의 추위가 지배하는 얼어붙은 은하입니다. 창백한 푸른빛 성운은 마치 유리처럼 차갑게 빛나며, 모든 움직임을 멈추게 만드는 냉혹하고도 아름다운 빙하의 우주입니다."
