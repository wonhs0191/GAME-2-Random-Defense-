extends AnimatedSprite2D

class_name ZoneField

# ZONE 유닛이 경로 위에 깔아 두는 장판의 표시. 피해 계산은 유닛이 한다.

const FRAME_SIZE := 32.0

func setup(effect_frames: SpriteFrames, radius: float) -> void:
	sprite_frames = effect_frames
	scale = Vector2.ONE * (radius * 2.0 / FRAME_SIZE)
	play("default")
