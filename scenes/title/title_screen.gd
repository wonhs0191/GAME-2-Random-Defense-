extends Node2D

# 행성이 z_index로 앞에 그려지므로 설정 창은 별도 레이어에 둔다
@onready var setting_panel: ColorRect = $SettingLayer/SettingPanel
@onready var codex_panel: ColorRect = $SettingLayer/CodexPanel

func _ready():
	Sound.bind_buttons(self)
	Sound.play_bgm("title")

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/lobby/playsetup.tscn")

func _on_codex_button_pressed():
	codex_panel.open()

func _on_setting_button_pressed():
	setting_panel.open()

func _on_quit_button_pressed():
	get_tree().quit()
