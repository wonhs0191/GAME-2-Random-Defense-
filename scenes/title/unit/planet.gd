extends Node2D

@export var switch_duration: float = 7.0  # 애니메이션 전환 시간 (초)
@export var fade_duration: float = 1.0  # Fade 효과 지속 시간 (초)
@export var screen_fade_duration_multiplier: float = 2.0  # Screen fade in 속도 배율 (행성보다 느리게)
@export var planet_texts: Array[String] = [  # 각 애니메이션별 Label 텍스트
	"  ID :  308913\n  TYPE1 : TERRAN\n  TYPE2 : DRY\n  ROTATION : 10\n",
	"  ID :  259900\n  TYPE1 : TERRAN\n  TYPE2 : ICE\n  ROTATION : 15\n",
	"  ID :  262888\n  TYPE1 : TERRAN\n  TYPE2 : LAVA\n  ROTATION : 20\n",
	"  ID :  284134\n  TYPE1 : NO ATM \n  TYPE2 : DRY\n  ROTATION : 25\n",
	"  ID :  294788\n  TYPE1 : TERRAN\n  TYPE2 : DRY\n  ROTATION : 5\n",
	"  ID :  308913\n  TYPE1 : ISLAND\n  TYPE2 : WET\n  ROTATION : 30\n",
	"  ID :  259900\n  TYPE1 : GALAXY\n  TYPE2 : NONE\n  ROTATION : 15\n",
	"  ID :  262888\n  TYPE1 : NO ATM \n  TYPE2 : DRY\n  ROTATION : 10\n",
]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var screen: Control = $Screen
@onready var label: Label = $Screen/Label
@onready var switch_timer: Timer = Timer.new()

var animations = ["planet1", "planet2", "planet3", "planet4", "planet5", "planet6", "planet7", "planet8"]
var current_animation_index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Timer 설정
	add_child(switch_timer)
	switch_timer.one_shot = true
	switch_timer.timeout.connect(_on_switch_timer_timeout)
	
	# 첫 번째 애니메이션 시작 (투명하게 시작)
	animated_sprite.animation = animations[current_animation_index]
	animated_sprite.play()
	animated_sprite.modulate.a = 0.0  # 투명하게 시작
	
	# 첫 번째 애니메이션에 해당하는 Label 텍스트 설정
	if current_animation_index < planet_texts.size():
		label.text = planet_texts[current_animation_index]
	
	# Screen 노드 초기 상태 설정 (투명하게 시작)
	screen.visible = true
	screen.modulate.a = 0.0
	
	# Planet fade in 시작
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 1.0, fade_duration)
	tween.tween_callback(_on_initial_fade_in_complete)
	
	# 설정된 시간 후 다음 애니메이션으로 전환
	switch_timer.wait_time = switch_duration
	switch_timer.start()


func start_animation():
	# 현재 애니메이션 설정 및 재생
	animated_sprite.animation = animations[current_animation_index]
	animated_sprite.play()
	
	# 설정된 시간 후 다음 애니메이션으로 전환
	switch_timer.wait_time = switch_duration
	switch_timer.start()


func _on_switch_timer_timeout():
	# Screen 노드를 invisible로 설정
	screen.visible = false
	
	# Fade out 시작
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(_switch_to_next_animation)


func _switch_to_next_animation():
	# 다음 애니메이션 인덱스로 이동 (순환)
	current_animation_index = (current_animation_index + 1) % animations.size()
	
	# 애니메이션 변경
	animated_sprite.animation = animations[current_animation_index]
	animated_sprite.play()
	
	# 해당 애니메이션에 맞는 Label 텍스트 설정
	if current_animation_index < planet_texts.size():
		label.text = planet_texts[current_animation_index]
	
	# Fade in 시작
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 1.0, fade_duration)
	tween.tween_callback(_on_fade_in_complete)
	
	# 다음 전환을 위한 타이머 재시작
	switch_timer.wait_time = switch_duration
	switch_timer.start()


func _on_initial_fade_in_complete():
	# 초기 시작 시 Screen fade in (행성보다 느리게)
	screen.visible = true
	screen.modulate.a = 0.0  # 투명하게 시작
	
	var screen_fade_duration = fade_duration * screen_fade_duration_multiplier
	var screen_tween = create_tween()
	screen_tween.tween_property(screen, "modulate:a", 1.0, screen_fade_duration)


func _on_fade_in_complete():
	# Screen 노드를 visible로 설정하고 fade in 시작
	screen.visible = true
	screen.modulate.a = 0.0  # 투명하게 시작
	
	# Screen fade in (행성보다 느리게)
	var screen_fade_duration = fade_duration * screen_fade_duration_multiplier
	var screen_tween = create_tween()
	screen_tween.tween_property(screen, "modulate:a", 1.0, screen_fade_duration)
