extends ColorRect

# 일시 정지 메뉴. 게임이 멈춘 동안에도 입력을 받아야 하므로 HUD와 따로 처리한다.

signal title_pressed

@onready var setting_panel: ColorRect = $SettingPanel

func _ready() -> void:
	Sound.bind_buttons(self)

# 증강을 고르는 중이거나 게임이 끝나 이미 멈춘 상태면 열지 않는다.
func open() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	show()

func close() -> void:
	setting_panel.hide()
	hide()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		close()
	else:
		open()
	get_viewport().set_input_as_handled()

func _on_resume_button_pressed() -> void:
	close()

func _on_setting_button_pressed() -> void:
	setting_panel.open()

func _on_title_button_pressed() -> void:
	title_pressed.emit()
