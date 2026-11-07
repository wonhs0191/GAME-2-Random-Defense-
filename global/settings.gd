extends Node

# 사용자 설정. 게임을 다시 켜도 유지되도록 파일에 저장한다.

const SECTION := "settings"

var path: String = "user://settings.cfg"
var bgm_volume: float = 0.7 # 0~1
var sfx_volume: float = 0.8 # 0~1
var fullscreen: bool = false

func _ready() -> void:
	load_settings()
	apply()

func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	bgm_volume = file.get_value(SECTION, "bgm_volume", bgm_volume)
	sfx_volume = file.get_value(SECTION, "sfx_volume", sfx_volume)
	fullscreen = file.get_value(SECTION, "fullscreen", fullscreen)

func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "bgm_volume", bgm_volume)
	file.set_value(SECTION, "sfx_volume", sfx_volume)
	file.set_value(SECTION, "fullscreen", fullscreen)
	file.save(path)

func apply() -> void:
	Sound.set_volumes(bgm_volume, sfx_volume)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
