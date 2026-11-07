extends CPUParticles2D

class_name Firework

# 뽑기 폭죽. 한 번 터지고 사라진다.

const SPARK_LIFETIME := 0.9
const SPARK_SPEED_MIN := 70.0
const SPARK_SPEED_MAX := 260.0
const SPARK_GRAVITY := Vector2(0, 170)

func setup(spark_color: Color, spark_count: int) -> void:
	color = spark_color
	amount = spark_count

func _ready() -> void:
	one_shot = true
	explosiveness = 1.0
	lifetime = SPARK_LIFETIME
	spread = 180.0
	gravity = SPARK_GRAVITY
	initial_velocity_min = SPARK_SPEED_MIN
	initial_velocity_max = SPARK_SPEED_MAX
	scale_amount_min = 3.0
	scale_amount_max = 6.0
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	color_ramp = fade
	finished.connect(queue_free)
	emitting = true
	Sound.play("firework")
