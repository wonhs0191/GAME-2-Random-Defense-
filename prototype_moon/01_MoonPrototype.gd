extends Node2D

@onready var unit_04c = $"04CUnit"

func _ready():
	print("Unit: ", unit_04c)
	print("적 그룹: ", get_tree().get_nodes_in_group("Enemy"))

func _process(delta):
	pass

# attack 버튼을 눌렀을 때 호출되는 함수
func _on_attack_test_pressed():
	if unit_04c:
		unit_04c.attempt_attack()

# upgrade 버튼을 눌렀을 때 호출되는 함수
func _on_upgrade_test_pressed():
	if unit_04c:
		unit_04c.upgrade()
