extends AnimatedSprite2D

class_name ZoneField

# ZONE 유닛이 경로 위에 깔아 두는 장판의 표시. 피해 계산은 유닛이 한다.

const FRAME_SIZE := 32.0

# 불꽃 그림은 프레임 아래쪽에 치우친 것이 있어 무게중심을 노드 위치에 맞춘다.
func setup(effect_frames: SpriteFrames, radius: float, effect_center: Vector2) -> void:
	sprite_frames = effect_frames
	scale = Vector2.ONE * (radius * 2.0 / FRAME_SIZE)
	offset = Vector2.ONE * FRAME_SIZE / 2.0 - effect_center
	play("default")
