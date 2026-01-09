extends Area2D

# 투사체 속성
var speed = 400
var damage = 10
var target = null

@onready var animation_sprite = $AnimatedSprite2D

func _ready():
	pass

func _process(delta):
	# 타겟이 유효한지 확인
	if is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		position += direction * speed * delta
		look_at(target.global_position)
	else:
		queue_free()

# Area2D 충돌 감지
func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("적에 충돌! 데미지: ", damage)
		queue_free()
