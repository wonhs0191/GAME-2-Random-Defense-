extends Node2D

# Attack 변수 선언
@onready var attack01 = $"01Unit/Attack"
@onready var attack02 = $"02Unit/Attack"
@onready var attack03 = $"03Unit/Attack"

# Called when the node enters the scene tree for the first time.
func _ready():
	print(2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# attack 버튼 눌렀을 때
func _on_attack_test_pressed():
	print(1)
	# 어택 재생
	attack01.play()
	attack02.play()
	attack03.play()
