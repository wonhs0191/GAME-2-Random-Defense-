extends Node2D

@export var switch_duration: float = 5.0  # 애니메이션 전환 시간 (초)
@export var fade_duration: float = 0.5  # Fade 효과 지속 시간 (초)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var switch_timer: Timer = Timer.new()

var animations = ["planet1", "planet2", "planet3", "planet4", "planet5"]
var current_animation_index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Timer 설정
	add_child(switch_timer)
	switch_timer.one_shot = true
	switch_timer.timeout.connect(_on_switch_timer_timeout)
	
	# 첫 번째 애니메이션 시작 (fade in 없이)
	animated_sprite.animation = animations[current_animation_index]
	animated_sprite.play()
	animated_sprite.modulate.a = 1.0
	
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
	
	# Fade in 시작
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 1.0, fade_duration)
	
	# 다음 전환을 위한 타이머 재시작
	switch_timer.wait_time = switch_duration
	switch_timer.start()
