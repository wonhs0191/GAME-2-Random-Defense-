extends SceneTree

# A·S 등급 공격 이펙트 생성기. 외부 에셋 없이 그린다.
# 사용: Godot --headless --path . --script res://tools/generate_effects.gd
#
# SHOT은 회전하는 구체, ZONE은 원 안에서 피어오르는 입자다. 둘 다 끊김 없이 반복된다.

const OUT_DIR := "res://entities/units/generated/effects"
const SHOT_SIZE := 20
const SHOT_FRAMES := 16
const ZONE_SIZE := 32
const ZONE_FRAMES := 30
const ZONE_PARTICLES := 26
const SHOTS := {
	"shot_gold": ["ff7a1a", "ffd84a", "fffbe0"], "shot_blue": ["1f6bff", "6fc8ff", "f0fdff"],
	"shot_amber": ["a8641f", "edc97a", "fff4d0"], "shot_violet": ["7a2be2", "e070d8", "fff0ff"],
	"shot_teal": ["1f8ac0", "70e0d0", "f0fff8"], "shot_ember": ["d0502a", "ffb040", "fff8e0"],
	"shot_jade": ["20a8a0", "80f0d0", "f0fff4"],
	"shot_rose": ["c01a4a", "ff7a9a", "fff0f4"], "shot_lime": ["3ab060", "b0f080", "f8fff0"],
	"shot_ice": ["3a6ad0", "90d8ff", "f0fcff"], "shot_nova": ["e0501a", "ffd060", "fffdf0"],
}
const ZONES := {
	"zone_lava": ["ff5a1f", "ffd23f"], "zone_violet": ["c02cff", "ff9cf0"], "zone_lilac": ["9060b8", "f8e0ff"],
	"zone_flare": ["e0551a", "fff4c9"], "zone_abyss": ["8a2be2", "ffe0ff"],
	"zone_prism": ["3a6ad0", "c0f0ff"], "zone_rose": ["d03a90", "ffd0e8"], "zone_ember": ["a07058", "ffb040"],
	"zone_nebula": ["a02ac0", "ffc0d8"], "zone_sun": ["ffb030", "fffdf0"],
}

func _init() -> void:
	for effect_name in SHOTS:
		_render_shot(effect_name, SHOTS[effect_name])
	for effect_name in ZONES:
		_render_zone(effect_name, ZONES[effect_name])
	print("generated effects")
	quit()

func _render_shot(effect_name: String, hexes: Array) -> void:
	var dir: String = OUT_DIR.path_join(effect_name)
	DirAccess.make_dir_recursive_absolute(dir)
	for frame in SHOT_FRAMES:
		var image := Image.create(SHOT_SIZE, SHOT_SIZE, false, Image.FORMAT_RGBA8)
		var phase := TAU * frame / SHOT_FRAMES
		var center := Vector2.ONE * SHOT_SIZE / 2.0
		for y in SHOT_SIZE:
			for x in SHOT_SIZE:
				var offset := Vector2(x, y) + Vector2.ONE * 0.5 - center
				var distance := offset.length()
				var wobble := sin(offset.angle() * 3.0 + phase) * 1.2
				if distance < 2.5:
					image.set_pixel(x, y, Color(hexes[2]))
				elif distance < 4.5 + wobble * 0.5:
					image.set_pixel(x, y, Color(hexes[1]))
				elif distance < 7.0 + wobble:
					image.set_pixel(x, y, Color(hexes[0]))
		image.save_png(dir.path_join("%d.png" % (frame + 1)))

func _render_zone(effect_name: String, hexes: Array) -> void:
	var dir: String = OUT_DIR.path_join(effect_name)
	DirAccess.make_dir_recursive_absolute(dir)
	var random := RandomNumberGenerator.new()
	random.seed = effect_name.hash()
	var particles: Array[Vector3] = []
	for i in ZONE_PARTICLES:
		particles.append(Vector3(random.randf(), random.randf(), random.randf()))
	var half := ZONE_SIZE / 2.0
	for frame in ZONE_FRAMES:
		var image := Image.create(ZONE_SIZE, ZONE_SIZE, false, Image.FORMAT_RGBA8)
		for y in ZONE_SIZE:
			for x in ZONE_SIZE:
				var distance := (Vector2(x, y) + Vector2.ONE * 0.5 - Vector2.ONE * half).length()
				if distance > half - 2.0 and distance < half - 0.5:
					image.set_pixel(x, y, Color(Color(hexes[0]), 0.7))
		for particle in particles:
			var life := fposmod(float(frame) / ZONE_FRAMES + particle.z, 1.0)
			var angle := particle.x * TAU
			var spot := Vector2.from_angle(angle) * sqrt(particle.y) * (half - 4.0)
			var pixel := Vector2i(spot + Vector2(half, half - life * 8.0 + 4.0))
			var color := Color(hexes[1] if life < 0.5 else hexes[0])
			for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]:
				var target: Vector2i = pixel + offset
				if target.x >= 0 and target.y >= 0 and target.x < ZONE_SIZE and target.y < ZONE_SIZE:
					image.set_pixelv(target, Color(color, 1.0 - life * 0.6))
		image.save_png(dir.path_join("%d.png" % (frame + 1)))
