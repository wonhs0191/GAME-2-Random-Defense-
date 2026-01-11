extends Area2D

func _ready():
	# 애니메이션 플레이어가 있으면 항상 애니메이션 실행
	var anim_sprite = $AnimatedSprite2D
	if anim_sprite:
		if not anim_sprite.is_playing():
			anim_sprite.play("default") # "default" 애니메이션 이름에 맞게 수정

func _process(_delta):
	# 따로 처리 필요 없음 (애니메이션은 AnimatedSprite2D에서 루프되므로)
	pass
