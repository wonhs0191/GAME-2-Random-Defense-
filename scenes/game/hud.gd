extends CanvasLayer

# 전투 화면 UI. 표시만 담당하고 실제 처리는 시그널로 GamePlay에 넘긴다.

signal wave_start_pressed
signal gacha_pressed
signal upgrade_pressed
signal augment_chosen(index: int)
signal ultimate_pressed
signal title_requested

const SPEEDS: Array[float] = [1.0, 2.0, 3.0]
const RESULT_FADE_TIME := 0.5
const TOOLTIP_GAP := 40.0 # 유닛 중심에서 설명 창까지의 거리 (px)
const TOOLTIP_AREA := Rect2(8, 68, 1264, 568) # 설명 창이 들어갈 영역
const BOSS_COLOR := Color(1, 0.4, 0.3)
const SUCCESS_COLOR := Color(1.0, 0.85, 0.35)
const FAILURE_COLOR := Color(0.6, 0.65, 0.8)
const MESSAGE_TIME := 1.2
const MESSAGE_FADE_TIME := 0.4
const FLASH_ALPHA := 0.6
const FLASH_TIME := 0.5

var _wave_manager: WaveManager = null
var _augments: AugmentManager = null
var _ultimates: UltimateManager = null
var _selected_unit: UnitBase = null
var _tooltip_unit: UnitBase = null
var _message_tween: Tween = null

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var status_label: Label = $TopBar/StatusLabel
@onready var wave_button: Button = $BottomBar/WaveButton
@onready var gacha_button: Button = $BottomBar/GachaButton
@onready var unit_info_label: Label = $BottomBar/UnitInfoLabel
@onready var upgrade_button: Button = $BottomBar/UpgradeButton
@onready var message_label: Label = $MessageLabel
@onready var flash: ColorRect = $Flash
@onready var odds_panel: ColorRect = $OddsPanel
@onready var odds_label: Label = $OddsPanel/OddsLabel
@onready var unit_tooltip: PanelContainer = $UnitTooltip
@onready var unit_tooltip_label: Label = $UnitTooltip/Label
@onready var placement_label: Label = $PlacementLabel
@onready var ultimate_button: Button = $BottomBar/UltimateButton
@onready var augment_panel: ColorRect = $AugmentPanel
@onready var augment_title: Label = $AugmentPanel/TitleLabel
@onready var augment_cards: Array[Button] = [$AugmentPanel/Card1, $AugmentPanel/Card2, $AugmentPanel/Card3]
@onready var speed_button: Button = $TopBar/SpeedButton
@onready var pause_menu: ColorRect = $PauseMenu
@onready var result_panel: ColorRect = $ResultPanel
@onready var result_label: Label = $ResultPanel/ResultLabel
@onready var result_detail: Label = $ResultPanel/ResultDetail

func setup(wave_manager: WaveManager, augments: AugmentManager, ultimates: UltimateManager) -> void:
	_wave_manager = wave_manager
	_augments = augments
	_ultimates = ultimates
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.game_ended.connect(_on_game_ended)
	odds_label.text = _build_odds_text()
	Sound.bind_buttons(self)
	pause_menu.title_pressed.connect(title_requested.emit)
	pause_menu.visibility_changed.connect(unit_tooltip.hide)
	gacha_button.tooltip_text = "골드 %d로 행성 1개를 뽑습니다.\n뽑기 %d회마다 증강 카드가 나옵니다." % [
		GameState.GACHA_COST, AugmentManager.DRAWS_PER_OFFER,
	]
	upgrade_button.tooltip_text = "선택한 행성을 강화합니다. 공격력이 2성 %d%%, 3성 %d%%가 됩니다.\n실패해도 골드는 돌아오지 않습니다." % [
		roundi(UnitData.STAR_DAMAGE[1] * 100.0), roundi(UnitData.STAR_DAMAGE[2] * 100.0),
	]
	show_unit(null)
	_on_gold_changed(GameState.gold)
	_on_lives_changed(GameState.lives)

func _process(_delta: float) -> void:
	if _wave_manager == null:
		return
	var wave := _wave_manager.wave
	var fighting := _wave_manager.state in [WaveManager.State.SPAWNING, WaveManager.State.FIGHTING]
	var boss_fight := fighting and _wave_manager.is_boss_wave(wave)
	var wave_text := "WAVE %d/%d" % [wave, _wave_manager.total_waves]
	wave_label.text = "BOSS " + wave_text if boss_fight else wave_text
	wave_label.modulate = BOSS_COLOR if boss_fight else Color.WHITE
	wave_button.disabled = not _wave_manager.can_start_wave()
	gacha_button.text = "GACHA %dG\n증강까지 %d회" % [GameState.GACHA_COST, _augments.draws_until_offer]
	_refresh_ultimate_button()
	_refresh_unit_tooltip()
	match _wave_manager.state:
		WaveManager.State.WAITING:
			status_label.text = "준비되면 WAVE START"
		WaveManager.State.PREP:
			var next_text := "보스 출현" if _wave_manager.is_boss_wave(wave + 1) else "다음 웨이브"
			status_label.text = "%s %d초" % [next_text, ceili(_wave_manager.prep_left)]
		_:
			if not boss_fight:
				status_label.text = "전투 중"
			elif _wave_manager.is_final_wave(wave):
				status_label.text = "최종 보스 전투"
			else:
				status_label.text = "보스 전투"

# 선택된 유닛 정보와 강화 버튼을 표시한다. null이면 숨긴다.
func show_unit(unit: UnitBase) -> void:
	_selected_unit = unit
	unit_info_label.visible = unit != null
	upgrade_button.visible = unit != null
	_refresh_upgrade_button()
	if unit == null:
		return
	var data := unit.data
	unit_info_label.text = "%s등급 %s  %d성\n공격력 %.1f  간격 %.2f초  사거리 %d" % [
		data.get_grade_name(), data.id, unit.stars, unit.get_damage(), unit.get_attack_interval(), unit.get_attack_range(),
	]

# 마우스가 올라간 행성의 설명을 띄운다. null이면 숨긴다.
func show_unit_tooltip(unit: UnitBase) -> void:
	_tooltip_unit = unit
	_refresh_unit_tooltip()

func _refresh_unit_tooltip() -> void:
	if not is_instance_valid(_tooltip_unit):
		unit_tooltip.hide()
		return
	var text := _build_unit_tooltip(_tooltip_unit)
	if unit_tooltip_label.text != text:
		unit_tooltip_label.text = text
		unit_tooltip.reset_size()
	unit_tooltip.show()
	# 평소에는 오른쪽, 공간이 없으면 왼쪽에 띄운다
	var center := _tooltip_unit.global_position
	var size := unit_tooltip.size
	var spot := center + Vector2(TOOLTIP_GAP, -size.y / 2.0)
	if spot.x + size.x > TOOLTIP_AREA.end.x:
		spot.x = center.x - TOOLTIP_GAP - size.x
	spot.y = clampf(spot.y, TOOLTIP_AREA.position.y, TOOLTIP_AREA.end.y - size.y)
	unit_tooltip.position = spot

func _build_unit_tooltip(unit: UnitBase) -> String:
	var data := unit.data
	var is_zone := data.attack_type == UnitData.AttackType.ZONE
	var lines: Array[String] = [
		data.get_display_name(),
		"%s등급  %d성  %s 공격" % [data.get_grade_name(), unit.stars, UnitData.ATTACK_TYPE_NAMES[data.attack_type]],
		"공격력 %.1f  공격 간격 %.2f초" % [unit.get_damage(), unit.get_attack_interval()],
		"사거리 %d%s" % [unit.get_attack_range(), "  장판 반경 %d" % data.zone_radius if is_zone else ""],
	]
	var bonuses := _zone_bonus_texts(unit)
	if not bonuses.is_empty():
		lines.append("구역 효과: " + ", ".join(bonuses))
	lines.append("")
	lines.append(data.description)
	lines.append("")
	lines.append("클릭: 강화 메뉴")
	if data.grade < UnitData.Grade.S:
		lines.append("같은 행성 위로 끌어 놓기: 조합 %dG" % data.merge_cost())
	return "\n".join(lines)

func _zone_bonus_texts(unit: UnitBase) -> Array[String]:
	var texts: Array[String] = []
	for stat in AugmentData.Stat.values():
		var bonus := unit.get_zone_bonus(stat)
		if bonus > 0.0:
			texts.append("%s +%d%%" % [AugmentData.STAT_NAMES[stat], roundi(bonus * 100.0)])
	return texts

func show_augment_cards(cards: Array[Resource], title: String) -> void:
	placement_label.hide()
	unit_tooltip.hide()
	augment_title.text = title
	for i in cards.size():
		var card := augment_cards[i]
		card.text = "%s\n\n%s" % [cards[i].get_title(), cards[i].get_description()]
		card.get_node("Strip").color = cards[i].get_color()
		card.tooltip_text = "이 카드를 고릅니다."
	augment_panel.show()

func show_placement_hint(augment: AugmentData) -> void:
	augment_panel.hide()
	placement_label.text = "%s을 놓을 곳을 클릭하세요" % augment.get_title()
	placement_label.show()

func hide_augment_ui() -> void:
	augment_panel.hide()
	placement_label.hide()

func show_merge_unaffordable(cost: int) -> void:
	show_message("조합 골드 부족 (%dG)" % cost, FAILURE_COLOR)

func show_upgrade_result(succeeded: bool) -> void:
	if succeeded:
		show_message("강화 성공!", SUCCESS_COLOR)
	else:
		show_message("강화 실패...", FAILURE_COLOR)

# A등급 이상은 크게 알린다. S등급은 화면도 번쩍인다.
func show_reveal(data: UnitData) -> void:
	if data.grade < UnitData.Grade.A:
		return
	show_message("%s등급 등장!  %s" % [data.get_grade_name(), data.get_display_name()], UnitData.GRADE_COLORS[data.grade])
	if data.grade == UnitData.Grade.S:
		_flash(Color.WHITE)

func show_boss_warning(is_final: bool) -> void:
	show_message("경고: 최종 기함 접근" if is_final else "경고: 외계 연합 기함 접근", BOSS_COLOR)

func show_faction(faction_name: String) -> void:
	show_message("%s 선단 진입" % faction_name, Color.WHITE)

func show_ultimate(ultimate: UltimateData) -> void:
	show_message(ultimate.get_title(), ultimate.get_color())
	_flash(ultimate.get_color())

func show_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.modulate = color
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_message_tween.tween_interval(MESSAGE_TIME)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, MESSAGE_FADE_TIME)

func _flash(color: Color) -> void:
	flash.color = color
	flash.modulate.a = FLASH_ALPHA
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(flash, "modulate:a", 0.0, FLASH_TIME)

func _refresh_ultimate_button() -> void:
	var state := "준비" if _ultimates.can_use() else "%d초" % ceili(_ultimates.cooldown_left)
	ultimate_button.text = "%s\n%s" % [_ultimates.current.get_title(), state]
	ultimate_button.tooltip_text = _ultimates.current.get_description()
	ultimate_button.disabled = not _ultimates.can_use()

func _refresh_upgrade_button() -> void:
	if _selected_unit == null:
		return
	if not _selected_unit.can_upgrade():
		upgrade_button.text = "강화 완료"
		upgrade_button.disabled = true
		return
	var stars := _selected_unit.stars
	var cost := _selected_unit.data.upgrade_cost(stars)
	upgrade_button.text = "강화 %dG (%d%%)" % [cost, roundi(UnitData.UPGRADE_CHANCE[stars - 1] * 100.0)]
	upgrade_button.disabled = GameState.gold < cost

# 표시 내용이 실제 수치와 어긋나지 않도록 상수에서 만든다.
func _build_odds_text() -> String:
	var lines: Array[String] = ["뽑기 확률"]
	for grade in Catalog.GRADE_ODDS:
		lines.append("%s등급  %.1f%%  (%d종)" % [
			UnitData.GRADE_NAMES[grade], Catalog.GRADE_ODDS[grade], Catalog.units_of_grade(grade).size(),
		])
	lines.append("")
	lines.append("강화 확률 (실패해도 골드 소모)")
	for i in UnitData.UPGRADE_CHANCE.size():
		lines.append("%d성 → %d성  %d%%" % [i + 1, i + 2, roundi(UnitData.UPGRADE_CHANCE[i] * 100.0)])
	lines.append("")
	lines.append("조합: 같은 유닛 2개를 겹치면")
	lines.append("상위 등급 유닛 1개가 랜덤으로 나온다")
	var costs: Array[String] = []
	for grade in Catalog.GRADE_ODDS:
		if UnitData.MERGE_COST[grade] > 0:
			costs.append("%s %dG" % [UnitData.GRADE_NAMES[grade], UnitData.MERGE_COST[grade]])
	lines.append("조합 비용: " + " / ".join(costs))
	lines.append("")
	lines.append("증강: 뽑기 %d회마다, 보스 처치마다" % AugmentManager.DRAWS_PER_OFFER)
	lines.append("같은 능력치 구역은 %d개까지 겹쳐 적용" % GridManager.MAX_ZONE_STACK)
	return "\n".join(lines)

func _on_gold_changed(gold: int) -> void:
	gold_label.text = "GOLD %d" % gold
	gacha_button.disabled = gold < GameState.GACHA_COST
	_refresh_upgrade_button()

func _on_lives_changed(lives: int) -> void:
	lives_label.text = "LIFE %d" % lives

func _on_game_ended(cleared: bool) -> void:
	result_label.text = "CLEAR" if cleared else "GAME OVER"
	var story := "이 구역의 확률이 안정화되었습니다." if cleared else "방어선 붕괴. 오늘의 확률은 당신 편이 아니었습니다."
	result_detail.text = "%s\n도달 웨이브 %d/%d" % [story, _wave_manager.wave, _wave_manager.total_waves]
	result_panel.modulate.a = 0.0
	result_panel.show()
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(result_panel, "modulate:a", 1.0, RESULT_FADE_TIME)

func _on_wave_button_pressed() -> void:
	wave_start_pressed.emit()

func _on_gacha_button_pressed() -> void:
	gacha_pressed.emit()

func _on_upgrade_button_pressed() -> void:
	upgrade_pressed.emit()

func _on_speed_button_pressed() -> void:
	var next := (SPEEDS.find(Engine.time_scale) + 1) % SPEEDS.size()
	Engine.time_scale = SPEEDS[next]
	speed_button.text = "x%d" % SPEEDS[next]

func _on_pause_button_pressed() -> void:
	pause_menu.open()

func _on_ultimate_button_pressed() -> void:
	ultimate_pressed.emit()

func _on_augment_card_pressed(index: int) -> void:
	augment_chosen.emit(index)

func _on_odds_button_pressed() -> void:
	odds_panel.visible = not odds_panel.visible

func _on_odds_close_button_pressed() -> void:
	odds_panel.hide()

func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_title_button_pressed() -> void:
	title_requested.emit()
