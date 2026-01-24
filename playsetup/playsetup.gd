extends Control

@onready var background = $background
# 맵 선언(경로)
var map01 = preload("res://playsetup/backgrund_img/Space Background (1).png")
var map02 = preload("res://playsetup/backgrund_img/Space Background (2).png")
var map03 = preload("res://playsetup/backgrund_img/Space Background (3).png")
var map04 = preload("res://playsetup/backgrund_img/Space Background (4).png")

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_theme_1_mouse_entered():
	background.texture = map01

func _on_theme_2_mouse_entered():
	background.texture = map02


func _on_theme_3_mouse_entered():
	background.texture = map03

func _on_theme_4_mouse_entered():
	background.texture = map04
