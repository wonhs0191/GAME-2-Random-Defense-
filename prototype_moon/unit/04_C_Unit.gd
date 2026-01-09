extends AnimatedSprite2D

# 총알 씬 파일 연결
@export var projectile_scene: PackedScene 
@export var range_radius = 3000.0

# 업그레이드 상태
var is_upgraded = false

func _ready():
	pass

func _process(delta):
	pass

func attempt_attack():
	# 1. 적을 찾고
	var enemy = find_enemy()
	
	# 2. 적이 있으면 발사!
	if enemy != null:
		fire(enemy)
	else:
		print("사거리 내에 적이 없습니다!")

# 적 찾기
func find_enemy():
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) <= range_radius:
			return enemy
	return null

# 발사
func fire(target):
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.target = target
	projectile.damage = 20
	get_parent().add_child(projectile)
	if is_upgraded:
		projectile.animation_sprite.play("Idle_Cp")
	print("투사체 발사! 타겟: ", target.name)

# 강화
func upgrade():
	# 본인 애니메이션 프레임 변경
	play("Idle_Cp")
	is_upgraded = true
