extends Area2D

func _ready():
	# 애니메이션 플레이어가 있으면 항상 애니메이션 실행
	var anim_player = $AnimatedSprite2D
	if anim_player:
		if not anim_player.is_playing():
			anim_player.play("default") # "default" 애니메이션 이름에 맞게 수정

func _process(_delta):
	# 따로 처리 필요 없음 (애니메이션은 AnimationPlayer에서 루프되므로)
	pass
