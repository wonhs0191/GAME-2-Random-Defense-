extends SceneTree

# B~S 등급 행성 스프라이트 시트 생성기. 외부 에셋 없이 노이즈로 그린다.
# 사용: Godot --headless --path . --script res://tools/generate_planets.gd
#
# 구를 한 바퀴 돌리는 방식이라 마지막 프레임이 첫 프레임으로 자연스럽게 이어진다.

const OUT_DIR := "res://entities/units/generated"
const COLUMNS := 10
const ROWS := 6
const FRAME_COUNT := COLUMNS * ROWS
const LIGHT := Vector3(-0.55, -0.6, 0.58)
const SHADE_STEPS := 4.0
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
]

var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _colors: Array[Color] = []

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for spec in SPECS:
		_render(spec)
		print("generated ", spec["id"])
	quit()

func _render(spec: Dictionary) -> void:
	var size: int = spec["size"]
	_colors.clear()
	for hex: String in spec["colors"]:
		_colors.append(Color(hex))
	_setup_noise(_noise, spec["seed"], 3)
	_setup_noise(_detail, spec["seed"] + 100, 2)

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
