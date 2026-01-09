extends CharacterBody2D

var hp = 100

func _ready():
	pass

func _process(delta):
	pass

# 데미지 받을 때 디버깅
func take_damage(value):
	print(" 데미지를 받았습니다! 남은 HP: ")
