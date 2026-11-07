extends Node2D

# 난이도 버튼 장식용 함선. 엔진 애니메이션만 재생한다.

func _ready() -> void:
	$Engine.play("default")
