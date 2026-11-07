extends ColorRect

# 행성 도감. 뽑기나 조합으로 얻은 행성만 정보가 보이고 나머지는 실루엣으로 남는다.

const GRADE_ORDER := [UnitData.Grade.S, UnitData.Grade.A, UnitData.Grade.B, UnitData.Grade.C]
const SLOT_SIZE := Vector2(64, 64)
const DETAIL_SIZE := 150.0
const LOCKED_COLOR := Color(0.0, 0.0, 0.05, 0.9)
const FRAME_RATE := 7.5

var _slots: Dictionary = {} # UnitData -> TextureButton
var _selected: UnitData = null
var _frame_time: float = 0.0

@onready var rows: VBoxContainer = $Box/Rows
@onready var progress_label: Label = $Box/ProgressLabel
@onready var detail_planet: Sprite2D = $Box/DetailPlanet
@onready var detail_name: Label = $Box/DetailName
@onready var detail_text: Label = $Box/DetailText
@onready var selection_frame: Panel = $Box/SelectionFrame

func _ready() -> void:
	Sound.bind_buttons(self)
	for grade in GRADE_ORDER:
		_add_grade_row(grade)

func _add_grade_row(grade: UnitData.Grade) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	rows.add_child(row)
	var label := Label.new()
	label.text = UnitData.GRADE_NAMES[grade]
	label.custom_minimum_size = Vector2(36, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", UnitData.GRADE_COLORS[grade])
	row.add_child(label)
	for unit in Catalog.units_of_grade(grade):
		var slot := TextureButton.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.ignore_texture_size = true
		slot.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot.focus_mode = Control.FOCUS_NONE
		slot.texture_normal = unit.get_thumbnail()
		slot.tooltip_text = "???"
		slot.pressed.connect(select.bind(unit))
		slot.mouse_entered.connect(select.bind(unit))
		row.add_child(slot)
		_slots[unit] = slot

func open() -> void:
	progress_label.text = "발견 %d / %d" % [Codex.discovered_count(), Catalog.units.size()]
	for unit: UnitData in _slots:
		var slot: TextureButton = _slots[unit]
		var known := Codex.is_discovered(unit.id)
		slot.modulate = Color.WHITE if known else LOCKED_COLOR
		slot.tooltip_text = unit.id if known else "???"
	show()
	select(_first_discovered())

func close() -> void:
	hide()

func _first_discovered() -> UnitData:
	for grade in GRADE_ORDER:
		for unit in Catalog.units_of_grade(grade):
			if Codex.is_discovered(unit.id):
				return unit
	return Catalog.units[0]

func select(unit: UnitData) -> void:
	_selected = unit
	_frame_time = 0.0
	selection_frame.show()
	var known := Codex.is_discovered(unit.id)
	detail_planet.texture = load(unit.sheet_path)
	detail_planet.hframes = unit.sheet_columns
	detail_planet.vframes = unit.sheet_rows
	detail_planet.frame = 0
	detail_planet.scale = Vector2.ONE * DETAIL_SIZE / (detail_planet.texture.get_width() / float(unit.sheet_columns))
	detail_planet.modulate = Color.WHITE if known else LOCKED_COLOR
	detail_name.modulate = UnitData.GRADE_COLORS[unit.grade]
	if known:
		detail_name.text = unit.get_display_name()
		detail_text.text = _build_detail(unit)
	else:
		detail_name.text = "???"
		detail_text.text = "%s등급 행성\n\n아직 발견하지 못했습니다.\n뽑기나 조합으로 얻으면 기록됩니다." % unit.get_grade_name()

func _build_detail(unit: UnitData) -> String:
	var lines: Array[String] = [
		"%s등급  %s 공격" % [unit.get_grade_name(), UnitData.ATTACK_TYPE_NAMES[unit.attack_type]],
		"뽑기 확률 %.1f%% (등급 전체)" % Catalog.GRADE_ODDS[unit.grade],
		"",
		"공격력 %.0f  공격 간격 %.2f초" % [unit.damage, unit.attack_interval],
		"초당 피해 %.1f" % (unit.damage / unit.attack_interval),
		"사거리 %d" % unit.attack_range,
	]
	if unit.attack_type == UnitData.AttackType.ZONE:
		lines.append("장판 반경 %d" % unit.zone_radius)
	lines.append("")
	lines.append(unit.description)
	return "\n".join(lines)

func _process(delta: float) -> void:
	if not visible or _selected == null:
		return
	_frame_time += delta
	detail_planet.frame = int(_frame_time * FRAME_RATE) % (detail_planet.hframes * detail_planet.vframes)
	# 처음 열 때는 칸 배치가 늦게 끝나므로 매 프레임 맞춘다
	selection_frame.global_position = _slots[_selected].global_position

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_close_button_pressed() -> void:
	close()
