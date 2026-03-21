extends CharacterBody2D

class_name EnemyBase

var move_speed: float = 50.0          # 이동 속도

func _ready():
	# 씬 실행 시 default 애니메이션 자동 재생
	var engine = $Engine
	if engine:
		engine.play("default")
