extends Node2D

@onready var fighter_timer = $fighter_timer
@onready var path_2d       = $Path2D

const FIGHTER_SCENE = preload("res://enemy/nautolan/fighter/fighter.tscn")

func _ready():
	# 부모 노드를 찾아서 game_play의 wave_started signal에 연결
	var parent = get_parent()  # map 노드
	if parent:
		var game_play_node = parent.get_parent()  # GamePlay 노드
		if game_play_node and game_play_node.has_signal("wave_started"):
			game_play_node.wave_started.connect(_on_wave_started)

func _on_wave_started():
	fighter_timer.start()

func _on_fighter_timer_timeout():
	var fighter_instance = FIGHTER_SCENE.instantiate()
	path_2d.add_child(fighter_instance)
