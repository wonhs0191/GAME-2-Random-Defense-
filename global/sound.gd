extends Node

# 효과음과 BGM. 소리 파일은 tools/generate_audio.py로 만든다.

const SFX_PATH := "res://assets/audio/sfx/%s.wav"
const BGM_PATH := "res://assets/audio/bgm/%s.wav"
const BGM_BUS := "BGM"
const SFX_BUS := "SFX"
const PLAYER_COUNT := 16
const BGM_FADE_TIME := 1.2

# 자주 나는 소리는 간격을 둔다 (밀리초). 한꺼번에 울리면 소리가 뭉개진다.
const MIN_REPEAT_MS := {"shot": 70, "enemy_die": 50, "firework": 60}

var current_bgm: String = ""
var last_sfx: String = ""

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _bgm_players: Array[AudioStreamPlayer] = []
var _active_bgm: int = 0
var _fade_tween: Tween = null
var _playlist: Array = []
var _playlist_index: int = -1
var _next_player: int = 0
var _last_played_ms: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # 일시 정지 메뉴에서도 소리가 나야 한다
	_add_bus(BGM_BUS)
	_add_bus(SFX_BUS)
	for i in 2: # 곡이 바뀔 때 겹쳐서 넘긴다
		var bgm_player := AudioStreamPlayer.new()
		bgm_player.bus = BGM_BUS
		add_child(bgm_player)
		_bgm_players.append(bgm_player)
	for i in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_players.append(player)

func _add_bus(bus_name: String) -> void:
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")

func set_volumes(bgm: float, sfx: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BGM_BUS), linear_to_db(bgm))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), linear_to_db(sfx))

func play(sfx_name: String) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_played_ms.get(sfx_name, -100000) < MIN_REPEAT_MS.get(sfx_name, 0):
		return
	_last_played_ms[sfx_name] = now
	last_sfx = sfx_name
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % PLAYER_COUNT
	player.stream = _get_stream(SFX_PATH % sfx_name)
	player.play()

# 한 곡을 반복한다.
func play_bgm(bgm_name: String) -> void:
	_playlist = []
	_switch_bgm(bgm_name)

# 곡이 끝날 때마다 다음 곡으로 넘어간다. 보스전 뒤에 다시 부르면 이어서 다음 곡부터 나온다.
func play_playlist(bgm_names: Array) -> void:
	if _playlist == bgm_names:
		return
	_playlist = bgm_names
	next_in_playlist()

func next_in_playlist() -> void:
	_playlist_index = (_playlist_index + 1) % _playlist.size()
	_switch_bgm(_playlist[_playlist_index])

func _process(_delta: float) -> void:
	if _playlist.is_empty():
		return
	var player := _bgm_players[_active_bgm]
	if player.playing and player.get_playback_position() >= player.stream.get_length() - BGM_FADE_TIME:
		next_in_playlist()

func _switch_bgm(bgm_name: String) -> void:
	if bgm_name == current_bgm:
		return
	current_bgm = bgm_name
	var stream := _get_stream(BGM_PATH % bgm_name)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	var fading_out := _bgm_players[_active_bgm]
	_active_bgm = 1 - _active_bgm
	var fading_in := _bgm_players[_active_bgm]
	fading_in.stream = stream
	fading_in.volume_linear = 0.0
	fading_in.play()
	_fade(fading_in, fading_out)

func stop_bgm() -> void:
	current_bgm = ""
	_playlist = []
	_fade(null, _bgm_players[_active_bgm])

func _fade(fading_in: AudioStreamPlayer, fading_out: AudioStreamPlayer) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween().set_parallel()
	if fading_in:
		_fade_tween.tween_property(fading_in, "volume_linear", 1.0, BGM_FADE_TIME)
	_fade_tween.tween_property(fading_out, "volume_linear", 0.0, BGM_FADE_TIME)
	_fade_tween.chain().tween_callback(fading_out.stop)

# 아래 모든 버튼에 클릭 소리를 붙인다. 씬이 겹쳐 있어도 한 번만 붙는다.
func bind_buttons(root: Node) -> void:
	var click := play.bind("ui_click")
	for button: BaseButton in root.find_children("*", "BaseButton", true, false):
		if not button.pressed.is_connected(click):
			button.pressed.connect(click)

func _get_stream(path: String) -> AudioStreamWAV:
	if not _streams.has(path):
		_streams[path] = load(path)
	return _streams[path]
