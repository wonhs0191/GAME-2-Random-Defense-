extends ColorRect

# 설정 창. 타이틀과 일시 정지 메뉴에서 함께 쓴다.

@onready var bgm_slider: HSlider = $BgmSlider
@onready var sfx_slider: HSlider = $SfxSlider
@onready var fullscreen_check: CheckButton = $FullscreenCheck

func _ready() -> void:
	Sound.bind_buttons(self)

func open() -> void:
	bgm_slider.value = Settings.bgm_volume
	sfx_slider.value = Settings.sfx_volume
	fullscreen_check.button_pressed = Settings.fullscreen
	show()

func close() -> void:
	Settings.save_settings()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_bgm_slider_value_changed(value: float) -> void:
	Settings.bgm_volume = value
	Settings.apply()

func _on_sfx_slider_value_changed(value: float) -> void:
	Settings.sfx_volume = value
	Settings.apply()

func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	Settings.fullscreen = toggled_on
	Settings.apply()

func _on_close_button_pressed() -> void:
	close()
