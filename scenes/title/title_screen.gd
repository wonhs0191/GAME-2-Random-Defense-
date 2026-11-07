extends Node2D

@onready var setting_panel: ColorRect = $SettingPanel

func _ready():
	Sound.bind_buttons(self)
	Sound.play_bgm("title")

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/lobby/playsetup.tscn")

func _on_setting_button_pressed():
	setting_panel.open()

func _on_quit_button_pressed():
	get_tree().quit()
