extends SceneTree

# B~S 등급 행성 스프라이트 시트 생성기. 외부 에셋 없이 노이즈로 그린다.
# 사용: Godot --headless --path . --script res://tools/generate_planets.gd
#
# 구를 한 바퀴 돌리는 방식이라 마지막 프레임이 첫 프레임으로 자연스럽게 이어진다.

const OUT_DIR := "res://entities/units/generated"
const ICON_PATH := "res://assets/icon.png"
const ICON_SOURCE := "PRD-A-FS-03" # 앱 아이콘으로 쓸 행성
const ICON_SCALE := 4
const COLUMNS := 10
const ROWS := 6
const FRAME_COUNT := COLUMNS * ROWS
const LIGHT := Vector3(-0.55, -0.6, 0.58)
const SHADE_STEPS := 4.0
const CRATER_COUNT := 14
const SPECS := [
	{"id": "PRD-B-FR-01", "kind": "ice", "size": 52, "seed": 11, "colors": ["0e2a5c", "2f6fb5", "8fd3ee", "e8f7ff"]},
	{"id": "PRD-B-FR-02", "kind": "wet", "size": 52, "seed": 12, "colors": ["123a7a", "2670b8", "3f9a58", "8cc56a", "f2f7ff"]},
	{"id": "PRD-B-FS-01", "kind": "gas", "size": 52, "seed": 13, "colors": ["7a3f22", "b86a35", "e3a862", "f6dfb0"]},
	{"id": "PRD-B-FS-02", "kind": "gas", "size": 52, "seed": 14, "colors": ["2c2a6e", "4f4fb0", "8a86dc", "d6d2ff"]},
	{"id": "PRD-B-FS-03", "kind": "wet", "size": 52, "seed": 15, "colors": ["0f4a5c", "1f8c94", "c9b458", "e9dc98", "ffffff"]},
	{"id": "PRD-A-FR-01", "kind": "lava", "size": 56, "seed": 21, "colors": ["1f1420", "4a2230", "ff5a1f", "ffd23f"]},
	{"id": "PRD-A-FR-02", "kind": "lava", "size": 56, "seed": 22, "colors": ["14142a", "2e2450", "c02cff", "ff9cf0"]},
	{"id": "PRD-A-FR-03", "kind": "ring", "size": 56, "seed": 23, "colors": ["5a3a7a", "9060b8", "d0a0e8", "f8e0ff"]},
	{"id": "PRD-A-FS-01", "kind": "star", "size": 56, "seed": 24, "colors": ["ff6a13", "ffa31a", "ffd84a", "fff6c8"]},
	{"id": "PRD-A-FS-02", "kind": "star", "size": 56, "seed": 25, "colors": ["1f6bff", "4aa8ff", "9fe0ff", "f2fdff"]},
	{"id": "PRD-A-FS-03", "kind": "ring", "size": 56, "seed": 26, "colors": ["80521f", "c08a3e", "edc97a", "fff0c4"]},
	{"id": "PRD-S-FR-01", "kind": "blackhole", "size": 60, "seed": 31, "colors": ["7a1a10", "e0551a", "ffb32e", "fff4c9"]},
	{"id": "PRD-S-FR-02", "kind": "blackhole", "size": 60, "seed": 32, "colors": ["3a1078", "8a2be2", "e060ff", "ffe0ff"]},
	{"id": "PRD-S-FS-01", "kind": "galaxy", "size": 60, "seed": 33, "colors": ["2a1a6e", "7a3fd0", "e070d8", "fff0ff"]},
	{"id": "PRD-S-FS-02", "kind": "galaxy", "size": 60, "seed": 34, "colors": ["0f3a6e", "1f8ac0", "70e0d0", "f0fff8"]},
	{"id": "PRD-S-FS-03", "kind": "galaxy", "size": 60, "seed": 35, "colors": ["6e1f1a", "d0502a", "ffb040", "fff8e0"]},
	{"id": "PRD-S-FS-04", "kind": "blackhole", "size": 60, "seed": 36, "colors": ["0f4a4a", "20a8a0", "80f0d0", "f0fff4"]},
	{"id": "PRD-C-FR-05", "kind": "desert", "size": 50, "seed": 41, "colors": ["7a4a1f", "b87a35", "e0b060", "f6e0a8"]},
	{"id": "PRD-C-FR-06", "kind": "desert", "size": 50, "seed": 42, "colors": ["6e2a1f", "a84a2c", "d87a4a", "f0b080"]},
	{"id": "PRD-C-FR-08", "kind": "desert", "size": 50, "seed": 43, "colors": ["8a7a5a", "b8a880", "dcd0a8", "f4ecd0"]},
	{"id": "PRD-C-FR-09", "kind": "desert", "size": 50, "seed": 44, "colors": ["3a3a44", "5c5a66", "8a8690", "bcb8c0"]},
	{"id": "PRD-C-FS-08", "kind": "crater", "size": 50, "seed": 45, "colors": ["3a3c44", "62666e", "8c9098", "c0c4cc"]},
	{"id": "PRD-C-FS-09", "kind": "crater", "size": 50, "seed": 46, "colors": ["4a3050", "745080", "a080a8", "d0b8d8"]},
	{"id": "PRD-C-FS-10", "kind": "crater", "size": 50, "seed": 47, "colors": ["1f4a50", "3a7a7a", "68a8a0", "a8d8c8"]},
	{"id": "PRD-C-FS-11", "kind": "crater", "size": 50, "seed": 48, "colors": ["4a3020", "7a5238", "a87c58", "d8b490"]},
	{"id": "PRD-B-FR-03", "kind": "ocean", "size": 52, "seed": 51, "colors": ["0c2a6e", "1a56b0", "4fc0c8", "e0f0d0"]},
	{"id": "PRD-B-FR-04", "kind": "ocean", "size": 52, "seed": 52, "colors": ["2a0c5e", "5a2ab0", "c060d0", "f8e0f0"]},
	{"id": "PRD-B-FR-05", "kind": "wet", "size": 52, "seed": 53, "colors": ["1a4a3a", "2a8a70", "a8882c", "d8c060", "f8f8e8"]},
	{"id": "PRD-B-FR-06", "kind": "ice", "size": 52, "seed": 54, "colors": ["2a1a5c", "5a50b0", "b0a8ec", "f4f0ff"]},
	{"id": "PRD-B-FR-07", "kind": "toxic", "size": 52, "seed": 55, "colors": ["1f3a14", "4a7a1c", "a0c82c", "f0ff80"]},
	{"id": "PRD-B-FS-04", "kind": "gas", "size": 52, "seed": 56, "colors": ["6e1f3a", "b0406a", "e880a0", "fcd0e0"]},
	{"id": "PRD-B-FS-05", "kind": "gas", "size": 52, "seed": 57, "colors": ["1a4a5e", "2a88a0", "70d0d8", "d8fcfc"]},
	{"id": "PRD-B-FS-06", "kind": "gas", "size": 52, "seed": 58, "colors": ["5a4a1a", "a08a2a", "e0d060", "fcf8c0"]},
	{"id": "PRD-B-FS-07", "kind": "toxic", "size": 52, "seed": 59, "colors": ["3a1450", "7a2c90", "c060c8", "f8c0ff"]},
	{"id": "PRD-B-FS-08", "kind": "toxic", "size": 52, "seed": 60, "colors": ["143a3a", "1f7a60", "50c890", "d0ffc0"]},
	{"id": "PRD-B-FS-09", "kind": "storm", "size": 52, "seed": 61, "colors": ["7a3a1a", "c07030", "f0b070", "fff0d8"]},
	{"id": "PRD-A-FR-04", "kind": "crystal", "size": 56, "seed": 71, "colors": ["1a2a6e", "3a6ad0", "80c8ff", "f0fcff"]},
	{"id": "PRD-A-FR-05", "kind": "crystal", "size": 56, "seed": 72, "colors": ["6e1a4a", "d03a90", "ff90c8", "fff0f8"]},
	{"id": "PRD-A-FR-06", "kind": "shattered", "size": 56, "seed": 73, "colors": ["2a1a1f", "5a3a34", "a07058", "ffb040"]},
	{"id": "PRD-A-FS-04", "kind": "binary", "size": 56, "seed": 74, "colors": ["e0501a", "ffb030", "ffe8a0", "fffdf0"]},
	{"id": "PRD-A-FS-05", "kind": "star", "size": 56, "seed": 75, "colors": ["c01a4a", "ff4a70", "ff9ab0", "fff0f0"]},
	{"id": "PRD-A-FS-06", "kind": "ring", "size": 56, "seed": 76, "colors": ["1f5a50", "3aa088", "90e0c0", "f0fff0"]},
	{"id": "PRD-A-FS-07", "kind": "crystal", "size": 56, "seed": 77, "colors": ["1a5a2a", "3ab060", "90f0a0", "f4fff0"]},
	{"id": "PRD-A-FS-08", "kind": "shattered", "size": 56, "seed": 78, "colors": ["141a2a", "34506e", "7098b8", "60e8ff"]},
	{"id": "PRD-S-FR-03", "kind": "nebula", "size": 60, "seed": 81, "colors": ["3a106e", "a02ac0", "ff70a8", "fff0e0"]},
	{"id": "PRD-S-FR-04", "kind": "dyson", "size": 60, "seed": 82, "colors": ["5a6478", "ffb030", "ffe080", "fffdf0"]},
	{"id": "PRD-S-FS-05", "kind": "pulsar", "size": 60, "seed": 83, "colors": ["1a50c0", "50a8ff", "c8f0ff", "ffffff"]},
	{"id": "PRD-S-FS-06", "kind": "pulsar", "size": 60, "seed": 84, "colors": ["c0301a", "ff7a30", "ffd890", "ffffff"]},
]

var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _cells := FastNoiseLite.new()
var _colors: Array[Color] = []
var _craters: Array[Vector3] = []

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for spec in SPECS:
		_render(spec)
		print("generated ", spec["id"])
	_save_icon()
	quit()

func _save_icon() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, ICON_SOURCE]))
	var size := sheet.get_width() / COLUMNS
	var icon := sheet.get_region(Rect2i(0, 0, size, size))
	icon.resize(size * ICON_SCALE, size * ICON_SCALE, Image.INTERPOLATE_NEAREST)
	icon.save_png(ICON_PATH)

func _render(spec: Dictionary) -> void:
	var size: int = spec["size"]
	_colors.clear()
	for hex: String in spec["colors"]:
		_colors.append(Color(hex))
	_setup_noise(_noise, spec["seed"], 3)
	_setup_noise(_detail, spec["seed"] + 100, 2)
	_cells.seed = spec["seed"]
	_cells.noise_type = FastNoiseLite.TYPE_CELLULAR
	_cells.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	_cells.fractal_type = FastNoiseLite.FRACTAL_NONE
	_cells.frequency = 2.2
	_scatter_craters(spec["seed"])

	var shade_fn := Callable(self, "_" + spec["kind"])
	var sheet := Image.create(size * COLUMNS, size * ROWS, false, Image.FORMAT_RGBA8)
	var radius := size * 0.46
	for frame in FRAME_COUNT:
		var phase := TAU * frame / FRAME_COUNT
		var origin := Vector2i(frame % COLUMNS, frame / COLUMNS) * size
		for y in size:
			for x in size:
				var uv := (Vector2(x, y) + Vector2.ONE * 0.5 - Vector2.ONE * size / 2.0) / radius
				var color: Color = shade_fn.call(uv, phase)
				if color.a > 0.0:
					sheet.set_pixelv(origin + Vector2i(x, y), color)
	sheet.save_png("%s/%s.png" % [OUT_DIR, spec["id"]])

# 크레이터 위치. 구 위의 방향으로 고정해 행성과 함께 돈다.
func _scatter_craters(crater_seed: int) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = crater_seed
	_craters.clear()
	for i in CRATER_COUNT:
		_craters.append(Vector3(random.randf_range(-1, 1), random.randf_range(-1, 1), random.randf_range(-1, 1)).normalized())

func _setup_noise(noise: FastNoiseLite, noise_seed: int, octaves: int) -> void:
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 1.0
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves

func _palette(t: float) -> Color:
	return _colors[clampi(int(t * _colors.size()), 0, _colors.size() - 1)]

func _sphere(uv: Vector2) -> Vector3:
	return Vector3(uv.x, uv.y, sqrt(maxf(1.0 - uv.length_squared(), 0.0)))

func _spin(normal: Vector3, phase: float) -> Vector3:
	return normal.rotated(Vector3.RIGHT, 0.35).rotated(Vector3.UP, phase)

func _sample(noise: FastNoiseLite, p: Vector3) -> float:
	return noise.get_noise_3dv(p)

# 빛을 몇 단계로만 나눠 픽셀 아트 음영을 만든다.
func _lit(color: Color, normal: Vector3) -> Color:
	var light := clampf(normal.dot(LIGHT.normalized()) * 0.75 + 0.45, 0.0, 1.0)
	return color.darkened((1.0 - floorf(light * SHADE_STEPS) / SHADE_STEPS) * 0.8)

func _gas(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var band := p.y * 4.5 + _sample(_noise, p * 1.4) * 1.6
	return _lit(_palette((sin(band * PI) + 1.0) / 2.0), normal)

func _wet(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var color := _colors[0]
	if abs(p.y) + _sample(_detail, p * 2.0) * 0.2 > 0.82:
		color = _colors[4]
	elif _sample(_noise, p * 1.5) > 0.02:
		color = _colors[3] if _sample(_detail, p * 3.0) > 0.0 else _colors[2]
	elif _sample(_detail, p * 2.4) > -0.05:
		color = _colors[1]
	# 구름은 땅보다 두 배 빠르게 돈다
	if _sample(_noise, _spin(normal, phase * 2.0) * 2.0 + Vector3.ONE * 5.0) > 0.22:
		color = _colors[4]
	return _lit(color, normal)

func _ice(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var value := _sample(_noise, p * 1.8)
	var color := _colors[3]
	if value < -0.22:
		color = _colors[0]
	elif value < -0.05:
		color = _colors[1]
	elif value < 0.12:
		color = _colors[2]
	return _lit(color, normal)

func _lava(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var crack := absf(_sample(_noise, p * 2.0))
	if crack < 0.035:
		return _colors[3]
	if crack < 0.09:
		return _colors[2]
	return _lit(_colors[1] if _sample(_detail, p * 3.0) > 0.0 else _colors[0], normal)

func _star(uv: Vector2, phase: float) -> Color:
	var scaled := uv * 1.3 # 코로나 자리를 남긴다
	var distance := scaled.length()
	if distance < 1.0:
		var p := _spin(_sphere(scaled), phase)
		return _palette((_sample(_noise, p * 2.4) + 0.5) * 0.9 + (1.0 - distance) * 0.5)
	if distance > 1.3:
		return Color.TRANSPARENT
	var angle := scaled.angle()
	var flare := _sample(_noise, Vector3(cos(angle) * 2.0, sin(angle) * 2.0, cos(phase) + sin(phase)))
	if (distance - 1.0) / 0.3 < flare * 1.5 + 0.35:
		return Color(_colors[1], 0.75)
	return Color.TRANSPARENT

func _ring(uv: Vector2, phase: float) -> Color:
	var scaled := uv * 1.65
	var tilted := scaled.rotated(-0.35)
	var ring_uv := Vector2(tilted.x, tilted.y / 0.3)
	var ring_distance := ring_uv.length()
	var on_ring := ring_distance > 1.3 and ring_distance < 1.62
	var on_planet := scaled.length_squared() < 1.0
	# 고리는 앞쪽만 행성을 가린다
	if on_ring and (tilted.y > 0.0 or not on_planet):
		var spin := ring_uv.normalized().rotated(phase) * 2.0
		var shade := _sample(_detail, Vector3(spin.x, spin.y, ring_distance * 3.0))
		return _colors[3] if shade > 0.05 else _colors[2]
	if on_planet:
		return _gas(scaled, phase)
	return Color.TRANSPARENT

func _galaxy(uv: Vector2, phase: float) -> Color:
	var tilted := uv.rotated(0.5)
	var flat := Vector2(tilted.x, tilted.y / 0.6)
	var distance := flat.length()
	if distance > 1.0:
		return Color.TRANSPARENT
	var angle := flat.angle()
	var arm := (sin(2.0 * (angle - phase) + distance * 7.0) + 1.0) / 2.0
	var turning := flat.rotated(-phase) * 3.0
	var density := arm * (1.0 - distance) * 1.3 + _sample(_noise, Vector3(turning.x, turning.y, 0.0)) * 0.5
	density += exp(-distance * distance * 28.0) * 1.2
	if density < 0.14:
		return Color.TRANSPARENT
	return _palette((density - 0.14) * 1.4)

func _desert(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var dune := sin((p.y * 7.0 + _sample(_noise, p * 1.6) * 5.0) * PI)
	return _lit(_palette((dune + 1.0) / 2.0 * 0.7 + (_sample(_detail, p * 3.0) + 0.3) * 0.5), normal)

func _crater(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var color := _palette((_sample(_noise, p * 2.2) + 0.6) * 0.85)
	for index in _craters.size():
		var size := 0.1 + 0.06 * (index % 3)
		var distance := p.distance_to(_craters[index])
		if distance < size * 0.7:
			color = _colors[0]
		elif distance < size:
			color = _colors[3]
	return _lit(color, normal)

func _ocean(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var land := _sample(_noise, p * 2.0)
	var color := _colors[1] if _sample(_detail, p * 2.6) > -0.05 else _colors[0]
	if land > 0.3:
		color = _colors[3]
	elif land > 0.2:
		color = _colors[2]
	if _sample(_noise, _spin(normal, phase * 2.0) * 2.4 + Vector3.ONE * 7.0) > 0.26:
		color = _colors[3]
	return _lit(color, normal)

func _toxic(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var swirl := p.y * 3.0 + _sample(_noise, p * 2.0) * 3.2
	var color := _palette((sin(swirl * PI) + 1.0) / 2.0 * 0.75)
	if _sample(_detail, _spin(normal, phase * 2.0) * 3.5) > 0.24:
		color = _colors[3]
	return _lit(color, normal)

func _storm(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var eye := Vector3(0.0, -0.32, 0.95).normalized()
	var distance := p.distance_to(eye)
	if distance < 0.5:
		var side := (p - eye).normalized()
		var angle := atan2(side.y, side.x)
		return _lit(_palette((sin(distance * 26.0 + angle * 2.0) + 1.0) / 2.0 * (0.5 + distance)), normal)
	return _gas(uv, phase)

func _crystal(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var facet := (_cells.get_noise_3dv(p) + 1.0) / 2.0
	var color := _palette(facet)
	# 면마다 빛이 튀어 반짝인다
	if sin(facet * 40.0 + phase * 3.0) > 0.93:
		color = _colors[3]
	return color.darkened((1.0 - clampf(normal.dot(LIGHT.normalized()) * 0.6 + 0.7, 0.0, 1.0)) * 0.7)

func _shattered(uv: Vector2, phase: float) -> Color:
	var scaled := uv * 1.35
	for i in 7:
		var angle := phase * (1 + i % 2) + TAU * i / 7.0
		var fragment := Vector2(cos(angle) * 1.2, sin(angle) * 0.34).rotated(-0.3)
		if scaled.distance_to(fragment) < 0.075 + 0.03 * (i % 3):
			return _colors[2]
	if scaled.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(scaled)
	var p := _spin(normal, phase)
	var crack := absf(_sample(_noise, p * 1.3))
	if crack < 0.03:
		return _colors[3]
	if crack < 0.06:
		return Color.TRANSPARENT
	return _lit(_colors[2] if _sample(_detail, p * 3.0) > 0.08 else _colors[1 if crack > 0.15 else 0], normal)

func _binary(uv: Vector2, phase: float) -> Color:
	var orbit := Vector2(cos(phase), sin(phase) * 0.42) * 0.5
	var bodies := [[orbit, 0.0], [-orbit, 3.0]] if sin(phase) > 0.0 else [[-orbit, 3.0], [orbit, 0.0]]
	for body: Array in bodies:
		var local: Vector2 = (uv - body[0]) / 0.42
		if local.length_squared() < 1.0:
			var p := _spin(_sphere(local), phase * 2.0)
			var heat := (_sample(_noise, p * 2.2 + Vector3.ONE * float(body[1])) + 0.5) * 0.8 + (1.0 - local.length()) * 0.5
			return _palette(clampf(heat, 0.0, 0.99) * (0.75 if body[1] > 0.0 else 1.0))
	if absf(uv.length() - 0.5) < 0.025:
		return Color(_colors[1], 0.4)
	return Color.TRANSPARENT

func _pulsar(uv: Vector2, phase: float) -> Color:
	var distance := uv.length()
	if distance < 0.22:
		return _colors[3]
	if distance < 0.3:
		return _colors[2]
	var direction := Vector2.from_angle(phase - 0.6)
	var along := absf(uv.dot(direction))
	var across := absf(uv.cross(direction))
	if distance < 1.05 and across < 0.05 + along * 0.1:
		return _colors[2] if across < 0.04 else Color(_colors[1], 0.8)
	var ring := absf(distance - 0.62 - _sample(_noise, Vector3(uv.x, uv.y, 0.0).normalized() * 1.5) * 0.15)
	if ring < 0.035:
		return Color(_colors[0], 0.9)
	return Color.TRANSPARENT

func _nebula(uv: Vector2, phase: float) -> Color:
	var distance := uv.length()
	if distance > 1.0:
		return Color.TRANSPARENT
	var turning := uv.rotated(-phase)
	var cloud := (_sample(_noise, Vector3(turning.x, turning.y, 0.0) * 1.7) + 0.55) * (1.0 - distance * distance)
	if distance < 0.16:
		return _colors[3]
	var sparkle := fposmod(sin(turning.x * 91.0 + turning.y * 37.0) * 4375.0, 1.0)
	if sparkle > 0.985 and cloud > 0.1:
		return Color.WHITE
	if cloud < 0.2:
		return Color.TRANSPARENT
	return _palette((cloud - 0.2) * 2.4)

func _dyson(uv: Vector2, phase: float) -> Color:
	if uv.length_squared() >= 1.0:
		return Color.TRANSPARENT
	var normal := _sphere(uv)
	var p := _spin(normal, phase)
	var longitude := atan2(p.z, p.x)
	var latitude := asin(clampf(p.y, -1.0, 1.0))
	var on_rib := fposmod(longitude * 8.0 / TAU, 1.0) < 0.18 or fposmod(latitude * 5.0 / PI, 1.0) < 0.2
	if on_rib:
		return _lit(_colors[0], normal)
	if uv.length_squared() < 0.5:
		return _palette((_sample(_noise, _spin(_sphere(uv / 0.71), -phase) * 2.2) + 0.5) * 0.8 + 0.25)
	return Color.TRANSPARENT

func _blackhole(uv: Vector2, phase: float) -> Color:
	var distance := uv.length()
	var tilted := uv.rotated(0.4)
	var disk := Vector2(tilted.x, tilted.y / 0.4)
	var disk_distance := disk.length()
	var on_disk := disk_distance > 0.72 and disk_distance < 1.08
	if on_disk and (tilted.y > 0.0 or distance > 0.5):
		var turning := disk.normalized().rotated(phase) * 2.0
		var heat := _sample(_noise, Vector3(turning.x, turning.y, disk_distance * 4.0))
		# 다가오는 쪽이 더 밝다
		return _palette(0.45 + heat + cos(disk.angle()) * 0.3)
	if distance < 0.5:
		return Color(0.0, 0.0, 0.02)
	if distance < 0.58:
		return _colors[3]
	if distance < 0.64:
		return _colors[1]
	return Color.TRANSPARENT
