extends AnimatedSprite2D

class_name Projectile

# SHOT 유닛의 유도 투사체. 대상이 먼저 사라지면 마지막 위치까지 날아가 소멸한다.

const SPEED := 420.0

var target: EnemyBase
var damage: float = 0.0

var _destination: Vector2

func launch(effect_frames: SpriteFrames, from: Vector2, enemy: EnemyBase, amount: float) -> void:
	sprite_frames = effect_frames
	global_position = from
	target = enemy
	damage = amount
	_destination = enemy.global_position
	play("default")

func _process(delta: float) -> void:
	if is_instance_valid(target):
		_destination = target.global_position

	var offset := _destination - global_position
	var step := SPEED * delta
	if offset.length() > step:
		global_position += offset.normalized() * step
		return

	if is_instance_valid(target) and target.is_in_group("enemy"):
		target.take_damage(damage)
	queue_free()
