extends Node

# 행성 도감의 발견 기록. 게임을 다시 켜도 유지되도록 파일에 저장한다.

const SECTION := "discovered"

var path: String = "user://codex.cfg"
var persist: bool = true

var _discovered: Dictionary = {} # id -> true

func _ready() -> void:
	# 테스트와 봇이 뽑은 행성이 실제 도감에 남으면 안 된다
	for argument in OS.get_cmdline_args():
		if argument.begins_with("res://tests/"):
			persist = false
	load_codex()

func load_codex() -> void:
	_discovered.clear()
	var file := ConfigFile.new()
	if not persist or file.load(path) != OK or not file.has_section(SECTION):
		return
	for id in file.get_section_keys(SECTION):
		_discovered[id] = true

func is_discovered(id: String) -> bool:
	return _discovered.has(id)

func discovered_count() -> int:
	return _discovered.size()

# 처음 발견했으면 true.
func discover(id: String) -> bool:
	if _discovered.has(id):
		return false
	_discovered[id] = true
	if persist:
		var file := ConfigFile.new()
		for key in _discovered:
			file.set_value(SECTION, key, true)
		file.save(path)
	return true
