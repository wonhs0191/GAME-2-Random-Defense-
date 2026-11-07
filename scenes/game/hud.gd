extends CanvasLayer

# 전투 화면 UI. 표시만 담당하고 실제 처리는 시그널로 GamePlay에 넘긴다.

signal wave_start_pressed
signal gacha_pressed

const TITLE_SCENE := "res://scenes/title/title_screen.tscn"

var _wave_manager: WaveManager = null

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var status_label: Label = $TopBar/StatusLabel
@onready var wave_button: Button = $BottomBar/WaveButton
@onready var gacha_button: Button = $BottomBar/GachaButton
@onready var result_panel: ColorRect = $ResultPanel
@onready var result_label: Label = $ResultPanel/ResultLabel

func setup(wave_manager: WaveManager) -> void:
	_wave_manager = wave_manager
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.game_ended.connect(_on_game_ended)
	gacha_button.text = "GACHA %dG" % GameState.GACHA_COST
	_on_gold_changed(GameState.gold)
	_on_lives_changed(GameState.lives)

func _process(_delta: float) -> void:
	if _wave_manager == null:
		return
	wave_label.text = "WAVE %d/%d" % [_wave_manager.wave, _wave_manager.total_waves]
	wave_button.disabled = not _wave_manager.can_start_wave()
	match _wave_manager.state:
		WaveManager.State.WAITING:
			status_label.text = "준비되면 WAVE START"
		WaveManager.State.PREP:
			status_label.text = "다음 웨이브 %d초" % ceili(_wave_manager.prep_left)
		_:
			status_label.text = "전투 중"

func _on_gold_changed(gold: int) -> void:
	gold_label.text = "GOLD %d" % gold
	gacha_button.disabled = gold < GameState.GACHA_COST

func _on_lives_changed(lives: int) -> void:
	lives_label.text = "LIFE %d" % lives

func _on_game_ended(cleared: bool) -> void:
	result_label.text = "CLEAR" if cleared else "GAME OVER"
	result_panel.show()

func _on_wave_button_pressed() -> void:
	wave_start_pressed.emit()

func _on_gacha_button_pressed() -> void:
	gacha_pressed.emit()

func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_title_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
