extends Node2D

func _ready():
	# 씬 실행 시 default 애니메이션 자동 재생
	var animation = $AnimatedSprite2D
	if animation:
		animation.play("default")